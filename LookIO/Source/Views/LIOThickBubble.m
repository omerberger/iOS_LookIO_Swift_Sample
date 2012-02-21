//
//  LIOThickBubble.m
//  LookIO
//
//  Created by Joseph Toscano on 1/20/12.
//  Copyright (c) 2012 LookIO, Inc. All rights reserved.
//

#import "LIOThickBubble.h"
#import "LIOLookIOManager.h"

@implementation LIOThickBubble

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        UIImage *backgroundImage = lookioImage(@"LIOStretchableThickBubble");
        UIImage *stretchableBackgroundImage = [backgroundImage stretchableImageWithLeftCapWidth:18 topCapHeight:79];
        background = [[UIImageView alloc] initWithImage:stretchableBackgroundImage];
    }
    
    return self;
}

- (void)dealloc
{
    [background release];
    
    [super dealloc];
}

@end
