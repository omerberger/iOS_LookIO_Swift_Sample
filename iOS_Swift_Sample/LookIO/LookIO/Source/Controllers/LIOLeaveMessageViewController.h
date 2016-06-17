//
//  LIOLeaveMessageViewController.h
//  LookIO
//
//  Created by Joe Toscano on 9/30/11.
//  Copyright 2011 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LIOLeaveMessageViewController;
@class LIONavigationBar;

@protocol LIONavigationBarDelegate;

@protocol LIOLeaveMessageViewControllerDelegate
- (void)leaveMessageViewControllerWasCancelled:(LIOLeaveMessageViewController *)aController;
- (void)leaveMessageViewController:(LIOLeaveMessageViewController *)aController didSubmitEmailAddress:(NSString *)anEmail withMessage:(NSString *)aMessage;
- (BOOL)leaveMessageViewController:(LIOLeaveMessageViewController *)aController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation;
@end

@interface LIOLeaveMessageViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate, UIAlertViewDelegate, LIONavigationBarDelegate>
{
    LIONavigationBar *navBar;
    UIScrollView *scrollView;
    UITextField *emailField;
    UITextView *messageView;
    UIImageView *fieldBackground, *messageBackground;
    BOOL keyboardShown, messageViewActive;
    NSString *initialMessage;
    UIButton *submitButton;
    UILabel *label02;
    UIAlertView *alertView;
    id<LIOLeaveMessageViewControllerDelegate> delegate;
}

@property(nonatomic, assign) id<LIOLeaveMessageViewControllerDelegate> delegate;
@property(nonatomic, retain) NSString *initialMessage;
@property(nonatomic, retain) NSString *initialEmailAddress;

@end