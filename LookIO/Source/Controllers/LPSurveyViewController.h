//
//  LPSurveyViewController.h
//  LookIO
//
//  Created by Yaron Karasik on 12/31/13.
//
//

#import <UIKit/UIKit.h>
#import "LIOSurvey.h"
#import "LIOSurveyQuestionView.h"

@class LPSurveyViewController;

@protocol LPSurveyViewControllerDelegate

- (void)surveyViewController:(LPSurveyViewController *)surveyViewController didCompleteSurvey:(LIOSurvey *)survey;
- (void)surveyViewController:(LPSurveyViewController *)surveyViewController didCancelSurvey:(LIOSurvey *)survey;

@end

@interface LPSurveyViewController : UIViewController <LIOSurveyQuestionViewDelegate>

@property (nonatomic, assign) id <LPSurveyViewControllerDelegate> delegate;

- (id)initWithSurvey:(LIOSurvey *)aSurvey;

@end
