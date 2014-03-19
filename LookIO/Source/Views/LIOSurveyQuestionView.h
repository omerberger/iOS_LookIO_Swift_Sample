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

typedef enum
{
    LIOSurveyQuestionViewKeyboard,
    LIOSurveyQuestionViewNoKeyboard
} LIOSurveyQuestionViewType;

@protocol LIOSurveyQuestionViewDelegate

- (void)surveyQuestionViewAnswerDidChange:(LIOSurveyQuestionView *)surveyQuestionView;
- (void)surveyQuestionViewDidTapNextButton:(LIOSurveyQuestionView *)surveyQuestionView;
- (void)surveyQuestionViewDidTapCancelButton:(LIOSurveyQuestionView *)surveyQuestionView;

@end

@interface LIOSurveyQuestionView : UIView

- (void)setupViewWithQuestion:(LIOSurveyQuestion *)question isLastQuestion:(BOOL)isLastQuestion delegate:(id)delegate;

@property (nonatomic, assign) id <LIOSurveyQuestionViewDelegate> delegate;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) LIOSurveyQuestionViewType questionViewType;

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UITextView *textView;

- (void)becomeFirstResponder;
- (void)questionViewDidAppear;
- (void)questionViewDidDisappear;
- (void)reloadTableViewDataIfNeeded;

@end
