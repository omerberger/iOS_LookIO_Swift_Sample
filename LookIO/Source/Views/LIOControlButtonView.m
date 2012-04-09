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
#import "LIOLookIOManager.h"
#import "LIOBundleManager.h"

@implementation LIOControlButtonView

@synthesize textColor, labelText, delegate, label, currentMode;
@dynamic tintColor;

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        // Defaults.
        self.tintColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
        self.textColor = [UIColor whiteColor];
        self.labelText = @"Live Help";
        
        label = [[UILabel alloc] initWithFrame:self.bounds];
        label.font = [UIFont systemFontOfSize:17.0];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = textColor;
        label.text = labelText;
        label.textAlignment = UITextAlignmentCenter;
        label.layer.shadowColor = [UIColor blackColor].CGColor;
        label.layer.shadowOpacity = 1.0;
        label.layer.shadowOffset = CGSizeMake(1.5, 1.5);
        label.layer.shadowRadius = 1.5;
        label.userInteractionEnabled = NO;
        [self addSubview:label];
        
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeZero;
        self.layer.shadowOpacity = 1.0;
        self.layer.shadowRadius = 4.0;
        
        self.opaque = NO;
        
        UITapGestureRecognizer *tapper = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)] autorelease];
        [self addGestureRecognizer:tapper];
        
        if ([UIScreen instancesRespondToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2.0)
            innerShadow = [[UIImageView alloc] initWithImage:[[LIOBundleManager sharedBundleManager] lioTabInnerShadow2x]];
        else
            innerShadow = [[UIImageView alloc] initWithImage:[[LIOBundleManager sharedBundleManager] lioTabInnerShadow]];
        
        [self addSubview:innerShadow];
        
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [spinner startAnimating];
        [self addSubview:spinner];
    }
    
    return self;
}

- (void)dealloc
{
    [tintColor release];
    [label release];
    [labelText release];
    [textColor release];
    [fillColor release];
    [shadowColor release];
    [innerShadow release];
    [spinner release];
    
    [fadeTimer stopTimer];
    [fadeTimer release];
    
    [super dealloc];
}

- (void)layoutSubviews
{
    if (labelText)
        label.text = labelText;
    else
        label.text = @"Live Chat";
    
    if (textColor)
        label.textColor = textColor;
    else
        label.textColor = [UIColor whiteColor];
    
    label.hidden = currentMode == LIOControllButtonViewModePending;
    
    //innerShadow.transform = CGAffineTransformIdentity;
    
    if (UIInterfaceOrientationPortrait == [UIApplication sharedApplication].statusBarOrientation)
    {
        innerShadow.transform = CGAffineTransformIdentity;
    }
    else if (UIInterfaceOrientationLandscapeLeft == [UIApplication sharedApplication].statusBarOrientation)
    {
        CGAffineTransform rotate = CGAffineTransformMakeRotation((3.0*M_PI)/2.0);
        CGAffineTransform translate = CGAffineTransformMakeTranslation(37.0, 37.0);
        innerShadow.transform = CGAffineTransformConcat(translate, rotate);
    }
    else if (UIInterfaceOrientationPortraitUpsideDown == [UIApplication sharedApplication].statusBarOrientation)
    {
        innerShadow.transform = CGAffineTransformMakeScale(-1.0, -1.0);
    }
    else if (UIInterfaceOrientationLandscapeRight == [UIApplication sharedApplication].statusBarOrientation)
    {
        CGAffineTransform translate = CGAffineTransformMakeTranslation(-37.0, -37.0);
        CGAffineTransform rotate = CGAffineTransformMakeRotation(M_PI/2.0);
        innerShadow.transform = CGAffineTransformConcat(translate, rotate);
    }
    
    innerShadow.frame = self.bounds;
    
    CGRect aFrame = spinner.frame;
    aFrame.origin.x = (self.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = (self.frame.size.height / 2.0) - (aFrame.size.height / 2.0);
    spinner.frame = aFrame;
    spinner.hidden = currentMode != LIOControllButtonViewModePending;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (nil == tintColor)
        tintColor = [UIColor blackColor];
    
    UIRectCorner corners = UIRectCornerTopLeft | UIRectCornerBottomLeft;
    if (UIInterfaceOrientationLandscapeLeft == [UIApplication sharedApplication].statusBarOrientation)
        corners = UIRectCornerBottomLeft | UIRectCornerBottomRight;
    else if (UIInterfaceOrientationPortraitUpsideDown == [UIApplication sharedApplication].statusBarOrientation)
        corners = UIRectCornerTopRight | UIRectCornerBottomRight;
    else if (UIInterfaceOrientationLandscapeRight == [UIApplication sharedApplication].statusBarOrientation)
        corners = UIRectCornerTopLeft | UIRectCornerTopRight;
    
    CGContextClearRect(context, rect);
    
    CGRect smallerRect = CGRectMake(rect.origin.x + 0.5, rect.origin.y + 0.5, rect.size.width, rect.size.height - 1.0);
    
    CGContextSetFillColorWithColor(context, fillColor.CGColor);
    UIBezierPath *innerPath = [UIBezierPath bezierPathWithRoundedRect:smallerRect
                                                    byRoundingCorners:corners
                                                          cornerRadii:CGSizeMake(8.0, 8.0)];
    [innerPath fill];
    
    /*
    CGRect smallestRect = CGRectMake(rect.origin.x + 1.5, rect.origin.y + 1.0, rect.size.width, rect.size.height - 2.0);
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:1.0 alpha:0.42].CGColor);
    UIBezierPath *innerShadowPath = [UIBezierPath bezierPathWithRoundedRect:smallestRect
                                                          byRoundingCorners:corners
                                                                cornerRadii:CGSizeMake(8.0, 8.0)];
    innerShadowPath.lineWidth = 2.0;
    [innerShadowPath stroke];
    */
    
    CGContextSetStrokeColorWithColor(context, shadowColor.CGColor);
    UIBezierPath *outerPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width/* + 5.0*/, rect.size.height)
                                                    byRoundingCorners:corners
                                                          cornerRadii:CGSizeMake(10.0, 10.0)];
    outerPath.lineWidth = 2.0;
    [outerPath stroke];
}

- (void)startFadeTimer
{
    [fadeTimer stopTimer];
    [fadeTimer release];
    
    self.alpha = 1.0;
    
    fadeTimer = [[LIOTimerProxy alloc] initWithTimeInterval:5.0 target:self selector:@selector(fadeTimerDidFire)];
}

- (void)stopFadeTimer
{
    [fadeTimer stopTimer];
    [fadeTimer release];
    fadeTimer = nil;
}

#pragma mark -
#pragma mark Dynamic property accessors

- (void)setTintColor:(UIColor *)aColor
{
    [tintColor release];
    tintColor = [aColor retain];
    
    [fillColor release];
    fillColor = nil;
    
    [shadowColor release];
    shadowColor = nil;
    
    if (aColor)
    {
        const CGFloat *rgba = CGColorGetComponents(tintColor.CGColor);
        
        // Shadow color is used for text shadow and outer line.
        shadowColor = [[UIColor alloc] initWithRed:(rgba[0] * 0.5) green:(rgba[1] * 0.5) blue:(rgba[2] * 0.5) alpha:rgba[3]];
        label.layer.shadowColor = shadowColor.CGColor;
        
        // The "fill color" is the color we actually paint inside the control button.
        fillColor = [[UIColor alloc] initWithRed:rgba[0] green:rgba[1] blue:rgba[2] alpha:0.66];
    }
}

- (UIColor *)tintColor
{
    return tintColor;
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