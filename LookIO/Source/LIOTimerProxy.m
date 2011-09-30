//
//  LIOTimerProxy.m
//  LookIO
//
//  Created by Joe Toscano on 9/30/11.
//  Copyright 2011 LookIO, Inc. All rights reserved.
//

#import "LIOTimerProxy.h"

@implementation LIOTimerProxy

- (id)initWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector
{
    if (self == [super init])
    {
        theTarget = aTarget;
        theSelector = aSelector;
        
        theTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:ti]
                                            interval:ti
                                              target:self
                                            selector:@selector(theTimerDidFire:)
                                            userInfo:nil
                                             repeats:YES];
        
        [[NSRunLoop mainRunLoop] addTimer:theTimer forMode:NSRunLoopCommonModes];

        /*
        theTimer = [[NSTimer scheduledTimerWithTimeInterval:ti
                                                     target:self
                                                   selector:@selector(theTimerDidFire:)
                                                   userInfo:nil
                                                    repeats:YES] retain];
        */
    }
    
    return self;
}

- (void)stopTimer
{
    [theTimer invalidate];
    [theTimer release];
    theTimer = nil;
}

- (void)theTimerDidFire:(NSTimer *)aTimer
{
    [theTarget performSelector:theSelector];
}

@end