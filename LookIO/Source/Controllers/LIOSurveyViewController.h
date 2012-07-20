//
//  LIOSurveyViewController.h
//  LookIO
//
//  Created by Joseph Toscano on 7/9/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LIOSurveyTemplate;
@class LIOSurveyViewController;
@class LIOSurveyPickerView;
@class LIONavigationBar;

@protocol LIOSurveyPickerViewDelegate;
@protocol LIONavigationBarDelegate;

@protocol LIOSurveyViewControllerDelegate
- (BOOL)surveyViewController:(LIOSurveyViewController *)aController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void)surveyViewControllerDidCancel:(LIOSurveyViewController *)aController;
- (void)surveyViewControllerDidFinishSurvey:(LIOSurveyViewController *)aController;
@end

@interface LIOSurveyViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate, LIOSurveyPickerViewDelegate, LIONavigationBarDelegate>
{
    LIONavigationBar *navBar;
    UIScrollView *currentScrollView, *nextScrollView;
    NSString *headerString;
    LIOSurveyTemplate *currentSurvey;
    UILabel *currentQuestionLabel;
    UITextField *currentInputField;
    UIImageView *currentInputFieldBackground;
    LIOSurveyPickerView *currentPickerView, *oldPickerView;
    int currentQuestionIndex;
    CGRect keyboardFrame;
    BOOL keyboardShown;
    UIView *keyboardUnderlay;
    id<LIOSurveyViewControllerDelegate> delegate;
}

@property(nonatomic, assign) id<LIOSurveyViewControllerDelegate> delegate;
@property(nonatomic, retain) LIOSurveyTemplate *currentSurvey;
@property(nonatomic, retain) NSString *headerString;
@property(nonatomic, assign) int currentQuestionIndex;

@end