//
//  LIOAnimatedKeyboardIcon.m
//  LookIO
//
//  Created by Joseph Toscano on 4/17/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import "LIOAnimatedKeyboardIcon.h"

#import "LIOLogManager.h"
#import "LIOBundleManager.h"

#import "LIOTimerProxy.h"


@implementation LIOAnimatedKeyboardIcon

@synthesize animating;

- (id)initWithFrame:(CGRect)frame forElement:(LIOBrandingElement)brandingElement
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        UIColor *keyboardTintColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:brandingElement];
        
        UIImageView *background = [[[UIImageView alloc] initWithImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOKeyboardIcon" withTint:keyboardTintColor]] autorelease];
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
        if (keyOpacities[i] <= 0.0 && 0 == arc4random() % (LIOAnimatedKeyboardIconRandomFrequency + (arc4random() % 10)))
            keyOpacities[i] = 1.0;
        else if (keyOpacities[i] > 0.0)
            keyOpacities[i] -= LIOAnimatedKeyboardIconKeyDecayRate * elapsed;
    }
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (NO == animating)
        return;
    
    [self processKeyOpacities];
    
    UIColor *keyboardTintColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementBrandingBarNotifications];

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    CGContextSetFillColorWithColor(context, keyboardTintColor.CGColor);
    
    for (int i=0; i<LIOAnimatedKeyboardIconNumKeys; i++)
    {
        CGFloat alpha = keyOpacities[i];
        if (alpha < 0.0) alpha = 0.0;
        CGContextSetAlpha(context, alpha);
        
        switch (i)
        {
            case 0: CGContextAddRect(context, CGRectMake(2.5, 3.0, 1.5, 1.5)); break;
            case 1: CGContextAddRect(context, CGRectMake(5.0, 3.0, 1.5, 1.5)); break;
            case 2: CGContextAddRect(context, CGRectMake(7.5, 3.0, 1.5, 1.5)); break;
            case 3: CGContextAddRect(context, CGRectMake(10.0, 3.0, 1.5, 1.5)); break;
            case 4: CGContextAddRect(context, CGRectMake(2.5, 6.0, 3.0, 1.5)); break;
            case 5: CGContextAddRect(context, CGRectMake(6.5, 6.0, 1.5, 1.5)); break;
            case 6: CGContextAddRect(context, CGRectMake(9.0, 6.0, 1.5, 1.5)); break;
            case 7: CGContextAddRect(context, CGRectMake(11.5, 6.0, 1.5, 1.5)); break;
            case 8: CGContextAddRect(context, CGRectMake(2.5, 8.5, 1.5, 1.5)); break;
            case 9: CGContextAddRect(context, CGRectMake(5.0, 8.5, 8.0, 1.5)); break;
            case 10: CGContextAddRect(context, CGRectMake(14.0, 8.5, 1.5, 1.5)); break;
        }
        
        CGContextFillPath(context);
    }
}

- (void)animationTimerDidFire
{
    [self setNeedsDisplay];
}

@end
