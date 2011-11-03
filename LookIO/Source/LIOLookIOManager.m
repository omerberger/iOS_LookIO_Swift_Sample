//
//  LIOLookIOManager.m
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioToolbox.h>
#import <sys/socket.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <sys/sysctl.h>
#import "LIOLookIOManager.h"
#import "AsyncSocket.h"
#import "SBJSON.h"
#import "LIOChatboxView.h"
#import "NSData+Base64.h"
#import "LIOChatViewController.h"
#import "LIOLeaveMessageViewController.h"
#import "LIOEmailHistoryViewController.h"
#import "LIOAboutViewController.h"
#import "LIOControlButtonView.h"

// Misc. constants
#define LIOLookIOManagerVersion @"1.0.0"

#define LIOLookIOManagerScreenCaptureInterval   0.33

#define LIOLookIOManagerWriteTimeout            5.0

#define LIOLookIOManagerControlEndpointRequestURL   @"http://connect.look.io/api/v1/endpoint"
#define LIOLookIOManagerControlEndpointPort         8100
#define LIOLookIOManagerControlEndpointPortTLS      9000

#define LIOLookIOManagerMessageSeparator        @"!look.io!"

#define LIOLookIOManagerDisconnectConfirmAlertViewTag       1
#define LIOLookIOManagerScreenshotPermissionAlertViewTag    2
#define LIOLookIOManagerDisconnectErrorAlertViewTag         3
#define LIOLookIOManagerNoAgentsOnlineAlertViewTag          4
#define LIOLookIOManagerUnprovisionedAlertViewTag           5
#define LIOLookIOManagerAgentEndedSessionAlertViewTag       6

@interface LIOLookIOManager ()
{
    NSTimer *screenCaptureTimer;
    UIImage *touchImage;
    AsyncSocket_LIO *controlSocket;
    BOOL waitingForScreenshotAck, waitingForIntroAck, controlSocketConnecting, introduced, enqueued;
    NSData *messageSeparatorData;
    NSData *lastScreenshotSent;
    SBJsonParser_LIO *jsonParser;
    SBJsonWriter_LIO *jsonWriter;
    UIImageView *cursorView, *clickView;
    LIOControlButtonView *controlButton;
    NSMutableArray *chatHistory;
    SystemSoundID soundYay, soundDing;
    BOOL unloadAfterDisconnect, killConnectionAfterChatViewDismissal;
    BOOL minimized;
    NSNumber *lastKnownQueuePosition;
    BOOL screenshotsAllowed;
    UIBackgroundTaskIdentifier backgroundTaskId;
    NSString *targetAgentId;
    BOOL usesTLS, usesControlButton, usesSounds;
    UIWindow *lookioWindow;
    NSMutableURLRequest *endpointRequest;
    NSURLConnection *endpointRequestConnection;
    NSString *controlEndpoint;
    NSMutableData *endpointRequestData;
    NSInteger endpointRequestHTTPResponseCode;
    NSInteger numIncomingChatMessages;
    LIOChatViewController *chatViewController;
    LIOEmailHistoryViewController *emailHistoryViewController;
    LIOLeaveMessageViewController *leaveMessageViewController;
    LIOAboutViewController *aboutViewController;
    NSString *pendingFeedbackText;
    NSString *friendlyName;
    NSArray *supportedOrientations;
    BOOL pendingLeaveMessage;
    NSDictionary *sessionExtras;
    UIWindow *previousKeyWindow;
}

@property(nonatomic, readonly) BOOL screenshotsAllowed;

- (void)controlButtonWasTapped;
- (void)rejiggerWindows;

@end

NSBundle *lookioBundle()
{
    static NSBundle *bundle = nil;
    
    if (nil == bundle)
    {
        NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"LookIO.bundle"];
        bundle = [[NSBundle bundleWithPath:path] retain];
    }
    
    return bundle;
}

UIImage *lookioImage(NSString *path)
{
    NSBundle *bundle = lookioBundle();
    if (bundle)
    {
        if ([UIScreen instancesRespondToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2.0)
        {
            NSString *path2x = [path stringByAppendingString:@"@2x"];
            NSString *actualPath = [bundle pathForResource:path2x ofType:@"png"];
            if ([actualPath length])
            {
                NSData *fileData = [NSData dataWithContentsOfFile:actualPath];
                if (fileData)
                {
                    UIImage *newImage = [UIImage imageWithData:fileData];
                    return [[[UIImage alloc] initWithCGImage:[newImage CGImage] scale:2.0 orientation:UIImageOrientationUp] autorelease];
                }
            }
        }
        
        NSString *actualPath = [bundle pathForResource:path ofType:@"png"];
        if ([actualPath length])
        {
            NSData *fileData = [NSData dataWithContentsOfFile:actualPath];
            if (fileData)
                return [UIImage imageWithData:fileData];
        }
        
#ifdef DEBUG
            NSLog(@"[LOOKIO] Couldn't find normal or @2x file for resource \"%@\" in LookIO bundle!", path);
#endif
    }
    else
    {
#ifdef DEBUG
        NSLog(@"[LOOKIO] No LookIO bundle! Loading \"%@\" from main bundle...", path);
#endif
        return [UIImage imageNamed:path];
    }
    
    // Never reached.
    return nil;
}

NSString *uniqueIdentifier()
{
    int mib[6];
    size_t len;
    char *buf;
    unsigned char *ptr;
    struct if_msghdr *ifm;
    struct sockaddr_dl *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0)
    {
        printf("Error: if_nametoindex error\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0)
    {
        printf("Error: sysctl, take 1\n");
        return NULL;
    }
    
    if ((buf = malloc(len)) == NULL)
    {
        printf("Could not allocate memory. error!\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0)
    {
        printf("Error: sysctl, take 2");
        return NULL;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    NSString *outstring = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X", 
                           *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    free(buf);
    
    const char *value = [outstring UTF8String];
    
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, strlen(value), outputBuffer);
    
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++)
        [outputString appendFormat:@"%02x",outputBuffer[count]];
    
    return [outputString autorelease];
}

@implementation LIOLookIOManager

@synthesize touchImage, targetAgentId, usesTLS, usesControlButton, usesSounds, screenshotsAllowed, supportedOrientations, sessionExtras;
@dynamic controlButtonOrigin, horizontalControlButton;

static LIOLookIOManager *sharedLookIOManager = nil;

+ (LIOLookIOManager *)sharedLookIOManager
{
    if (nil == sharedLookIOManager)
        sharedLookIOManager = [[LIOLookIOManager alloc] init];
    
    return sharedLookIOManager;
}

- (id)init
{
    NSAssert([NSThread currentThread] == [NSThread mainThread], @"LookIO can only be used on the main thread!");
    
    self = [super init];
    
    if (self)
    {
        // Try to get supported orientation information from plist.
        NSArray *plistOrientations = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedInterfaceOrientations"];
        if (plistOrientations)
        {
            NSMutableArray *orientationNumbers = [NSMutableArray array];
            
            if ([plistOrientations containsObject:@"UIInterfaceOrientationPortrait"])
                [orientationNumbers addObject:[NSNumber numberWithInt:UIInterfaceOrientationPortrait]];
            
            if ([plistOrientations containsObject:@"UIInterfaceOrientationPortraitUpsideDown"])
                [orientationNumbers addObject:[NSNumber numberWithInt:UIInterfaceOrientationPortraitUpsideDown]];
            
            if ([plistOrientations containsObject:@"UIInterfaceOrientationLandscapeLeft"])
                [orientationNumbers addObject:[NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft]];

            if ([plistOrientations containsObject:@"UIInterfaceOrientationLandscapeRight"])
                [orientationNumbers addObject:[NSNumber numberWithInt:UIInterfaceOrientationLandscapeRight]];
            
            supportedOrientations = [orientationNumbers retain];
        }
        else
        {
            supportedOrientations = [[NSArray alloc] initWithObjects:[NSNumber numberWithInt:UIInterfaceOrientationPortrait], [NSNumber numberWithInt:UIInterfaceOrientationPortraitUpsideDown], [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft], [NSNumber numberWithInt:UIInterfaceOrientationLandscapeRight], nil];
        }
        
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        lookioWindow = [[UIWindow alloc] initWithFrame:keyWindow.frame];
        lookioWindow.hidden = YES;
        lookioWindow.windowLevel = 0.1;
        
        controlSocket = [[AsyncSocket_LIO alloc] initWithDelegate:self];
        
        screenCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:LIOLookIOManagerScreenCaptureInterval
                                                              target:self
                                                            selector:@selector(screenCaptureTimerDidFire:)
                                                            userInfo:nil
                                                             repeats:YES];
        
        messageSeparatorData = [[LIOLookIOManagerMessageSeparator dataUsingEncoding:NSUTF8StringEncoding] retain];
        
        jsonParser = [[SBJsonParser_LIO alloc] init];
        jsonWriter = [[SBJsonWriter_LIO alloc] init];
        
        self.touchImage = lookioImage(@"LIODefaultTouch");
        
        chatHistory = [[NSMutableArray alloc] init];

        controlButton = [[LIOControlButtonView alloc] initWithFrame:CGRectMake(0.0, 68.0, 100.0, 24.0)];
        controlButton.alpha = 0.0;
        controlButton.hidden = YES;
        controlButton.delegate = self;
        [keyWindow addSubview:controlButton];
                
        endpointRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:LIOLookIOManagerControlEndpointRequestURL]
                                                       cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                   timeoutInterval:10.0];
        [endpointRequest setValue:[[NSBundle mainBundle] bundleIdentifier] forHTTPHeaderField:@"X-LookIO-BundleID"];
        
        NSString *aPath = [lookioBundle() pathForResource:@"LookIODing" ofType:@"caf"];
        if ([aPath length])
        {
            NSURL *soundURL = [NSURL fileURLWithPath:aPath];
            AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &soundDing);
        }
        else
        {
            NSString *anotherPath = [[NSBundle mainBundle] pathForResource:@"LookIODing" ofType:@"caf"];
            if ([anotherPath length])
            {
                NSURL *soundURL = [NSURL fileURLWithPath:anotherPath];
                AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &soundDing);
            }
        }
        
        aPath = [lookioBundle() pathForResource:@"LookIOConnect" ofType:@"caf"];
        if ([aPath length])
        {
            NSURL *soundURL = [NSURL fileURLWithPath:aPath];
            AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &soundYay);
        }
        else
        {
            NSString *anotherPath = [[NSBundle mainBundle] pathForResource:@"LookIOConnect" ofType:@"caf"];
            if ([anotherPath length])
            {
                NSURL *soundURL = [NSURL fileURLWithPath:anotherPath];
                AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &soundYay);
            }
        }
                
        backgroundTaskId = UIBackgroundTaskInvalid;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillResignActive:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(deviceOrientationDidChange:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        
        usesTLS = YES;
        usesControlButton = NO;
        usesSounds = YES;
        numIncomingChatMessages = 0;
        
        NSLog(@"[LOOKIO] Loaded.");
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.touchImage = nil;
    
    [controlSocket disconnect];
    [controlSocket release];
    [messageSeparatorData release];
    [jsonParser release];
    [jsonWriter release];
    [cursorView release];
    [clickView release];
    [controlButton release];
    [chatHistory release];
    [lastScreenshotSent release];
    [lastKnownQueuePosition release];
    [targetAgentId release];
    [endpointRequest release];
    [controlEndpoint release];
    [endpointRequestConnection release];
    [endpointRequestData release];
    [pendingFeedbackText release];
    [friendlyName release];
    [supportedOrientations release];
    
    [leaveMessageViewController release];
    leaveMessageViewController = nil;
    
    [emailHistoryViewController release];
    emailHistoryViewController = nil;
    
    [aboutViewController release];
    aboutViewController = nil;
    
    [chatViewController release];
    chatViewController = nil;
    
    AudioServicesDisposeSystemSoundID(soundDing);
    AudioServicesDisposeSystemSoundID(soundYay);
    
    [self rejiggerWindows];
    
    [lookioWindow release];
    
    NSLog(@"[LOOKIO] Unloaded.");
    
    [super dealloc];
}

- (void)unload
{
    [chatViewController.view removeFromSuperview];
    [aboutViewController.view removeFromSuperview];
    [leaveMessageViewController.view removeFromSuperview];
    [emailHistoryViewController.view removeFromSuperview];
    
    [cursorView removeFromSuperview];
    [clickView removeFromSuperview];
    [controlButton removeFromSuperview];
    
    [controlSocket setDelegate:nil];
    
    [screenCaptureTimer invalidate];
    screenCaptureTimer = nil;
    
    [sharedLookIOManager release];
    sharedLookIOManager = nil;
}

- (void)rejiggerWindows
{
    if (chatViewController || leaveMessageViewController || emailHistoryViewController || aboutViewController)
    {
        if (nil == previousKeyWindow)
        {
            previousKeyWindow = [[UIApplication sharedApplication] keyWindow];
            [lookioWindow makeKeyAndVisible];
        }
    }
    else
    {
        lookioWindow.hidden = YES;
        
        [previousKeyWindow makeKeyAndVisible];
        previousKeyWindow = nil;
        
        if (usesControlButton)
            [controlButton startFadeTimer];
    }
    
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
}

- (UIImage *)captureScreen
{
    CGSize imageSize = [[UIScreen mainScreen] bounds].size;
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 1.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Iterate over every window from back to front
    for (UIWindow *window in [[UIApplication sharedApplication] windows]) 
    {
        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen])
        {
            // -renderInContext: renders in the coordinate space of the layer,
            // so we must first apply the layer's geometry to the graphics context
            CGContextSaveGState(context);
            // Center the context around the window's anchor point
            CGContextTranslateCTM(context, [window center].x, [window center].y);
            // Apply the window's transform about the anchor point
            CGContextConcatCTM(context, [window transform]);
            // Offset by the portion of the bounds left of and above the anchor point
            CGContextTranslateCTM(context,
                                  -[window bounds].size.width * [[window layer] anchorPoint].x,
                                  -[window bounds].size.height * [[window layer] anchorPoint].y);
            
            // Render the layer hierarchy to the current context
            [[window layer] renderInContext:context];
            
            // Restore the context
            CGContextRestoreGState(context);
        }
    }
    
    // Retrieve the screenshot image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

- (NSString *)nextGUID
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
    NSString *newUUID = (NSString *)uuidString;
    CFRelease(uuid);
    return [newUUID autorelease];
}

- (void)screenCaptureTimerDidFire:(NSTimer *)aTimer
{
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (keyWindow != lookioWindow)
    {
        [keyWindow bringSubviewToFront:controlButton];
        [keyWindow bringSubviewToFront:cursorView];
        [keyWindow bringSubviewToFront:clickView];
    }
    
    if (NO == [controlSocket isConnected] || waitingForScreenshotAck || NO == introduced || YES == enqueued || NO == screenshotsAllowed || chatViewController || aboutViewController)
        return;
    
    if (UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
        return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *screenshotImage = [self captureScreen];
        CGSize screenshotSize = screenshotImage.size;
        NSData *screenshotData = UIImageJPEGRepresentation(screenshotImage, 0.0);
        if (nil == lastScreenshotSent || NO == [lastScreenshotSent isEqualToData:screenshotData])
        {
            [lastScreenshotSent release];
            lastScreenshotSent = [screenshotData retain];
            
            NSString *base64Data = base64EncodedStringFromData(screenshotData);
            
            NSString *orientation = @"portrait";
            if (UIInterfaceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
                orientation = @"landscape";
            /*
            else if (UIInterfaceOrientationPortraitUpsideDown == [[UIDevice currentDevice] orientation])
                orientation = @"portrait_ud";
             */
            
            NSString *screenshot = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                 @"screenshot", @"type",
                                                                 [self nextGUID], @"screenshot_id",
                                                                 base64Data, @"screenshot",
                                                                 [NSNumber numberWithFloat:screenshotSize.width], @"width",
                                                                 [NSNumber numberWithFloat:screenshotSize.height], @"height",
                                                                 orientation, @"orientation",
                                                                 nil]];
            
            screenshot = [screenshot stringByAppendingString:LIOLookIOManagerMessageSeparator];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                waitingForScreenshotAck = YES;
                [controlSocket writeData:[screenshot dataUsingEncoding:NSUTF8StringEncoding]
                             withTimeout:-1
                                     tag:0];
                
#ifdef DEBUG
                NSLog(@"[SCREENSHOT] Sent %dx%d %@ screenshot (base64: %u bytes).", (int)screenshotSize.width, (int)screenshotSize.height, orientation, [base64Data length]);
#endif
            });
        }
    });
}

/*
- (void)showConnectionUI
{
    if (connectViewController)
        return;
    
    connectViewController = [[LIOConnectViewController alloc] initWithNibName:nil bundle:nil];
    connectViewController.delegate = self;
    
    connectViewController.targetLogoBoundsForHiding = self.controlButtonBounds;
    if (UIInterfaceOrientationIsLandscape((UIInterfaceOrientation)[[UIDevice currentDevice] orientation]))
        connectViewController.targetLogoCenterForHiding = self.controlButtonCenterLandscape;
    else
        connectViewController.targetLogoCenterForHiding = self.controlButtonCenter;
    
    [lookioWindow addSubview:connectViewController.view];
    [self rejiggerWindows];
    
    if (lastKnownQueuePosition)
    {
        if ([lastKnownQueuePosition intValue] == 1)
            connectViewController.connectionLabel.text = [NSString stringWithFormat:@"Waiting for live agent..."];
        else
            connectViewController.connectionLabel.text = [NSString stringWithFormat:@"You are number %@ in line.", lastKnownQueuePosition];
    }
    else if (controlSocketConnecting)
    {
        connectViewController.connectionLabel.text = @"Connecting to a live agent...";
    }
    else
    {
        connectViewController.connectionLabel.text = @"Not connected.";
    }
    
    [connectViewController showAnimated:YES];
    
    if (0 == [friendlyName length])
    {
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [connectViewController showNameEntryFieldAnimated:YES];
        });
    }
}
*/

- (void)showChat
{
    if (chatViewController)
        return;
    
    chatViewController = [[LIOChatViewController alloc] initWithNibName:nil bundle:nil];
    chatViewController.delegate = self;
    chatViewController.dataSource = self;
    chatViewController.view.alpha = 0.0;
    [lookioWindow addSubview:chatViewController.view];
    [self rejiggerWindows];
    
    [chatViewController performRevealAnimation];
    
    [chatViewController reloadMessages];
    //[chatViewController scrollToBottom];
    
    if (usesSounds)
        AudioServicesPlaySystemSound(soundYay);
    
    if (introduced)
    {
        NSString *chatUp = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                         @"advisory", @"type",
                                                         @"chat_up", @"action",
                                                         nil]];
        chatUp = [chatUp stringByAppendingString:LIOLookIOManagerMessageSeparator];
        
        [controlSocket writeData:[chatUp dataUsingEncoding:NSUTF8StringEncoding]
                     withTimeout:LIOLookIOManagerWriteTimeout
                             tag:0];
    }
    
    controlButton.hidden = YES;
}

- (void)showLeaveMessageUI
{
    if (leaveMessageViewController)
        return;
    
    leaveMessageViewController = [[LIOLeaveMessageViewController alloc] initWithNibName:nil bundle:nil];
    leaveMessageViewController.delegate = self;
    leaveMessageViewController.initialMessage = pendingFeedbackText;
    [lookioWindow addSubview:leaveMessageViewController.view];
    [self rejiggerWindows];
}

- (void)showAboutUI
{
    if (aboutViewController)
        return;
    
    aboutViewController = [[LIOAboutViewController alloc] initWithNibName:nil bundle:nil];
    aboutViewController.delegate = self;
    [lookioWindow addSubview:aboutViewController.view];
    [self rejiggerWindows];
}

- (void)beginSession
{
    if (controlSocketConnecting || endpointRequestConnection)
    {
        NSLog(@"[CONNECT] Connect attempt ignored: connecting or already connected.");
        return;
    }
    
    if ([controlSocket isConnected])
    {
        [self controlButtonWasTapped];
        return;
    }

    // Bypass REST call.
    [controlEndpoint release];
    controlEndpoint = [[NSString stringWithString:@"connect.look.io"] retain];
    
    if (0 == [controlEndpoint length])
    {
        if (nil == endpointRequestConnection)
        {
            endpointRequestConnection = [[NSURLConnection alloc] initWithRequest:endpointRequest delegate:self startImmediately:YES];
            return;
        }
        else
            return;
    }
     
    
    NSUInteger chosenPort = LIOLookIOManagerControlEndpointPortTLS;
    if (NO == usesTLS)
        chosenPort = LIOLookIOManagerControlEndpointPort;
    
    NSError *connectError = nil;
    BOOL connectResult = [controlSocket connectToHost:controlEndpoint
                                               onPort:chosenPort
                                                error:&connectError];
    if (NO == connectResult)
    {
        [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
        
        NSLog(@"[CONNECT] Connection failed. Reason: %@", [connectError localizedDescription]);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                            message:[connectError localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"k :(", nil];
        [alertView show];
        [alertView autorelease];
        
        controlSocketConnecting = NO;
        
        return;
    }
    
    if (usesSounds)
        AudioServicesPlaySystemSound(soundDing);
    
#ifdef DEBUG
    NSLog(@"[CONNECT] Trying \"%@:%u\"...", controlEndpoint, chosenPort);
#endif
    
    controlSocketConnecting = YES;
    
    //[self showConnectionUI];
    [chatHistory addObject:LIOChatboxViewAdTextTrigger];
    [chatHistory addObject:@"Send a message to our live service reps for immediate help."];
    [self showChat];
}

- (void)killConnection
{
    NSString *outro = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    @"outro", @"type",
                                                    nil]];
    outro = [outro stringByAppendingString:LIOLookIOManagerMessageSeparator];
    
    [controlSocket writeData:[outro dataUsingEncoding:NSUTF8StringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];
    
    [controlSocket disconnectAfterWriting];
}

- (void)recordCurrentUILocation:(NSString *)aLocationString
{
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:aLocationString, @"location_name", nil];
    NSString *uiLocation = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                         @"advisory", @"type",
                                                         @"ui_location", @"action",
                                                         dataDict, @"data",
                                                         nil]];
    uiLocation = [uiLocation stringByAppendingString:LIOLookIOManagerMessageSeparator];
    
    [controlSocket writeData:[uiLocation dataUsingEncoding:NSUTF8StringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];
}

- (void)handlePacket:(NSDictionary *)aPacket
{
    NSAssert([NSThread currentThread] == [NSThread mainThread], @"LookIO cannot be used on a non-main thread!");
    
    NSString *type = [aPacket objectForKey:@"type"];
    if ([type isEqualToString:@"ack"])
    {
        if (waitingForIntroAck)
        {
#ifdef DEBUG
            NSLog(@"[INTRODUCTION] Introduction complete.");
#endif
            introduced = YES;
            waitingForIntroAck = NO;
            enqueued = YES;
            
            [controlSocket readDataToData:messageSeparatorData
                              withTimeout:-1
                                      tag:0];
        }
        else if (waitingForScreenshotAck)
        {
#ifdef DEBUG
            NSLog(@"[SCREENSHOT] Screenshot received by remote host.");
#endif
            waitingForScreenshotAck = NO;
        }
    }
    else if ([type isEqualToString:@"chat"])
    {
        NSString *text = [aPacket objectForKey:@"text"];
        [chatHistory addObject:[NSString stringWithFormat:@"Agent: %@", text]];

        if (nil == chatViewController)
        {
            [self showChat];
        }
        else
        {
            [chatViewController reloadMessages];
            //[chatViewController scrollToBottom];
        }
        
        if (numIncomingChatMessages > 0 && UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
        {
            UILocalNotification *localNotification = [[[UILocalNotification alloc] init] autorelease];
            localNotification.soundName = @"LookIODing.caf";
            localNotification.alertBody = @"The support agent has sent a chat message to you.";
            localNotification.alertAction = @"Go!";
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
        }
        
        numIncomingChatMessages++;
    }
    else if ([type isEqualToString:@"cursor"])
    {
        if (nil == cursorView)
        {
            UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
            cursorView = [[UIImageView alloc] initWithImage:touchImage];
            [keyWindow addSubview:cursorView];
        }
        
        [lookioWindow bringSubviewToFront:cursorView];
        
        NSNumber *x = [aPacket objectForKey:@"x"];
        NSNumber *y = [aPacket objectForKey:@"y"];
        CGRect aFrame = cursorView.frame;
        aFrame.origin.x = [x floatValue];
        aFrame.origin.y = [y floatValue];
        
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState)
                         animations:^{ cursorView.frame = aFrame; }
                         completion:nil];
    }
    else if ([type isEqualToString:@"advisory"])
    {
        NSString *action = [aPacket objectForKey:@"action"];
        
        if ([action isEqualToString:@"cursor_start"])
        {
            UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
            
            if (nil == cursorView)
            {
                cursorView = [[UIImageView alloc] initWithImage:touchImage];
                [keyWindow addSubview:cursorView];
            }
            
            [keyWindow bringSubviewToFront:cursorView];
            
            CGRect aFrame = CGRectZero;
            aFrame.size.width = cursorView.image.size.width * 8.0;
            aFrame.size.height = cursorView.image.size.height * 8.0;
            aFrame.origin.x = (keyWindow.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
            aFrame.origin.y = (keyWindow.frame.size.height / 2.0) - (aFrame.size.height / 2.0);
            cursorView.frame = aFrame;
            cursorView.alpha = 0.0;
            
            aFrame.size.width = cursorView.image.size.width;
            aFrame.size.height = cursorView.image.size.height;
            aFrame.origin.x = (keyWindow.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
            aFrame.origin.y = (keyWindow.frame.size.height / 2.0) - (aFrame.size.height / 2.0);
            
            [UIView animateWithDuration:0.25
                                  delay:0.0
                                options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseIn)
                             animations:^{
                                 cursorView.frame = aFrame;
                                 cursorView.alpha = 1.0;
                             }
                             completion:nil];
            
        }
        else if ([action isEqualToString:@"cursor_end"])
        {
            /*
            UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
            
            if (nil == cursorView)
            {
                cursorView = [[UIImageView alloc] initWithImage:touchImage];
                [keyWindow addSubview:cursorView];
            }
            
            [keyWindow bringSubviewToFront:cursorView];
            
            CGRect aFrame = CGRectZero;
            aFrame.size.width = cursorView.image.size.width * 8.0;
            aFrame.size.height = cursorView.image.size.height * 8.0;
            aFrame.origin.x = (keyWindow.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
            aFrame.origin.y = (keyWindow.frame.size.height / 2.0) - (aFrame.size.height / 2.0);
            
            [UIView animateWithDuration:0.25
                                  delay:0.0
                                options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut)
                             animations:^{
                                 cursorView.frame = aFrame;
                                 cursorView.alpha = 0.0;
                             }
                             completion:nil];
             */
            cursorView.alpha = 0.0;
        }
        else if ([action isEqualToString:@"connected"])
        {
#ifdef DEBUG
            NSLog(@"[QUEUE] We're live!");
#endif
            enqueued = NO;
            
            if (UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
            {
                UILocalNotification *localNotification = [[[UILocalNotification alloc] init] autorelease];
                localNotification.soundName = @"LookIODing.caf";
                localNotification.alertBody = @"The support agent is ready to chat with you!";
                localNotification.alertAction = @"Go!";
                [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                
                [self showChat];
            }
        }
        else if ([action isEqualToString:@"queued"])
        {
            NSDictionary *data = [aPacket objectForKey:@"data"];
            NSNumber *online = [data objectForKey:@"online"];
            if (online && NO == [online boolValue])
            {
                pendingLeaveMessage = YES;
                /*
                if (chatViewController)
                    [chatViewController performDismissalAnimation];
                
                [self showLeaveMessageUI];
                
                 */
                /*
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry"
                                                                    message:@"No agents are available right now. Would you like to leave a message?"
                                                                   delegate:self
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"No", @"Yes", nil];
                alertView.tag = LIOLookIOManagerNoAgentsOnlineAlertViewTag;
                [alertView show];
                [alertView autorelease];
                 */
            }
            else
            {
                NSNumber *position = [data objectForKey:@"position"];
                [lastKnownQueuePosition release];
                lastKnownQueuePosition = [position retain];
            }
        }
        else if ([action isEqualToString:@"permission"])
        {
            NSDictionary *data = [aPacket objectForKey:@"data"];
            NSString *permission = [data objectForKey:@"permission"];
            if ([permission isEqualToString:@"screenshot"] && NO == screenshotsAllowed)
            {
                if (UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
                {
                    UILocalNotification *localNotification = [[[UILocalNotification alloc] init] autorelease];
                    localNotification.soundName = @"LookIODing.caf";
                    localNotification.alertBody = @"The support agent wants to view your screen.";
                    localNotification.alertAction = @"Go!";
                    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                }
                
                [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Question"
                                                                    message:@"Allow remote agent to see your screen?"
                                                                   delegate:self
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"No", @"Yes", nil];
                alertView.tag = LIOLookIOManagerScreenshotPermissionAlertViewTag;
                [alertView show];
                [alertView autorelease];
            }
        }
        else if ([action isEqualToString:@"unprovisioned"])
        {
            [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:@"This app is not configured for live help. Please contact the app developer."
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"Dismiss", nil];
            alertView.tag = LIOLookIOManagerUnprovisionedAlertViewTag;
            [alertView show];
            [alertView autorelease];
        }
    }
    else if ([type isEqualToString:@"click"])
    {
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        
        if (nil == clickView)
        {
            clickView = [[UIImageView alloc] initWithImage:lookioImage(@"LIOClickIndicator")];
            [keyWindow addSubview:clickView];
        }
        
        [keyWindow bringSubviewToFront:clickView];
        
        NSNumber *x = [aPacket objectForKey:@"x"];
        NSNumber *y = [aPacket objectForKey:@"y"];
        
#ifdef DEBUG
        NSLog(@"[CLICK] x: %@, y: %@", x, y);
#endif
        
        CGRect aFrame = CGRectZero;
        aFrame.origin.x = [x floatValue];
        aFrame.origin.y = [y floatValue];
        clickView.frame = aFrame;
        clickView.alpha = 0.0;
        
        aFrame.size.width = clickView.image.size.width * 2.0;
        aFrame.size.height = clickView.image.size.height * 2.0;
        aFrame.origin.x = clickView.frame.origin.x - (aFrame.size.width / 2.0);
        aFrame.origin.y = clickView.frame.origin.y - (aFrame.size.height / 2.0);
        
        [UIView animateWithDuration:0.1
                              delay:0.0
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut)
                         animations:^{
                             clickView.frame = aFrame;
                             clickView.alpha = 1.0;
                         }
                         completion:^(BOOL finished) {
                             [UIView animateWithDuration:0.1
                                                   delay:0.2
                                                 options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseIn)
                                              animations:^{
                                                  clickView.alpha = 0.0;
                                              }
                                              completion:nil];
                         }];
    }
    else if ([type isEqualToString:@"outro"])
    {
        if ([controlSocket isConnected])
        {
            unloadAfterDisconnect = YES;
            [self killConnection];
        }
        else
            [self unload];
        
        [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
        
        /*
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Notice"
                                                            message:@"The remote agent ended the session."
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Dismiss", nil];
        alertView.tag = LIOLookIOManagerAgentEndedSessionAlertViewTag;
        [alertView show];
        [alertView autorelease];
        */
    }
    
    [controlSocket readDataToData:messageSeparatorData
                      withTimeout:-1
                              tag:0];
}

- (void)performIntroduction
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);  
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);  
    NSString *deviceType = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
    free(machine);
    
    NSString *udid = uniqueIdentifier();
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    NSMutableDictionary *introDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      @"intro", @"type",
                                      udid, @"device_id",
                                      deviceType, @"device_type",
                                      bundleId, @"app_id",
                                      @"Apple iOS", @"platform",
                                      LIOLookIOManagerVersion, @"version",
                                      nil];
    if ([targetAgentId length])
        [introDict setObject:targetAgentId forKey:@"agent_id"];
    
    if ([sessionExtras count])
        [introDict setObject:sessionExtras forKey:@"extras"];
    
    NSString *intro = [jsonWriter stringWithObject:introDict];
    intro = [intro stringByAppendingString:LIOLookIOManagerMessageSeparator];
    
    waitingForIntroAck = YES;
    
    [controlSocket writeData:[intro dataUsingEncoding:NSUTF8StringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];
    
    [controlSocket readDataToData:messageSeparatorData
                      withTimeout:-1
                              tag:0];    
}

#pragma mark -
#pragma mark AsyncSocketDelegate methods

- (void)onSocket:(AsyncSocket_LIO *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    controlSocketConnecting = NO;
    
    NSLog(@"[CONNECT] Connected to %@:%u", host, port);
    
    if (usesTLS)
        [controlSocket startTLS:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], (NSString *)kCFStreamSSLAllowsAnyRoot, nil]];
    else
        [self performIntroduction];
}

- (void)onSocketDidSecure:(AsyncSocket_LIO *)sock
{
    NSLog(@"[CONNECT] Secured.");    
    
    [self performIntroduction];
}

- (void)onSocket:(AsyncSocket_LIO *)sock willDisconnectWithError:(NSError *)err
{
    controlSocketConnecting = NO;
    introduced = NO;
    waitingForIntroAck = NO;
    waitingForScreenshotAck = NO;
    enqueued = NO;
    
    if (err)
    {
        [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Couldn't connect right now. Please try again later!"
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Dismiss", nil];
        alertView.tag = LIOLookIOManagerDisconnectErrorAlertViewTag;
        [alertView show];
        [alertView autorelease];
    }
        
    unloadAfterDisconnect = YES;
    [self killConnection];
    
    NSLog(@"[CONNECT] Connection terminated unexpectedly. Reason: %@", [err localizedDescription]);
}

- (void)onSocketDidDisconnect:(AsyncSocket_LIO *)sock
{
    NSLog(@"[CONNECT] Socket disconnected.");
    
    if (unloadAfterDisconnect)
        [self unload];
}

- (void)onSocket:(AsyncSocket_LIO *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *jsonString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    jsonString = [jsonString substringToIndex:([jsonString length] - [LIOLookIOManagerMessageSeparator length])];
    NSDictionary *result = [jsonParser objectWithString:jsonString];
    
#ifdef DEBUG
    NSLog(@"\n[READ]\n%@\n", jsonString);
#endif
    
    [self performSelectorOnMainThread:@selector(handlePacket:) withObject:result waitUntilDone:NO];    
}

- (NSTimeInterval)onSocket:(AsyncSocket_LIO *)sock shouldTimeoutReadWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length;
{
    NSLog(@"\n\nREAD TIMEOUT\n\n");
    return 0;
}

- (NSTimeInterval)onSocket:(AsyncSocket_LIO *)sock shouldTimeoutWriteWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length;
{
    NSLog(@"\n\nWRITE TIMEOUT\n\n");
    return 0;
}

#pragma mark -
#pragma mark LIOChatViewControllerDataSource methods

- (NSArray *)chatViewControllerChatMessages:(LIOChatViewController *)aController
{
    return chatHistory;
}

#pragma mark -
#pragma mark LIOChatViewController delegate methods

- (void)chatViewControllerWasDismissed:(LIOChatViewController *)aController
{
    [chatViewController performDismissalAnimation];
}

- (void)chatViewController:(LIOChatViewController *)aController didChatWithText:(NSString *)aString
{
    if (pendingLeaveMessage)
    {
        [pendingFeedbackText release];
        pendingFeedbackText = [aString retain];
        
        [chatViewController performDismissalAnimation];
        
        [self showLeaveMessageUI];
    }
    else
    {
        NSString *chat = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        @"chat", @"type",
                                                        aString, @"text",
                                                        nil]];
        
        chat = [chat stringByAppendingString:LIOLookIOManagerMessageSeparator];

        [controlSocket writeData:[chat dataUsingEncoding:NSUTF8StringEncoding]
                     withTimeout:LIOLookIOManagerWriteTimeout
                             tag:0];
        
        [controlSocket readDataToData:messageSeparatorData
                          withTimeout:-1
                                  tag:0];
        
        [chatHistory addObject:[NSString stringWithFormat:@"Me: %@", aString]];
        [chatViewController reloadMessages];
        //[chatViewController scrollToBottom];
    }
}

- (void)chatViewControllerDidTapEndSessionButton:(LIOChatViewController *)aController
{
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
                                                        message:@"End this session?"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"No", @"Yes", nil];
    alertView.tag = LIOLookIOManagerDisconnectConfirmAlertViewTag;
    [alertView show];
    [alertView autorelease];
}

- (void)chatViewControllerDidTapEndScreenshotsButton:(LIOChatViewController *)aController
{
    screenshotsAllowed = NO;
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"screenshot", @"permission", nil];
    NSDictionary *permissionDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"advisory", @"type",
                                    @"permission_revoked", @"action",
                                    dataDict, @"data",
                                    nil];
    
    NSString *permissionRevoked = [jsonWriter stringWithObject:permissionDict];
    permissionRevoked = [permissionRevoked stringByAppendingString:LIOLookIOManagerMessageSeparator];
    
    [controlSocket writeData:[permissionRevoked dataUsingEncoding:NSUTF8StringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];

}

- (void)chatViewControllerDidTapEmailButton:(LIOChatViewController *)aController
{
    [chatViewController.view removeFromSuperview];
    [chatViewController autorelease];
    chatViewController = nil;
    
    emailHistoryViewController = [[LIOEmailHistoryViewController alloc] initWithNibName:nil bundle:nil];
    emailHistoryViewController.delegate = self;
    [lookioWindow addSubview:emailHistoryViewController.view];
    
    [self rejiggerWindows];
}

- (void)chatViewControllerDidFinishDismissalAnimation:(LIOChatViewController *)aController
{
    [chatViewController.view removeFromSuperview];
    [chatViewController release];
    chatViewController = nil;
    
    controlButton.alpha = 0.0;
    controlButton.hidden = NO;
    
    [UIView animateWithDuration:1.0
                     animations:^{
                         controlButton.alpha = 1.0;
                     }];
    
    NSString *chatDown = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                       @"advisory", @"type",
                                                       @"chat_down", @"action",
                                                       nil]];
    chatDown = [chatDown stringByAppendingString:LIOLookIOManagerMessageSeparator];
    
    [controlSocket writeData:[chatDown dataUsingEncoding:NSUTF8StringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];

    [self rejiggerWindows];
    
    if (killConnectionAfterChatViewDismissal)
    {
        unloadAfterDisconnect = YES;
        [self killConnection];
    }
}

- (void)chatViewControllerTypingDidStart:(LIOChatViewController *)aController
{
    if (introduced)
    {
        NSString *typingStart = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              @"advisory", @"type",
                                                              @"typing_start", @"action",
                                                              nil]];
        typingStart = [typingStart stringByAppendingString:LIOLookIOManagerMessageSeparator];
        
        [controlSocket writeData:[typingStart dataUsingEncoding:NSUTF8StringEncoding]
                     withTimeout:LIOLookIOManagerWriteTimeout
                             tag:0];
    }
}

- (void)chatViewControllerTypingDidStop:(LIOChatViewController *)aController
{
    if (introduced)
    {
        NSString *typingStop = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             @"advisory", @"type",
                                                             @"typing_stop", @"action",
                                                             nil]];
        typingStop = [typingStop stringByAppendingString:LIOLookIOManagerMessageSeparator];
        
        [controlSocket writeData:[typingStop dataUsingEncoding:NSUTF8StringEncoding]
                     withTimeout:LIOLookIOManagerWriteTimeout
                             tag:0];
    }
}

- (void)chatViewControllerDidTapAboutButton:(LIOChatViewController *)aController
{
    [chatViewController.view removeFromSuperview];
    [chatViewController autorelease];
    chatViewController = nil;
    
    [self showAboutUI];
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag)
    {
        case LIOLookIOManagerDisconnectConfirmAlertViewTag:
        {
            if (1 == buttonIndex) // "Yes"
            {
                if (NO == [controlSocket isConnected])
                    [self unload];
                else if (chatViewController)
                {
                    killConnectionAfterChatViewDismissal = YES;
                    [chatViewController performDismissalAnimation];
                }
                else
                {
                    unloadAfterDisconnect = YES;
                    [self killConnection];
                }
                
            }
            
            break;
        }
            
        case LIOLookIOManagerScreenshotPermissionAlertViewTag:
        {
            if (1 == buttonIndex) // "Yes"
            {
                screenshotsAllowed = YES;
                
                if (chatViewController)
                {
                    [chatViewController.view removeFromSuperview];
                    [chatViewController release];
                    chatViewController = nil;
                    [self rejiggerWindows];
                }
            }
            
            break;
        }
            
        /*    
        case LIOLookIOManagerNoAgentsOnlineAlertViewTag:
        {
            if (1 == buttonIndex) // "Yes"
            {
                [connectViewController.view removeFromSuperview];
                [connectViewController release];
                connectViewController = nil;
                
                feedbackViewController = [[LIOTextEntryViewController alloc] initWithNibName:nil bundle:nil];
                feedbackViewController.delegate = self;
                feedbackViewController.instructionsText = @"Please leave a message.";
                [lookioWindow addSubview:feedbackViewController.view];
                lookioWindow.hidden = NO;
            }
            else
            {
                unloadAfterDisconnect = YES;
                [self killConnection];
            }
            
            break;
        }
        */
            
        case LIOLookIOManagerUnprovisionedAlertViewTag:
        {
            unloadAfterDisconnect = YES;
            [self killConnection];
        }
            
        case LIOLookIOManagerAgentEndedSessionAlertViewTag:
        {
            if ([controlSocket isConnected])
            {
                unloadAfterDisconnect = YES;
                [self killConnection];
            }
            else
            {
                [self unload];
            }
        }
    }
}

/*
#pragma mark -
#pragma mark LIOConnectViewController delegate methods

- (void)connectViewControllerDidTapHideButton:(LIOConnectViewController *)aController
{
    [connectViewController hideAnimated:YES];
    minimized = YES;
}

- (void)connectViewControllerDidTapCancelButton:(LIOConnectViewController *)aController
{
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
                                                        message:@"End this session?"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"No", @"Yes", nil];
    alertView.tag = LIOLookIOManagerDisconnectConfirmAlertViewTag;
    [alertView show];
    [alertView autorelease];
}

- (void)connectViewControllerWasHidden:(LIOConnectViewController *)aController
{
    if (usesControlButton)
        controlButton.hidden = NO;
    
    controlButtonSpinner.hidden = NO == enqueued;
    
    [connectViewController.view removeFromSuperview];
    [connectViewController release];
    connectViewController = nil;

    [self rejiggerWindows];
}

- (void)connectViewController:(LIOConnectViewController *)aController didEnterFriendlyName:(NSString *)aString
{
    [friendlyName release];
    friendlyName = [aString retain];
    
    NSDictionary *aDict = [NSDictionary dictionaryWithObjectsAndKeys:friendlyName, @"name", nil];
    NSMutableDictionary *nameDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     @"advisory", @"type",
                                     @"friendly_name", @"action",
                                     aDict, @"data",
                                     nil];
    
    NSString *name = [jsonWriter stringWithObject:nameDict];
    name = [name stringByAppendingString:LIOLookIOManagerMessageSeparator];
    
    [controlSocket writeData:[name dataUsingEncoding:NSUTF8StringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];
}
*/

#pragma mark -
#pragma mark Notification handlers

- (void)applicationWillResignActive:(NSNotification *)aNotification
{
    if (UIBackgroundTaskInvalid == backgroundTaskId)
    {
        backgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskId];
            backgroundTaskId = UIBackgroundTaskInvalid;
        }];
    }
    
    if ([controlSocket isConnected])
    {
        NSMutableDictionary *backgroundedDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                 @"advisory", @"type",
                                                 @"app_backgrounded", @"action",
                                                 nil];
        
        NSString *backgrounded = [jsonWriter stringWithObject:backgroundedDict];
        backgrounded = [backgrounded stringByAppendingString:LIOLookIOManagerMessageSeparator];
        
        [controlSocket writeData:[backgrounded dataUsingEncoding:NSUTF8StringEncoding]
                     withTimeout:LIOLookIOManagerWriteTimeout
                             tag:0];
    }
    
    [chatViewController.view removeFromSuperview];
    [chatViewController release];
    chatViewController = nil;
    
    [emailHistoryViewController.view removeFromSuperview];
    [emailHistoryViewController release];
    emailHistoryViewController = nil;
    
    [leaveMessageViewController.view removeFromSuperview];
    [leaveMessageViewController release];
    leaveMessageViewController = nil;
    
    [aboutViewController.view removeFromSuperview];
    [aboutViewController release];
    aboutViewController = nil;
    
    [self rejiggerWindows];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
    if (UIBackgroundTaskInvalid != backgroundTaskId)
    {
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskId];
        backgroundTaskId = UIBackgroundTaskInvalid;
    }
    
    if ([controlSocket isConnected])
    {
        NSMutableDictionary *foregroundedDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                    @"advisory", @"type",
                                                    @"app_foregrounded", @"action",
                                                    nil];
        
        NSString *foregrounded = [jsonWriter stringWithObject:foregroundedDict];
        foregrounded = [foregrounded stringByAppendingString:LIOLookIOManagerMessageSeparator];
        
        [controlSocket writeData:[foregrounded dataUsingEncoding:NSUTF8StringEncoding]
                     withTimeout:LIOLookIOManagerWriteTimeout
                             tag:0];
        
        // We also force the LookIO UI to the foreground here.
        // This prevents any jank: the user can always go out of the app and come back in
        // to correct any wackiness that might occur.
        if (nil == leaveMessageViewController && nil == emailHistoryViewController && nil == aboutViewController)
            [self showChat];
    }
}

- (void)deviceOrientationDidChange:(NSNotification *)aNotification
{
    /*
    //CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    CGAffineTransform transform;
    
    if (UIInterfaceOrientationPortrait == (UIInterfaceOrientation)[[UIDevice currentDevice] orientation])
    { 
        transform = CGAffineTransformIdentity;
        
        controlButton.bounds = controlButtonBounds;
        controlButton.center = controlButtonCenter;
        connectViewController.targetLogoBoundsForHiding = controlButton.bounds;
        connectViewController.targetLogoCenterForHiding = controlButton.center;
    }
    else if (UIInterfaceOrientationLandscapeLeft == (UIInterfaceOrientation)[[UIDevice currentDevice] orientation])
    {
        transform = CGAffineTransformMakeRotation(-90.0 / 180.0 * M_PI);
        //transform = CGAffineTransformTranslate(transform, -screenSize.height, 0.0);
        
        controlButton.bounds = controlButtonBounds;
        controlButton.center = controlButtonCenterLandscape;
        connectViewController.targetLogoBoundsForHiding = controlButton.bounds;
        connectViewController.targetLogoCenterForHiding = controlButton.center;
    }
    else if (UIInterfaceOrientationPortraitUpsideDown == (UIInterfaceOrientation)[[UIDevice currentDevice] orientation])
    {
        transform = CGAffineTransformMakeRotation(-180.0 / 180.0 * M_PI);
        //transform = CGAffineTransformTranslate(transform, -screenSize.width, -screenSize.height);
        
        controlButton.bounds = controlButtonBounds;
        controlButton.center = controlButtonCenter;
        connectViewController.targetLogoBoundsForHiding = controlButton.bounds;
        connectViewController.targetLogoCenterForHiding = controlButton.center;
    }
    else // Landscape, home button right
    {
        transform = CGAffineTransformMakeRotation(-270.0 / 180.0 * M_PI);
        //transform = CGAffineTransformTranslate(transform, 0.0, -screenSize.width);
        
        controlButton.bounds = controlButtonBounds;
        controlButton.center = controlButtonCenterLandscape;
        connectViewController.targetLogoBoundsForHiding = controlButton.bounds;
        connectViewController.targetLogoCenterForHiding = controlButton.center;
    }
    
    controlButton.transform = transform;
    clickView.transform = transform;
    cursorView.transform = transform;
    */
}

#pragma mark -
#pragma mark NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    endpointRequestHTTPResponseCode = [httpResponse statusCode];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (nil == endpointRequestData)
        endpointRequestData = [[NSMutableData alloc] init];
    
    [endpointRequestData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *json = [[[NSString alloc] initWithData:endpointRequestData encoding:NSUTF8StringEncoding] autorelease];
    NSDictionary *endpointDict = [jsonParser objectWithString:json];
    NSString *endpoint = [endpointDict objectForKey:@"endpoint"];
    if ([endpoint length])
    {
        [controlEndpoint release];
        controlEndpoint = [endpoint retain];
        
#ifdef DEBUG
        NSLog(@"[CONNECT] Got an endpoint: \"%@\"", controlEndpoint);
#endif
    }
    
    [endpointRequestData release];
    endpointRequestData = nil;
    
    [endpointRequestConnection release];
    endpointRequestConnection = nil;
    
    [self beginSession];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"[CONNECT] Couldn't get an endpoint via HTTP. Reason: %@", [error localizedDescription]);
    
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                        message:@"Could not connect to the look.io service."
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Dismiss", nil];
    [alertView show];
    [alertView autorelease];
    
    controlSocketConnecting = NO;
}

#pragma mark -
#pragma mark LIOLeaveMessageViewControllerDelegate methods

- (void)leaveMessageViewControllerWasDismissed:(LIOLeaveMessageViewController *)aController
{
    [leaveMessageViewController.view removeFromSuperview];
    [leaveMessageViewController release];
    leaveMessageViewController = nil;

    [self rejiggerWindows];
    
    unloadAfterDisconnect = YES;
    [self killConnection];
}

- (void)leaveMessageViewController:(LIOLeaveMessageViewController *)aController wasDismissedWithEmailAddress:(NSString *)anEmail message:(NSString *)aMessage
{
    [leaveMessageViewController.view removeFromSuperview];
    [leaveMessageViewController release];
    leaveMessageViewController = nil;

    [self rejiggerWindows];
    
    NSMutableDictionary *feedbackDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         @"feedback", @"type",
                                         anEmail, @"email_address",
                                         aMessage, @"message",
                                         nil];
    
    NSString *feedback = [jsonWriter stringWithObject:feedbackDict];
    feedback = [feedback stringByAppendingString:LIOLookIOManagerMessageSeparator];
    
    [controlSocket writeData:[feedback dataUsingEncoding:NSUTF8StringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];
    
    unloadAfterDisconnect = YES;
    [self killConnection];
    
}

#pragma mark -
#pragma mark LIOEmailHistoryViewControllerDelegate methods

- (void)emailHistoryViewControllerWasDismissed:(LIOLeaveMessageViewController *)aController
{
    [emailHistoryViewController.view removeFromSuperview];
    [emailHistoryViewController release];
    emailHistoryViewController = nil;

    [self showChat];
}

- (void)emailHistoryViewController:(LIOLeaveMessageViewController *)aController wasDismissedWithEmailAddress:(NSString *)anEmail
{
    NSDictionary *aDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:anEmail], @"email_addresses", nil];
    NSMutableDictionary *emailDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      @"advisory", @"type",
                                      @"chat_history", @"action",
                                      aDict, @"data",
                                      nil];
    
    NSString *email = [jsonWriter stringWithObject:emailDict];
    email = [email stringByAppendingString:LIOLookIOManagerMessageSeparator];
    
    [controlSocket writeData:[email dataUsingEncoding:NSUTF8StringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];
    
    [emailHistoryViewController.view removeFromSuperview];
    [emailHistoryViewController release];
    emailHistoryViewController = nil;
    
    [self showChat];
}

#pragma mark -
#pragma mark LIOAboutViewControllerDelegate methods

- (void)aboutViewControllerWasDismissed:(LIOAboutViewController *)aController
{
    [aboutViewController.view removeFromSuperview];
    [aboutViewController release];
    aboutViewController = nil;
    
    [self showChat];
}

- (void)aboutViewController:(LIOAboutViewController *)aController wasDismissedWithEmail:(NSString *)anEmail
{
    [aboutViewController.view removeFromSuperview];
    [aboutViewController release];
    aboutViewController = nil;
    
    if ([anEmail length])
    {
        NSDictionary *aDict = [NSDictionary dictionaryWithObjectsAndKeys:anEmail, @"email", nil];
        NSMutableDictionary *emailDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          @"advisory", @"type",
                                          @"beta_email", @"action",
                                          aDict, @"data",
                                          nil];
        
        NSString *email = [jsonWriter stringWithObject:emailDict];
        email = [email stringByAppendingString:LIOLookIOManagerMessageSeparator];
        
        [controlSocket writeData:[email dataUsingEncoding:NSUTF8StringEncoding]
                     withTimeout:LIOLookIOManagerWriteTimeout
                             tag:0];
    }
    
    [self showChat];
}

#pragma mark -
#pragma mark LIOControlButtonViewDelegate methods

- (void)controlButtonViewWasTapped:(LIOControlButtonView *)aControlButton
{
    [self showChat];
}

#pragma mark -
#pragma mark Dynamic property accessors

- (CGPoint)controlButtonOrigin
{
    return controlButton.frame.origin;
}

- (void)setControlButtonOrigin:(CGPoint)aPoint
{
    CGRect aFrame = controlButton.frame;
    aFrame.origin = aPoint;
    controlButton.frame = aFrame;
}

- (BOOL)horizontalControlButton
{
    return controlButton.currentMode == LIOControlButtonViewModeHorizontal;
}

- (void)setHorizontalControlButton:(BOOL)aBool
{
    if (aBool)
        controlButton.currentMode = LIOControlButtonViewModeHorizontal;
    else
        controlButton.currentMode = LIOControlButtonViewModeVertical;
}

@end