//
//  LIOLookIOManager.m
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <sys/sysctl.h>
#import "LIOLookIOManager.h"
#import "GCDAsyncSocket.h"
#import "SBJSON.h"
#import "LIOChatboxView.h"
#import "NSData+Base64.h"
#import "LIOChatViewController.h"

// Misc. constants
#define LIOLookIOManagerVersion @"0.1"

#define LIOLookIOManagerScreenCaptureInterval   0.33

#define LIOLookIOManagerWriteTimeout            5.0

#define LIOLookIOManagerControlEndpoint         @"look.io"
#define LIOLookIOManagerControlEndpointPort     8100

#define LIOLookIOManagerMessageSeparator        @"!look.io!"

#define LIOLookIOManagerDisconnectConfirmAlertViewTag 1

@implementation LIOLookIOManager

@synthesize touchImage, controlButtonFrame;

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
        NSLog(@"[LOOKIO] Loaded.");
        
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
        
        NSURL *soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"LookIODing" ofType:@"caf"]];
        AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &soundDing);
        
        soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"LookIOConnect" ofType:@"caf"]];
        AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &soundYay);    
    }
    
    return self;
}

- (void)dealloc
{
    self.touchImage = nil;
    
    [controlSocket disconnect];
    [controlSocket release];
    [messageSeparatorData release];
    [jsonParser release];
    [jsonWriter release];
    [cursorView release];
    [clickView release];
    [controlButton release];
    [connectionSpinner release];
    [connectionLabel release];
    [connectionBackground release];
    [connectionLogo release];
    [chatViewController release];
    [chatHistory release];
    [lastScreenshotSent release];
    
    
    AudioServicesDisposeSystemSoundID(soundDing);
    AudioServicesDisposeSystemSoundID(soundYay);
    
    NSLog(@"[LOOKIO] Unloaded.");
    
    [super dealloc];
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
    if (controlSocket.isDisconnected || waitingForScreenshotAck || NO == introduced || YES == enqueued)
        return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *screenshotImage = [self captureScreen];
        NSData *screenshotData = UIImageJPEGRepresentation(screenshotImage, 0.0);
        if (nil == lastScreenshotSent || NO == [lastScreenshotSent isEqualToData:screenshotData])
        {
            [lastScreenshotSent release];
            lastScreenshotSent = [screenshotData retain];
            
            NSString *base64Data = base64EncodedStringFromData(screenshotData);
            
            NSString *screenshot = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                 @"screenshot", @"type",
                                                                 [self nextGUID], @"screenshot_id",
                                                                 base64Data, @"screenshot",
                                                                 nil]];
            
            screenshot = [screenshot stringByAppendingString:LIOLookIOManagerMessageSeparator];
            
            waitingForScreenshotAck = YES;
            [controlSocket writeData:[screenshot dataUsingEncoding:NSASCIIStringEncoding]
                         withTimeout:-1
                                 tag:0];
        }
    });
}

- (void)beginConnecting
{
    if (controlSocket.isConnected || controlSocketConnecting)
    {
        NSLog(@"[CONNECT] Connect attempt ignored: connecting or already connected.");
        return;
    }
    
    NSError *connectError = nil;
    BOOL connectResult = [controlSocket connectToHost:LIOLookIOManagerControlEndpoint
                                               onPort:LIOLookIOManagerControlEndpointPort
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
    
    NSLog(@"[CONNECT] Trying \"%@:%d\"...", LIOLookIOManagerControlEndpoint, LIOLookIOManagerControlEndpointPort);
    
    controlSocketConnecting = YES;
    
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    
    connectionBackground = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, keyWindow.frame.size.width, keyWindow.frame.size.height)];
    connectionBackground.backgroundColor = [UIColor blackColor];
    connectionBackground.alpha = 0.0;
    [keyWindow addSubview:connectionBackground];
    
    UIImage *logoImage = [UIImage imageNamed:@"LookIOLogo"];
    connectionLogo = [[UIImageView alloc] initWithImage:logoImage];
    connectionLogo.frame = CGRectZero;
    connectionLogo.center = CGPointMake(keyWindow.frame.size.width / 2.0, keyWindow.frame.size.height / 2.0);
    [keyWindow addSubview:connectionLogo];
    
    CGSize targetSize = CGSizeMake(224.0, 224.0);
    CGRect targetFrame = CGRectMake((keyWindow.frame.size.width / 2.0) - (targetSize.width / 2.0),
                                    (keyWindow.frame.size.height / 2.0) - (targetSize.height / 2.0),
                                    targetSize.width,
                                    targetSize.height);
    
    CGFloat spinnerSize = 64.0;
    connectionSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    connectionSpinner.frame = CGRectMake((targetFrame.size.width / 2.0) - (spinnerSize / 2.0),
                                         (targetFrame.size.height / 2.0) - (spinnerSize / 2.0),
                                         spinnerSize,
                                         spinnerSize);
    [connectionSpinner startAnimating];
    connectionSpinner.alpha = 0.0;
    [connectionLogo addSubview:connectionSpinner];
    
    // Logo zoom to center.
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut)
                     animations:^{
                         connectionLogo.frame = targetFrame;
                         connectionLogo.alpha = 0.9;
                         connectionBackground.alpha = 0.33;
                     }
                     completion:^(BOOL finished) {                    
                         connectionSpinner.alpha = 1.0;
                     }];
}

- (void)killConnection
{
    NSString *udid = [[UIDevice currentDevice] uniqueIdentifier];
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    NSString *outro = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    @"outro", @"type",
                                                    udid, @"device_id",
                                                    bundleId, @"app_id",
                                                    nil]];
    outro = [outro stringByAppendingString:LIOLookIOManagerMessageSeparator];
    
    [controlSocket writeData:[outro dataUsingEncoding:NSASCIIStringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];
    
    [controlSocket disconnectAfterWriting];
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
            
            // Logo shrink down to designated position.
            /*
            double delayInSeconds = 1.5;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            */
                connectionSpinner.hidden = YES;
            //});
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.5
                                      delay:0.0//1.5
                                    options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseIn)
                                 animations:^{
                                     connectionBackground.alpha = 0.0;
                                     connectionLogo.frame = self.controlButtonFrame;
                                     connectionLogo.alpha = 1.0;
                                 }
                                 completion:^(BOOL finished) {
                                     [connectionBackground removeFromSuperview];
                                     [connectionBackground release];
                                     connectionBackground = nil;
                                     
                                     [connectionSpinner removeFromSuperview];
                                     [connectionSpinner release];
                                     connectionSpinner = nil;
                                     
                                     [connectionLogo removeFromSuperview];
                                     [connectionLogo release];
                                     connectionLogo = nil;
                                     
                                     controlButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
                                     [controlButton setImage:[UIImage imageNamed:@"ControlButton"] forState:UIControlStateNormal];
                                     [controlButton addTarget:self action:@selector(controlButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
                                     controlButton.frame = self.controlButtonFrame;
                                     [[[UIApplication sharedApplication] keyWindow] addSubview:controlButton];
                                     
                                     if (chatViewController)
                                         [[[UIApplication sharedApplication] keyWindow] insertSubview:controlButton belowSubview:chatViewController.view];
                                 }];
            });
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

#pragma mark -
#pragma mark UIControl actions

- (void)controlButtonWasTapped
{
    [self showChat];
}

#pragma mark -
#pragma mark GCDAsyncSocketDelegate methods

- (void)socket:(GCDAsyncSocket_LIO *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    controlSocketConnecting = NO;
    
    NSLog(@"[CONNECT] Connected!");
    
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);  
    char *machine = malloc(size);  
    sysctlbyname("hw.machine", machine, &size, NULL, 0);  
    NSString *deviceType = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
    free(machine);
    
    NSString *udid = [[UIDevice currentDevice] uniqueIdentifier];
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    NSString *intro = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    @"intro", @"type",
                                                    udid, @"device_id",
                                                    deviceType, @"device_type",
                                                    bundleId, @"app_id",
                                                    LIOLookIOManagerVersion, @"version",
                                                    nil]];
    intro = [intro stringByAppendingString:LIOLookIOManagerMessageSeparator];
    
    waitingForIntroAck = YES;
    
    [controlSocket writeData:[intro dataUsingEncoding:NSASCIIStringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];
    
    [controlSocket readDataToData:messageSeparatorData
                      withTimeout:-1
                              tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket_LIO *)sock withError:(NSError *)err
{
    [connectionBackground removeFromSuperview];
    [connectionBackground release];
    connectionBackground = nil;
    
    [connectionSpinner removeFromSuperview];
    [connectionSpinner release];
    connectionSpinner = nil;
    
    [connectionLabel removeFromSuperview];
    [connectionLabel release];
    connectionLabel = nil;
    
    [connectionLogo removeFromSuperview];
    [connectionLogo release];
    connectionLogo = nil;
    
    [controlButton removeFromSuperview];
    [controlButton release];
    controlButton = nil;
    
    controlSocketConnecting = NO;
    introduced = NO;
    waitingForIntroAck = NO;
    waitingForScreenshotAck = NO;
    enqueued = NO;
    
    if (err)
    {
        if (controlSocketConnecting)
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
    }
    else
    {
        NSLog(@"[CONNECT] Socket disconnected.");
    }
    
    if (unloadAfterDisconnect)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [chatViewController.view removeFromSuperview];
            
            [screenCaptureTimer invalidate];
            screenCaptureTimer = nil;
            
            [sharedLookIOManager release];
            sharedLookIOManager = nil;
        });
    }
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
#pragma LIOChatViewController delegate methods

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
                unloadAfterDisconnect = YES;
                [self killConnection];
            }
            
            break;
        }
    }
}

@end