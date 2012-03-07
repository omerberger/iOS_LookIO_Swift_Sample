//
//  LIODismissalBarView.m
//  LookIO
//
//  Created by Joseph Toscano on 3/6/12.
//  Copyright (c) 2012 LookIO, Inc. All rights reserved.
//

#import "LIODismissalBarView.h"
#import "LIOLookIOManager.h"

@implementation LIODismissalBarView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        
        separator = [[UIView alloc] init];
        separator.backgroundColor = [UIColor colorWithPatternImage:lookioImage(@"LIORepeatableBlendedSeparatorBottom")];
        separator.opaque = NO;
        CGRect aFrame = separator.frame;
        aFrame.size.height = 15.0;
        aFrame.size.width = self.frame.size.width;
        separator.frame = aFrame;
        separator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:separator];
        
        dismissLabel = [[UILabel alloc] init];
        dismissLabel.backgroundColor = [UIColor clearColor];
        dismissLabel.font = [UIFont boldSystemFontOfSize:14.0];
        dismissLabel.alpha = 0.75;
        dismissLabel.textColor = [UIColor whiteColor];
        dismissLabel.text = @"Dismiss Chat";
        [dismissLabel sizeToFit];
        [self addSubview:dismissLabel];
        
        UITapGestureRecognizer *tapper = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)] autorelease];
        [self addGestureRecognizer:tapper];
    }
    
    return self;
}

- (void)dealloc
{
    [separator release];
    [dismissLabel release];
    
    [super dealloc];
}

- (void)layoutSubviews
{
    CGRect aFrame = separator.frame;
    aFrame.origin.y -= 9.0;
    aFrame.size.height = 15.0;
    aFrame.size.width = self.frame.size.width;
    separator.frame = aFrame;
    
    aFrame = dismissLabel.frame;
    aFrame.origin.x = (self.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = (self.frame.size.height / 2.0) - (aFrame.size.height / 2.0);
    dismissLabel.frame = aFrame;
}

#pragma mark -
#pragma mark UIControl actions

- (void)dismissButtonWasTapped
{
    [delegate dismissalBarViewButtonWasTapped:self];
}

#pragma mark -
#pragma mark Gesture handlers

- (void)handleTap:(UITapGestureRecognizer *)aTap
{
    [delegate dismissalBarViewButtonWasTapped:self];
}

@end