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
#import "LIOBundleManager.h"
#import "LIOTimerProxy.h"

@implementation LIOHeaderBarView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.clipsToBounds = YES;
        
        separator = [[UIView alloc] init];
        separator.backgroundColor = [UIColor colorWithPatternImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIORepeatableBlendedSeparatorTop"]];
        separator.opaque = NO;
        CGRect aFrame = separator.frame;
        aFrame.size.height = 15.0;
        aFrame.size.width = self.bounds.size.width;
        aFrame.origin.y = self.bounds.size.height - 14.0;
        separator.frame = aFrame;
        separator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:separator];
                
        defaultNotification = [[UIView alloc] initWithFrame:self.bounds];
        aFrame = defaultNotification.frame;
        aFrame.size.height = 32.0;
        defaultNotification.frame = aFrame;
        defaultNotification.backgroundColor = [UIColor clearColor];
        defaultNotification.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:defaultNotification];

        UILabel *adLabel = [[[UILabel alloc] init] autorelease];
        adLabel.backgroundColor = [UIColor clearColor];
        adLabel.font = [UIFont boldSystemFontOfSize:12.0];
        adLabel.textColor = [UIColor whiteColor];
        adLabel.text = @"Live Chat powered by";
        [adLabel sizeToFit];
        aFrame = adLabel.frame;
        aFrame.origin.x = 0.0;
        aFrame.origin.y = 16.0 - (aFrame.size.height / 2.0);
        adLabel.frame = aFrame;
        
        UIImageView *tinyLogo = [[[UIImageView alloc] initWithImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOHeaderBarTinyLogo"]] autorelease];
        aFrame = tinyLogo.frame;
        aFrame.origin.y = 16.0 - (tinyLogo.frame.size.height / 2.0);
        aFrame.origin.x = adLabel.frame.origin.x + adLabel.frame.size.width + 5.0;
        tinyLogo.frame = aFrame;
        
        UIButton *plusButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [plusButton addTarget:self action:@selector(plusButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
        [plusButton setBackgroundImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOHeaderPlusIcon"] forState:UIControlStateNormal];
        [plusButton sizeToFit];
        aFrame = plusButton.frame;
        aFrame.size.height = 15.0;
        aFrame.origin.y = 8.0;
        aFrame.origin.x = tinyLogo.frame.origin.x + tinyLogo.frame.size.width + 5.0;
        plusButton.frame = aFrame;

        UIView *lolcontainer = [[[UIView alloc] initWithFrame:self.bounds] autorelease];
        lolcontainer.backgroundColor = [UIColor clearColor];
        aFrame = lolcontainer.frame;
        aFrame.size.height = 32.0;
        aFrame.size.width = adLabel.frame.size.width + tinyLogo.frame.size.width + plusButton.frame.size.width + 10.0;
        aFrame.origin.x = (self.bounds.size.width / 2.0) - (aFrame.size.width / 2.0);
        lolcontainer.frame = aFrame;
        lolcontainer.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [defaultNotification addSubview:lolcontainer];
        
        [lolcontainer addSubview:adLabel];
        [lolcontainer addSubview:tinyLogo];
        [lolcontainer addSubview:plusButton];
        
        UITapGestureRecognizer *tapper = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)] autorelease];
        tappableBackground = [[UIView alloc] initWithFrame:self.bounds];
        tappableBackground.backgroundColor = [UIColor clearColor];
        [tappableBackground addGestureRecognizer:tapper];
        [self addSubview:tappableBackground];
    }
    
    return self;
}

- (void)dealloc
{
    [defaultNotification release];
    [separator release];
    [tappableBackground release];
    
    [notificationTimer stopTimer];
    [notificationTimer release];
    
    [super dealloc];
}

- (UIView *)createNotificationViewWithString:(NSString *)aString
{
    UIView *newNotification = [[UIView alloc] initWithFrame:self.bounds];
    CGRect aFrame = newNotification.frame;
    aFrame.size.height = 32.0;
    newNotification.frame = aFrame;
    newNotification.backgroundColor = [UIColor clearColor];
    newNotification.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UILabel *aLabel = [[[UILabel alloc] init] autorelease];
    aLabel.backgroundColor = [UIColor clearColor];
    aLabel.font = [UIFont boldSystemFontOfSize:12.0];
    aLabel.textColor = [UIColor whiteColor];
    aLabel.text = aString;
    [aLabel sizeToFit];
    aFrame = aLabel.frame;
    aFrame.origin.y = (newNotification.frame.size.height / 2.0) - (aFrame.size.height / 2.0);
    aFrame.origin.x = (newNotification.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    aLabel.frame = aFrame;
    aLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [newNotification addSubview:aLabel];
    
    return newNotification;
}

- (void)revealDefaultNotification
{
    if (activeNotification)
        return;
    
    CGRect startFrame = defaultNotification.frame;
    startFrame.origin.x = -startFrame.size.width;
    defaultNotification.frame = startFrame;
    defaultNotification.hidden = NO;
    
    CGRect targetFrameOne = defaultNotification.frame;
    targetFrameOne.origin.x = 10.0; // overshot
    
    CGRect targetFrameTwo = targetFrameOne;
    targetFrameTwo.origin.x = 0.0;
    
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         defaultNotification.frame = targetFrameOne;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.1
                                               delay:0.0
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              defaultNotification.frame = targetFrameTwo;
                                          }
                                          completion:^(BOOL finished) {
                                          }];
                     }];
}

- (void)dismissDefaultNotification
{
    CGRect startFrame = defaultNotification.frame;
    startFrame.origin.x = 0.0;
    defaultNotification.frame = startFrame;
    defaultNotification.hidden = NO;
    
    CGRect targetFrame = defaultNotification.frame;
    targetFrame.origin.x = startFrame.size.width;
    
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         defaultNotification.frame = targetFrame;
                     }
                     completion:^(BOOL finished) {
                         defaultNotification.hidden = YES;
                     }];
}

- (void)revealNotificationString:(NSString *)aString
{
    if (activeNotification)
    {
        [notificationTimer stopTimer];
        [notificationTimer release];
        
        [self dismissActiveNotification];
    }
    else
    {
        [self dismissDefaultNotification];
    }
    
    activeNotification = [self createNotificationViewWithString:aString];
    [self addSubview:activeNotification];
    
    CGRect startFrame = activeNotification.frame;
    startFrame.origin.x = -startFrame.size.width;
    activeNotification.frame = startFrame;
    activeNotification.hidden = NO;
    
    CGRect targetFrameOne = activeNotification.frame;
    targetFrameOne.origin.x = 10.0; // overshot
    
    CGRect targetFrameTwo = targetFrameOne;
    targetFrameTwo.origin.x = 0.0;
    
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         activeNotification.frame = targetFrameOne;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.1
                                               delay:0.0
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              activeNotification.frame = targetFrameTwo;
                                          }
                                          completion:^(BOOL finished) {
                                              
                                          }];
                     }];
    
    notificationTimer = [[LIOTimerProxy alloc] initWithTimeInterval:LIOHeaderBarViewDefaultNotificationDuration
                                                             target:self
                                                           selector:@selector(notificationTimerDidFire)];
}

- (void)dismissActiveNotification
{
    if (nil == activeNotification)
        return;
    
    UIView *notificationToDismiss = activeNotification;
    activeNotification = nil;
    
    CGRect targetFrame = notificationToDismiss.frame;
    targetFrame.origin.y = -self.bounds.size.height;
    
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         notificationToDismiss.frame = targetFrame;
                         notificationToDismiss.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         [notificationToDismiss removeFromSuperview];
                         [notificationToDismiss autorelease];
                     }];
}

- (void)notificationTimerDidFire
{
    [notificationTimer stopTimer];
    [notificationTimer release];
    notificationTimer = nil;
    
    [self dismissActiveNotification];
    [self revealDefaultNotification];
}

#pragma mark -
#pragma mark UIControl actions

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