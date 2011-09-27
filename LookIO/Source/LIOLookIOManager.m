//
//  LIOLookIOManager.m
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioToolbox.h>
#import <sys/sysctl.h>
#import "LIOLookIOManager.h"
#import "AsyncSocket.h"
#import "SBJSON.h"
#import "LIOChatboxView.h"
#import "NSData+Base64.h"
#import "LIOChatViewController.h"
#import "LIOConnectViewController.h"
#import "LIOTextEntryViewController.h"

// Misc. constants
#define LIOLookIOManagerVersion @"0.1"

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
    UIButton *controlButton;
    UIActivityIndicatorView *controlButtonSpinner;
    CGRect controlButtonFrame;
    CGRect controlButtonFrameLandscape;
    NSMutableArray *chatHistory;
    SystemSoundID soundYay, soundDing;
    BOOL unloadAfterDisconnect;
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
    LIOConnectViewController *connectViewController;
    LIOTextEntryViewController *feedbackViewController, *emailEntryViewController;
    NSString *pendingFeedbackText;
    NSString *friendlyName;
    NSArray *supportedOrientations;
}

@property(nonatomic, readonly) BOOL screenshotsAllowed;

- (void)controlButtonWasTapped;

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

@implementation LIOLookIOManager

@synthesize touchImage, controlButtonCenter, controlButtonCenterLandscape, controlButtonBounds;
@synthesize targetAgentId, usesTLS, usesControlButton, usesSounds, screenshotsAllowed, supportedOrientations;

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
        
        messageSeparatorData = [[LIOLookIOManagerMessageSeparator dataUsingEncoding:NSASCIIStringEncoding] retain];
        
        jsonParser = [[SBJsonParser_LIO alloc] init];
        jsonWriter = [[SBJsonWriter_LIO alloc] init];
        
        self.touchImage = [UIImage imageNamed:@"DefaultTouch"];
        self.controlButtonCenter = CGPointMake(16.0, 36.0);
        self.controlButtonCenterLandscape = CGPointMake(16.0, 36.0);
        self.controlButtonBounds = CGRectMake(0.0, 0.0, 32.0, 32.0);
        
        chatHistory = [[NSMutableArray alloc] init];

        controlButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        [controlButton setImage:[UIImage imageNamed:@"ControlButton"] forState:UIControlStateNormal];
        [controlButton addTarget:self action:@selector(controlButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
        controlButton.bounds = self.controlButtonBounds;
        controlButton.center = self.controlButtonCenter;
        controlButton.hidden = YES;
        [keyWindow addSubview:controlButton];
        
        controlButtonSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        controlButtonSpinner.frame = CGRectMake(0.0, 0.0, controlButton.bounds.size.width * 0.9, controlButton.bounds.size.height * 0.9);
        controlButtonSpinner.center = CGPointMake(controlButton.bounds.size.width / 2.0, controlButton.bounds.size.height / 2.0);
        [controlButtonSpinner startAnimating];
        controlButtonSpinner.hidden = YES;
        controlButtonSpinner.userInteractionEnabled = NO;
        [controlButton addSubview:controlButtonSpinner];
        
        endpointRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:LIOLookIOManagerControlEndpointRequestURL]
                                                       cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                   timeoutInterval:10.0];
        [endpointRequest setValue:[[NSBundle mainBundle] bundleIdentifier] forHTTPHeaderField:@"X-LookIO-BundleID"];
        
        NSURL *soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"LookIODing" ofType:@"caf"]];
        if (soundURL)
            AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &soundDing);
        
        soundURL = nil;
        soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"LookIOConnect" ofType:@"caf"]];
        if (soundURL)
            AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &soundYay);
        
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
    [chatViewController release];
    [chatHistory release];
    [lastScreenshotSent release];
    [lastKnownQueuePosition release];
    [targetAgentId release];
    [lookioWindow release];
    [endpointRequest release];
    [controlEndpoint release];
    [endpointRequestConnection release];
    [endpointRequestData release];
    [feedbackViewController release];
    [emailEntryViewController release];
    [pendingFeedbackText release];
    [friendlyName release];
    [supportedOrientations release];
    
    AudioServicesDisposeSystemSoundID(soundDing);
    AudioServicesDisposeSystemSoundID(soundYay);
    
    NSLog(@"[LOOKIO] Unloaded.");
    
    [super dealloc];
}

- (void)unload
{
    [chatViewController.view removeFromSuperview];
    [connectViewController.view removeFromSuperview];
    [feedbackViewController.view removeFromSuperview];
    [emailEntryViewController.view removeFromSuperview];
    
    [cursorView removeFromSuperview];
    [clickView removeFromSuperview];
    [controlButton removeFromSuperview];
    
    [controlSocket setDelegate:nil];
    
    [screenCaptureTimer invalidate];
    screenCaptureTimer = nil;
    
    [sharedLookIOManager release];
    sharedLookIOManager = nil;
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
    
    if (NO == [controlSocket isConnected] || waitingForScreenshotAck || NO == introduced || YES == enqueued || NO == screenshotsAllowed || chatViewController)
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
                [controlSocket writeData:[screenshot dataUsingEncoding:NSASCIIStringEncoding]
                             withTimeout:-1
                                     tag:0];
                
                NSLog(@"[SCREENSHOT] Sent %dx%d %@ screenshot (base64: %u bytes).", (int)screenshotSize.width, (int)screenshotSize.height, orientation, [base64Data length]);
            });
        }
    });
}

- (void)showConnectionUI
{
    if (connectViewController)
        return;
    
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    
    connectViewController = [[LIOConnectViewController alloc] initWithNibName:nil bundle:nil];
    connectViewController.delegate = self;
    
    connectViewController.targetLogoBoundsForHiding = self.controlButtonBounds;
    if (UIInterfaceOrientationIsLandscape((UIInterfaceOrientation)[[UIDevice currentDevice] orientation]))
        connectViewController.targetLogoCenterForHiding = self.controlButtonCenterLandscape;
    else
        connectViewController.targetLogoCenterForHiding = self.controlButtonCenter;
    
    [lookioWindow addSubview:connectViewController.view];
    lookioWindow.hidden = NO;
    
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

- (void)showChat
{
    if (chatViewController)
        return;
    
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    
    chatViewController = [[LIOChatViewController alloc] initWithNibName:nil bundle:nil];
    chatViewController.delegate = self;
    chatViewController.dataSource = self;
    [lookioWindow addSubview:chatViewController.view];
    lookioWindow.hidden = NO;
    
    [chatViewController reloadMessages];
    [chatViewController scrollToBottom];
    
    if (usesSounds)
        AudioServicesPlaySystemSound(soundYay);
    
    NSString *chatUp = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                     @"advisory", @"type",
                                                     @"chat_up", @"action",
                                                     nil]];
    chatUp = [chatUp stringByAppendingString:LIOLookIOManagerMessageSeparator];
    
    [controlSocket writeData:[chatUp dataUsingEncoding:NSASCIIStringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];
}

- (void)beginSession
{
    if (controlSocketConnecting || endpointRequestConnection)
    {
        NSLog(@"[CONNECT] Connect attempt ignored: connecting or already connected.");
        return;
    }
    
    if (introduced)
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
    
    NSLog(@"[CONNECT] Trying \"%@:%u\"...", controlEndpoint, chosenPort);
    
    controlSocketConnecting = YES;
    
    [self showConnectionUI];
}

- (void)killConnection
{
    NSString *outro = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    @"outro", @"type",
                                                    nil]];
    outro = [outro stringByAppendingString:LIOLookIOManagerMessageSeparator];
    
    [controlSocket writeData:[outro dataUsingEncoding:NSASCIIStringEncoding]
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
    
    [controlSocket writeData:[uiLocation dataUsingEncoding:NSASCIIStringEncoding]
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
            NSLog(@"[INTRODUCTION] Introduction complete.");
            introduced = YES;
            waitingForIntroAck = NO;
            enqueued = YES;
            
            [controlSocket readDataToData:messageSeparatorData
                              withTimeout:-1
                                      tag:0];
        }
        else if (waitingForScreenshotAck)
        {
            NSLog(@"[SCREENSHOT] Screenshot received by remote host.");
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
            [chatViewController scrollToBottom];
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
            NSLog(@"[QUEUE] We're live!");
            enqueued = NO;
            
            [connectViewController hideAnimated:YES];
            controlButtonSpinner.hidden = YES;
            
            /*
            if (UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
            {
                UILocalNotification *localNotification = [[[UILocalNotification alloc] init] autorelease];
                localNotification.soundName = @"LookIODing.caf";
                localNotification.alertBody = @"The support agent is ready to chat with you!";
                localNotification.alertAction = @"Go!";
                [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
            }
            */
        }
        else if ([action isEqualToString:@"queued"])
        {
            NSDictionary *data = [aPacket objectForKey:@"data"];
            NSNumber *online = [data objectForKey:@"online"];
            if (online && NO == [online boolValue])
            {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry"
                                                                    message:@"No agents are available right now. Would you like to leave a message?"
                                                                   delegate:self
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"No", @"Yes", nil];
                alertView.tag = LIOLookIOManagerNoAgentsOnlineAlertViewTag;
                [alertView show];
                [alertView autorelease];
            }
            else
            {
                NSNumber *position = [data objectForKey:@"position"];
                [lastKnownQueuePosition release];
                lastKnownQueuePosition = [position retain];
                if ([lastKnownQueuePosition intValue] == 1)
                    connectViewController.connectionLabel.text = [NSString stringWithFormat:@"Waiting for live agent..."];
                else
                    connectViewController.connectionLabel.text = [NSString stringWithFormat:@"You are number %@ in line.", lastKnownQueuePosition];
            }
        }
        else if ([action isEqualToString:@"permission"])
        {
            NSDictionary *data = [aPacket objectForKey:@"data"];
            NSString *permission = [data objectForKey:@"permission"];
            if ([permission isEqualToString:@"screenshot"])
            {
                if (UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
                {
                    UILocalNotification *localNotification = [[[UILocalNotification alloc] init] autorelease];
                    localNotification.soundName = @"LookIODing.caf";
                    localNotification.alertBody = @"The support agent wants to view your screen.";
                    localNotification.alertAction = @"Go!";
                    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                }
                
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
            clickView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ClickIndicator"]];
            [keyWindow addSubview:clickView];
        }
        
        [keyWindow bringSubviewToFront:clickView];
        
        NSNumber *x = [aPacket objectForKey:@"x"];
        NSNumber *y = [aPacket objectForKey:@"y"];
        
        NSLog(@"[CLICK] x: %@, y: %@", x, y);
        
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
        unloadAfterDisconnect = YES;
        [self killConnection];
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
    
    NSString *udid = [[UIDevice currentDevice] uniqueIdentifier];
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
    
    NSString *intro = [jsonWriter stringWithObject:introDict];
    intro = [intro stringByAppendingString:LIOLookIOManagerMessageSeparator];
    
    waitingForIntroAck = YES;
    
    [controlSocket writeData:[intro dataUsingEncoding:NSASCIIStringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];
    
    [controlSocket readDataToData:messageSeparatorData
                      withTimeout:-1
                              tag:0];    
}

#pragma mark -
#pragma mark UIControl actions

- (void)controlButtonWasTapped
{
    if (enqueued && minimized)
    {
        controlButton.hidden = YES;
        [self showConnectionUI];
        minimized = NO;
    }
    else
        [self showChat];
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
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Couldn't connect right now. Please try again later!"
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Dismiss", nil];
        alertView.tag = LIOLookIOManagerDisconnectErrorAlertViewTag;
        [alertView show];
        [alertView autorelease];
        
        unloadAfterDisconnect = YES;
        
        NSLog(@"[CONNECT] Connection failed. Reason: %@", [err localizedDescription]);
    }
}

- (void)onSocketDidDisconnect:(AsyncSocket_LIO *)sock
{
    NSLog(@"[CONNECT] Socket disconnected.");
    
    if (unloadAfterDisconnect)
        [self unload];
}

- (void)onSocket:(AsyncSocket_LIO *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *jsonString = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
    jsonString = [jsonString substringToIndex:([jsonString length] - [LIOLookIOManagerMessageSeparator length])];
    NSDictionary *result = [jsonParser objectWithString:jsonString];
    
    NSLog(@"\n[READ]\n%@\n", jsonString);
    
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
    [chatViewController.view removeFromSuperview];
    [chatViewController release];
    chatViewController = nil;
    
    NSString *chatDown = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                       @"advisory", @"type",
                                                       @"chat_down", @"action",
                                                       nil]];
    chatDown = [chatDown stringByAppendingString:LIOLookIOManagerMessageSeparator];
    
    [controlSocket writeData:[chatDown dataUsingEncoding:NSASCIIStringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];
    
    if (nil == connectViewController)
        lookioWindow.hidden = YES;
}

- (void)chatViewController:(LIOChatViewController *)aController didChatWithText:(NSString *)aString
{
    NSString *chat = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    @"chat", @"type",
                                                    aString, @"text",
                                                    nil]];
    
    chat = [chat stringByAppendingString:LIOLookIOManagerMessageSeparator];

    [controlSocket writeData:[chat dataUsingEncoding:NSASCIIStringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];
    
    [controlSocket readDataToData:messageSeparatorData
                      withTimeout:-1
                              tag:0];
    
    [chatHistory addObject:[NSString stringWithFormat:@"Me: %@", aString]];
    [chatViewController reloadMessages];
    [chatViewController scrollToBottom];
}

- (void)chatViewControllerDidTapEndSessionButton:(LIOChatViewController *)aController
{
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
    
    [controlSocket writeData:[permissionRevoked dataUsingEncoding:NSASCIIStringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];

}

- (void)chatViewControllerDidTapEmailButton:(LIOChatViewController *)aController
{
    [chatViewController.view removeFromSuperview];
    [chatViewController release];
    chatViewController = nil;
    
    emailEntryViewController = [[LIOTextEntryViewController alloc] initWithNibName:nil bundle:nil];
    emailEntryViewController.delegate = self;
    emailEntryViewController.instructionsText = @"Please enter your e-mail address.";
    [lookioWindow addSubview:emailEntryViewController.view];
    lookioWindow.hidden = NO;
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
                    lookioWindow.hidden = YES;
                }
            }
            
            break;
        }
            
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
            
        case LIOLookIOManagerUnprovisionedAlertViewTag:
        {
            unloadAfterDisconnect = YES;
            [self killConnection];
        }
    }
}

#pragma mark -
#pragma mark LIOConnectViewController delegate methods

- (void)connectViewControllerDidTapHideButton:(LIOConnectViewController *)aController
{
    [connectViewController hideAnimated:YES];
    minimized = YES;
}

- (void)connectViewControllerDidTapCancelButton:(LIOConnectViewController *)aController
{
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
    
    if (nil == chatViewController)
        lookioWindow.hidden = YES;
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
    
    [controlSocket writeData:[name dataUsingEncoding:NSASCIIStringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];
}

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
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
    if (UIBackgroundTaskInvalid != backgroundTaskId)
    {
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskId];
        backgroundTaskId = UIBackgroundTaskInvalid;
    }
}

- (void)deviceOrientationDidChange:(NSNotification *)aNotification
{
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
    NSString *json = [[[NSString alloc] initWithData:endpointRequestData encoding:NSASCIIStringEncoding] autorelease];
    NSDictionary *endpointDict = [jsonParser objectWithString:json];
    NSString *endpoint = [endpointDict objectForKey:@"endpoint"];
    if ([endpoint length])
    {
        [controlEndpoint release];
        controlEndpoint = [endpoint retain];
        NSLog(@"[CONNECT] Got an endpoint: \"%@\"", controlEndpoint);
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
#pragma mark LIOTextEntryViewController delegate methods

- (void)textEntryViewControllerWasDismissed:(LIOTextEntryViewController *)aController
{
    if (feedbackViewController == aController)
    {
        [feedbackViewController.view removeFromSuperview];
        [feedbackViewController release];
        feedbackViewController = nil;
        
        lookioWindow.hidden = YES;
        
        unloadAfterDisconnect = YES;
        [self killConnection];
    }
    else if (emailEntryViewController == aController)
    {
        [emailEntryViewController.view removeFromSuperview];
        [emailEntryViewController release];
        emailEntryViewController = nil;
        
        lookioWindow.hidden = YES;
    }
}

- (void)textEntryViewController:(LIOTextEntryViewController *)aController wasDismissedWithText:(NSString *)someText
{
    if (feedbackViewController == aController)
    {
        [feedbackViewController.view removeFromSuperview];
        [feedbackViewController release];
        feedbackViewController = nil;
        
        lookioWindow.hidden = YES;
        
        if ([someText length])
        {
            [pendingFeedbackText release];
            pendingFeedbackText = [someText retain];
            
            emailEntryViewController = [[LIOTextEntryViewController alloc] initWithNibName:nil bundle:nil];
            emailEntryViewController.delegate = self;
            emailEntryViewController.instructionsText = @"Please enter your e-mail address.";
            [lookioWindow addSubview:emailEntryViewController.view];
            lookioWindow.hidden = NO;
        }
        else
        {
            unloadAfterDisconnect = YES;
            [self killConnection];
        }
    }
    else if (emailEntryViewController == aController)
    {
        [emailEntryViewController.view removeFromSuperview];
        [emailEntryViewController release];
        emailEntryViewController = nil;
        
        lookioWindow.hidden = YES;
        
        if ([pendingFeedbackText length])
        {
            // Post-feedback e-mail entry.
            if ([someText length])
            {
                NSMutableDictionary *feedbackDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                     @"feedback", @"type",
                                                     someText, @"email_address",
                                                     pendingFeedbackText, @"message",
                                                     nil];
                
                NSString *feedback = [jsonWriter stringWithObject:feedbackDict];
                feedback = [feedback stringByAppendingString:LIOLookIOManagerMessageSeparator];
                
                [controlSocket writeData:[feedback dataUsingEncoding:NSASCIIStringEncoding]
                             withTimeout:LIOLookIOManagerWriteTimeout
                                     tag:0];
                
                [pendingFeedbackText release];
                pendingFeedbackText = nil;
                
                unloadAfterDisconnect = YES;
                [self killConnection];
            }
        }
        else
        {
            // Straight up e-mail entry.
            NSDictionary *aDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:someText], @"email_addresses", nil];
            NSMutableDictionary *emailDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                 @"advisory", @"type",
                                                 @"chat_history", @"action",
                                                 aDict, @"data",
                                                 nil];
            
            NSString *email = [jsonWriter stringWithObject:emailDict];
            email = [email stringByAppendingString:LIOLookIOManagerMessageSeparator];
            
            [controlSocket writeData:[email dataUsingEncoding:NSASCIIStringEncoding]
                         withTimeout:LIOLookIOManagerWriteTimeout
                                 tag:0];
        }
    }
}

- (UIReturnKeyType)textEntryViewControllerReturnKeyType:(LIOTextEntryViewController *)aController
{
    if (emailEntryViewController == aController)
        return UIReturnKeySend;
    else if (feedbackViewController == aController)
        return UIReturnKeyNext;
    
    return UIReturnKeyDefault;
}

- (UIKeyboardType)textEntryViewControllerKeyboardType:(LIOTextEntryViewController *)aController
{
    if (emailEntryViewController == aController)
        return UIKeyboardTypeEmailAddress;
    
    return UIKeyboardTypeDefault;
}

- (UITextAutocorrectionType)textEntryViewControllerAutocorrectionType:(LIOTextEntryViewController *)aController
{
    if (emailEntryViewController == aController)
        return UITextAutocorrectionTypeNo;
    
    return UITextAutocorrectionTypeDefault;
}

- (UITextAutocapitalizationType)textEntryViewControllerAutocapitalizationType:(LIOTextEntryViewController *)aController
{
    if (emailEntryViewController == aController)
        return UITextAutocapitalizationTypeNone;
    
    return UITextAutocapitalizationTypeSentences;
}

@end