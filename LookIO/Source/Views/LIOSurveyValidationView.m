//
//  LIOSurveyValidationView.m
//  LookIO
//
//  Created by Joseph Toscano on 6/20/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import "LIOSurveyValidationView.h"
#import "LIOBundleManager.h"
#import <QuartzCore/QuartzCore.h>

@implementation LIOSurveyValidationView

@synthesize label, delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = NO;
        
        // The bar portion of this image is 22.5 points high.
        UIImage *repeatableBackground = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIORepeatableEtchedRedGlassMiniToolbar"];
        repeatableBackground = [repeatableBackground stretchableImageWithLeftCapWidth:0 topCapHeight:0];
        backgroundImage = [[UIImageView alloc] initWithImage:repeatableBackground];
        [self addSubview:backgroundImage];
        
        label = [[UILabel alloc] init];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12.0];
        label.numberOfLines = 1;
        label.lineBreakMode = UILineBreakModeTailTruncation;
        label.backgroundColor = [UIColor clearColor];
        label.alpha = 0.66;
        [self addSubview:label];
        
        cautionSign = [[UIImageView alloc] initWithImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOTinyTransparentCautionIcon"]];
        [self addSubview:cautionSign];
    }
    
    return self;
}

- (void)dealloc
{
    [self.layer removeAllAnimations];
    
    [label release];
    [cautionSign release];
    [backgroundImage release];
    
    [super dealloc];
}

- (void)layoutSubviews
{
    CGRect aFrame = self.frame;
    aFrame.size.height = 22.5;
    self.frame = aFrame;
    
    CGFloat maxLabelWidth = self.bounds.size.width - 40.0;
    CGSize labelSize = [label.text sizeWithFont:label.font forWidth:maxLabelWidth lineBreakMode:UILineBreakModeTailTruncation];
    
    [label sizeToFit];
    aFrame = label.frame;
    aFrame.size.width = labelSize.width;
    aFrame.origin.x = (self.bounds.size.width / 2.0) - (aFrame.size.width / 2.0) + 7.0;
    aFrame.origin.y = (self.bounds.size.height / 2.0) - (aFrame.size.height / 2.0);
    label.frame = aFrame;
    
    aFrame = cautionSign.frame;
    aFrame.size.width = 15.0;
    aFrame.size.height = 13.0;
    aFrame.origin.x = label.frame.origin.x - 20.0;
    aFrame.origin.y = (self.bounds.size.height / 2.0) - (aFrame.size.height / 2.0);
    cautionSign.frame = aFrame;
    
    aFrame = backgroundImage.frame;
    aFrame.origin.x = 0.0;
    aFrame.origin.y = -4.5; // Shadow spills over top.
    aFrame.size.width = self.bounds.size.width;
    backgroundImage.frame = aFrame;
}

- (void)showAnimated
{
    self.alpha = 0.0;
    
    [UIView animateWithDuration:0.33
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                     }];
}

- (void)hideAnimated
{
    [UIView animateWithDuration:0.33
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         [delegate surveyValidationViewDidFinishDismissalAnimation:self];
                     }];
}

@end