//
//  LIOAboutViewController.h
//  LookIO
//
//  Created by Joseph Toscano on 10/25/11.
//  Copyright (c) 2011 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LIOAboutViewController;
@class LIONavigationBar;

@protocol LIONavigationBarDelegate;

@protocol LIOAboutViewControllerDelegate
- (void)aboutViewController:(LIOAboutViewController *)aController wasDismissedWithEmail:(NSString *)anEmail;
- (BOOL)aboutViewController:(LIOAboutViewController *)aController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation;
@end

@interface LIOAboutViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate, LIONavigationBarDelegate>
{
    UIImageView *texturedBackground;
    UILabel *textsplosion01, *textsplosion02, *header01, *header02, *label02;
    UIImageView *fieldBackground, *logoView;
    UIImageView *bottomSeparator, *topSeparator;
    UIScrollView *scrollView;
    UITextField *inputField;
    UIView *p1Container, *p2Container;
    UIButton *submitButton;
    LIONavigationBar *navBar;
    BOOL keyboardShown;
    id<LIOAboutViewControllerDelegate> delegate;
}

@property(nonatomic, assign) id<LIOAboutViewControllerDelegate> delegate;

@end