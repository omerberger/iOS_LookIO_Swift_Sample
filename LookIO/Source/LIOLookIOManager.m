//
//  LIOLookIOManager.m
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "LIOLookIOManager.h"
#import "GCDAsyncSocket.h"
#import "SBJSON.h"
#import "LIOChatboxView.h"
#import "NSData+Base64.h"
#import "LIOChatboxView.h"

// Misc. constants
#define LIOLookIOManagerScreenCaptureInterval   0.33

#define LIOLookIOManagerWriteTimeout            5.0

#define LIOLookIOManagerControlEndpoint         @"look.io"
#define LIOLookIOManagerControlEndpointPort     8100

#define LIOLookIOMAnagerChatboxTimeoutInterval  5.0

#define LIOLookIOManagerMessageSeparator        @"!look.io!"

#define LIOLookIOManagerCustomerPhoneNumber     @"9495052670"
#define LIOLookIOManagerSupportPhoneNumber      @"3108716614"

@implementation LIOLookIOManager

@synthesize touchImage, delegate;

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
        
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        CGRect aFrame = CGRectZero;
        aFrame.origin.y = 40.0;
        aFrame.origin.x = 7.0;
        aFrame.size.width = 306.0;
        aFrame.size.height = 80.0;
        chatbox = [[LIOChatboxView alloc] initWithFrame:aFrame];
        chatbox.delegate = self;
        chatbox.hidden = YES;
        chatbox.layer.borderWidth = 1.0;
        chatbox.layer.borderColor = [UIColor blackColor].CGColor;
        [keyWindow addSubview:chatbox];
        
        chatField = [[UITextField alloc] initWithFrame:CGRectMake(7.0, 120.0, 306.0, 30.0)];
        chatField.hidden = YES;
        chatField.layer.borderWidth = 1.0;
        chatField.layer.borderColor = [UIColor blackColor].CGColor;
        chatField.delegate = self;
        chatField.backgroundColor = [UIColor whiteColor];
        [keyWindow addSubview:chatField];
        
        jsonParser = [[SBJsonParser_LIO alloc] init];
        jsonWriter = [[SBJsonWriter_LIO alloc] init];
        
        self.touchImage = [UIImage imageNamed:@"DefaultTouch"];
    }
    
    return self;
}

- (void)dealloc
{
    self.touchImage = nil;
    
    [controlSocket disconnect];
    [controlSocket release];
    [messageSeparatorData release];
    [chatbox removeFromSuperview];
    [chatbox release];
    [jsonParser release];
    [jsonWriter release];
    [cursorView release];
    [clickView release];
    
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
    if (controlSocket.isDisconnected || waitingForScreenshotAck || NO == introduced)
        return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *screenshotImage = [self captureScreen];
        NSData *screenshotData = UIImageJPEGRepresentation(screenshotImage, 0.0);
        if (nil == lastScreenshotSent || NO == [lastScreenshotSent isEqualToData:screenshotData])
        {
            [lastScreenshotSent release];
            lastScreenshotSent = [screenshotData retain];
            
            NSString *base64Data = [screenshotData base64EncodedString];
            
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

- (void)callTwilio
{
    NSURL *theURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.hirahim.com/twilio/lookio/make-call.php?customer=%@&support=%@", LIOLookIOManagerCustomerPhoneNumber, LIOLookIOManagerSupportPhoneNumber]];
    NSURLRequest *request = [NSURLRequest requestWithURL:theURL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60.0];
    [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"[TWILIO] Failure: %@", [error localizedDescription]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"[TWILIO] Success! Expect a call...");
}

- (void)beginConnecting
{
    if (controlSocket.isConnected || controlSocketConnecting)
    {
        NSLog(@"[CONNECT] Connect attempt ignored: connecting or already connected.");
        return;
    }
    
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    [keyWindow bringSubviewToFront:chatbox];
    
    UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LookIOLogo"]];
    logo.frame = CGRectZero;
    logo.center = CGPointMake(keyWindow.frame.size.width / 2.0, keyWindow.frame.size.height / 2.0);
    logo.alpha = 0.0;
    [keyWindow addSubview:logo];
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut)
                     animations:^{
                         CGSize imageSize = CGSizeMake(logo.image.size.width * 3.5, logo.image.size.height * 3.5);
                         logo.frame = CGRectMake((keyWindow.frame.size.width / 2.0) - (imageSize.width / 2.0), (keyWindow.frame.size.height / 2.0) - (imageSize.height / 2.0), imageSize.width, imageSize.height);
                         logo.alpha = 0.9;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.2
                                               delay:0.6
                                             options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseIn)
                                          animations:^{
                                              CGSize imageSize = CGSizeMake(logo.image.size.width * 8.0, logo.image.size.height * 8.0);
                                              logo.frame = CGRectMake((keyWindow.frame.size.width / 2.0) - (imageSize.width / 2.0), (keyWindow.frame.size.height / 2.0) - (imageSize.height / 2.0), imageSize.width, imageSize.height);
                                              logo.alpha = 0.0;
                                          }
                                          completion:^(BOOL finished) {
                                              [logo removeFromSuperview];
                                              [logo release];
                                          }];
                     }];
    
    NSError *connectError = nil;
    BOOL connectResult = [controlSocket connectToHost:LIOLookIOManagerControlEndpoint
                                               onPort:LIOLookIOManagerControlEndpointPort
                                                error:&connectError];
    if (NO == connectResult)
    {
        NSLog(@"[CONNECT] Connection failed. Reason: %@", [connectError localizedDescription]);
        [delegate lookIOManagerFailedToConnectWithError:connectError];
        return;
    }
    
    NSLog(@"[CONNECT] Trying \"%@:%d\"...", LIOLookIOManagerControlEndpoint, LIOLookIOManagerControlEndpointPort);
    
    controlSocketConnecting = YES;
}

- (void)chatboxTimerDidFire:(NSTimer *)theTimer
{
    chatbox.hidden = YES;
    
    chatboxTimer = nil;
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
        [chatbox addText:[NSString stringWithFormat:@"Support: %@", text]];
        
        if (nil == chatboxTimer && NO == chatting)
        {
            chatboxTimer = [NSTimer scheduledTimerWithTimeInterval:LIOLookIOMAnagerChatboxTimeoutInterval
                                                            target:self
                                                          selector:@selector(chatboxTimerDidFire:)
                                                          userInfo:nil
                                                           repeats:NO];
        }
        
        chatbox.hidden = NO;
        
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        [keyWindow bringSubviewToFront:chatbox];
        
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
        // cursor_start, cursor_end
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
#pragma mark GCDAsyncSocketDelegate methods

- (void)socket:(GCDAsyncSocket_LIO *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    controlSocketConnecting = NO;
    
    NSLog(@"[CONNECT] Connected!");
    
    NSString *udid = [[UIDevice currentDevice] uniqueIdentifier];
    NSString *intro = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    @"intro", @"type",
                                                    udid, @"device_id",
                                                    @"blah", @"customer_id",
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
    if (err)
    {
        if (controlSocketConnecting)
        {
            NSLog(@"[CONNECT] Connection failed. Reason: %@", [err localizedDescription]);
            [delegate lookIOManagerFailedToConnectWithError:err];
            controlSocketConnecting = NO;
            return;
        }
    }
    else
    {
        NSLog(@"[CONNECT] Socket disconnected.");
        waitingForScreenshotAck = NO;
        introduced = NO;
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
#pragma mark LIOChatboxViewDelegate

- (void)chatboxViewWasTapped:(LIOChatboxView *)aView
{
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];

    [keyWindow bringSubviewToFront:chatbox];
    [keyWindow bringSubviewToFront:chatField];
    
    [chatboxTimer invalidate];
    chatboxTimer = nil;
    
    chatField.hidden = NO;
    [chatField becomeFirstResponder];
    
    chatting = YES;
}

#pragma mark -
#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString *chat = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    @"chat", @"type",
                                                    chatField.text, @"text",
                                                    nil]];
    chat = [chat stringByAppendingString:LIOLookIOManagerMessageSeparator];
    
    [controlSocket writeData:[chat dataUsingEncoding:NSASCIIStringEncoding]
                 withTimeout:-1
                         tag:0];
    
    [chatbox addText:[NSString stringWithFormat:@"Me: %@", chatField.text]];
    
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    [keyWindow endEditing:YES];
    chatField.text = @"";
    chatField.hidden = YES;
    
    if (nil == chatboxTimer)
    {
        chatboxTimer = [NSTimer scheduledTimerWithTimeInterval:LIOLookIOMAnagerChatboxTimeoutInterval
                                                        target:self
                                                      selector:@selector(chatboxTimerDidFire:)
                                                      userInfo:nil
                                                       repeats:NO];
    }
    
    chatting = NO;
     
    return YES;
}

@end