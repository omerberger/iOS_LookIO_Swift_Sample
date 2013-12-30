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

@interface LIOHeaderBarView ()

@property (nonatomic, strong) LIONotificationArea* notificationArea;
@property (nonatomic, strong) UIView *tappableBackground;
@property (nonatomic, strong) UIView *separator;

@end

@implementation LIOHeaderBarView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.clipsToBounds = YES;
        
        self.separator = [[UIView alloc] init];
        self.separator.backgroundColor = [UIColor lightGrayColor];
        CGRect aFrame = self.separator.frame;
        aFrame.size.height = 1.0;
        aFrame.size.width = self.bounds.size.width;
        aFrame.origin.y = self.bounds.size.height - 1.0;
        
        self.separator.frame = aFrame;
        self.separator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:self.separator];
        
        self.notificationArea = [[LIONotificationArea alloc] initWithFrame:self.bounds];
        self.notificationArea.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:self.notificationArea];
        
        UITapGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        self.tappableBackground = [[UIView alloc] initWithFrame:self.bounds];
        self.tappableBackground.backgroundColor = [UIColor clearColor];
        [self.tappableBackground addGestureRecognizer:tapper];
        [self addSubview:self.tappableBackground];
    }
    
    return self;
}

- (void)rejiggerSubviews {
    CGRect aFrame = self.separator.frame;
    aFrame.size.height = 1.0;
    aFrame.size.width = self.bounds.size.width;
    aFrame.origin.y = self.bounds.size.height - 1.0;
    self.separator.frame = aFrame;
    
    aFrame = self.bounds;
    self.notificationArea.frame = aFrame;
}

- (void)revealNotificationString:(NSString *)aString withAnimatedKeyboard:(BOOL)animated permanently:(BOOL)permanent
{
    self.notificationArea.keyboardIconVisible = animated;
    [self.notificationArea revealNotificationString:aString permanently:permanent];
}

#pragma mark -
#pragma mark UIControl actions

- (void)plusButtonWasTapped
{
    [self.delegate headerBarViewPlusButtonWasTapped:self];
}

#pragma mark -
#pragma mark Gesture handlers

- (void)handleTap:(UITapGestureRecognizer *)aTapper
{
    [self.delegate headerBarViewPlusButtonWasTapped:self];
}

@end