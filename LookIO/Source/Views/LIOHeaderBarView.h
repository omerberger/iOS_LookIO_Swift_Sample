//
//  LIOHeaderBarView.h
//  LookIO
//
//  Created by Joseph Toscano on 1/20/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define LIOHeaderBarViewDefaultHeight 32.0

@class LIOHeaderBarView, LIOTimerProxy, LIONotificationArea;

@protocol LIOHeaderBarViewDelegate

- (void)headerBarViewPlusButtonWasTapped:(LIOHeaderBarView *)aView;
- (void)headerBarViewHideButtonWasTapped:(LIOHeaderBarView *)aView;
- (BOOL)headerBarShouldDismissNotification:(LIOHeaderBarView *)aView;
- (BOOL)headerBarShouldDisplayIsTypingAfterDismiss:(LIOHeaderBarView *)aView;

@end

@interface LIOHeaderBarView : UIView

@property (nonatomic, assign) id<LIOHeaderBarViewDelegate> delegate;
@property (nonatomic, readonly) LIONotificationArea* notificationArea;

- (id)initWithFrame:(CGRect)frame statusBarInset:(CGFloat)anInset;

- (void)revealNotificationString:(NSString *)aString withAnimatedKeyboard:(BOOL)animated permanently:(BOOL)permanent;
- (void)hideCurrentNotification;
- (void)removeTimersAndNotifications;

- (void)updateStatusBarInset:(CGFloat)inset;
- (void)rejiggerSubviews;

@end