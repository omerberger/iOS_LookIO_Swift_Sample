//
//  LIOHeaderBarView.m
//  LookIO
//
//  Created by Joseph Toscano on 1/20/12.
//  Copyright (c) 2012 LookIO, Inc. All rights reserved.
//

#import "LIOHeaderBarView.h"
#import "LIOLookIOManager.h"
#import <QuartzCore/QuartzCore.h>

@implementation LIOHeaderBarView

@synthesize mode, delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {        
        separator = [[UIView alloc] init];
        separator.backgroundColor = [UIColor colorWithPatternImage:lookioImage(@"LIORepeatableBlendedSeparatorTop")];
        separator.opaque = NO;
        CGRect aFrame = separator.frame;
        aFrame.size.height = 15.0;
        aFrame.size.width = self.frame.size.width;
        aFrame.origin.y = self.frame.size.height;
        separator.frame = aFrame;
        separator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:separator];
                
        adLabel = [[UILabel alloc] init];
        adLabel.backgroundColor = [UIColor clearColor];
        adLabel.font = [UIFont boldSystemFontOfSize:12.0];
        adLabel.textColor = [UIColor whiteColor];
        adLabel.text = @"Live Chat powered by";
        [adLabel sizeToFit];
        [self addSubview:adLabel];
        
        tinyLogo = [[UIImageView alloc] initWithImage:lookioImage(@"LIOHeaderBarTinyLogo")];
        [self addSubview:tinyLogo];
        
        UITapGestureRecognizer *tapper = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)] autorelease];
        [self addGestureRecognizer:tapper];
        
        tappableBackground = [[UIView alloc] initWithFrame:self.bounds];
        tappableBackground.backgroundColor = [UIColor clearColor];
        [tappableBackground addGestureRecognizer:tapper];
        [self addSubview:tappableBackground];
        
        UIImage *buttonImage = [lookioImage(@"LIOHeaderBarViewStretchableButton") stretchableImageWithLeftCapWidth:10 topCapHeight:0];        
        
        moreButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        [moreButton addTarget:self action:@selector(moreButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
        moreButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
        [moreButton setTitle:@"Learn More  >" forState:UIControlStateNormal];
        [moreButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
        CGRect buttonFrame = moreButton.frame;
        buttonFrame.size.width = 100.0;
        buttonFrame.size.height = 29.0;
        buttonFrame.origin.x = self.bounds.size.width - 100.0 - 8.0;
        buttonFrame.origin.y = (57.0 / 2.0) - (buttonFrame.size.height / 2.0);
        moreButton.frame = buttonFrame;
        [self addSubview:moreButton];
        
        plusButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        [plusButton addTarget:self action:@selector(plusButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
        [plusButton setBackgroundImage:lookioImage(@"LIOHeaderPlusIcon") forState:UIControlStateNormal];
        [plusButton sizeToFit];
        aFrame = plusButton.frame;
        aFrame.size.height = 15.0;
        aFrame.origin.y = 8.0;
        plusButton.frame = aFrame;
        [self addSubview:plusButton];
    }
    
    return self;
}

- (void)dealloc
{
    [tinyLogo release];
    [adLabel release];
    [separator release];
    [plusButton release];
    [tappableBackground release];
    
    [super dealloc];
}

- (void)switchToMode:(LIOHeaderBarViewMode)aMode animated:(BOOL)animated
{
    if (aMode == mode)
        return;
    
    mode = aMode;
    
    if (LIOHeaderBarViewModeMinimal == mode)
    {
        [adLabel sizeToFit];
        CGRect labelFrame = adLabel.frame;
        labelFrame.origin.x = (self.frame.size.width / 2.0) - ((labelFrame.size.width + tinyLogo.frame.size.width + 3.0) / 2.0);
        labelFrame.origin.y = 16.0 - (labelFrame.size.height / 2.0);
        
        CGRect logoFrame = tinyLogo.frame;
        logoFrame.origin.x = labelFrame.origin.x + labelFrame.size.width + 3.0;
        logoFrame.origin.y = 16.0 - (logoFrame.size.height / 2.0);
        
        CGRect plusFrame = plusButton.frame;
        plusFrame.origin.x = logoFrame.origin.x + logoFrame.size.width + 5.0;
        plusButton.frame = plusFrame;
        
        // Bar portion minus shadow is 32.0px
        CGRect aFrame = self.frame;
        aFrame.size.height = 40.0;
        
        CGRect sepFrame = separator.frame;
        sepFrame.origin.y = aFrame.size.height - 14.0;
        
        if (NO == animated)
        {
            self.frame = aFrame;
            
            separator.frame = sepFrame;
            adLabel.frame = labelFrame;
            tinyLogo.frame = logoFrame;
            
            [self bringSubviewToFront:adLabel];
            [self bringSubviewToFront:tinyLogo];
            [self bringSubviewToFront:moreButton];
            
            moreButton.alpha = 0.0;
            plusButton.alpha = 1.0;
        }
        else
        {
            [self bringSubviewToFront:adLabel];
            [self bringSubviewToFront:tinyLogo];
            [self bringSubviewToFront:moreButton];
            
            [UIView animateWithDuration:0.5
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 moreButton.alpha = 0.0;
                                 plusButton.alpha = 1.0;
                                 adLabel.frame = labelFrame;
                                 tinyLogo.frame = logoFrame;
                                 separator.frame = sepFrame;
                                 self.frame = aFrame;
                             }
                             completion:^(BOOL finished) {
                                 moreButton.hidden = YES;
                             }];
        }
    }
    else if (LIOHeaderBarViewModeFull == mode)
    {
        [adLabel sizeToFit];
        CGRect labelFrame = adLabel.frame;
        labelFrame.origin.x = 17.0;
        labelFrame.origin.y = (49.0 / 2.0) - (labelFrame.size.height / 2.0);
        
        CGRect logoFrame = tinyLogo.frame;
        logoFrame.origin.x = labelFrame.origin.x + labelFrame.size.width + 5.0;
        logoFrame.origin.y = (49.0 / 2.0) - (logoFrame.size.height / 2.0);
        
        CGRect buttonFrame = moreButton.frame;
        buttonFrame.size.width = 100.0;
        buttonFrame.size.height = 29.0;
        buttonFrame.origin.x = self.bounds.size.width - 100.0 - 8.0;
        buttonFrame.origin.y = (49.0 / 2.0) - (buttonFrame.size.height / 2.0);
        
        // Bar portion: 49.0px
        CGRect aFrame = self.frame;
        aFrame.size.height = 57.0;
        
        CGRect sepFrame = separator.frame;
        sepFrame.origin.y = aFrame.size.height - 14.0;
        
        if (NO == animated)
        {
            self.frame = aFrame;
            
            adLabel.frame = labelFrame;
            tinyLogo.frame = logoFrame;
            moreButton.frame = buttonFrame;
            separator.frame = sepFrame;
            
            [self bringSubviewToFront:adLabel];
            [self bringSubviewToFront:tinyLogo];
            [self bringSubviewToFront:moreButton];
            
            moreButton.hidden = NO;
            moreButton.alpha = 1.0;
            
            plusButton.alpha = 0.0;
        }
        else
        {
            [self bringSubviewToFront:adLabel];
            [self bringSubviewToFront:tinyLogo];
            [self bringSubviewToFront:moreButton];
            
            moreButton.alpha = 0.0;
            moreButton.hidden = NO;
            
            [UIView animateWithDuration:0.5
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 moreButton.alpha = 1.0;
                                 plusButton.alpha = 0.0;
                                 
                                 self.frame = aFrame;
                                 
                                 adLabel.frame = labelFrame;
                                 tinyLogo.frame = logoFrame;
                                 moreButton.frame = buttonFrame;
                                 separator.frame = sepFrame;
                             }
                             completion:^(BOOL finished) {
                                 moreButton.alpha = 1.0;
                                 moreButton.hidden = NO;
                             }];
        }
        
        tappableBackground.frame = self.bounds;
        [self sendSubviewToBack:tappableBackground];
    }
}

- (void)rejiggerLayout
{
    LIOHeaderBarViewMode savedMode = mode;
    [self switchToMode:LIOHeaderBarViewModeNone animated:NO];
    [self switchToMode:savedMode animated:NO];
}

#pragma mark -
#pragma mark UIControl actions

- (void)moreButtonWasTapped
{
    [delegate headerBarViewAboutButtonWasTapped:self];
}

- (void)plusButtonWasTapped
{
    [delegate headerBarViewPlusButtonWasTapped:self];
}

#pragma mark -
#pragma mark Gesture handlers

- (void)handleTap:(UITapGestureRecognizer *)aTapper
{
    [delegate headerBarViewPlusButtonWasTapped:self];
}

@end