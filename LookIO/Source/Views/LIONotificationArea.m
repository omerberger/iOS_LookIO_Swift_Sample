//
//  LIONotificationArea.m
//  LookIO
//
//  Created by Joseph Toscano on 5/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LIONotificationArea.h"
#import "LIOBundleManager.h"
#import "LIOTimerProxy.h"
#import "LIOAnimatedKeyboardIcon.h"
#import "LIOLookIOManager.h"
#import <QuartzCore/QuartzCore.h>

@implementation LIONotificationArea

@synthesize keyboardIconVisible;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.clipsToBounds = YES;
        
        BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
        
        defaultNotification = [[UIView alloc] initWithFrame:self.bounds];
        CGRect aFrame = defaultNotification.frame;
        aFrame.size.height = 32.0;
        defaultNotification.frame = aFrame;
        defaultNotification.backgroundColor = [UIColor clearColor];
        defaultNotification.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:defaultNotification];
        
        if (padUI)
        {
            UIView *finalBrandingView = nil;
            
            CGSize brandingSize = CGSizeMake(130.0, 44.0);
            id aBrandingView = [[LIOLookIOManager sharedLookIOManager] brandingViewWithDimensions:brandingSize];
            if (aBrandingView)
            {
                if ([aBrandingView isKindOfClass:[UIImage class]])
                {
                    UIImage *anImage = (UIImage *)aBrandingView;
                    finalBrandingView = [[[UIImageView alloc] initWithImage:anImage] autorelease];
                    finalBrandingView.contentMode = UIViewContentModeScaleAspectFit;
                    finalBrandingView.frame = CGRectMake(0.0, 0.0, 130.0, 44.0);
                }
                else
                    finalBrandingView = aBrandingView;
            }
            
            if (nil == finalBrandingView)
            {
                finalBrandingView = [[[UIImageView alloc] initWithImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOBigLivePersonLogo"]] autorelease];
                finalBrandingView.contentMode = UIViewContentModeScaleAspectFit;
                aFrame = finalBrandingView.frame;
                aFrame.size.width = 130.0;
                aFrame.size.height = 44.0;
                finalBrandingView.frame = aFrame;
            }
            
            finalBrandingView.userInteractionEnabled = NO;
            aFrame = finalBrandingView.frame;
            aFrame.origin.x = 16.0;
            aFrame.origin.y = 16.0;
            finalBrandingView.frame = aFrame;
//            finalBrandingView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
//            finalBrandingView.backgroundColor = [UIColor clearColor];
//            finalBrandingView.layer.shadowColor = [UIColor whiteColor].CGColor;
//            finalBrandingView.layer.shadowOffset = CGSizeMake(0.5, 0.5);
//            finalBrandingView.layer.shadowOpacity = 0.33;
//            finalBrandingView.layer.shadowRadius = 0.75;
            [self addSubview:finalBrandingView];
        }
        else
        {
            UIView *finalBrandingView = nil;
            
            CGSize brandingSize = CGSizeMake(240.0, 17.0);
            id aBrandingView = [[LIOLookIOManager sharedLookIOManager] brandingViewWithDimensions:brandingSize];
            if (aBrandingView)
            {
                if ([aBrandingView isKindOfClass:[UIImage class]])
                {
                    UIImage *anImage = (UIImage *)aBrandingView;
                    finalBrandingView = [[[UIImageView alloc] initWithImage:anImage] autorelease];
                    finalBrandingView.contentMode = UIViewContentModeScaleAspectFit;
                    finalBrandingView.frame = CGRectMake(0.0, 0.0, 240.0, 17.0);
                }
                else
                    finalBrandingView = aBrandingView;
                
                finalBrandingView.userInteractionEnabled = NO;
                aFrame = finalBrandingView.frame;
                aFrame.origin.y = 8.0;
                aFrame.origin.x = (defaultNotification.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
                finalBrandingView.frame = aFrame;
                finalBrandingView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            }
            
            if (nil == finalBrandingView)
            {
                finalBrandingView = [[[UIView alloc] initWithFrame:self.bounds] autorelease];
                finalBrandingView.backgroundColor = [UIColor clearColor];
                //            aFrame = lolcontainer.frame;
                //            aFrame.size.height = 32.0;
                //            aFrame.origin.y = (self.bounds.size.height / 2.0) - (aFrame.size.height / 2.0);
                //            lolcontainer.frame = aFrame;
                finalBrandingView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
                
                UILabel *adLabel = [[[UILabel alloc] init] autorelease];
                adLabel.backgroundColor = [UIColor clearColor];
                adLabel.font = [UIFont boldSystemFontOfSize:12.0];
                adLabel.textColor = [UIColor whiteColor];
                adLabel.text = LIOLocalizedString(@"LIONotificationArea.PoweredBy");
                [adLabel sizeToFit];
                aFrame = adLabel.frame;
                aFrame.origin.x = 0.0;
                aFrame.origin.y = 8.0;
                adLabel.frame = aFrame;
                
                UIImageView *tinyLogo = [[[UIImageView alloc] initWithImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOLivePersonMobileLogo"]] autorelease];
                aFrame = tinyLogo.frame;
                aFrame.origin.y = 8.0;
                aFrame.origin.x = adLabel.frame.origin.x + adLabel.frame.size.width + 5.0;
                tinyLogo.frame = aFrame;
                tinyLogo.layer.shadowColor = [UIColor whiteColor].CGColor;
                tinyLogo.layer.shadowOffset = CGSizeMake(0.5, 0.5);
                tinyLogo.layer.shadowOpacity = 0.33;
                tinyLogo.layer.shadowRadius = 0.75;
                
                UIButton *plusButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [plusButton addTarget:self action:@selector(plusButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
                [plusButton setBackgroundImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOHeaderPlusIcon"] forState:UIControlStateNormal];
                [plusButton sizeToFit];
                aFrame = plusButton.frame;
                aFrame.size.height = 15.0;
                aFrame.origin.y = 8.0;
                aFrame.origin.x = tinyLogo.frame.origin.x + tinyLogo.frame.size.width + 5.0;
                plusButton.frame = aFrame;
                
                aFrame = finalBrandingView.frame;
                aFrame.size.width = adLabel.frame.size.width + tinyLogo.frame.size.width + plusButton.frame.size.width + 10.0;
                aFrame.origin.x = (self.bounds.size.width / 2.0) - (aFrame.size.width / 2.0);
                finalBrandingView.frame = aFrame;
                
                [finalBrandingView addSubview:adLabel];
                [finalBrandingView addSubview:tinyLogo];
                [finalBrandingView addSubview:plusButton];
            }
            
            [defaultNotification addSubview:finalBrandingView];
        }
        
        keyboardIcon = [[LIOAnimatedKeyboardIcon alloc] initWithFrame:CGRectMake(0.0, 0.0, 13.0, 18.0)];
        keyboardIcon.backgroundColor = [UIColor clearColor];
        
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
    
    [notificationTimer stopTimer];
    [notificationTimer release];
    
    [animatedEllipsisTimer stopTimer];
    [animatedEllipsisTimer release];
    
    [defaultNotification release];
    [activeNotification release];
    [keyboardIcon release];
    
    [super dealloc];
}

- (UIView *)createNotificationViewWithString:(NSString *)aString
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    UIView *newNotification = [[UIView alloc] initWithFrame:self.bounds];
    newNotification.backgroundColor = [UIColor clearColor];
    newNotification.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UILabel *aLabel = [[[UILabel alloc] init] autorelease];
    aLabel.tag = LIONotificationAreaNotificationLabelTag;
    aLabel.backgroundColor = [UIColor clearColor];
    aLabel.font = [UIFont boldSystemFontOfSize:12.0];
    aLabel.textColor = [UIColor whiteColor];
    aLabel.text = aString;
    [newNotification addSubview:aLabel];
    
    if (padUI)
    {
        aLabel.numberOfLines = 0;
        CGSize calculatedSize = [aLabel.text sizeWithFont:aLabel.font constrainedToSize:CGSizeMake(self.bounds.size.width - 20.0, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
        CGRect aFrame = aLabel.frame;
        aFrame.size = calculatedSize;
        aFrame.origin.y = (newNotification.frame.size.height / 2.0) - (aFrame.size.height / 2.0);
        aFrame.origin.x = (newNotification.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
        aLabel.frame = aFrame;
    }
    else
    {
        aLabel.numberOfLines = 1;
        [aLabel sizeToFit];

        CGRect aFrame = aLabel.frame;
        aFrame.origin.y = 8.0;
        aFrame.origin.x = (newNotification.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
        aLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        aLabel.frame = aFrame;
    }
    
    return newNotification;
}

- (void)revealDefaultNotification
{
    if (activeNotification)
        return;
    
    keyboardIconVisible = NO;
    [keyboardIcon removeFromSuperview];
    
    CGRect startFrame = defaultNotification.frame;
    startFrame.origin.x = -startFrame.size.width;
    defaultNotification.frame = startFrame;
    defaultNotification.hidden = NO;
    
    CGRect targetFrameOne = defaultNotification.frame;
    targetFrameOne.origin.x = 10.0; // overshot
    
    CGRect targetFrameTwo = targetFrameOne;
    targetFrameTwo.origin.x = 0.0;
    
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         defaultNotification.frame = targetFrameOne;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.05
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
    
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         defaultNotification.frame = targetFrame;
                     }
                     completion:^(BOOL finished) {
                         defaultNotification.hidden = YES;
                     }];
}

- (void)revealNotificationString:(NSString *)aString permanently:(BOOL)permanent
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    if (nil == aString)
    {
        [notificationTimer stopTimer];
        [notificationTimer release];
        notificationTimer = nil;
        
        [self dismissActiveNotification];
        
        [self revealDefaultNotification];
        
        return;
    }
    
    if (activeNotification)
    {
        [notificationTimer stopTimer];
        [notificationTimer release];
        notificationTimer = nil;
        
        [self dismissActiveNotification];
    }
    else
    {
        [self dismissDefaultNotification];
    }
    
    BOOL animated = [aString hasSuffix:@"..."];
    
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
    
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         activeNotification.frame = targetFrameOne;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.05
                                               delay:0.0
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              activeNotification.frame = targetFrameTwo;
                                          }
                                          completion:^(BOOL finished) {
                                              
                                          }];
                     }];
    
    if (NO == permanent)
    {
        notificationTimer = [[LIOTimerProxy alloc] initWithTimeInterval:LIONotificationAreaDefaultNotificationDuration
                                                                 target:self
                                                               selector:@selector(notificationTimerDidFire)];
    }
    
    [animatedEllipsisTimer stopTimer];
    [animatedEllipsisTimer release];
    animatedEllipsisTimer = nil;
    
    if (animated)
        animatedEllipsisTimer = [[LIOTimerProxy alloc] initWithTimeInterval:0.5 target:self selector:@selector(animatedEllipsisTimerDidFire)];

    if (keyboardIconVisible)
    {
        UILabel *notificationLabel = (UILabel *)[activeNotification viewWithTag:LIONotificationAreaNotificationLabelTag];
        
        CGRect aFrame = keyboardIcon.frame;
        if (padUI)
        {
            aFrame.origin.y = (activeNotification.frame.size.height / 2.0) - (aFrame.size.height / 2.0) + 3.0;
            aFrame.origin.x = notificationLabel.frame.origin.x - 5.0;
        }
        else
        {
            aFrame.origin.y = 9.0;
            aFrame.origin.x = notificationLabel.frame.origin.x - 7.0;
        }
        keyboardIcon.frame = aFrame;
        keyboardIcon.animating = YES;
        [self addSubview:keyboardIcon];
        
        aFrame = notificationLabel.frame;
        aFrame.origin.x += keyboardIcon.frame.size.width + 5.0;
        notificationLabel.frame = aFrame;
        
        [activeNotification addSubview:keyboardIcon];
    }
    else
    {
        [keyboardIcon removeFromSuperview];
        keyboardIcon.animating = NO;
    }
}

- (void)dismissActiveNotification
{
    if (nil == activeNotification)
        return;
    
    UIView *notificationToDismiss = activeNotification;
    activeNotification = nil;
    
    CGRect targetFrame = notificationToDismiss.frame;
    targetFrame.origin.y = -self.bounds.size.height;
    
    [UIView animateWithDuration:0.3
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

- (void)animatedEllipsisTimerDidFire
{
    if (nil == activeNotification)
        return;
    
    UILabel *aLabel = (UILabel *)[activeNotification viewWithTag:LIONotificationAreaNotificationLabelTag];
    if ([aLabel.text hasSuffix:@"..."])
        aLabel.text = [aLabel.text stringByReplacingCharactersInRange:NSMakeRange([aLabel.text length] - 3, 3) withString:@"."];
    else if ([aLabel.text hasSuffix:@".."])
        aLabel.text = [aLabel.text stringByReplacingCharactersInRange:NSMakeRange([aLabel.text length] - 2, 2) withString:@"..."];
    else if ([aLabel.text hasSuffix:@"."])
        aLabel.text = [aLabel.text stringByReplacingCharactersInRange:NSMakeRange([aLabel.text length] - 1, 1) withString:@".."];
    
    [aLabel setNeedsDisplay];
}

#pragma mark -
#pragma mark Notification handlers

- (void)didChangeStatusBarOrientation:(NSNotification *)aNotification
{
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (activeNotification)
        {
            UILabel *notificationLabel = (UILabel *)[activeNotification viewWithTag:LIONotificationAreaNotificationLabelTag];
            
            CGRect aFrame = keyboardIcon.frame;
            aFrame.origin.x = notificationLabel.frame.origin.x - aFrame.size.width - 10.0;
            aFrame.origin.y = 9.0;
            keyboardIcon.frame = aFrame;
        }
    });
}

@end