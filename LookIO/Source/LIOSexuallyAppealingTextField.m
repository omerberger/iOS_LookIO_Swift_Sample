//
//  LIOSexuallyAppealingTextField.m
//  LookIO
//
//  Created by Joe Toscano on 9/6/11.
//  Copyright 2011 LookIO, Inc. All rights reserved.
//

#import "LIOSexuallyAppealingTextField.h"

@implementation LIOSexuallyAppealingTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.borderStyle = UITextBorderStyleNone;
        self.background = [[UIImage imageNamed:@"LIOInputBar"] stretchableImageWithLeftCapWidth:13 topCapHeight:13];
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    CGRect newBounds = bounds;
    newBounds.origin.x = 10.0;
    newBounds.origin.y = 3.0;
    newBounds.size.width = bounds.size.width - 15.0;
    return newBounds;
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
    CGRect newBounds = bounds;
    newBounds.origin.x = 10.0;
    newBounds.origin.y = 3.0;
    newBounds.size.width = bounds.size.width - 15.0;
    return newBounds;
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds
{
    CGRect newBounds = bounds;
    newBounds.origin.x = 10.0;
    newBounds.origin.y = 3.0;
    newBounds.size.width = bounds.size.width - 15.0;
    return newBounds;
}

@end