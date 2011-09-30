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
 @end
 */

@interface LIOEmailHistoryViewController : UIViewController <UITextFieldDelegate>
{
    UIView *bubbleView;
    UIScrollView *scrollView;
    LIONiceTextField *emailField;
    BOOL keyboardShown;
    id delegate;
}

@property(nonatomic, assign) id delegate;

@end
