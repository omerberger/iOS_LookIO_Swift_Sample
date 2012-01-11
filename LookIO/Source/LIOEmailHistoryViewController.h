//
//  LIOEmailHistoryViewController.h
//  LookIO
//
//  Created by Joe Toscano on 9/30/11.
//  Copyright 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LIONiceTextField.h"

/*
 @protocol LIOEmailHistoryViewControllerDelegate
 - (void)emailHistoryViewControllerWasDismissed:(LIOLeaveMessageViewController *)aController;
 - (void)emailHistoryViewController:(LIOLeaveMessageViewController *)aController wasDismissedWithEmailAddress:(NSString *)anEmail;
 - (BOOL)emailHistoryViewController:(LIOEmailHistoryViewController *)aController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation;
 @end
 */

@interface LIOEmailHistoryViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate>
{
    UIView *bubbleView;
    UIScrollView *scrollView;
    LIONiceTextField *emailField;
    BOOL keyboardShown;
    NSString *initialEmailAddress;
    id delegate;
}

@property(nonatomic, assign) id delegate;
@property(nonatomic, retain) NSString *initialEmailAddress;

@end
