//
//  LIToasterView.m
//  LookIO
//
//  Created by Joseph Toscano on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LIOToasterView.h"
#import <QuartzCore/QuartzCore.h>
#import "LIOAnimatedKeyboardIcon.h"
#import "LIOTimerProxy.h"
#import "LIOLookIOManager.h"
#import "LIOBrandingManager.h"

@implementation LIOToasterView

@synthesize keyboardIconVisible, delegate, yOrigin, shown;
@dynamic text;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.layer.cornerRadius = 5.0;
        self.layer.masksToBounds = YES;
        UIColor *backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementToasterView];
        CGFloat alpha = [[LIOBrandingManager brandingManager] backgroundAlphaForElement:LIOBrandingElementToasterView];
        self.backgroundColor = [backgroundColor colorWithAlphaComponent:alpha];
        
        CGRect aFrame = self.frame;
        aFrame.size.height = 50.0;
        self.frame = aFrame;
        
        keyboardIcon = [[LIOAnimatedKeyboardIcon alloc] initWithFrame:CGRectMake(0.0, 0.0, 13.0, 18.0) forElement:LIOBrandingElementToasterView];
        keyboardIcon.backgroundColor = [UIColor clearColor];
        [self addSubview:keyboardIcon];
        
        textLabel = [[UILabel alloc] init];
        textLabel.backgroundColor = [UIColor clearColor];
        textLabel.numberOfLines = 1;
        textLabel.font = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementToasterView];
        textLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementToasterView];
        [self addSubview:textLabel];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willChangeStatusBarOrientation:)
                                                     name:UIApplicationWillChangeStatusBarOrientationNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangeStatusBarOrientation:)
                                                     name:UIApplicationDidChangeStatusBarOrientationNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    delegate = nil;
    
    [textLabel release];
    [keyboardIcon release];
    
    [animatedEllipsisTimer stopTimer];
    [animatedEllipsisTimer release];
    
    [notificationTimer stopTimer];
    [notificationTimer release];
    
    [super dealloc];
}

- (void)layoutSubviews
{
    [animatedEllipsisTimer stopTimer];
    [animatedEllipsisTimer release];
    animatedEllipsisTimer = nil;
    
    if ([textLabel.text hasSuffix:@"..."])
        animatedEllipsisTimer = [[LIOTimerProxy alloc] initWithTimeInterval:0.5 target:self selector:@selector(animatedEllipsisTimerDidFire)];        
    
    keyboardIcon.hidden = NO == keyboardIconVisible;
    keyboardIcon.animating = keyboardIconVisible;
    
    CGRect aFrame = keyboardIcon.frame;
    aFrame.origin.x = 30.0;
    aFrame.origin.y = (self.bounds.size.height / 2.0) - (aFrame.size.height / 2.0) + 2.0;
    keyboardIcon.frame = aFrame;
    
    [textLabel sizeToFit];
    aFrame = textLabel.frame;
    aFrame.origin.y = (self.bounds.size.height / 2.0) - (aFrame.size.height / 2.0);
    if (keyboardIconVisible) aFrame.origin.x = keyboardIcon.frame.origin.x + keyboardIcon.bounds.size.width + 10.0;
    else aFrame.origin.x = 30.0;
    textLabel.frame = aFrame;
    
    aFrame = self.frame;
    aFrame.origin.y = yOrigin;
    if (keyboardIconVisible) aFrame.size.width = 30.0 + keyboardIcon.bounds.size.width + 10.0 + textLabel.bounds.size.width + 10.0;
    else aFrame.size.width = 30.0 + textLabel.bounds.size.width + 10.0;
    self.frame = aFrame;
}

- (void)showAnimated:(BOOL)animated permanently:(BOOL)permanent
{
    if (shown)
        return;
    
    shown = YES;
    
    CGRect startingFrame = self.frame;
    startingFrame.origin.x = -self.bounds.size.width;
    
    CGRect targetFrameOne = startingFrame;
    targetFrameOne.origin.x = -5.0;
    
    CGRect targetFrameTwo = startingFrame;
    targetFrameTwo.origin.x = -20.0;
    
    self.frame = startingFrame;
    
    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.frame = targetFrameOne;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.05
                                               delay:0.0
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              self.frame = targetFrameTwo;
                                          }
                                          completion:^(BOOL finished) {
                                              [delegate toasterViewDidFinishShowing:self];
                                          }];
                     }];
    
    if (NO == permanent)
    {
        [notificationTimer stopTimer];
        [notificationTimer release];
        notificationTimer = [[LIOTimerProxy alloc] initWithTimeInterval:LIOToasterViewDefaultNotificationDuration
                                                                 target:self
                                                               selector:@selector(notificationTimerDidFire)];
    }
}

- (void)hideAnimated:(BOOL)animated
{
    if (NO == shown)
        return;
    
    shown = NO;
    
    CGRect targetFrameOne = self.frame;
    targetFrameOne.origin.x = -5.0;
    
    CGRect targetFrameTwo = self.frame;
    targetFrameTwo.origin.x = -self.bounds.size.width;
    
    [UIView animateWithDuration:0.05
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.frame = targetFrameOne;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.15
                                               delay:0.0
                                             options:UIViewAnimationOptionCurveLinear
                                          animations:^{
                                              self.frame = targetFrameTwo;
                                          }
                                          completion:^(BOOL finished) {
                                              [delegate toasterViewDidFinishHiding:self];
                                          }];
                     }]; 
}

- (void)animatedEllipsisTimerDidFire
{
    if ([textLabel.text hasSuffix:@"..."])
        textLabel.text = [textLabel.text stringByReplacingCharactersInRange:NSMakeRange([textLabel.text length] - 3, 3) withString:@"."];
    else if ([textLabel.text hasSuffix:@".."])
        textLabel.text = [textLabel.text stringByReplacingCharactersInRange:NSMakeRange([textLabel.text length] - 2, 2) withString:@"..."];
    else if ([textLabel.text hasSuffix:@"."])
        textLabel.text = [textLabel.text stringByReplacingCharactersInRange:NSMakeRange([textLabel.text length] - 1, 1) withString:@".."];
    
    [textLabel setNeedsDisplay];
}

- (void)notificationTimerDidFire
{
    [notificationTimer stopTimer];
    [notificationTimer release];
    notificationTimer = nil;
    
    [self hideAnimated:YES];
}

#pragma mark -
#pragma mark Notification handlers

- (void)willChangeStatusBarOrientation:(NSNotification *)aNotification
{
    self.hidden = YES;
}

- (void)didChangeStatusBarOrientation:(NSNotification *)aNotification
{
    self.hidden = NO;
}

#pragma mark -
#pragma mark Dynamic accessor methods

- (NSString *)text
{
    return textLabel.text;
}

- (void)setText:(NSString *)aString
{
    textLabel.text = aString;
    [self layoutSubviews];
}

@end