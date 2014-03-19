//
//  LIONotificationArea.h
//  LookIO
//
//  Created by Joseph Toscano on 5/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define LIONotificationAreaDefaultNotificationDuration   5.0
#define LIONotificationAreaPreLongTextAnimationDuration  3.0
#define LIONotificationAreaPostLongTextAnimationDuration 3.0
#define LIONotificationAreaNotificationLabelTag         2749

@class LIOAnimatedKeyboardIcon, LIOTimerProxy;

@class LIONotificationArea;

@protocol LIONotificationAreaDelegate <NSObject>

- (BOOL)notificationAreaShouldDismissNotification:(LIONotificationArea *)aView;
- (BOOL)notificationAreaShouldDisplayIsTypingAfterDismiss:(LIONotificationArea *)aView;

@end

@interface LIONotificationArea : UIView

@property (nonatomic, assign) id <LIONotificationAreaDelegate> delegate;

@property (nonatomic, assign, getter=isKeyboardIconVisible) BOOL keyboardIconVisible;
@property (nonatomic, assign) BOOL hasCustomBranding;

- (void)revealNotificationString:(NSString *)aString permanently:(BOOL)permanent;
- (void)hideCurrentNotification;
- (void)removeTimersAndNotifications;

@end