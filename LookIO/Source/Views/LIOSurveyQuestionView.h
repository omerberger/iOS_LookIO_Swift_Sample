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

- (void)surveyQuestionViewDidTapCancelButton:(LIOSurveyQuestionView *)surveyQuestionView;
- (void)surveyQuestionViewDidTapNextButton:(LIOSurveyQuestionView *)surveyQuestionView;

@end

@interface LIOSurveyQuestionView : UIScrollView

- (void)setupViewWithQuestion:(LIOSurveyQuestion *)question existingResponse:(id)existingResponse isLastQuestion:(BOOL)isLastQuestion delegate:(id)delegate;

@property (nonatomic, assign) id <LIOSurveyQuestionViewDelegate> delegate;

@end
