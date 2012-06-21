//
//  LIOSurveyValidationView.m
//  LookIO
//
//  Created by Joseph Toscano on 6/20/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import "LIOSurveyValidationView.h"

@implementation LIOSurveyValidationView

@synthesize label;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.backgroundColor = [UIColor redColor];
        
        label = [[UILabel alloc] init];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0];
        label.numberOfLines = 1;
        label.lineBreakMode = UILineBreakModeTailTruncation;
        label.backgroundColor = [UIColor clearColor];
        [self addSubview:label];
        
        cautionSign = [[UIImageView alloc] init];
        cautionSign.backgroundColor = [UIColor whiteColor];
        [self addSubview:cautionSign];
    }
    
    return self;
}

- (void)dealloc
{
    [label release];
    [cautionSign release];
    
    [super dealloc];
}

- (void)layoutSubviews
{
    [label sizeToFit];
    CGRect aFrame = label.frame;
    aFrame.origin.x = 50.0;
    aFrame.size.width = self.bounds.size.width - 50.0;
    aFrame.origin.y = (self.bounds.size.height / 2.0) - (aFrame.size.height / 2.0);
    label.frame = aFrame;
    
    aFrame = cautionSign.frame;
    aFrame.size.width = 25.0;
    aFrame.size.height = 25.0;
    aFrame.origin.x = 10.0;
    aFrame.origin.y = (self.bounds.size.height / 2.0) - (aFrame.size.height / 2.0);
    cautionSign.frame = aFrame;
}

@end