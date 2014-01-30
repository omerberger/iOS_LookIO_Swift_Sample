//
//  LIOSurveyQuestionView.h
//  LookIO
//
//  Created by Yaron Karasik on 12/31/13.
//
//

#import <UIKit/UIKit.h>
#import "LIOSurveyManager.h"
#import "LIOSurveyQuestion.h"

@class LIOSurveyQuestionView;

@protocol LIOSurveyQuestionViewDelegate

- (void)surveyQuestionViewAnswerDidChange:(LIOSurveyQuestionView *)surveyQuestionView;
- (void)surveyQuestionViewDidTapNextButton:(LIOSurveyQuestionView *)surveyQuestionView;
- (void)surveyQuestionViewDidTapCancelButton:(LIOSurveyQuestionView *)surveyQuestionView;

@end

@interface LIOSurveyQuestionView : UIScrollView

- (void)setupViewWithQuestion:(LIOSurveyQuestion *)question isLastQuestion:(BOOL)isLastQuestion delegate:(id)delegate;

@property (nonatomic, assign) id <LIOSurveyQuestionViewDelegate> delegate;

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UITextView *textView;

- (void)becomeFirstResponder;
- (void)questionViewDidAppear;
- (void)questionViewDidDisappear;

@end
