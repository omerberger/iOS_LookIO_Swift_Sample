//
//  LIOTimerProxy.m
//  LookIO
//
//  Created by Joe Toscano on 9/30/11.
//  Copyright 2011 LivePerson, Inc. All rights reserved.
//

#import "LIOTimerProxy.h"

@implementation LIOTimerProxy

@synthesize userInfo;

- (id)initWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)aUserInfo
{
    if (self == [super init])
    {
        userInfo = [aUserInfo retain];
        
        theTarget = aTarget;
        
        theSelector = aSelector;
        NSMethodSignature *sig = [theTarget methodSignatureForSelector:theSelector];
        selectorTakesArgument = [sig numberOfArguments] == 1;
        
        theTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:ti]
                                            interval:ti
                                              target:self
                                            selector:@selector(theTimerDidFire:)
                                            userInfo:nil
                                             repeats:YES];
        
        [[NSRunLoop mainRunLoop] addTimer:theTimer forMode:NSRunLoopCommonModes];
    }
    
    return self;
}

- (id)initWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector
{
    return [self initWithTimeInterval:ti target:aTarget selector:aSelector userInfo:nil];
}

- (void)stopTimer
{
    [theTimer invalidate];
    [theTimer release];
    theTimer = nil;
}

- (void)theTimerDidFire:(NSTimer *)aTimer
{
    if (selectorTakesArgument)
        [theTarget performSelector:theSelector withObject:self];
    else
        [theTarget performSelector:theSelector];
}

- (void)dealloc
{
    [userInfo release];
    
    [super dealloc];
}

@end