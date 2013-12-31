//
//  LPSurveyViewController.m
//  LookIO
//
//  Created by Yaron Karasik on 12/31/13.
//
//

#import "LPSurveyViewController.h"
#import "LIOSurveyView.h"

@interface LPSurveyViewController ()

@property (nonatomic, strong) LIOSurvey *survey;

@property (nonatomic, assign) NSInteger currentQuestionIndex;
@property (nonatomic, assign) NSInteger nextQuestionIndex;

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) NSMutableArray* selectedIndices;
@property (nonatomic, strong) UIImageView* previousQuestionImageView, *nextQuestionImageView, *currentQuestionImageView;
@property (nonatomic, strong) UIPageControl* pageControl;
@property (nonatomic, strong) UIView* backgroundDismissableArea;

@property (nonatomic, strong) UITapGestureRecognizer* tapGestureRecognizer, *iPadBackgroundGestureRecognizer;

/*
BOOL isAnimatingTransition;
BOOL isAnimatingEntrance;
CGFloat keyboardHeight;
*/

@property (nonatomic, strong) LIOSurveyValidationView *validationView;
@property (nonatomic, strong) LIOTimerProxy *validationTimer;

@property (nonatomic, strong) UIAlertView *alertView;


@end

@implementation LPSurveyViewController

- (id)initWithSurvey:(LIOSurvey *)aSurvey
{
    self = [super init];
    if (self)
    {
        self.survey = aSurvey;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor greenColor];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scrollView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    

}

@end
