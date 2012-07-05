//
//  LIOAnimatedCogView.h
//  LookIO
//
//  Created by Joseph Toscano on 7/5/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LIOTimerProxy;

@interface LIOAnimatedCogView : UIView
{
    UIImageView *cog, *signalOne, *signalTwo;
    LIOTimerProxy *timer;
}

- (void)fadeIn;

@end