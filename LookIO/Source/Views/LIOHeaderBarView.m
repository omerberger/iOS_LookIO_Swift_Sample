//
//  LIOHeaderBarView.m
//  LookIO
//
//  Created by Joseph Toscano on 1/20/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "LIOHeaderBarView.h"
#import "LIOLookIOManager.h"
#import "LIOBundleManager.h"
#import "LIOTimerProxy.h"
#import "LIONotificationArea.h"

@implementation LIOHeaderBarView

@synthesize delegate, notificationArea;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.clipsToBounds = YES;
        
        separator = [[UIView alloc] init];
        separator.backgroundColor = [UIColor colorWithPatternImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIORepeatableBlendedSeparatorTop"]];
        separator.opaque = NO;
        CGRect aFrame = separator.frame;
        aFrame.size.height = 15.0;
        aFrame.size.width = self.bounds.size.width;
        aFrame.origin.y = self.bounds.size.height - 14.0;
        
        separator.frame = aFrame;
        separator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:separator];
        [separator release];
                
        notificationArea = [[LIONotificationArea alloc] initWithFrame:self.bounds];
                
        notificationArea.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:notificationArea];
        [notificationArea release];
        
        UITapGestureRecognizer *tapper = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)] autorelease];
        tappableBackground = [[UIView alloc] initWithFrame:self.bounds];
        tappableBackground.backgroundColor = [UIColor clearColor];
        [tappableBackground addGestureRecognizer:tapper];
        [self addSubview:tappableBackground];
        [tappableBackground release];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)revealNotificationString:(NSString *)aString withAnimatedKeyboard:(BOOL)animated permanently:(BOOL)permanent
{
    notificationArea.keyboardIconVisible = animated;
    [notificationArea revealNotificationString:aString permanently:permanent];
}

#pragma mark -
#pragma mark UIControl actions

- (void)plusButtonWasTapped
{
    [delegate headerBarViewPlusButtonWasTapped:self];
}

#pragma mark -
#pragma mark Gesture handlers

- (void)handleTap:(UITapGestureRecognizer *)aTapper
{
    [delegate headerBarViewPlusButtonWasTapped:self];
}

@end