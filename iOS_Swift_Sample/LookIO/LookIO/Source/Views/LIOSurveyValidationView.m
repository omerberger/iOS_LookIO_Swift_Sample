//
//  LIOSurveyValidationView.m
//  LookIO
//
//  Created by Joseph Toscano on 6/20/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import "LIOSurveyValidationView.h"

#import <QuartzCore/QuartzCore.h>

#import "LIOBundleManager.h"
#import "LIOBrandingManager.h"

@interface LIOSurveyValidationView ()

@property (nonatomic, strong) UIImageView *cautionSign;

@end

@implementation LIOSurveyValidationView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.clipsToBounds = NO;
        self.backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementSurveyValidationAlert];
        
        self.label = [[UILabel alloc] init];
        self.label.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementSurveyValidationAlert];
        self.label.font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementSurveyValidationAlert];
        self.label.numberOfLines = 1;
        self.label.lineBreakMode = UILineBreakModeTailTruncation;
        self.label.backgroundColor = [UIColor clearColor];
        [self addSubview:self.label];
        
        self.cautionSign = [[UIImageView alloc] initWithImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOTinyTransparentCautionIcon"]];
        [self addSubview:self.cautionSign];
    }
    
    return self;
}

- (void)layoutSubviews
{
    CGRect aFrame = self.frame;
    aFrame.size.height = 26.0;
    self.frame = aFrame;
    
    CGFloat maxLabelWidth = self.bounds.size.width - 40.0;
    CGSize labelSize = [self.label.text sizeWithFont:self.label.font forWidth:maxLabelWidth lineBreakMode:UILineBreakModeTailTruncation];
    
    [self.label sizeToFit];
    aFrame = self.label.frame;
    aFrame.size.width = labelSize.width;
    aFrame.origin.x = (self.bounds.size.width / 2.0) - (aFrame.size.width / 2.0) + 7.0;

    aFrame.origin.y = (self.bounds.size.height - aFrame.size.height)/3.0;
    self.label.frame = aFrame;
    
    aFrame = self.cautionSign.frame;
    aFrame.size.width = 15.0;
    aFrame.size.height = 13.0;
    aFrame.origin.x = self.label.frame.origin.x - 20.0;
    aFrame.origin.y = (self.bounds.size.height - aFrame.size.height)/3.0;
    self.cautionSign.frame = aFrame;
}

- (void)showAnimated
{
    [self layoutSubviews];
    
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
    [self layoutSubviews];
    [UIView animateWithDuration:0.33
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         [self.delegate surveyValidationViewDidFinishDismissalAnimation:self];
                     }];
}

@end