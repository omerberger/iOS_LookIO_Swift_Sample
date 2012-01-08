//
//  LIOAboutViewController.h
//  LookIO
//
//  Created by Joseph Toscano on 10/25/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LIONiceTextField.h"

@class LIOAboutViewController;

@protocol LIOAboutViewControllerDelegate
- (void)aboutViewControllerWasDismissed:(LIOAboutViewController *)aController;
- (void)aboutViewController:(LIOAboutViewController *)aController wasDismissedWithEmail:(NSString *)anEmail;
- (BOOL)aboutViewController:(LIOAboutViewController *)aController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation;
@end

@interface LIOAboutViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate>
{
    UILabel *textsplosion01, *textsplosion02, *header01, *header02;
    UIImageView *fieldBackground;
    UIScrollView *scrollView;
    UITextField *inputField;
    UIView *p1Container, *p2Container;
    UIButton *submitButton;
    BOOL keyboardShown;
    id<LIOAboutViewControllerDelegate> delegate;
}

@property(nonatomic, assign) id<LIOAboutViewControllerDelegate> delegate;

@end
