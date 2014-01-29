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

@interface LIOHeaderBarView ()

@property (nonatomic, strong) LIONotificationArea* notificationArea;

@property (nonatomic, assign) CGFloat statusBarInset;

@property (nonatomic, strong) UIView *tappableBackground;
@property (nonatomic, strong) UIView *separator;

@property (nonatomic, strong) UIButton *backToChatButton;
@property (nonatomic, strong) UIButton *openInSafariButton;
@property (nonatomic, strong) LIOBadgeView *webBadgeView;
@property (nonatomic, assign) NSInteger webUnreadChatMessages;

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
            [self addSubview:self.notificationArea];
        }
        
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

#pragma mark WebView Methods

- (void)toggleWebMode:(BOOL)webMode
{
    if (webMode)
    {
        UIColor *buttonColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementBrandingBarWebviewButtons];
        self.openInSafariButton = [[UIButton alloc] initWithFrame:CGRectMake(self.bounds.size.width - 27.0, self.bounds.size.height - 30, 18.0, 24.0)];
        [self.openInSafariButton setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOShareIcon" withTint:buttonColor] forState:UIControlStateNormal];
        [self.openInSafariButton addTarget:self action:@selector(openInSafariButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        self.openInSafariButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self addSubview:self.openInSafariButton];
        
        NSString *buttonText = LIOLocalizedString(@"LIOLookIOManager.WebViewBackToChatButton");
        UIFont *buttonFont = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementBrandingBarWebviewButtons];
        CGSize expectedButtonSize = [buttonText sizeWithFont:buttonFont constrainedToSize:self.bounds.size];
        
        self.backToChatButton = [[UIButton alloc] initWithFrame:CGRectMake(6.0, self.bounds.size.height - expectedButtonSize.height - 5.0, expectedButtonSize.width + 10.0, expectedButtonSize.height)];
        [self.backToChatButton setTitle:buttonText forState:UIControlStateNormal];
        self.backToChatButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        self.backToChatButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        [self.backToChatButton addTarget:self action:@selector(backToChatButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        self.backToChatButton.titleLabel.font = buttonFont;
        [self.backToChatButton setTitleColor:buttonColor forState:UIControlStateNormal];
        [self addSubview:self.backToChatButton];
        
        self.webBadgeView = [[LIOBadgeView alloc] initWithFrame:CGRectMake(7.0 + expectedButtonSize.width, self.bounds.size.height - expectedButtonSize.height - 10.0, 17, 17) forBrandingElement:LIOBrandingElementBrandingBarWebviewButtonsBadge];
        [self.webBadgeView setBadgeNumber:1];
        self.webBadgeView.hidden = YES;
        [self addSubview:self.webBadgeView];
        
        self.webUnreadChatMessages = 0;
    }
    else
    {
        [self.openInSafariButton removeFromSuperview];
        [self.backToChatButton removeFromSuperview];
        [self.webBadgeView removeFromSuperview];
    }
}

- (void)reportUnreadChatMessageForWebView
{
    self.webBadgeView.hidden = NO;
    self.webUnreadChatMessages += 1;
    [self.webBadgeView setBadgeNumber:self.webUnreadChatMessages];
}

- (void)openInSafariButtonWasTapped:(id)sender
{
    [self.delegate headerBarViewOpenInSafariButtonWasTapped:self];
}

- (void)backToChatButtonWasTapped:(id)sender
{
    [self.delegate headerBarViewBackToChatButtonWasTapped:self];
}



@end