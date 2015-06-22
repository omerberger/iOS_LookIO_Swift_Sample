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

@interface LIOHeaderBarView () <LIONotificationAreaDelegate,UIGestureRecognizerDelegate>

@property (nonatomic, strong) LIONotificationArea* notificationArea;

@property (nonatomic, assign) CGFloat statusBarInset;

@property (nonatomic, strong) UIView *tappableBackground;
@property (nonatomic, strong) UIView *separator;

@property (nonatomic, strong) UIView *hideButton;   //Could be image or text

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
        self.separator.backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementBrandingBar];
        CGRect aFrame = self.separator.frame;
        aFrame.size.height = 1.0;
        aFrame.size.width = self.bounds.size.width;
        aFrame.origin.y = self.bounds.size.height - 1.0;
        
        self.separator.frame = aFrame;
        self.separator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:self.separator];
        
        self.hideButton = nil;
        
        LPBrandingBarBackButtonType backButtonType = [[LIOBrandingManager brandingManager] brandingBarBackButtonType];
        switch (backButtonType) {
            case LPBrandingBarBackButtonTypeText: {
                NSString *hideString = LIOLocalizedString(@"LPBrandingBar.HideChatButton");;
                UIFont *hideButtonFont = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementBrandingBarBackButton];
                CGSize expectedSize = [hideString sizeWithAttributes:
                                       @{NSFontAttributeName:hideButtonFont}];

                UIButton *hideButton = [UIButton buttonWithType:UIButtonTypeSystem];
                [hideButton addTarget:self action:@selector(handleTapOnHide:) forControlEvents:UIControlEventTouchUpInside];
                [hideButton setTitle:hideString forState:UIControlStateNormal];
                hideButton.frame = CGRectMake(0, 0, ceil(expectedSize.width), ceil(expectedSize.height));
                hideButton.titleLabel.text = hideString;
                hideButton.titleLabel.font = hideButtonFont;
                hideButton.tintColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementBrandingBarBackButton];
                hideButton.titleLabel.textAlignment = UITextAlignmentCenter;

                
                self.hideButton = [[UIView alloc] initWithFrame:hideButton.frame];
                [self.hideButton addSubview:hideButton];
                self.hideButton.center = CGPointMake(self.hideButton.frame.size.width/2+5, self.bounds.size.height/2+9);
                self.hideButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
                [self addSubview:self.hideButton];
                
                

                break;
            }
            case LPBrandingBarBackButtonTypeImage: {
                UIColor *backIconColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorIcon forElement:LIOBrandingElementBrandingBarBackButton];
                UIImage *backButtonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LPBackButtonIcon" withTint:backIconColor];
                
                UIButton *hideButton = [UIButton buttonWithType:UIButtonTypeSystem];
                [hideButton addTarget:self action:@selector(handleTapOnHide:) forControlEvents:UIControlEventTouchUpInside];
                [hideButton setImage:backButtonImage forState:UIControlStateNormal];
                hideButton.frame = CGRectMake(0, 0, backButtonImage.size.width, backButtonImage.size.height);
                hideButton.tintColor = backIconColor;
                
                self.hideButton = [[UIView alloc] initWithFrame:hideButton.frame];
                [self.hideButton addSubview:hideButton];
                self.hideButton.center = CGPointMake(self.hideButton.frame.size.width/2+5, self.bounds.size.height/2+9);
                self.hideButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
                [self addSubview:self.hideButton];
            }
                break;
                
                
            default: //LPBrandingBarBackButtonTypeNone
                //Nothing to do
                break;
        }

        
        BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
        if (!padUI)
        {
            CGFloat originX = (self.hideButton ? self.hideButton.frame.size.width+10 : 0);
            CGFloat widthSize = self.bounds.size.width - (self.hideButton ? self.hideButton.frame.size.width*2+20 : 0);
            self.notificationArea = [[LIONotificationArea alloc] initWithFrame:CGRectMake(originX, self.statusBarInset, widthSize , self.bounds.size.height - self.statusBarInset)];
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
        

        [self bringSubviewToFront:self.hideButton];
    }
    
    return self;
}

- (void)updateStatusBarInset:(CGFloat)inset
{
    self.statusBarInset = inset;
    [self rejiggerSubviews];
    
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

- (void)removeTimersAndNotifications
{
    [self.notificationArea removeTimersAndNotifications];
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

- (void)handleTapOnHide:(UITapGestureRecognizer *)aTapper
{
    [self.delegate headerBarViewHideButtonWasTapped:self];
}

@end