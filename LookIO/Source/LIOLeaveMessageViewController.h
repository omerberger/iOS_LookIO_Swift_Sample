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
@end
*/

@interface LIOLeaveMessageViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate>
{
    UIView *bubbleView;
    UIScrollView *scrollView;
    LIONiceTextField *emailField;
    UITextView *messageView;
    BOOL keyboardShown;
    NSString *initialMessage;
    id delegate;
}

@property(nonatomic, assign) id delegate;
@property(nonatomic, retain) NSString *initialMessage;

@end
