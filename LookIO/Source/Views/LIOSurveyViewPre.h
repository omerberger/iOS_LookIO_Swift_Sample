//
//  LIOPreSurveyView.h
//  LookIO
//
//  Created by Yaron Karasik on 5/30/13.
//
//

#import <UIKit/UIKit.h>

@class LIOSurveyTemplate;

@interface LIOSurveyViewPre : UIView <UITextFieldDelegate> {
    LIOSurveyTemplate *currentSurvey;
    NSString *headerString;
    int currentQuestionIndex, nextQuestionIndex;

    UIScrollView* currentScrollView, *nextScrollView;
    UILabel *currentQuestionLabel;
    UIPageControl* pageControl;
    UITextField *currentInputField;
}

@property (nonatomic, retain) LIOSurveyTemplate* currentSurvey;
@property (nonatomic, copy) NSString* headerString;

-(void)setupViews;

@end
