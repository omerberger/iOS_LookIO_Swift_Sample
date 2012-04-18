//
//  LIOAnimatedKeyboardIcon.h
//  LookIO
//
//  Created by Joseph Toscano on 4/17/12.
//  Copyright (c) 2012 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define LIOAnimatedKeyboardIconNumKeys          15
#define LIOAnimatedKeyboardIconKeyDecayRate     3.0
#define LIOAnimatedKeyboardIconAnimationRate    0.1
#define LIOAnimatedKeyboardIconRandomFrequency  20

@class LIOTimerProxy;

@interface LIOAnimatedKeyboardIcon : UIView
{
    CGFloat keyOpacities[LIOAnimatedKeyboardIconNumKeys];
    LIOTimerProxy *animationTimer;
    BOOL animating;
}

@property(nonatomic, assign, getter=isAnimating) BOOL animating;

@end