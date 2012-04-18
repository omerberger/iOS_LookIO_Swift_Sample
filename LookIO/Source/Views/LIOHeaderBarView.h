//
//  LIOHeaderBarView.h
//  LookIO
//
//  Created by Joseph Toscano on 1/20/12.
//  Copyright (c) 2012 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define LIOHeaderBarViewDefaultHeight               40.0
#define LIOHeaderBarViewDefaultNotificationDuration 5.0

@class LIOHeaderBarView, LIOTimerProxy;

@protocol LIOHeaderBarViewDelegate
- (void)headerBarViewPlusButtonWasTapped:(LIOHeaderBarView *)aView;
@end

@interface LIOHeaderBarView : UIView
{
    UIView *defaultNotification, *activeNotification;
    UIView *tappableBackground;
    UIView *separator;
    LIOTimerProxy *notificationTimer;
    id<LIOHeaderBarViewDelegate> delegate;
}

@property(nonatomic, assign) id<LIOHeaderBarViewDelegate> delegate;

- (void)revealNotificationString:(NSString *)aString;

@end