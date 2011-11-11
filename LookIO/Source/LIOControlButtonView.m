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
        self.tintColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
        self.textColor = [UIColor whiteColor];
        self.labelText = @"Chat";
        
        label = [[UILabel alloc] initWithFrame:self.bounds];
        label.font = [UIFont boldSystemFontOfSize:20.0];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = textColor;
        label.text = labelText;
        label.textAlignment = UITextAlignmentCenter;
        label.layer.shadowColor = [UIColor blackColor].CGColor;
        label.layer.shadowOpacity = 1.0;
        label.layer.shadowOffset = CGSizeMake(2.0, 2.0);
        label.layer.shadowRadius = 1.0;
        label.userInteractionEnabled = NO;
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
    
    if (LIOControlButtonViewModeHorizontal == currentMode)
    {
        CGRect aFrame = self.frame;
        aFrame.size.width = 120.0;
        aFrame.size.height = 40.0;
        self.frame = aFrame;
    }
    else
    {
        CGRect aFrame = self.frame;
        aFrame.size.width = 40.0;
        aFrame.size.height = 120.0;
        self.frame = aFrame;
    }
    
    label.transform = CGAffineTransformIdentity;
    if (LIOControlButtonViewModeVertical == currentMode)
        label.transform = CGAffineTransformMakeRotation(-90.0 * (M_PI / 180.0));
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
    if (LIOControlButtonViewRoundedCornersModeNone != roundedCornersMode)
    {
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds 
                                                       byRoundingCorners:corners
                                                             cornerRadii:CGSizeMake(5.0, 5.0)];
        
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.frame = self.bounds;
        maskLayer.path = maskPath.CGPath;
        
        self.layer.mask = maskLayer;
    }
    else
        self.layer.mask = nil;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Paint the entire thing the tint...
    CGContextSetFillColorWithColor(context, [tintColor CGColor]);
    CGContextFillRect(context, rect);
    
    // ... and then the lower half a bit darker.
    /*
    CGFloat mid = rect.size.height / 2.0;
    CGRect halfRect = CGRectMake(0.0, mid, rect.size.width, mid);
    CGContextSetFillColorWithColor(context, [darkTintColor CGColor]);
    CGContextFillRect(context, halfRect);
     */
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
    
    const CGFloat *rgba = CGColorGetComponents(tintColor.CGColor);
    //NSLog(@"rgba: (%.2f, %.2f, %.2f, %.2f)", rgba[0], rgba[1], rgba[2], rgba[3]);
    
    [darkTintColor release];
    darkTintColor = [[UIColor alloc] initWithRed:(rgba[0] * 0.6) green:(rgba[1] * 0.6) blue:(rgba[2] * 0.6) alpha:rgba[3]];
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
                         self.alpha = 0.5;
                     }];
}

#pragma mark -
#pragma mark Gesture handlers

- (void)handleTap:(UITapGestureRecognizer *)tapper
{
    [delegate controlButtonViewWasTapped:self];
}

@end