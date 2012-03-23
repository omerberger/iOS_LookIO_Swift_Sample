//
//  LIOEmailHistoryViewController.h
//  LookIO
//
//  Created by Joe Toscano on 9/30/11.
//  Copyright 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LIOEmailHistoryViewController;

@protocol LIOEmailHistoryViewControllerDelegate
- (void)emailHistoryViewControllerWasDismissed:(LIOEmailHistoryViewController *)aController;
- (void)emailHistoryViewController:(LIOEmailHistoryViewController *)aController wasDismissedWithEmailAddress:(NSString *)anEmail;
- (BOOL)emailHistoryViewController:(LIOEmailHistoryViewController *)aController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation;
@end

@interface LIOEmailHistoryViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate>
{
    UINavigationBar *navBar;
    UIScrollView *scrollView;
    UIImageView *fieldBackground;
    UITextField *inputField;
    UIButton *submitButton;
    BOOL keyboardShown;
    NSString *initialEmailAddress;
    id<LIOEmailHistoryViewControllerDelegate> delegate;
}

@property(nonatomic, assign) id<LIOEmailHistoryViewControllerDelegate> delegate;
@property(nonatomic, retain) NSString *initialEmailAddress;

@end
