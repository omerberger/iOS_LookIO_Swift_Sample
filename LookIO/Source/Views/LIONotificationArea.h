//
//  LIONotificationArea.h
//  LookIO
//
//  Created by Joseph Toscano on 5/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define LIONotificationAreaDefaultNotificationDuration 5.0

@class LIOAnimatedKeyboardIcon, LIOTimerProxy;

@interface LIONotificationArea : UIView
{
    UIView *defaultNotification, *activeNotification;
    LIOTimerProxy *notificationTimer, *animatedEllipsisTimer;
    LIOAnimatedKeyboardIcon *keyboardIcon;
}

@end
