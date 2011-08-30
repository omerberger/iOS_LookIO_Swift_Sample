//
//  LIOConnectViewController.h
//  LookIO
//
//  Created by Joe Toscano on 8/30/11.
//  Copyright 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
@class LIOConnectViewController;

@protocol LIOConnectViewControllerDelegate
- (void)connectViewControllerDidTapHideButton:(LIOConnectViewController *)aController;
- (void)connectViewControllerDidTapCancelButton:(LIOConnectViewController *)aController;
- (void)connectViewControllerWasHidden:(LIOConnectViewController *)aController;
@end
*/

@interface LIOConnectViewController : UIViewController
{
    UIImageView *connectionLogo;
    UIButton *hideButton, *cancelButton;
    UIActivityIndicatorView *connectionSpinner;
    UILabel *connectionLabel;
    UIView *connectionBackground;
    CGRect targetLogoFrameForHiding;
    id delegate;
}

@property(nonatomic, assign) id delegate;
@property(nonatomic, assign) CGRect targetLogoFrameForHiding;

- (void)showAnimated:(BOOL)animated;
- (void)hideAnimated:(BOOL)animated;

@end
