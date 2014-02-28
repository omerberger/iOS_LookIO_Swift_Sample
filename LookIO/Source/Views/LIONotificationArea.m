//
//  LIONotificationArea.m
//  LookIO
//
//  Created by Joseph Toscano on 5/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LIONotificationArea.h"

#import <QuartzCore/QuartzCore.h>

#import "LIOLookIOManager.h"
#import "LIOBundleManager.h"
#import "LIOBrandingManager.h"

#import "LIOTimerProxy.h"
#import "LIOAnimatedKeyboardIcon.h"

@interface LIONotificationArea ()

@property (nonatomic, strong) UIView *defaultNotification;
@property (nonatomic, strong) UIView *activeNotification;
@property (nonatomic, strong) LIOTimerProxy *notificationTimer;
@property (nonatomic, strong) LIOTimerProxy *animatedEllipsisTimer;
@property (nonatomic, strong) LIOTimerProxy *startAnimatedLongTextTimer;
@property (nonatomic, strong) LIOTimerProxy *moveAnimatedLongTextTimer;
@property (nonatomic, strong) LIOAnimatedKeyboardIcon *keyboardIcon;

@property (nonatomic, assign) BOOL animatingLongText;
@property (nonatomic, assign) BOOL agentIsTyping;

@end

@implementation LIONotificationArea

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.clipsToBounds = YES;
        
        BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
        
        self.defaultNotification = [[UIView alloc] initWithFrame:self.bounds];
        CGRect aFrame = self.defaultNotification.frame;
        aFrame.size.height = 32.0;
        self.defaultNotification.frame = aFrame;
        self.defaultNotification.backgroundColor = [UIColor clearColor];
        self.defaultNotification.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:self.defaultNotification];
        
        self.hasCustomBranding = NO;
        if (padUI)
        {
            UIView *finalBrandingView = nil;
            
            CGSize brandingSize = CGSizeMake(130.0, 44.0);
            id aBrandingView = [[LIOLookIOManager sharedLookIOManager] performSelector:@selector(brandingViewWithDimensions:) withObject:[NSValue valueWithCGSize:brandingSize]];
            if (aBrandingView)
            {
                if ([aBrandingView isKindOfClass:[UIImage class]])
                {
                    UIImage *anImage = (UIImage *)aBrandingView;
                    finalBrandingView = [[UIImageView alloc] initWithImage:anImage];
                    finalBrandingView.contentMode = UIViewContentModeScaleAspectFit;
                    finalBrandingView.frame = CGRectMake(0.0, 0.0, 130.0, 44.0);
                    
                    self.hasCustomBranding = YES;
                }
                else
                    finalBrandingView = nil;
            }
            
            if (nil == finalBrandingView)
            {
                finalBrandingView = [[UIImageView alloc] initWithImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOBigLivePersonLogo"]];
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
            [self addSubview:finalBrandingView];
        }
        else
        {
            UIView *finalBrandingView = nil;
            
            CGSize brandingSize = CGSizeMake(240.0, 17.0);
            id aBrandingView = [[LIOLookIOManager sharedLookIOManager] performSelector:@selector(brandingViewWithDimensions:) withObject:[NSValue valueWithCGSize:brandingSize]];
            if (aBrandingView)
            {
                if ([aBrandingView isKindOfClass:[UIImage class]])
                {
                    UIImage *anImage = (UIImage *)aBrandingView;
                    finalBrandingView = [[UIImageView alloc] initWithImage:anImage];
                    finalBrandingView.contentMode = UIViewContentModeScaleAspectFit;
                    finalBrandingView.frame = CGRectMake(0.0, 0.0, 240.0, 17.0);
                    
                    finalBrandingView.userInteractionEnabled = NO;
                    aFrame = finalBrandingView.frame;
                    aFrame.origin.y = 8.0;
                    aFrame.origin.x = (self.defaultNotification.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
                    finalBrandingView.frame = aFrame;
                    finalBrandingView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

                    self.hasCustomBranding = YES;
                }
                else
                    finalBrandingView = nil;
                
            }
            
            if (nil == finalBrandingView)
            {
                finalBrandingView = [[UIView alloc] initWithFrame:self.bounds];
                finalBrandingView.backgroundColor = [UIColor clearColor];
                //            aFrame = lolcontainer.frame;
                //            aFrame.size.height = 32.0;
                //            aFrame.origin.y = (self.bounds.size.height / 2.0) - (aFrame.size.height / 2.0);
                //            lolcontainer.frame = aFrame;
                finalBrandingView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
                                
                UIImageView *tinyLogo = [[UIImageView alloc] initWithImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOLivePersonMobileLogo"]];
                aFrame = tinyLogo.frame;
                aFrame.origin.y = 8.0;
                aFrame.origin.x = 0.0;
                tinyLogo.frame = aFrame;
                tinyLogo.layer.shadowColor = [UIColor whiteColor].CGColor;
                tinyLogo.layer.shadowOffset = CGSizeMake(0.5, 0.5);
                tinyLogo.layer.shadowOpacity = 0.33;
                tinyLogo.layer.shadowRadius = 0.75;
                
                aFrame = finalBrandingView.frame;
                aFrame.size.width = tinyLogo.frame.size.width + 10.0;
                aFrame.origin.x = (self.bounds.size.width / 2.0) - (aFrame.size.width / 2.0);
                finalBrandingView.frame = aFrame;
                
                [finalBrandingView addSubview:tinyLogo];
            }
            
            [self.defaultNotification addSubview:finalBrandingView];
        }
        
        self.keyboardIcon = [[LIOAnimatedKeyboardIcon alloc] initWithFrame:CGRectMake(0.0, 0.0, 13.0, 18.0) forElement:LIOBrandingElementBrandingBarNotifications];
        self.keyboardIcon.backgroundColor = [UIColor clearColor];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangeStatusBarOrientation:)
                                                     name:UIApplicationDidChangeStatusBarOrientationNotification
                                                   object:nil];
    }
    
    return self;
}

-(void)plusButtonWasTapped {
    
}

- (UIView *)createNotificationViewWithString:(NSString *)aString
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    UIView *newNotification = [[UIView alloc] initWithFrame:self.bounds];
    newNotification.backgroundColor = [UIColor clearColor];
    newNotification.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UILabel *aLabel = [[UILabel alloc] init];
    aLabel.isAccessibilityElement = YES;
    aLabel.tag = LIONotificationAreaNotificationLabelTag;
    aLabel.backgroundColor = [UIColor clearColor];
    aLabel.font = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementBrandingBarNotifications];
    aLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementBrandingBarNotifications];
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
        
        CGSize expectedSize = [aLabel.text sizeWithFont:aLabel.font constrainedToSize:CGSizeMake(9999, aLabel.frame.size.height) lineBreakMode:UILineBreakModeClip];
        
        CGRect aFrame = aLabel.frame;
        aFrame.origin.y = 8.0;
        aFrame.origin.x = (newNotification.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
        aLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        aLabel.frame = aFrame;
        if (expectedSize.width > self.frame.size.width)
            [self animateLongTextAnimationIfNeededForLabel:aLabel animated:NO];
    }
    
    return newNotification;
}

- (BOOL)animateLongTextAnimationIfNeededForLabel:(UILabel *)aLabel animated:(BOOL)animated
{
    CGSize expectedSize = [aLabel.text sizeWithFont:aLabel.font constrainedToSize:CGSizeMake(9999, aLabel.frame.size.height) lineBreakMode:UILineBreakModeClip];
    CGRect aFrame = aLabel.frame;
    
    if (expectedSize.width > self.frame.size.width) {
        aFrame.origin.x = 8.0;
        
        self.startAnimatedLongTextTimer = [[LIOTimerProxy alloc] initWithTimeInterval:LIONotificationAreaPreLongTextAnimationDuration
                                                                               target:self
                                                                             selector:@selector(startAnimatedLongText)];
        
        self.animatingLongText = YES;
    }
    else
    {
        return NO;
    }
    
    if (animated)
    {
        [UIView animateWithDuration:0.3 animations:^{
            CGRect overshootFrame = aFrame;
            overshootFrame.origin.x = 0;
            aLabel.frame = overshootFrame;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 animations:^{
                aLabel.frame = aFrame;
            }];
        }];
    }
    else
    {
        aLabel.frame = aFrame;
    }
    
    return YES;
}

- (void)revealDefaultNotification
{
    if (self.activeNotification)
        return;
    
    self.keyboardIconVisible = NO;
    [self.keyboardIcon removeFromSuperview];
    
    CGRect startFrame = self.defaultNotification.frame;
    startFrame.origin.x = -startFrame.size.width;
    self.defaultNotification.frame = startFrame;
    self.defaultNotification.hidden = NO;
    
    CGRect targetFrameOne = self.defaultNotification.frame;
    targetFrameOne.origin.x = 10.0; // overshot
    
    CGRect targetFrameTwo = targetFrameOne;
    targetFrameTwo.origin.x = 0.0;
    
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.defaultNotification.frame = targetFrameOne;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.05
                                               delay:0.0
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              self.defaultNotification.frame = targetFrameTwo;
                                          }
                                          completion:^(BOOL finished) {
                                          }];
                     }];
}

- (void)dismissDefaultNotification
{
    CGRect startFrame = self.defaultNotification.frame;
    startFrame.origin.x = 0.0;
    self.defaultNotification.frame = startFrame;
    self.defaultNotification.hidden = NO;
    
    CGRect targetFrame = self.defaultNotification.frame;
    targetFrame.origin.x = startFrame.size.width;
    
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.defaultNotification.frame = targetFrame;
                     }
                     completion:^(BOOL finished) {
                         self.defaultNotification.hidden = YES;
                     }];
}

- (void)revealNotificationString:(NSString *)aString permanently:(BOOL)permanent
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    if (nil == aString)
    {
        [self.notificationTimer stopTimer];
        self.notificationTimer = nil;
        
        if (self.animatingLongText) {
            [self.startAnimatedLongTextTimer stopTimer];
            self.startAnimatedLongTextTimer = nil;
            
            [self.moveAnimatedLongTextTimer stopTimer];
            self.moveAnimatedLongTextTimer = nil;
        }
        
        [self dismissActiveNotification];
        
        [self revealDefaultNotification];
        
        return;
    }
    
    if (self.activeNotification)
    {
        [self.notificationTimer stopTimer];
        self.notificationTimer = nil;
        
        if (self.animatingLongText) {
            [self.startAnimatedLongTextTimer stopTimer];
            self.startAnimatedLongTextTimer = nil;
            
            [self.moveAnimatedLongTextTimer stopTimer];
            self.moveAnimatedLongTextTimer = nil;
        }
        
        [self dismissActiveNotification];
    }
    else
    {
        [self dismissDefaultNotification];
    }
    
    BOOL animated = [aString hasSuffix:@"..."];
    
    self.activeNotification = [self createNotificationViewWithString:aString];
    [self addSubview:self.activeNotification];
    
    CGRect startFrame = self.activeNotification.frame;
    startFrame.origin.x = -startFrame.size.width;
    self.activeNotification.frame = startFrame;
    self.activeNotification.hidden = NO;
    
    CGRect targetFrameOne = self.activeNotification.frame;
    targetFrameOne.origin.x = 10.0; // overshot
    
    CGRect targetFrameTwo = targetFrameOne;
    targetFrameTwo.origin.x = 0.0;
    
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.activeNotification.frame = targetFrameOne;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.05
                                               delay:0.0
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              self.activeNotification.frame = targetFrameTwo;
                                          }
                                          completion:^(BOOL finished) {
                                          }];
                     }];
    
    if (NO == permanent && NO == self.animatingLongText)
    {
        self.notificationTimer = [[LIOTimerProxy alloc] initWithTimeInterval:LIONotificationAreaDefaultNotificationDuration
                                                                 target:self
                                                               selector:@selector(notificationTimerDidFire)];
    }
    
    [self.animatedEllipsisTimer stopTimer];
    self.animatedEllipsisTimer = nil;
    
    if (animated)
        self.animatedEllipsisTimer = [[LIOTimerProxy alloc] initWithTimeInterval:0.5 target:self selector:@selector(animatedEllipsisTimerDidFire)];

    if (self.keyboardIconVisible)
    {
        UILabel *notificationLabel = (UILabel *)[self.activeNotification viewWithTag:LIONotificationAreaNotificationLabelTag];
        
        CGRect aFrame = self.keyboardIcon.frame;
        if (padUI)
        {
            aFrame.origin.y = (self.activeNotification.frame.size.height / 2.0) - (aFrame.size.height / 2.0) + 3.0;
            aFrame.origin.x = notificationLabel.frame.origin.x - 5.0;
        }
        else
        {
            aFrame.origin.y = 9.0;
            aFrame.origin.x = notificationLabel.frame.origin.x - 7.0;
        }
        self.keyboardIcon.frame = aFrame;
        self.keyboardIcon.animating = YES;
        [self addSubview:self.keyboardIcon];
        
        aFrame = notificationLabel.frame;
        aFrame.origin.x += self.keyboardIcon.frame.size.width + 5.0;
        notificationLabel.frame = aFrame;
        
        [self.activeNotification addSubview:self.keyboardIcon];
    }
    else
    {
        [self.keyboardIcon removeFromSuperview];
        self.keyboardIcon.animating = NO;
    }
}

- (void)hideCurrentNotification
{
    if (nil == self.activeNotification)
        return;

    if (self.notificationTimer)
    {
        [self.notificationTimer stopTimer];
        self.notificationTimer = nil;
    }
    if (self.startAnimatedLongTextTimer)
    {
        [self.startAnimatedLongTextTimer stopTimer];
        self.startAnimatedLongTextTimer = nil;
    }
    if (self.moveAnimatedLongTextTimer)
    {
        [self.moveAnimatedLongTextTimer stopTimer];
        self.moveAnimatedLongTextTimer = nil;
    }
    if (self.animatedEllipsisTimer)
    {
        [self.animatedEllipsisTimer stopTimer];
        self.animatedEllipsisTimer = nil;
    }
    [self dismissActiveNotification];
    [self revealDefaultNotification];
}

- (void)removeTimersAndNotifications
{
    [self hideCurrentNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)dismissActiveNotification
{
    if (nil == self.activeNotification)
        return;
    
    UIView *notificationToDismiss = self.activeNotification;
    self.activeNotification = nil;
    
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
                     }];
}

- (void)notificationTimerDidFire
{
    [self.notificationTimer stopTimer];
    self.notificationTimer = nil;
    
    if (!self.animatingLongText) {
        
        // Let's check if we should dismiss this notification
        BOOL shouldDismiss = [self.delegate notificationAreaShouldDismissNotification:self];
        if (!shouldDismiss)
        {
            UILabel *notificationLabel = (UILabel *)[self.activeNotification viewWithTag:LIONotificationAreaNotificationLabelTag];
            BOOL isLongTextAnimation = [self animateLongTextAnimationIfNeededForLabel:notificationLabel animated:YES];
            
            // If this isn't a long text animation, let's set up another timer for dismissing it
            if (!isLongTextAnimation)
            {
                self.notificationTimer = [[LIOTimerProxy alloc] initWithTimeInterval:LIONotificationAreaPostLongTextAnimationDuration
                                                                              target:self
                                                                            selector:@selector(notificationTimerDidFire)];
            }
        }
        else
        {
            
            // Let's check if we should reveal the default notification, or the typing notification
            [self dismissActiveNotification];
            BOOL shouldDisplayIsTyping = [self.delegate notificationAreaShouldDisplayIsTypingAfterDismiss:self];
            if (!shouldDisplayIsTyping)
                [self revealDefaultNotification];
        }
    }
}

- (void)animatedEllipsisTimerDidFire
{
    if (nil == self.activeNotification)
        return;
    
    UILabel *aLabel = (UILabel *)[self.activeNotification viewWithTag:LIONotificationAreaNotificationLabelTag];
    if ([aLabel.text hasSuffix:@"..."])
        aLabel.text = [aLabel.text stringByReplacingCharactersInRange:NSMakeRange([aLabel.text length] - 3, 3) withString:@"."];
    else if ([aLabel.text hasSuffix:@".."])
        aLabel.text = [aLabel.text stringByReplacingCharactersInRange:NSMakeRange([aLabel.text length] - 2, 2) withString:@"..."];
    else if ([aLabel.text hasSuffix:@"."])
        aLabel.text = [aLabel.text stringByReplacingCharactersInRange:NSMakeRange([aLabel.text length] - 1, 1) withString:@".."];
    
    [aLabel setNeedsDisplay];
}

-(void)startAnimatedLongText {
    [self.startAnimatedLongTextTimer stopTimer];
    self.startAnimatedLongTextTimer = nil;

    self.moveAnimatedLongTextTimer = [[LIOTimerProxy alloc] initWithTimeInterval:0.05
                                                                 target:self
                                                               selector:@selector(animatedLongTextTimerDidFire)];

}

- (void)animatedLongTextTimerDidFire {
    if (self.activeNotification) {
        UILabel *aLabel = (UILabel *)[self.activeNotification viewWithTag:LIONotificationAreaNotificationLabelTag];
        
        if (aLabel) {
            CGSize expectedSize = [aLabel.text sizeWithFont:aLabel.font constrainedToSize:CGSizeMake(9999, aLabel.frame.size.height) lineBreakMode:UILineBreakModeClip];
            if (aLabel.frame.origin.x < (self.frame.size.width - expectedSize.width - 8.0)) {
                [self.moveAnimatedLongTextTimer stopTimer];
                self.moveAnimatedLongTextTimer = nil;
                
                self.animatingLongText = NO;
                
                self.notificationTimer = [[LIOTimerProxy alloc] initWithTimeInterval:LIONotificationAreaPostLongTextAnimationDuration
                                                                         target:self
                                                                       selector:@selector(notificationTimerDidFire)];
                
            } else {
                CGRect aFrame = aLabel.frame;
                aFrame.origin.x -= 1;
                aLabel.frame = aFrame;
            }
        }
    }
}

#pragma mark -
#pragma mark Notification handlers

- (void)didChangeStatusBarOrientation:(NSNotification *)aNotification
{
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (self.activeNotification)
        {
            UILabel *notificationLabel = (UILabel *)[self.activeNotification viewWithTag:LIONotificationAreaNotificationLabelTag];
            
            // Let's check if this label is too wide. If so, and it is still animating, reset it to position 0.
            // If not, we should just center it
            
            CGRect aFrame = notificationLabel.frame;
            
            if (self.animatingLongText) {
                aFrame.origin.x = 8.0;
            } else {
                aFrame.origin.x = (self.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
            }
            notificationLabel.frame = aFrame;
            
            aFrame = self.keyboardIcon.frame;
            aFrame.origin.x = notificationLabel.frame.origin.x - aFrame.size.width - 10.0;
            aFrame.origin.y = 9.0;
            
            self.keyboardIcon.frame = aFrame;
        } else {
            self.defaultNotification.frame = self.bounds;
        }
    });
}

@end