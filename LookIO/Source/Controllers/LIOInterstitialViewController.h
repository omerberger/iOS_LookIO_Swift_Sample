//
//  LIOInterstitialViewController.h
//  LookIO
//
//  Created by Joseph Toscano on 3/28/12.
//  Copyright (c) 2012 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LIOTimerProxy.h"

#define LIOInterstitialViewControllerTimeout    45.0

@class LIOInterstitialViewController;

@protocol LIOInterstitialViewControllerDelegate
- (void)interstitialViewControllerWasDismissed:(LIOInterstitialViewController *)aController;
- (void)interstitialViewControllerWantsChatInterface:(LIOInterstitialViewController *)aController;
- (BOOL)interstitialViewController:(LIOInterstitialViewController *)aController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation;
@end

@interface LIOInterstitialViewController : UIViewController <UIAlertViewDelegate>
{
    LIOTimerProxy *timeoutTimer;
    UIView *background;
    UIView *bezel;
    UIButton *dismissButton;
    id<LIOInterstitialViewControllerDelegate> delegate;
}

@property(nonatomic, assign) id<LIOInterstitialViewControllerDelegate> delegate;

- (void)performRevealAnimation;
- (void)performDismissalAnimation;

@end
