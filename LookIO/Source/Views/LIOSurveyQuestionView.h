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

@protocol LIOSurveyValidationViewDelegate, LIOStarRatingViewDelegate;

@interface LIOSurveyQuestionView : UIScrollView

- (void)setupViewWithQuestion:(LIOSurveyQuestion *)question;

@end
