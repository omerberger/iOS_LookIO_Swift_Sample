//
//  LIOFeedbackViewController.h
//  LookIO
//
//  Created by Joe Toscano on 9/9/11.
//  Copyright 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
@protocol LIOFeedbackViewControllerDelegate
- (void)feedbackViewControllerWasDismissed:(LIOFeedbackViewController *)aController;
- (void)feedbackViewController:(LIOFeedbackViewController *)aController wantsToSendMessage:(NSString *)aMessage;
@end
 */

@interface LIOFeedbackViewController : UIViewController
{
    UIView *backgroundView;
    //UIScrollView *scrollView;
    UITextView *textEditor;
    UILabel *instructionsLabel;
    BOOL keyboardShown;
    id cancelButton, sendButton, delegate;
}

@property(nonatomic, assign) id delegate;

@end
