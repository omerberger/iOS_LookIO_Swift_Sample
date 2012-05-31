//
//  LIORuleViewVisible.m
//  LookIO
//
//  Created by Joseph Toscano on 5/30/12.
//  Copyright (c) 2012 LookIO, Inc. All rights reserved.
//

#import "LIORuleViewVisible.h"
#import "LIOTimerProxy.h"

@implementation LIORuleViewVisible

@synthesize duration, locationName, delegate;

- (id)initWithLocationName:(NSString *)aString duration:(NSTimeInterval)anInterval
{
    self = [super init];
    
    if (self)
    {
        duration = anInterval;
        locationName = [aString retain];
    }
    
    return self;
}

- (void)dealloc
{
    [timer stopTimer];
    [timer release];
    
    [locationName release];    
    
    [super dealloc];
}

- (void)startTimer
{
    if (timer)
        return;
    
    timer = [[LIOTimerProxy alloc] initWithTimeInterval:duration target:self selector:@selector(timerDidFire)];
}

- (void)stopTimer
{
    [timer stopTimer];
    [timer release];
    timer = nil;
}

- (void)timerDidFire
{
    [timer stopTimer];
    [timer release];
    timer = nil;
    
    [delegate ruleViewVisibleTimerDidFire:self];
}

@end