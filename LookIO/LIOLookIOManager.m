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

// Misc. constants
#define LIOLookIOManagerScreenCaptureInterval   1.0

#define LIOLookIOManagerScreenshotTimeout       5.0
#define LIOLookIOManagerIntroductionTimeout     5.0

#define LIOLookIOManagerControlEndpoint         @"look.io"
#define LIOLookIOManagerControlEndpointPort     8100

#define LIOLookIOManagerMessageSeparator        @"!look.io!"

// Message identifiers
#define LIOLookIOManagerIntroductionTag 1
#define LIOLookIOManagerScreenshotTag   2

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
        controlSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:delegateQueue];
        
        screenCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:LIOLookIOManagerScreenCaptureInterval
                                                              target:self
                                                            selector:@selector(screenCaptureTimerDidFire:)
                                                            userInfo:nil
                                                             repeats:YES];
        
        messageSeparatorData = [[LIOLookIOManagerMessageSeparator dataUsingEncoding:NSASCIIStringEncoding] retain];
        
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        CGRect aFrame = CGRectZero;
        aFrame.size.height = 50.0;
        aFrame.size.width = keyWindow.frame.size.width;
        chatbox = [[LIOChatboxView alloc] initWithFrame:aFrame];
        [keyWindow addSubview:chatbox];
        
        jsonParser = [[SBJsonParser alloc] init];
        jsonWriter = [[SBJsonWriter alloc] init];
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
        NSString *base64Data = [screenshotData base64EncodedString];
        
        NSString *screenshot = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             @"screenshot", @"type",
                                                             [self nextGUID], @"screenshot_id",
                                                             base64Data, @"screenshot",
                                                             nil]];
        
        screenshot = [screenshot stringByAppendingString:LIOLookIOManagerMessageSeparator];
        
        waitingForScreenshotAck = YES;
        [controlSocket writeData:[screenshot dataUsingEncoding:NSASCIIStringEncoding]
                     withTimeout:LIOLookIOManagerScreenshotTimeout
                             tag:LIOLookIOManagerScreenshotTag];
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
        [delegate lookIOManagerFailedToConnectWithError:connectError];
        return;
    }
    
    controlSocketConnecting = YES;
}

#pragma mark -
#pragma mark GCDAsyncSocketDelegate methods

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
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
    
    [controlSocket writeData:[intro dataUsingEncoding:NSASCIIStringEncoding]
                 withTimeout:LIOLookIOManagerIntroductionTimeout
                         tag:LIOLookIOManagerIntroductionTag];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
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

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    if (LIOLookIOManagerIntroductionTag == tag)
    {
        // Waiting for ack...
        [controlSocket readDataToData:messageSeparatorData
                          withTimeout:LIOLookIOManagerIntroductionTimeout
                                  tag:LIOLookIOManagerIntroductionTag];
    }
    else if (LIOLookIOManagerScreenshotTag == tag)
    {
        // Waiting for ack...
        [controlSocket readDataToData:messageSeparatorData
                          withTimeout:LIOLookIOManagerScreenshotTimeout
                                  tag:LIOLookIOManagerScreenshotTag];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    if (LIOLookIOManagerIntroductionTag == tag)
    {
        NSString *jsonString = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
        jsonString = [jsonString substringToIndex:([jsonString length] - [LIOLookIOManagerMessageSeparator length])];
        NSDictionary *result = [jsonParser objectWithString:jsonString];
        NSString *type = [result objectForKey:@"type"];
        if (NO == [type isEqualToString:@"ack"])
        {
            NSLog(@"[INTRODUCTION] Was expecting ack. Didn't get one!");
            return;
        }
        
        NSLog(@"[INTRODUCTION] Introduction complete.");
        introduced = YES;
    }
    else if (LIOLookIOManagerScreenshotTag == tag)
    {
        NSString *jsonString = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
        jsonString = [jsonString substringToIndex:([jsonString length] - [LIOLookIOManagerMessageSeparator length])];
        NSDictionary *result = [jsonParser objectWithString:jsonString];
        NSString *type = [result objectForKey:@"type"];
        if (NO == [type isEqualToString:@"ack"])
        {
            NSLog(@"[SCREENSHOT] Was expecting ack. Didn't get one!");
            return;
        }
        
        NSLog(@"[SCREENSHOT] Screenshot received by remote host.");
        waitingForScreenshotAck = NO;
    }
}

@end