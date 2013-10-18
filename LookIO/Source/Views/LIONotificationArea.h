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

@interface LIONotificationArea : UIView
{
    UIView *defaultNotification, *activeNotification;
    LIOTimerProxy *notificationTimer, *animatedEllipsisTimer, *startAnimatedLongTextTimer, *moveAnimatedLongTextTimer;
    LIOAnimatedKeyboardIcon *keyboardIcon;
    BOOL keyboardIconVisible;
    BOOL animatingLongText;
    BOOL hasCustomBranding;
}

@property(nonatomic, assign, getter=isKeyboardIconVisible) BOOL keyboardIconVisible;
@property (nonatomic, readonly) BOOL hasCustomBranding;

- (void)revealNotificationString:(NSString *)aString permanently:(BOOL)permanent;

@end