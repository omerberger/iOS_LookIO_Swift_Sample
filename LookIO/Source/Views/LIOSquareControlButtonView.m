//
//  LIOControlButtonView.m
//  LookIO
//
//  Created by Joseph Toscano on 11/1/11.
//  Copyright (c) 2011 LivePerson, Inc. All rights reserved.
//

#import "LIOSquareControlButtonView.h"
#import <QuartzCore/QuartzCore.h>
#import "LIOLookIOManager.h"
#import "LIOBundleManager.h"

@implementation LIOSquareControlButtonView

@synthesize textColor, labelText, delegate, label, currentMode, spinner;
@dynamic tintColor;

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        // Defaults.
        self.tintColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
        self.textColor = [UIColor whiteColor];
        self.labelText = LIOLocalizedString(@"LIOControlButtonView.DefaultText");
        
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
        
        bubbleImageView = [[UIImageView alloc] initWithFrame:aFrame];
        bubbleImageView.image = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOControlButtonChatIcon"];
        [self addSubview:bubbleImageView];
        
    }
    
    return self;
}

- (void)updateButtonForChatTheme {
    if ([LIOLookIOManager sharedLookIOManager].selectedChatTheme == kLPChatThemeClassic) {
        innerShadow.hidden = NO;
        
        label.layer.shadowColor = [UIColor blackColor].CGColor;
        label.layer.shadowOpacity = 1.0;
        label.layer.shadowOffset = CGSizeMake(1.5, 1.5);
        label.layer.shadowRadius = 1.5;
        
        self.layer.shadowRadius = 4.0;
    } else {
        innerShadow.hidden = YES;
        
        label.layer.shadowColor = [UIColor blackColor].CGColor;
        label.layer.shadowOpacity = 0.0;
        label.layer.shadowOffset = CGSizeMake(0.0, 0.0);
        label.layer.shadowRadius = 0.0;
        
        self.layer.shadowRadius = 1.0;
    }
    
    [self setNeedsDisplay];
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
    [borderColor release];
    
    [super dealloc];
}

- (void)layoutSubviews
{
    if (LIOSquareControlButtonViewModePending == currentMode)
    {
        label.font = [UIFont systemFontOfSize:14.0];
        label.text = [NSString stringWithFormat:@"     %@", LIOLocalizedString(@"LIOControlButtonView.ReconnectingText")];
    }
    else if (labelText)
    {
        label.font = [UIFont systemFontOfSize:17.0];
        label.text = labelText;
    }
    else
    {
        label.font = [UIFont systemFontOfSize:17.0];
        label.text = LIOLocalizedString(@"LIOControlButtonView.DefaultText");
    }
    
    if (textColor)
        label.textColor = textColor;
    else
        label.textColor = [UIColor whiteColor];
    
    spinner.hidden = currentMode != LIOSquareControlButtonViewModePending;
    CGRect spinnerFrame = CGRectZero;
    spinnerFrame.size.height = 16.0;
    spinnerFrame.size.width = 16.0;
    
    UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationPortrait == actualOrientation)
    {
        innerShadow.transform = CGAffineTransformIdentity;
        
        spinnerFrame.origin.x = (self.bounds.size.width / 2.0) - (spinnerFrame.size.width / 2.0);
        spinnerFrame.origin.y = self.bounds.size.height - spinnerFrame.size.height - 8.0;
    }
    else if (UIInterfaceOrientationLandscapeLeft == actualOrientation)
    {
        CGAffineTransform rotate = CGAffineTransformMakeRotation((3.0*M_PI)/2.0);
        CGAffineTransform translate = CGAffineTransformMakeTranslation(37.0, 37.0);
        innerShadow.transform = CGAffineTransformConcat(translate, rotate);
        
        spinnerFrame.origin.x = self.bounds.size.width - spinnerFrame.size.height - 8.0;
        spinnerFrame.origin.y = (self.bounds.size.height / 2.0) - (spinnerFrame.size.width / 2.0);
    }
    else if (UIInterfaceOrientationPortraitUpsideDown == actualOrientation)
    {
        innerShadow.transform = CGAffineTransformMakeScale(-1.0, -1.0);
        
        spinnerFrame.origin.x = (self.bounds.size.width / 2.0) - (spinnerFrame.size.width / 2.0);
        spinnerFrame.origin.y = 8.0;
    }
    else if (UIInterfaceOrientationLandscapeRight == actualOrientation)
    {
        CGAffineTransform translate = CGAffineTransformMakeTranslation(-37.0, -37.0);
        CGAffineTransform rotate = CGAffineTransformMakeRotation(M_PI/2.0);
        innerShadow.transform = CGAffineTransformConcat(translate, rotate);
        
        spinnerFrame.origin.x = 8.0;
        spinnerFrame.origin.y = (self.bounds.size.height / 2.0) - (spinnerFrame.size.width / 2.0);
    }
    
    innerShadow.frame = self.bounds;
    
    spinner.frame = spinnerFrame;
    
    if (LIOSquareControlButtonViewModeDefault == currentMode)
        label.alpha = 1.0;
    else
        label.alpha = 0.33;
    
    bubbleImageView.frame = CGRectMake(12.5, 10, self.bounds.size.width - 25.0, self.bounds.size.width - 25.0);

}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (nil == tintColor)
        tintColor = [UIColor blackColor];
    
    UIRectCorner corners = UIRectCornerAllCorners;
    
    CGContextClearRect(context, rect);
    
    CGRect smallerRect = CGRectMake(rect.origin.x + 0.5, rect.origin.y + 0.5, rect.size.width - 1.0, rect.size.height - 1.0);
    
    CGContextSetFillColorWithColor(context, fillColor.CGColor);
    UIBezierPath *innerPath = [UIBezierPath bezierPathWithRoundedRect:smallerRect
                                                    byRoundingCorners:corners
                                                          cornerRadii:CGSizeMake(8.0, 8.0)];
    [innerPath fill];
        
    if ([LIOLookIOManager sharedLookIOManager].selectedChatTheme == kLPChatThemeClassic) {
        CGContextSetStrokeColorWithColor(context, shadowColor.CGColor);
        
        UIBezierPath *outerPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)
                                                        byRoundingCorners:corners
                                                              cornerRadii:CGSizeMake(13.0, 13.0)];
        outerPath.lineWidth = 2.0;
        [outerPath stroke];
    } else {
        CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
        
        CGRect smallerRect2 = CGRectMake(rect.origin.x + 0.5, rect.origin.y + 0.5, rect.size.width - 1.0, rect.size.height - 1.0);
        
        UIBezierPath *innerPath = [UIBezierPath bezierPathWithRoundedRect:smallerRect2
                                                        byRoundingCorners:corners
                                                              cornerRadii:CGSizeMake(8.0, 8.0)];
        innerPath.lineWidth = 1.0;
        [innerPath stroke];
    }
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
    
    [borderColor release];
    borderColor = nil;
    
    if (aColor)
    {
        const CGFloat *rgba = CGColorGetComponents(tintColor.CGColor);
        
        // Shadow color is used for text shadow and outer line.
        shadowColor = [[UIColor alloc] initWithRed:(rgba[0] * 0.5) green:(rgba[1] * 0.5) blue:(rgba[2] * 0.5) alpha:rgba[3]];
        label.layer.shadowColor = shadowColor.CGColor;
        
        // The "fill color" is the color we actually paint inside the control button.
        fillColor = [[UIColor alloc] initWithRed:rgba[0] green:rgba[1] blue:rgba[2] alpha:0.66];
        
        CGFloat lightness = (rgba[0] + rgba[1] + rgba[2])/3;
        
        
        CGFloat borderRed = lightness < 0.5 ? (1.0 + rgba[0])/2 : (0.0 + rgba[0])/2;
        CGFloat borderGreen = lightness < 0.5 ? (1.0 + rgba[1])/2 : (0.0 + rgba[1])/2;
        CGFloat borderBlue = lightness < 0.5 ? (1.0 + rgba[2])/2 : (0.0 + rgba[2])/2;
        
        borderColor = [[UIColor alloc] initWithRed:borderRed green:borderGreen blue:borderBlue alpha:1.0];
    }
}

- (UIColor *)tintColor
{
    return tintColor;
}

#pragma mark -
#pragma mark Gesture handlers

- (void)handleTap:(UITapGestureRecognizer *)tapper
{
    [delegate controlButtonViewWasTapped:self];
}

@end