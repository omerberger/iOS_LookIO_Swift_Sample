//
//  LIOAnimatedCogView.m
//  LookIO
//
//  Created by Joseph Toscano on 7/5/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import "LIOAnimatedCogView.h"
#import "LIOBundleManager.h"
#import <QuartzCore/QuartzCore.h>
#import "LIOTimerProxy.h"

@implementation LIOAnimatedCogView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        
        LIOBundleManager *bundleManager = [LIOBundleManager sharedBundleManager];
        cog = [[UIImageView alloc] initWithImage:[bundleManager imageNamed:@"LIOSignalCog"]];
        [self addSubview:cog];
        signalOne = [[UIImageView alloc] initWithImage:[bundleManager imageNamed:@"LIOSignalOne"]];
        signalOne.hidden = YES;
        [self addSubview:signalOne];
        signalTwo = [[UIImageView alloc] initWithImage:[bundleManager imageNamed:@"LIOSignalTwo"]];
        signalTwo.hidden = YES;
        [self addSubview:signalTwo];
        
        CABasicAnimation *rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotate.toValue = [NSNumber numberWithFloat:(M_PI * 2.0)];
        rotate.duration = 4.0;
        rotate.cumulative = YES;
        rotate.repeatCount = FLT_MAX;
        [cog.layer addAnimation:rotate forKey:@"rotationAnimation"];

        timer = [[LIOTimerProxy alloc] initWithTimeInterval:0.5 target:self selector:@selector(timerDidFire)];
    }
    
    return self;
}

- (void)dealloc
{
    [timer stopTimer];
    [timer release];
    
    [cog release];
    [signalOne release];
    [signalTwo release];
    
    [super dealloc];
}

- (void)layoutSubviews
{
    CGRect aFrame = self.frame;
    aFrame.size.width = 88;
    aFrame.size.height = 88.0;
    self.frame = aFrame;
    
    aFrame = cog.frame;
    aFrame.origin.x = 0.0;
    aFrame.origin.y = self.frame.size.height - aFrame.size.height;
    cog.frame = aFrame;
    
    aFrame = signalOne.frame;
    aFrame.origin.x = 30.0;
    aFrame.origin.y = 15.0;
    signalOne.frame = aFrame;
    
    aFrame = signalTwo.frame;
    aFrame.origin.x = self.frame.size.width - aFrame.size.width;
    aFrame.origin.y = 0.0;
    signalTwo.frame = aFrame;
}

- (void)timerDidFire
{
    if (YES == signalOne.hidden && YES == signalTwo.hidden)
    {
        signalOne.hidden = NO;
    }
    else if (NO == signalOne.hidden && YES == signalTwo.hidden)
    {
        signalTwo.hidden = NO;
    }
    else
    {
        signalOne.hidden = YES;
        signalTwo.hidden = YES;
    }
}

- (void)fadeIn
{
    self.alpha = 0.0;
    
    [UIView animateWithDuration:1.0
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.alpha = 1.0;
                     } completion:^(BOOL finished) {
                     }];
}

@end