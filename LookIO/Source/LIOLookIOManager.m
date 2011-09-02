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
#import "GCDAsyncSocket.h"
#import "SBJSON.h"
#import "LIOChatboxView.h"
#import "NSData+Base64.h"
#import "LIOChatViewController.h"
#import "LIOConnectViewController.h"

// Misc. constants
#define LIOLookIOManagerVersion @"0.1"

#define LIOLookIOManagerScreenCaptureInterval   0.33

#define LIOLookIOManagerWriteTimeout            5.0

#define LIOLookIOManagerControlEndpoint         @"look.io"
#define LIOLookIOManagerControlEndpointPort     8100
#define LIOLookIOManagerControlEndpointPortTLS  9000

#define LIOLookIOManagerMessageSeparator        @"!look.io!"

#define LIOLookIOManagerDisconnectConfirmAlertViewTag       1
#define LIOLookIOManagerScreenshotPermissionAlertViewTag    2

@interface LIOLookIOManager ()
{
    NSTimer *screenCaptureTimer;
    UIImage *touchImage;
    GCDAsyncSocket_LIO *controlSocket;
    BOOL waitingForScreenshotAck, waitingForIntroAck, controlSocketConnecting, introduced, enqueued;
    NSData *messageSeparatorData;
    NSData *lastScreenshotSent;
    SBJsonParser_LIO *jsonParser;
    SBJsonWriter_LIO *jsonWriter;
    UIImageView *cursorView, *clickView;
    UIButton *controlButton;
    UIActivityIndicatorView *controlButtonSpinner;
    CGRect controlButtonFrame;
    NSMutableArray *chatHistory;
    LIOChatViewController *chatViewController;
    LIOConnectViewController *connectViewController;
    SystemSoundID soundYay, soundDing;
    BOOL unloadAfterDisconnect;
    BOOL minimized;
    NSNumber *lastKnownQueuePosition;
    BOOL screenshotsAllowed;
    UIBackgroundTaskIdentifier backgroundTaskId;
    NSString *targetAgentId;
    BOOL usesTLS;
}

@end

@implementation LIOLookIOManager

@synthesize touchImage, controlButtonFrame, targetAgentId, usesTLS;

static LIOLookIOManager *sharedLookIOManager = nil;

+ (LIOLookIOManager *)sharedLookIOManager
{
    if (nil == sharedLookIOManager)
        sharedLookIOManager = [[LIOLookIOManager alloc] init];
    
    return sharedLookIOManager;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        dispatch_queue_t delegateQueue = dispatch_queue_create("async_socket_delegate", NULL);
        controlSocket = [[GCDAsyncSocket_LIO alloc] initWithDelegate:self delegateQueue:delegateQueue];
        
        screenCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:LIOLookIOManagerScreenCaptureInterval
                                                              target:self
                                                            selector:@selector(screenCaptureTimerDidFire:)
                                                            userInfo:nil
                                                             repeats:YES];
        
        messageSeparatorData = [[LIOLookIOManagerMessageSeparator dataUsingEncoding:NSASCIIStringEncoding] retain];
        
        jsonParser = [[SBJsonParser_LIO alloc] init];
        jsonWriter = [[SBJsonWriter_LIO alloc] init];
        
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        self.touchImage = [UIImage imageNamed:@"DefaultTouch"];
        self.controlButtonFrame = CGRectMake(keyWindow.frame.size.width - 32.0, 20.0, 32.0, 32.0);
        
        chatHistory = [[NSMutableArray alloc] init];

        controlButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        [controlButton setImage:[UIImage imageNamed:@"ControlButton"] forState:UIControlStateNormal];
        [controlButton addTarget:self action:@selector(controlButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
        controlButton.frame = self.controlButtonFrame;
        controlButton.hidden = YES;
        [[[UIApplication sharedApplication] keyWindow] addSubview:controlButton];
        
        controlButtonSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        controlButtonSpinner.frame = controlButton.bounds;
        [controlButtonSpinner startAnimating];
        controlButtonSpinner.hidden = YES;
        controlButtonSpinner.userInteractionEnabled = NO;
        [controlButton addSubview:controlButtonSpinner];
        
        NSURL *soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"LookIODing" ofType:@"caf"]];
        AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &soundDing);
        
        soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"LookIOConnect" ofType:@"caf"]];
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
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        
        usesTLS = YES;
        
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
    
    AudioServicesDisposeSystemSoundID(soundDing);
    AudioServicesDisposeSystemSoundID(soundYay);
    
    NSLog(@"[LOOKIO] Unloaded.");
    
    [super dealloc];
}

- (void)unload
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [chatViewController.view removeFromSuperview];
        [connectViewController.view removeFromSuperview];
        
        [cursorView removeFromSuperview];
        [clickView removeFromSuperview];
        [controlButton removeFromSuperview];
        
        [screenCaptureTimer invalidate];
        screenCaptureTimer = nil;
        
        [sharedLookIOManager release];
        sharedLookIOManager = nil;
    });
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
    if (controlSocket.isDisconnected || waitingForScreenshotAck || NO == introduced || YES == enqueued || NO == screenshotsAllowed)
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
            else if (UIInterfaceOrientationPortraitUpsideDown == [[UIDevice currentDevice] orientation])
                orientation = @"portrait_ud";
            
            NSString *screenshot = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                 @"screenshot", @"type",
                                                                 [self nextGUID], @"screenshot_id",
                                                                 base64Data, @"screenshot",
                                                                 [NSNumber numberWithFloat:screenshotSize.width], @"width",
                                                                 [NSNumber numberWithFloat:screenshotSize.height], @"height",
                                                                 orientation, @"orientation",
                                                                 nil]];
            
            screenshot = [screenshot stringByAppendingString:LIOLookIOManagerMessageSeparator];
            
            waitingForScreenshotAck = YES;
            [controlSocket writeData:[screenshot dataUsingEncoding:NSASCIIStringEncoding]
                         withTimeout:-1
                                 tag:0];
            
            NSLog(@"[SCREENSHOT] Sent %dx%d %@ screenshot (base64: %u bytes).", (int)screenshotSize.width, (int)screenshotSize.height, orientation, [base64Data length]);
        }
    });
}

- (void)showConnectionUI
{
    if (connectViewController)
        return;
    
    connectViewController = [[LIOConnectViewController alloc] initWithNibName:nil bundle:nil];
    connectViewController.delegate = self;
    connectViewController.targetLogoFrameForHiding = self.controlButtonFrame;
    [[[UIApplication sharedApplication] keyWindow] addSubview:connectViewController.view];
    
    if (lastKnownQueuePosition)
    {
        if ([lastKnownQueuePosition intValue] == 1)
            connectViewController.connectionLabel.text = [NSString stringWithFormat:@"You are next in line!"];
        else
            connectViewController.connectionLabel.text = [NSString stringWithFormat:@"You are number %@ in line.", lastKnownQueuePosition];
    }
    else if (controlSocketConnecting)
    {
        connectViewController.connectionLabel.text = @"Connecting...";
    }
    else
    {
        connectViewController.connectionLabel.text = @"Not connected.";
    }
    
    [connectViewController showAnimated:YES];
}

- (void)beginSession
{
    if (controlSocket.isConnected || controlSocketConnecting)
    {
        NSLog(@"[CONNECT] Connect attempt ignored: connecting or already connected.");
        return;
    }
    
    NSUInteger chosenPort = LIOLookIOManagerControlEndpointPortTLS;
    if (NO == usesTLS)
        chosenPort = LIOLookIOManagerControlEndpointPort;
    
    NSError *connectError = nil;
    BOOL connectResult = [controlSocket connectToHost:LIOLookIOManagerControlEndpoint
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
        
        return;
    }
    
    AudioServicesPlaySystemSound(soundDing);
    
    NSLog(@"[CONNECT] Trying \"%@:%d\"...", LIOLookIOManagerControlEndpoint, chosenPort);
    
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

- (void)showChat
{
    if (chatViewController)
        return;
    
    chatViewController = [[LIOChatViewController alloc] initWithNibName:nil bundle:nil];
    chatViewController.delegate = self;
    [chatViewController addMessages:chatHistory];
    [[[UIApplication sharedApplication] keyWindow] addSubview:chatViewController.view];
    
    [chatViewController scrollToBottom];
    
    AudioServicesPlaySystemSound(soundYay);
}

- (void)handlePacket:(NSDictionary *)aPacket
{
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
        [chatHistory addObject:[NSString stringWithFormat:@"Support: %@", text]];

        if (nil == chatViewController)
        {
            [self showChat];
        }
        else
        {
            [chatViewController addMessage:[chatHistory lastObject] animated:YES];
            [chatViewController reloadMessages];
            [chatViewController scrollToBottom];
        }
        
        NSLog(@"[CHAT] \"%@\"", text);
    }
    else if ([type isEqualToString:@"cursor"])
    {
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        
        if (nil == cursorView)
        {
            cursorView = [[UIImageView alloc] initWithImage:touchImage];
            [keyWindow addSubview:cursorView];
        }
        
        [keyWindow bringSubviewToFront:cursorView];
        
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
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [connectViewController hideAnimated:YES];
                controlButtonSpinner.hidden = YES;
                
                if (UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
                {
                    UILocalNotification *localNotification = [[[UILocalNotification alloc] init] autorelease];
                    localNotification.soundName = @"LookIODing.caf";
                    localNotification.alertBody = @"The support agent is ready to chat with you!";
                    localNotification.alertAction = @"Go!";
                    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                }
            });
        }
        else if ([action isEqualToString:@"queued"])
        {
            NSDictionary *data = [aPacket objectForKey:@"data"];
            NSNumber *position = [data objectForKey:@"position"];
            [lastKnownQueuePosition release];
            lastKnownQueuePosition = [position retain];
            if ([lastKnownQueuePosition intValue] == 1)
                connectViewController.connectionLabel.text = [NSString stringWithFormat:@"You are next in line!"];
            else
                connectViewController.connectionLabel.text = [NSString stringWithFormat:@"You are number %@ in line.", lastKnownQueuePosition];
        }
        else if ([action isEqualToString:@"permission"])
        {
            NSDictionary *data = [aPacket objectForKey:@"data"];
            NSString *permission = [data objectForKey:@"permission"];
            if ([permission isEqualToString:@"screenshot"])
            {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Security"
                                                                    message:@"Allow remote agent to see your screen?"
                                                                   delegate:self
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"No", @"Yes", nil];
                alertView.tag = LIOLookIOManagerScreenshotPermissionAlertViewTag;
                [alertView show];
                [alertView autorelease];
            }
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
#pragma mark GCDAsyncSocketDelegate methods

- (void)socket:(GCDAsyncSocket_LIO *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    controlSocketConnecting = NO;
    
    NSLog(@"[CONNECT] Connected!");
    
    if (usesTLS)
        [controlSocket startTLS:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], (NSString *)kCFStreamSSLAllowsAnyRoot, nil]];
    else
        [self performIntroduction];
}

- (void)socketDidSecure:(GCDAsyncSocket_LIO *)sock
{
    NSLog(@"[CONNECT] Secured.");    
    
    [self performIntroduction];
}

- (void)socketDidDisconnect:(GCDAsyncSocket_LIO *)sock withError:(NSError *)err
{
    controlSocketConnecting = NO;
    introduced = NO;
    waitingForIntroAck = NO;
    waitingForScreenshotAck = NO;
    enqueued = NO;
    
    if (err)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                            message:[err localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"k :(", nil];
        [alertView show];
        [alertView autorelease];
        
        NSLog(@"[CONNECT] Connection failed. Reason: %@", [err localizedDescription]);
        return;
    }
    else
    {
        NSLog(@"[CONNECT] Socket disconnected.");
    }
    
    if (unloadAfterDisconnect)
        [self unload];
}

- (void)socket:(GCDAsyncSocket_LIO *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *jsonString = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
    jsonString = [jsonString substringToIndex:([jsonString length] - [LIOLookIOManagerMessageSeparator length])];
    NSDictionary *result = [jsonParser objectWithString:jsonString];
    
    NSLog(@"\n[READ]\n%@\n", jsonString);
    
    [self performSelectorOnMainThread:@selector(handlePacket:) withObject:result waitUntilDone:NO];    
}

- (NSTimeInterval)socket:(GCDAsyncSocket_LIO *)sock shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length
{
    NSLog(@"\n\nREAD TIMEOUT\n\n");
    return 0;
}

- (NSTimeInterval)socket:(GCDAsyncSocket_LIO *)sock shouldTimeoutWriteWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length
{
    NSLog(@"\n\nWRITE TIMEOUT\n\n");
    return 0;
}

#pragma mark -
#pragma mark LIOChatViewController delegate methods

- (void)chatViewControllerWasDismissed:(LIOChatViewController *)aController
{
    [chatViewController.view removeFromSuperview];
    [chatViewController release];
    chatViewController = nil;
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
    [chatViewController addMessage:[chatHistory lastObject] animated:YES];
    [chatViewController reloadMessages];
    [chatViewController scrollToBottom];
}

- (void)chatViewControllerDidTapEndSessionButton:(LIOChatViewController *)aController
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
                                                        message:@"Cancel this session?"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"No", @"Yes", nil];
    alertView.tag = LIOLookIOManagerDisconnectConfirmAlertViewTag;
    [alertView show];
    [alertView autorelease];
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
                if (controlSocket.isDisconnected)
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
            }
            
            break;
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
                                                        message:@"Cancel this session?"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"No", @"Yes", nil];
    alertView.tag = LIOLookIOManagerDisconnectConfirmAlertViewTag;
    [alertView show];
    [alertView autorelease];
}

- (void)connectViewControllerWasHidden:(LIOConnectViewController *)aController
{
    controlButton.hidden = NO;
    controlButtonSpinner.hidden = NO == enqueued;
    
    [connectViewController.view removeFromSuperview];
    [connectViewController release];
    connectViewController = nil;
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

@end