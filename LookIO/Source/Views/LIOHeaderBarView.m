//
//  LIOHeaderBarView.m
//  LookIO
//
//  Created by Joseph Toscano on 1/20/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import "LIOHeaderBarView.h"

#import <QuartzCore/QuartzCore.h>

// Managers
#import "LIOBundleManager.h"
#import "LIOBrandingManager.h"

// Views
#import "LIONotificationArea.h"
#import "LIOBadgeView.h"

// Helpers
#import "LIOTimerProxy.h"

@interface LIOHeaderBarView () <LIONotificationAreaDelegate>

@property (nonatomic, strong) LIONotificationArea* notificationArea;

@property (nonatomic, assign) CGFloat statusBarInset;

@property (nonatomic, strong) UIView *tappableBackground;
@property (nonatomic, strong) UIView *separator;

@end

@implementation LIOHeaderBarView

- (id)initWithFrame:(CGRect)frame statusBarInset:(CGFloat)anInset
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.statusBarInset = anInset;
        self.clipsToBounds = YES;

        UIColor *backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementBrandingBar];
        CGFloat backgroundAlpha = [[LIOBrandingManager brandingManager] backgroundAlphaForElement:LIOBrandingElementBrandingBar];
        self.backgroundColor = [backgroundColor colorWithAlphaComponent:backgroundAlpha];
        
        self.separator = [[UIView alloc] init];
        self.separator.backgroundColor = [UIColor lightGrayColor];
        CGRect aFrame = self.separator.frame;
        aFrame.size.height = 1.0;
        aFrame.size.width = self.bounds.size.width;
        aFrame.origin.y = self.bounds.size.height - 1.0;
        
        self.separator.frame = aFrame;
        self.separator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:self.separator];
        
        BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
        if (!padUI)
        {
            self.notificationArea = [[LIONotificationArea alloc] initWithFrame:CGRectMake(0, self.statusBarInset, self.bounds.size.width, self.bounds.size.height - self.statusBarInset)];
            self.notificationArea.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            self.notificationArea.delegate = self;
            [self addSubview:self.notificationArea];
        }
        
        UITapGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        self.tappableBackground = [[UIView alloc] initWithFrame:self.bounds];
        self.tappableBackground.backgroundColor = [UIColor clearColor];
        self.tappableBackground.isAccessibilityElement = YES;
        self.tappableBackground.accessibilityLabel = LIOLocalizedString(@"LIOAltChatViewController.ScrollToTopButton");
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
    
    self.notificationArea.frame = CGRectMake(0, self.statusBarInset, self.bounds.size.width, self.bounds.size.height - self.statusBarInset);
}

- (void)revealNotificationString:(NSString *)aString withAnimatedKeyboard:(BOOL)animated permanently:(BOOL)permanent
{
    self.notificationArea.keyboardIconVisible = animated;
    [self.notificationArea revealNotificationString:aString permanently:permanent];
}

- (void)hideCurrentNotification
{
    [self.notificationArea hideCurrentNotification];
}

#pragma mark -
#pragma mark NotificationAreaDelegate Methods

- (BOOL)notificationAreaShouldDismissNotification:(LIONotificationArea *)aView
{
    return [self.delegate headerBarShouldDismissNotification:self];
}

- (BOOL)notificationAreaShouldDisplayIsTypingAfterDismiss:(LIONotificationArea *)aView;
{
    return [self.delegate headerBarShouldDisplayIsTypingAfterDismiss:self];
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