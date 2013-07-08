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

@synthesize delegate;

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
                
        notificationArea = [[LIONotificationArea alloc] initWithFrame:self.bounds];
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
            if (![[UIApplication sharedApplication] isStatusBarHidden]) {
                aFrame = notificationArea.frame;
                aFrame.origin.y += 20.0;
                notificationArea.frame = aFrame;
            }
        
        
        notificationArea.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:notificationArea];
        
        UITapGestureRecognizer *tapper = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)] autorelease];
        tappableBackground = [[UIView alloc] initWithFrame:self.bounds];
        tappableBackground.backgroundColor = [UIColor clearColor];
        [tappableBackground addGestureRecognizer:tapper];
        [self addSubview:tappableBackground];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [notificationArea release];
    [separator release];
    [tappableBackground release];
    
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