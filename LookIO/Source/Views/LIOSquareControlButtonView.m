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

@synthesize textColor, labelText, delegate, label, currentMode, spinner, bubbleImageView, isDragging, position, isAttachedToRight;
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
        
        labelText = @"Tap button for live chat";
        
        label = [[UILabel alloc] initWithFrame:self.bounds];
        label.font = [UIFont boldSystemFontOfSize:15.0];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = textColor;
        label.text = labelText;
        label.textAlignment = UITextAlignmentCenter;
        label.userInteractionEnabled = NO;
        label.backgroundColor = fillColor;
        label.layer.cornerRadius = 4.0;
        label.layer.borderColor = borderColor.CGColor;
        label.layer.borderWidth = 1.0;
        label.frame = CGRectMake(0, 12, 0, 26.0);
        label.contentMode = UIViewContentModeCenter;
        label.opaque = NO;
        label.alpha = 0.7;
        [self addSubview:label];
        
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeZero;
        self.layer.shadowOpacity = 1.0;
        self.layer.shadowRadius = 4.0;
        
        self.opaque = NO;
        
        UITapGestureRecognizer *tapper = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)] autorelease];
        [self addGestureRecognizer:tapper];

        backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        backgroundView.backgroundColor = tintColor;
        backgroundView.layer.borderColor = borderColor.CGColor;
        backgroundView.layer.borderWidth = 1.0;
        backgroundView.layer.cornerRadius = 8.0;
        backgroundView.alpha = 0.7;
        backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:backgroundView];
        
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        spinner.frame = self.bounds;
        spinner.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [spinner startAnimating];
        [self addSubview:spinner];
        
        bubbleImageView = [[UIImageView alloc] initWithFrame:aFrame];
        bubbleImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        bubbleImageView.image = [self imageWithTintedColor:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOControlButtonChatIcon"] withTint:textColor];
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

- (void)updateButtonColor {
    bubbleImageView.image = [self imageWithTintedColor:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOControlButtonChatIcon"] withTint:textColor];
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
    if (textColor) {
        label.textColor = textColor;
    }
    else {
        label.textColor = [UIColor whiteColor];
    }
    
    spinner.hidden = currentMode != LIOSquareControlButtonViewModePending;
    spinner.frame = self.bounds;
    bubbleImageView.hidden = currentMode == LIOSquareControlButtonViewModePending;
    
    innerShadow.frame = self.bounds;
    bubbleImageView.frame = CGRectMake(12.5, 10, self.bounds.size.width - 25.0, self.bounds.size.width - 25.0);
    
    

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
        fillColor = [[UIColor alloc] initWithRed:rgba[0] green:rgba[1] blue:rgba[2] alpha:0.7];
        
        CGFloat lightness = (rgba[0] + rgba[1] + rgba[2])/3;
        
        
        CGFloat borderRed = lightness < 0.5 ? (1.0 + rgba[0])/2 : (0.0 + rgba[0])/2;
        CGFloat borderGreen = lightness < 0.5 ? (1.0 + rgba[1])/2 : (0.0 + rgba[1])/2;
        CGFloat borderBlue = lightness < 0.5 ? (1.0 + rgba[2])/2 : (0.0 + rgba[2])/2;
        
        borderColor = [[UIColor alloc] initWithRed:borderRed green:borderGreen blue:borderBlue alpha:1.0];
        
        backgroundView.backgroundColor = fillColor;
        backgroundView.layer.borderColor = borderColor.CGColor;
        
        label.backgroundColor = fillColor;
        label.layer.borderColor = borderColor.CGColor;
    }
}

- (UIImage *)imageWithTintedColor:(UIImage *)image withTint:(UIColor *)color {
    UIGraphicsBeginImageContext(image.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [color setFill];
    
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    CGContextDrawImage(context, rect, image.CGImage);
    
    CGContextClipToMask(context, rect, image.CGImage);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context,kCGPathFill);
    
    UIImage *coloredImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return coloredImage;
}

- (UIColor *)tintColor
{
    return tintColor;
}

- (void)presentLabel {
    if (labelVisible)
        return;
    
    labelVisible = YES;
    
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGSize expectedLabelSize = [label.text sizeWithFont:[UIFont boldSystemFontOfSize:15.0] constrainedToSize:CGSizeMake(300, 17.0) lineBreakMode:UILineBreakModeTailTruncation];
        CGRect frame = label.frame;
        if (self.isAttachedToRight)
            frame.origin.x = -expectedLabelSize.width - 14.0;
        else
            frame.origin.x = self.frame.size.width;
        frame.origin.y = (self.frame.size.height/2 - 26.0/2);
        frame.size.width = expectedLabelSize.width + 15.0;
        frame.size.height = 26.0;
        label.frame = frame;
        label.alpha = 0.7;
    } completion:nil];
    
    timerProxy = [[LIOTimerProxy alloc] initWithTimeInterval:10.0 target:self selector:@selector(dismissLabelTimerDidExpire)];
}

- (void)dismissLabelTimerDidExpire {
    [timerProxy stopTimer];
    [self dismissLabelWithAnimation:LIOSquareControlButtonViewAnimationSlideIn];
}

- (void)dismissLabelWithAnimation:(LIOSquareControlButtonViewAnimationType)animationType {
    if (!labelVisible)
        return;
    
    labelVisible = NO;
    
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        if (LIOSquareControlButtonViewAnimationSlideIn == animationType) {
            CGRect frame = label.frame;
            frame.origin.x = 0;
            label.frame = frame;
        }
        if (LIOSquareControlButtonViewAnimationFadeOut == animationType) {
            label.alpha = 0.7;
        }
    } completion:^(BOOL finished) {
        CGRect frame = label.frame;
        frame.origin.x = 0;
        frame.size.width = 1;
        label.frame = frame;

        label.alpha = 0.7;
    }];
}

- (void)toggleLabel {
    if (labelVisible)
        [self dismissLabelWithAnimation:LIOSquareControlButtonViewAnimationSlideIn];
    else
        [self presentLabel];
}

#pragma mark -
#pragma mark Gesture handlers

- (void)handleTap:(UITapGestureRecognizer *)tapper
{
    [self dismissLabelWithAnimation:LIOSquareControlButtonViewAnimationFadeOut];
    [delegate controlButtonViewWasTapped:self];
}

@end