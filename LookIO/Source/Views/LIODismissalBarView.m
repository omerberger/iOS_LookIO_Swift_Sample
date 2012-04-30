//
//  LIODismissalBarView.m
//  LookIO
//
//  Created by Joseph Toscano on 3/6/12.
//  Copyright (c) 2012 LookIO, Inc. All rights reserved.
//

#import "LIODismissalBarView.h"
#import "LIOLookIOManager.h"
#import "LIOBundleManager.h"
#import "LIOTimerProxy.h"
#import "LIOAnimatedKeyboardIcon.h"

@implementation LIODismissalBarView

@synthesize delegate;
@dynamic keyboardIconActive;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        separator = [[UIView alloc] init];
        separator.backgroundColor = [UIColor colorWithPatternImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIORepeatableBlendedSeparatorBottom"]];
        separator.opaque = NO;
        CGRect aFrame = separator.frame;
        aFrame.size.height = 15.0;
        aFrame.size.width = self.frame.size.width;
        separator.frame = aFrame;
        separator.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [self addSubview:separator];
        
        dismissLabel = [[UILabel alloc] init];
        dismissLabel.backgroundColor = [UIColor clearColor];
        dismissLabel.font = [UIFont boldSystemFontOfSize:14.0];
        dismissLabel.alpha = 0.75;
        dismissLabel.textColor = [UIColor whiteColor];
        dismissLabel.text = @"Hide Chat";
        [dismissLabel sizeToFit];
        dismissLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:dismissLabel];
        
        UITapGestureRecognizer *tapper = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)] autorelease];
        [self addGestureRecognizer:tapper];
        
        keyboardIcon = [[LIOAnimatedKeyboardIcon alloc] init];
        [self addSubview:keyboardIcon];
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
    aFrame.origin.y = -9.0;
    aFrame.size.height = 15.0;
    aFrame.size.width = self.frame.size.width;
    separator.frame = aFrame;
    
    aFrame = dismissLabel.frame;
    aFrame.origin.x = (self.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = (self.frame.size.height / 2.0) - (aFrame.size.height / 2.0);
    dismissLabel.frame = aFrame;
    
    aFrame = keyboardIcon.frame;
    aFrame.size.width = 18.0;
    aFrame.size.height = 13.0;
    aFrame.origin.x = 8.0;
    aFrame.origin.y = (self.bounds.size.height / 2.0) - (aFrame.size.height / 2.0) + 1.0;
    keyboardIcon.frame = aFrame;
    
    if (keyboardIconActive)
        keyboardIcon.alpha = 1.0;
    else
        keyboardIcon.alpha = 0.2;
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

#pragma mark -
#pragma mark Dynamic accessors

- (BOOL)isKeyboardIconActive
{
    return keyboardIconActive;
}

- (void)setKeyboardIconActive:(BOOL)aBool
{
    keyboardIconActive = aBool;
    keyboardIcon.animating = keyboardIconActive;
    
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

@end