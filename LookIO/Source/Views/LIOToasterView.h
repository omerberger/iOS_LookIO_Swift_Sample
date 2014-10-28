//
//  LIToasterView.h
//  LookIO
//
//  Created by Joseph Toscano on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define LIOToasterViewDefaultNotificationDuration 10.0

@class LIOToasterView, LIOAnimatedKeyboardIcon, LIOTimerProxy;

@protocol LIOToasterViewDelegate
- (void)toasterViewDidFinishShowing:(LIOToasterView *)aView;
- (void)toasterViewDidFinishHiding:(LIOToasterView *)aView;
- (BOOL)toasterViewShouldDismissNotification:(LIOToasterView *)aView;

@end

@interface LIOToasterView : UIView
{
    UILabel *textLabel;
    LIOAnimatedKeyboardIcon *keyboardIcon;
    BOOL keyboardIconVisible;
    BOOL shown;
    LIOTimerProxy *notificationTimer, *animatedEllipsisTimer;
    CGFloat yOrigin;
    id<LIOToasterViewDelegate> delegate;
}

@property(nonatomic, copy) NSString *text;
@property(nonatomic, assign, getter=isKeyboardIconVisible) BOOL keyboardIconVisible;
@property(nonatomic, assign) CGFloat yOrigin;
@property(nonatomic, readonly, getter=isShown) BOOL shown;
@property(nonatomic, assign) id<LIOToasterViewDelegate> delegate;

- (void)showAnimated:(BOOL)animated permanently:(BOOL)permanent;
- (void)hideAnimated:(BOOL)animated;

@end