//
//  LIOLeaveMessageViewController.h
//  LookIO
//
//  Created by Joe Toscano on 9/30/11.
//  Copyright 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LIONiceTextField.h"

/*
@protocol LIOLeaveMessageViewControllerDelegate
- (void)leaveMessageViewControllerWasDismissed:(LIOLeaveMessageViewController *)aController;
- (void)leaveMessageViewController:(LIOLeaveMessageViewController *)aController wasDismissedWithEmailAddress:(NSString *)anEmail message:(NSString *)aMessage;
- (void)leaveMessageViewController:(LIOLeaveMessageViewController *)aController didSubmitEmailAddress:(NSString *)anEmail withMessage:(NSString *)aMessage;
- (BOOL)leaveMessageViewController:(LIOLeaveMessageViewController *)aController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation;
@end
*/

@interface LIOLeaveMessageViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate, UIAlertViewDelegate>
{
    UIView *bubbleView;
    UIScrollView *scrollView;
    LIONiceTextField *emailField;
    UITextView *messageView;
    BOOL keyboardShown;
    NSString *initialMessage;
    UILabel *instructionsLabel, *emailLabel, *messageLabel;
    UIButton *cancelButton, *sendButton;
    UIImageView *messageViewBackground;
    BOOL suppressKeyboardNotifications;
    id delegate;
}

@property(nonatomic, assign) id delegate;
@property(nonatomic, retain) NSString *initialMessage;
@property(nonatomic, retain) NSString *initialEmailAddress;

@end
