//
//  LIOControlButtonView.m
//  LookIO
//
//  Created by Joseph Toscano on 11/1/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import "LIOControlButtonView.h"
#import <QuartzCore/QuartzCore.h>
#import "LIOTimerProxy.h"

@implementation LIOControlButtonView

@synthesize textColor, labelText, delegate;
@dynamic tintColor, currentMode, roundedCornersMode;

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        // Defaults.
        self.tintColor = [UIColor redColor];
        self.textColor = [UIColor whiteColor];
        self.labelText = @"Chat";
        
        label = [[UILabel alloc] initWithFrame:self.bounds];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = textColor;
        label.text = labelText;
        label.textAlignment = UITextAlignmentCenter;
        [self addSubview:label];
        
        UITapGestureRecognizer *tapper = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)] autorelease];
        [self addGestureRecognizer:tapper];
    }
    
    return self;
}

- (void)dealloc
{
    [tintColor release];
    [label release];
    [labelText release];
    [textColor release];
    [darkTintColor release];
    
    [fadeTimer stopTimer];
    [fadeTimer release];
    
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    //CGRectMake(116.0, 68.0, 100.0, 24.0)
    if (LIOControlButtonViewModeHorizontal == currentMode)
    {
        CGRect aFrame = self.frame;
        aFrame.size.width = 100.0;
        aFrame.size.height = 24.0;
        self.frame = aFrame;
    }
    else
    {
        CGRect aFrame = self.frame;
        aFrame.size.width = 24.0;
        aFrame.size.height = 100.0;
        self.frame = aFrame;
    }
    
    label.frame = self.bounds;
    
    UIRectCorner corners;
    if (LIOControlButtonViewModeHorizontal == currentMode)
    {
        if (LIOControlButtonViewRoundedCornersModeDefault == roundedCornersMode)
            corners = UIRectCornerBottomRight | UIRectCornerBottomLeft;
        else
            corners = UIRectCornerTopRight | UIRectCornerTopLeft;
    }
    else
    {
        if (LIOControlButtonViewRoundedCornersModeDefault == roundedCornersMode)
            corners = UIRectCornerTopRight | UIRectCornerBottomRight;
        else
            corners = UIRectCornerTopLeft | UIRectCornerBottomLeft;
    }
    
    // Round the corners using a bezier mask.
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds 
                                                   byRoundingCorners:corners
                                                         cornerRadii:CGSizeMake(5.0, 5.0)];
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    
    self.layer.mask = maskLayer;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Paint the entire thing the tint...
    CGContextSetFillColorWithColor(context, [tintColor CGColor]);
    CGContextFillRect(context, rect);
    
    if (LIOControlButtonViewModeHorizontal == currentMode)
    {
        // ... and then the lower half a bit darker.
        CGFloat mid = rect.size.height / 2.0;
        CGRect halfRect = CGRectMake(0.0, mid, rect.size.width, mid);
        CGContextSetFillColorWithColor(context, [darkTintColor CGColor]);
        CGContextFillRect(context, halfRect);
    }
    else
    {
        // ... and then the right half a bit darker.
        CGFloat mid = rect.size.width / 2.0;
        CGRect halfRect = CGRectMake(mid, 0.0, mid, rect.size.height);
        CGContextSetFillColorWithColor(context, [darkTintColor CGColor]);
        CGContextFillRect(context, halfRect);
    }
    
    [super drawRect:rect];
}

- (void)startFadeTimer
{
    [fadeTimer stopTimer];
    [fadeTimer release];
    
    self.alpha = 1.0;
    
    fadeTimer = [[LIOTimerProxy alloc] initWithTimeInterval:5.0 target:self selector:@selector(fadeTimerDidFire)];
}

#pragma mark -
#pragma mark Dynamic property accessors

- (void)setTintColor:(UIColor *)aColor
{
    [tintColor release];
    tintColor = [aColor retain];
    
    CGFloat red, green, blue, alpha;
    [tintColor getRed:&red green:&green blue:&blue alpha:&alpha];
    
    [darkTintColor release];
    darkTintColor = [[UIColor alloc] initWithRed:(red * 0.85) green:(green * 0.85) blue:(blue * 0.85) alpha:alpha];
}

- (UIColor *)tintColor
{
    return tintColor;
}

- (void)setCurrentMode:(LIOControlButtonViewMode)aMode
{
    currentMode = aMode;
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (LIOControlButtonViewMode)currentMode
{
    return currentMode;
}

- (void)setRoundedCornersMode:(LIOControlButtonViewRoundedCornersMode)aMode
{
    roundedCornersMode = aMode;
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (LIOControlButtonViewRoundedCornersMode)roundedCornersMode
{
    return roundedCornersMode;
}

#pragma mark -
#pragma mark Timer callbacks

- (void)fadeTimerDidFire
{
    [fadeTimer stopTimer];
    [fadeTimer release];
    fadeTimer = nil;
    
    [UIView animateWithDuration:2.0
                     animations:^{
                         self.alpha = 0.33;
                     }];
}

#pragma mark -
#pragma mark Gesture handlers

- (void)handleTap:(UITapGestureRecognizer *)tapper
{
    [delegate controlButtonViewWasTapped:self];
}

@end