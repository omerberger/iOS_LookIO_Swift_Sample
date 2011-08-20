//
//  LIOLookIOManager.m
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import "LIOLookIOManager.h"
#import "GCDAsyncSocket.h"

// Misc. constants
#define LIOLookIOManagerScreenCaptureInterval 1.0

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
        screenCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:LIOLookIOManagerScreenCaptureInterval
                                                              target:self
                                                            selector:@selector(screenCaptureTimerDidFire:)
                                                            userInfo:nil
                                                             repeats:YES];
    }
    
    return self;
}

- (void)dealloc
{
    [touchImage release];
    
    [super dealloc];
}

- (void)screenCaptureTimerDidFire:(NSTimer *)aTimer
{
    //UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    UIImage *screenshotImage = UIGraphicsGetImageFromCurrentImageContext();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *screenshotData = UIImageJPEGRepresentation(screenshotImage, 0.0);
        NSLog(@"[0.0] screenshotData.length: %u", screenshotData.length);
    });
}

@end