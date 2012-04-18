//
//  LIOAnimatedKeyboardIcon.m
//  LookIO
//
//  Created by Joseph Toscano on 4/17/12.
//  Copyright (c) 2012 LookIO, Inc. All rights reserved.
//

#import "LIOAnimatedKeyboardIcon.h"
#import "LIOBundleManager.h"
#import "LIOTimerProxy.h"
#import "LIOLogManager.h"

@implementation LIOAnimatedKeyboardIcon

@synthesize animating;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        UIImageView *background = [[[UIImageView alloc] initWithImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOKeyboardIcon"]] autorelease];
        [self addSubview:background];
        
        for (int i=0; i<LIOAnimatedKeyboardIconNumKeys; i++)
            keyOpacities[i] = 1.0;
        
        animationTimer = [[LIOTimerProxy alloc] initWithTimeInterval:LIOAnimatedKeyboardIconAnimationRate
                                                              target:self
                                                            selector:@selector(animationTimerDidFire)];
    }
    
    return self;
}

- (void)dealloc
{
    [animationTimer stopTimer];
    [animationTimer release];
    
    [super dealloc];
}

- (void)processKeyOpacities
{
    static NSTimeInterval elapsed = 0.0;
    static NSTimeInterval previousTime = 0.0;
    
    if (0.0 == previousTime)
    {
        previousTime = [NSDate timeIntervalSinceReferenceDate];
        return;
    }
    
    elapsed = [NSDate timeIntervalSinceReferenceDate] - previousTime;
    previousTime = [NSDate timeIntervalSinceReferenceDate];
    
    for (int i=0; i<LIOAnimatedKeyboardIconNumKeys; i++)
    {
        // Full opacity (at random) if 0.0.
        if (keyOpacities[i] <= 0.0 && 0 == arc4random() % LIOAnimatedKeyboardIconRandomFrequency)
            keyOpacities[i] = 1.0;
        else if (keyOpacities[i] > 0.0)
            keyOpacities[i] -= LIOAnimatedKeyboardIconKeyDecayRate * elapsed;
    }
}

// keys are 3x3, padding between is 3
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (NO == animating)
        return;
    
    [self processKeyOpacities];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    
    for (int i=0; i<LIOAnimatedKeyboardIconNumKeys; i++)
    {
        if (i == 11 || i == 13)
            continue;
        
        CGFloat alpha = keyOpacities[i];
        if (alpha < 0.0) alpha = 0.0;
        CGContextSetAlpha(context, alpha);
        
        // 12 == space bar
        if (i == 12)
        {
            CGContextAddRect(context, CGRectMake(9.0, 13.0, 14.0, 3.0));
            CGContextFillPath(context);
        }
        else
        {
            int row = i / 5;
            int col = i % 5;
            CGFloat x = 3.0 + (col * 5.5);
            CGFloat y = 3.0 + (row * 5.5);
            
            CGContextAddRect(context, CGRectMake(x, y, 5.0, 5.0));
            CGContextFillPath(context);
        }
    }
}

- (void)animationTimerDidFire
{
    [self setNeedsDisplay];
}

@end
