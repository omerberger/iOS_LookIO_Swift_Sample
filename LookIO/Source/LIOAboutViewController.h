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

/*
@protocol LIOAboutViewControllerDelegate
- (void)aboutViewControllerWasDismissed:(LIOAboutViewController *)aController;
- (void)aboutViewController:(LIOAboutViewController *)aController wasDismissedWithEmail:(NSString *)anEmail;
@end
*/

@interface LIOAboutViewController : UIViewController <UITextFieldDelegate>
{
    UIScrollView *scrollView;
    UIView *bubbleView;
    UIButton *cancelButton, *submitButton;
    UILabel *poweredByLabel, *areYouDeveloperLabel, *emailLabel, *whatIsLabel, *canAgentsLabel;
    UILabel *paragraphOne, *paragraphTwo;
    LIONiceTextField *emailField;
    id delegate;
}

@property(nonatomic, assign) id delegate;

@end
