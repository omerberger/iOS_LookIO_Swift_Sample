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
@class LIOSurveyValidationView;
@class LIOTimerProxy;
@class LIOHeaderBarView;
@protocol LIOSurveyValidationViewDelegate;

@protocol LIOSurveyViewDelegate
- (BOOL)surveyView:(LIOSurveyViewPre*)aView shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void)surveyViewDidCancel:(LIOSurveyViewPre *)aView;
- (void)surveyViewDidFinish:(LIOSurveyViewPre *)aView;
@end

@interface LIOSurveyViewPre : UIView <UITextFieldDelegate, UIGestureRecognizerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDataSource, UITableViewDelegate, LIOSurveyValidationViewDelegate> {

    id<LIOSurveyViewDelegate> delegate;

    LIOSurveyTemplate *currentSurvey;
    NSString *headerString;
    int currentQuestionIndex, nextQuestionIndex;
    NSMutableArray* selectedIndices;

    UIScrollView* currentScrollView;
    UIPageControl* pageControl;
    UIView* backgroundDismissableArea;
    
    UISwipeGestureRecognizer* leftSwipeGestureRecognizer, *rightSwipeGestureRecognizer;
    UITapGestureRecognizer* tapGestureRecognizer;
    
    BOOL isAnimating;
    CGFloat keyboardHeight;
    
    LIOSurveyValidationView *validationView;
    LIOTimerProxy *validationTimer;
    
    LIOHeaderBarView* headerBar;

}

@property (nonatomic, assign) id<LIOSurveyViewDelegate> delegate;
@property (nonatomic, retain) LIOSurveyTemplate* currentSurvey;
@property (nonatomic, copy) NSString* headerString;
@property (nonatomic, assign) int currentQuestionIndex;

- (void)setupViews;
- (id)initWithFrame:(CGRect)frame;

@end
