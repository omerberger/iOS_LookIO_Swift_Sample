//
//  LIOSurveyView.h
//  LookIO
//
//  Created by Yaron Karasik on 5/30/13.
//
//

#import <UIKit/UIKit.h>
#import "LIOSurveyManager.h"

@class LIOSurveyTemplate;
@class LIOSurveyView;
@class LIOSurveyValidationView;
@class LIOTimerProxy;
@class LIOHeaderBarView;
@class LIOStarRatingView;
@protocol LIOSurveyValidationViewDelegate, LIOStarRatingViewDelegate;

@protocol LIOSurveyViewDelegate
- (BOOL)surveyView:(LIOSurveyView*)aView shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void)surveyViewDidCancel:(LIOSurveyView *)aView;
- (void)surveyViewDidFinish:(LIOSurveyView *)aView;
@end

@interface LIOSurveyView : UIView <UITextFieldDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, LIOSurveyValidationViewDelegate, LIOStarRatingViewDelegate, UIAlertViewDelegate> {

    id<LIOSurveyViewDelegate> delegate;

    LIOSurveyTemplate *currentSurvey;
    LIOSurveyManagerSurveyType currentSurveyType;
    NSString *headerString;
    int currentQuestionIndex, nextQuestionIndex;
    NSMutableArray* selectedIndices;

    UIScrollView* currentScrollView;
    UIImageView* previousQuestionImageView, *nextQuestionImageView, *currentQuestionImageView;
    UIPageControl* pageControl;
    UIView* backgroundDismissableArea;
    
    UISwipeGestureRecognizer* leftSwipeGestureRecognizer, *rightSwipeGestureRecognizer;
    UITapGestureRecognizer* tapGestureRecognizer, *iPadBackgroundGestureRecognizer;
    
    BOOL isAnimatingTransition;
    BOOL isAnimatingEntrance;
    CGFloat keyboardHeight;
    
    LIOSurveyValidationView *validationView;
    LIOTimerProxy *validationTimer;
    
    UIAlertView *alertView;
}

@property (nonatomic, assign) id<LIOSurveyViewDelegate> delegate;
@property (nonatomic, retain) LIOSurveyTemplate* currentSurvey;
@property (nonatomic, copy) NSString* headerString;
@property (nonatomic, assign) int currentQuestionIndex;
@property (nonatomic, assign) LIOSurveyManagerSurveyType currentSurveyType;

- (void)setupViews;
- (id)initWithFrame:(CGRect)frame;

@end
