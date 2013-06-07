//
//  LIOPreSurveyView.h
//  LookIO
//
//  Created by Yaron Karasik on 5/30/13.
//
//

#import <UIKit/UIKit.h>

@class LIOSurveyTemplate;
@class LIOSurveyViewPre;

@protocol LIOSurveyViewDelegate
- (BOOL)surveyView:(LIOSurveyViewPre*)aView shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void)surveyViewDidCancel:(LIOSurveyViewPre *)aView;
- (void)surveyViewDidFinish:(LIOSurveyViewPre *)aView;
@end

@interface LIOSurveyViewPre : UIView <UITextFieldDelegate, UIGestureRecognizerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDataSource, UITableViewDelegate> {

    id<LIOSurveyViewDelegate> delegate;

    LIOSurveyTemplate *currentSurvey;
    NSString *headerString;
    int currentQuestionIndex, nextQuestionIndex;
    NSMutableArray* selectedIndices;

    UIScrollView* currentScrollView;
    UILabel *currentQuestionLabel;
    UIPageControl* pageControl;
    UITextField *currentInputField;
    
    UISwipeGestureRecognizer* leftSwipeGestureRecognizer, *rightSwipeGestureRecognizer;
    
    BOOL isAnimating;
    CGFloat keyboardHeight;
}

@property (nonatomic, assign) id<LIOSurveyViewDelegate> delegate;
@property (nonatomic, retain) LIOSurveyTemplate* currentSurvey;
@property (nonatomic, copy) NSString* headerString;

-(void)setupViews;

@end
