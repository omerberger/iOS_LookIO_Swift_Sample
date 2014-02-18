//
//  LPSurveyViewController.m
//  LookIO
//
//  Created by Yaron Karasik on 12/31/13.
//
//

#import "LPSurveyViewController.h"

#import "LIOSurveyView.h"
#import "LIOSurveyQuestionView.h"
#import "LIOSurveyValidationView.h"
#import "LIOSurveyPickerEntry.h"
#import "LIOStarRatingView.h"

#import "LIOTimerProxy.h"
#import "LIOBundleManager.h"
#import "LIOBrandingManager.h"

#define LIOSurveyViewControllerValidationDuration   5

#define LIOSurveyViewTableCellLabelTag 100

#define LIOSurveyViewControllerAlertViewTagNextActionCancel 1001

#define LIOSurveyViewiPadNextQuestionAlpha               0.5
#define LIOSurveyViewiPadNextQuestionScale               0.8
#define LIOSurveyViewiPadNextNextQuestionScale           0.4
#define LIOSurveyViewiPadNextQuestionOffsetPortrait      0.55
#define LIOSurveyViewiPadNextQuestionOffsetLandscape     0.4

@interface LPSurveyViewController () <UIScrollViewDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) LIOSurvey *survey;

@property (nonatomic, assign) NSInteger currentQuestionIndex;
@property (nonatomic, assign) NSInteger nextQuestionIndex;
@property (nonatomic, assign) BOOL isLastQuestion;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) LIOSurveyQuestionView *currentQuestionView;
@property (nonatomic, strong) LIOSurveyQuestionView *nextQuestionView;
@property (nonatomic, strong) LIOSurveyQuestionView *previousQuestionView;
@property (nonatomic, strong) LIOSurveyQuestionView *reusableQuestionView;

@property (nonatomic, assign) CGFloat lastKeyboardHeight;

@property (nonatomic, strong) UIPageControl* pageControl;

@property (nonatomic, strong) LIOSurveyValidationView *validationView;
@property (nonatomic, strong) LIOTimerProxy *validationTimer;

@property (nonatomic, strong) UIAlertView *alertView;

@property (nonatomic, assign) BOOL isAnimatingBetweenTwoKeyboardViews;


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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Animate in the survey view

    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect frame = self.scrollView.frame;
        frame.origin.y = 0;
        frame.origin.x = 0;
        self.scrollView.frame = frame;
        
        frame = self.pageControl.frame;
        frame.origin.y = self.view.bounds.size.height - frame.size.height;
        self.pageControl.frame = frame;
    } completion:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateScrollView];
    [self updateSubviewFrames];
    
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    CGRect frame;
    if (padUI)
    {
        frame = self.scrollView.frame;
        frame.origin.x = frame.size.width;
        self.scrollView.frame = frame;
    }
    else
    {
        frame = self.scrollView.frame;
        frame.origin.y = -frame.size.height;
        self.scrollView.frame = frame;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.delegate = self;
    self.scrollView.scrollEnabled = NO;
    self.scrollView.clipsToBounds = NO;
    
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scrollView];
    
    UISwipeGestureRecognizer *swipeLeftGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeLeft:)];
    swipeLeftGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.scrollView addGestureRecognizer:swipeLeftGestureRecognizer];
    
    UISwipeGestureRecognizer *swipeRightGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeRight:)];
    swipeRightGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.scrollView addGestureRecognizer:swipeRightGestureRecognizer];
    
    CGRect frame;
    
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    if (padUI)
    {
        UIView *iPadTappableBackground = [[UIView alloc] initWithFrame:self.scrollView.bounds];
        iPadTappableBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.scrollView addSubview:iPadTappableBackground];
        
        UITapGestureRecognizer *iPadBackgroundTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(surveyQuestionViewDidTapCancelButton:)];
        [iPadTappableBackground addGestureRecognizer:iPadBackgroundTapGestureRecognizer];

        frame = self.scrollView.frame;
        frame.origin.x = frame.size.width;
        self.scrollView.frame = frame;
    }
    else
    {
        frame = self.scrollView.frame;
        frame.origin.y = -frame.size.height;
        self.scrollView.frame = frame;
    }
    
    LIOSurveyQuestion *currentQuestion = nil;
    self.currentQuestionIndex = self.survey.lastSeenQuestionIndex;
    if (self.currentQuestionIndex == LIOSurveyViewControllerIndexForIntroPage)
    {
        currentQuestion = [self.survey questionForIntroView];
    }
    else
    {
        currentQuestion = [self.survey.questions objectAtIndex:self.currentQuestionIndex];
    }

    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 20.0, self.view.bounds.size.width, 20.0)];
    self.pageControl.userInteractionEnabled = NO;
    self.pageControl.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    self.pageControl.numberOfPages = [self.survey numberOfQuestionsWithLogic] + 1;
    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
    {
        UIColor *indicatorColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorColor forElement:LIOBrandingElementSurveyPageControl];
        self.pageControl.currentPageIndicatorTintColor = indicatorColor;
        self.pageControl.pageIndicatorTintColor = [indicatorColor colorWithAlphaComponent:0.3];
    }
        
    if (self.currentQuestionIndex == LIOSurveyViewControllerIndexForIntroPage)
        self.pageControl.currentPage = 0;
    else
        self.pageControl.currentPage = self.currentQuestionIndex + 1;
    [self.view addSubview:self.pageControl];
    
    frame = self.pageControl.frame;
    frame.origin.y = frame.origin.y + frame.size.height;
    self.pageControl.frame = frame;
    
    self.currentQuestionView = [[LIOSurveyQuestionView alloc] initWithFrame:self.scrollView.bounds];
    self.currentQuestionView.tag = self.currentQuestionIndex;
    BOOL isLastQuestion = [self.survey isQuestionWithIndexLastQuestion:self.currentQuestionIndex];
    [self.currentQuestionView setupViewWithQuestion:currentQuestion isLastQuestion:isLastQuestion delegate:self];
    [self.scrollView addSubview:self.currentQuestionView];
    [self.currentQuestionView becomeFirstResponder];
    
    // Set up the next question; If we get a FALSE response, we're at the last question
    self.isLastQuestion = ![self setupNextQuestionScrollView];
    [self setupPreviousQuestionScrollView];
    
    [self updateScrollView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}


#pragma mark Subview Methods

- (void) updateSubviewFrames
{
    CGRect frame = self.pageControl.frame;
    frame.origin.y = self.view.bounds.size.height - self.lastKeyboardHeight - frame.size.height;
    self.pageControl.frame = frame;
    
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    if (!padUI)
    {
        CGRect frame = self.currentQuestionView.scrollView.frame;
        frame.size.width = self.view.frame.size.width;
        frame.size.height = self.view.bounds.size.height - self.lastKeyboardHeight;
        self.currentQuestionView.scrollView.frame = frame;
        
        frame = self.nextQuestionView.scrollView.frame;
        frame.size.width = self.view.frame.size.width;
        frame.size.height = self.view.bounds.size.height - self.lastKeyboardHeight;
        self.nextQuestionView.scrollView.frame = frame;

        frame = self.previousQuestionView.scrollView.frame;
        frame.size.width = self.view.frame.size.width;
        frame.size.height = self.view.bounds.size.height - self.lastKeyboardHeight;
        self.previousQuestionView.scrollView.frame = frame;
    }
        
    if (self.currentQuestionView)
        [self.currentQuestionView setNeedsLayout];
    if (self.nextQuestionView)
        [self.nextQuestionView setNeedsLayout];
    if (self.previousQuestionView)
        [self.previousQuestionView setNeedsLayout];
}


#pragma mark Keyboard Methods

- (void)keyboardWillShow:(NSNotification *)notification
{
    // Acquire keyboard info
    NSDictionary *info = [notification userInfo];
    
    UIViewAnimationCurve curve;
    [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&curve];
    
    NSTimeInterval duration;
    [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&duration];
    
    CGRect keyboardRect;
    [[info objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardRect];
    
    // Set new keyboard state and size
    UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;
    self.lastKeyboardHeight = UIInterfaceOrientationIsPortrait(actualOrientation) ? keyboardRect.size.height : keyboardRect.size.width;
    
    [UIView animateWithDuration:duration delay:0.0 options:(curve << 16) animations:^{
        [self updateSubviewFrames];
    } completion:^(BOOL finished) {
        if (self.currentQuestionView)
            [self.currentQuestionView setNeedsLayout];
        if (self.nextQuestionView)
            [self.nextQuestionView setNeedsLayout];
        if (self.previousQuestionView)
            [self.previousQuestionView setNeedsLayout];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    if (self.isAnimatingBetweenTwoKeyboardViews)
    {
        self.isAnimatingBetweenTwoKeyboardViews = NO;
        return;
    }
    
    // Acquire keyboard info
    NSDictionary *info = [notification userInfo];
    
    UIViewAnimationCurve curve;
    [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&curve];
    
    NSTimeInterval duration;
    [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&duration];
    
    CGRect keyboardRect;
    [[info objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardRect];
    
    self.lastKeyboardHeight = 0;
    
    [UIView animateWithDuration:duration delay:0.0 options:(curve << 16) animations:^{
        [self updateSubviewFrames];
    } completion:^(BOOL finished) {
        if (self.currentQuestionView)
            [self.currentQuestionView setNeedsLayout];
        if (self.nextQuestionView)
            [self.nextQuestionView setNeedsLayout];
        if (self.previousQuestionView)
            [self.previousQuestionView setNeedsLayout];
    }];
}

#pragma mark -
#pragma mark UIAlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        switch (alertView.tag) {
            case LIOSurveyViewControllerAlertViewTagNextActionCancel:
                [self cancelSurvey];
                break;
                
            default:
                break;
        }
    }
}

- (void)dismissExistingAlertView
{
    if (self.alertView)
    {
        [self.alertView dismissWithClickedButtonIndex:-1 animated:NO];
        self.alertView = nil;
    }
}

#pragma mark -
#pragma mark Action Methods

- (void)cancelSurveyImmediately:(id)sender
{
    [self.view endEditing:YES];
    if (self.validationView)
    {
        [self.validationTimer stopTimer];
        [self validationTimerDidFire];
    }
    
    [self.delegate surveyViewController:self didCancelSurvey:self.survey];
}

#pragma mark -
#pragma mark LIOSurveyQuestionView Delegate

- (void)surveyQuestionViewAnswerDidChange:(LIOSurveyQuestionView *)surveyQuestionView
{
    // Validate and register the new answer
    [self validateAndRegisterCurrentAnswerAndShowAlert:NO];
    
    // We also need to check to re-build the logic and check to see if the next question has changed
    self.isLastQuestion = ![self setupNextQuestionScrollView];
    
    [self updateScrollView];
    if (self.nextQuestionView)
        [self.nextQuestionView setNeedsLayout];
        
    // We also need to reset the page control pages
    self.pageControl.numberOfPages = [self.survey numberOfQuestionsWithLogic] + 1;
    
}

- (void)didSwipeLeft:(id)sender
{
    [self surveyQuestionViewDidTapNextButton:self.currentQuestionView];
}

- (void)didSwipeRight:(id)sender
{
    [self surveyQuestionViewDidTapPreviousButton:self.currentQuestionView];
}

- (void)surveyQuestionViewDidTapPreviousButton:(LIOSurveyQuestionView *)surveyQuestionView
{
    if (self.currentQuestionIndex == LIOSurveyViewControllerIndexForIntroPage)
    {
        [self bounceViewLeft];
        return;
    }
    
    [self switchToPreviousQuestion];
}

- (void)surveyQuestionViewDidTapNextButton:(LIOSurveyQuestionView *)surveyQuestionView
{
    BOOL isAnswerValid = [self validateAndRegisterCurrentAnswerAndShowAlert:YES];
    if (isAnswerValid)
    {
        if (self.isLastQuestion)
        {
            if (self.validationView)
            {
                [self.validationTimer stopTimer];
                [self validationTimerDidFire];
            }
            
            [self completeSurvey];
            
            return;
        }

        [self switchToNextQuestion];
    }
    else
    {
        [self bounceViewRight];
    }
}

- (void)surveyQuestionViewDidTapCancelButton:(LIOSurveyQuestionView *)surveyQuestionView
{
    [self.view endEditing:YES];
        if (self.validationView)
    {
        [self.validationTimer stopTimer];
        [self validationTimerDidFire];
    }
    
    // For a prechat survey, we allow just tapping off
    if (LIOSurveyTypePrechat == self.survey.surveyType)
    {
        [self cancelSurvey];
    }
    else
    {
        [self dismissExistingAlertView];
        self.alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOSurveyView.LeaveSurveyAlertTitle")
                                                            message:LIOLocalizedString(@"LIOSurveyView.LeaveSurveyAlertBody")
                                                           delegate:self
                                                  cancelButtonTitle:LIOLocalizedString(@"LIOSurveyView.LeaveSurveyAlertNoButton")
                                                  otherButtonTitles:LIOLocalizedString(@"LIOSurveyView.LeaveSurveyAlertYesButton"), nil];
        self.alertView.tag = LIOSurveyViewControllerAlertViewTagNextActionCancel;
        [self.alertView show];
    }
}

- (void)completeSurvey {
    [self.view endEditing:YES];
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.pageControl.alpha = 0.0;

        self.scrollView.transform = CGAffineTransformMakeTranslation(0.0, -self.scrollView.bounds.size.height/2);
        self.scrollView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.delegate surveyViewController:self didCompleteSurvey:self.survey];
    }];
}

- (void)cancelSurvey
{
    [self.view endEditing:YES];
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.pageControl.alpha = 0.0;

        self.scrollView.transform = CGAffineTransformMakeTranslation(0.0, -self.scrollView.bounds.size.height/2);
        self.scrollView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.delegate surveyViewController:self didCancelSurvey:self.survey];
    }];
}

-(void)bounceViewLeft
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    if (!padUI) {
        [UIView animateWithDuration:0.1 animations:^{
            CGRect aFrame = self.scrollView.frame;
            aFrame.origin.x += 30;
            self.scrollView.frame = aFrame;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 animations:^{
                CGRect aFrame = self.scrollView.frame;
                aFrame.origin.x -= 40;
                self.scrollView.frame = aFrame;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.1 animations:^{
                    CGRect aFrame = self.scrollView.frame;
                    aFrame.origin.x += 30;
                    self.scrollView.frame = aFrame;
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.1 animations:^{
                        CGRect aFrame = self.scrollView.frame;
                        aFrame.origin.x -= 20;
                        self.scrollView.frame = aFrame;
                    } completion:^(BOOL finished) {
                    }];
                }];
            }];
        }];
    }
    else {
        [UIView animateWithDuration:0.15 animations:^{
            CGRect aFrame = self.currentQuestionView.frame;
            aFrame.origin.x += 70;
            self.currentQuestionView.frame = aFrame;
            if (self.nextQuestionView) {
                CGRect aFrame = self.nextQuestionView.frame;
                aFrame.origin.x += 35;
                self.nextQuestionView.frame = aFrame;
            }
            if (self.previousQuestionView) {
                CGRect aFrame = self.previousQuestionView.frame;
                aFrame.origin.x += 35;
                self.previousQuestionView.frame = aFrame;
            }
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 delay:0.05 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                CGRect aFrame = self.currentQuestionView.frame;
                aFrame.origin.x -= 70;
                self.currentQuestionView.frame = aFrame;
                if (self.nextQuestionView) {
                    CGRect aFrame = self.nextQuestionView.frame;
                    aFrame.origin.x -= 35;
                    self.nextQuestionView.frame = aFrame;
                }
                if (self.previousQuestionView) {
                    CGRect aFrame = self.previousQuestionView.frame;
                    aFrame.origin.x -= 35;
                    self.previousQuestionView.frame = aFrame;
                }
                
            } completion:^(BOOL finished) {
            }];
        }];
    }
}

- (void)bounceViewRight
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    if (!padUI)
    {
        [UIView animateWithDuration:0.1 animations:^{
            CGRect aFrame = self.scrollView.frame;
            aFrame.origin.x -= 30;
            self.scrollView.frame = aFrame;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 animations:^{
                CGRect aFrame = self.scrollView.frame;
                aFrame.origin.x += 40;
                self.scrollView.frame = aFrame;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.1 animations:^{
                    CGRect aFrame = self.scrollView.frame;
                    aFrame.origin.x -= 30;
                    self.scrollView.frame = aFrame;
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.1 animations:^{
                        CGRect aFrame = self.scrollView.frame;
                        aFrame.origin.x += 20;
                        self.scrollView.frame = aFrame;
                    } completion:^(BOOL finished) {
                    }];
                }];
            }];
        }];
    }
    else {
        [UIView animateWithDuration:0.15 animations:^{
            CGRect aFrame = self.currentQuestionView.frame;
            aFrame.origin.x -= 70;
            self.currentQuestionView.frame = aFrame;
            if (self.nextQuestionView) {
                CGRect aFrame = self.nextQuestionView.frame;
                aFrame.origin.x -= 35;
                self.nextQuestionView.frame = aFrame;
            }
            if (self.previousQuestionView) {
                CGRect aFrame = self.previousQuestionView.frame;
                aFrame.origin.x -= 35;
                self.previousQuestionView.frame = aFrame;
            }
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 delay:0.05 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                CGRect aFrame = self.currentQuestionView.frame;
                aFrame.origin.x += 70;
                self.currentQuestionView.frame = aFrame;
                if (self.nextQuestionView) {
                    CGRect aFrame = self.nextQuestionView.frame;
                    aFrame.origin.x += 35;
                    self.nextQuestionView.frame = aFrame;
                }
                if (self.previousQuestionView) {
                    CGRect aFrame = self.previousQuestionView.frame;
                    aFrame.origin.x += 35;
                    self.previousQuestionView.frame = aFrame;
                }
                
            } completion:^(BOOL finished) {
            }];
        }];
    }
}

- (BOOL)setupPreviousQuestionScrollView
{
    BOOL foundPreviousPage = NO;

    NSInteger previousQuestionIndex = self.currentQuestionIndex;
    while (!foundPreviousPage) {

        // If we're at the intro screen, just bounce the screen
        if (previousQuestionIndex == LIOSurveyViewControllerIndexForIntroPage)
        {
            return NO;
        }
        
        // Mode to the previous question, but check if we should show it taking into account logic issues
        previousQuestionIndex -= 1;
        
        if (previousQuestionIndex == LIOSurveyViewControllerIndexForIntroPage)
            foundPreviousPage = YES;
        else
            if ([self.survey shouldShowQuestion:previousQuestionIndex])
                foundPreviousPage = YES;
    }
    
    LIOSurveyQuestion *question;
    if (LIOSurveyViewControllerIndexForIntroPage == previousQuestionIndex)
        question = [self.survey questionForIntroView];
    else
        question = [self.survey.questions objectAtIndex:previousQuestionIndex];
    
    // If we already have a previous question view, and we're just updating it
    if (self.previousQuestionView)
    {
        self.previousQuestionView.tag = previousQuestionIndex;
        [self.previousQuestionView setupViewWithQuestion:question isLastQuestion:NO delegate:self];
    }
    else
    {
        // If not, we should set up a new one
        if (self.reusableQuestionView)
        {
            self.previousQuestionView = self.reusableQuestionView;
            self.reusableQuestionView = nil;
        }
        else
        {
            self.previousQuestionView = [[LIOSurveyQuestionView alloc] initWithFrame:self.scrollView.bounds];
        }
        [self.scrollView addSubview:self.previousQuestionView];
        
        self.previousQuestionView.tag = previousQuestionIndex;
        [self.previousQuestionView setupViewWithQuestion:question isLastQuestion:NO delegate:self];
    }
    
    return YES;
}

- (BOOL)setupNextQuestionScrollView
{
    NSInteger numberOfQuestions = [self.survey.questions count];
    if (self.currentQuestionIndex > numberOfQuestions - 1)
    {
        self.nextQuestionView = nil;
        return NO;
    }
    
    BOOL foundNextPage = NO;
    
    NSInteger nextQuestionIndex = self.currentQuestionIndex;
    while (!foundNextPage)
    {
        // If we're at the last question, finish the survey
        if (nextQuestionIndex == numberOfQuestions - 1)
        {
            [self.nextQuestionView removeFromSuperview];
            self.nextQuestionView.transform = CGAffineTransformIdentity;
            self.nextQuestionView = nil;
            return NO;
        }
        
        // Mode to the next question, but check if we should show it taking into account logic issues
        nextQuestionIndex += 1;
        if ([self.survey shouldShowQuestion:nextQuestionIndex])
            foundNextPage = YES;
    }
    
    LIOSurveyQuestion *question = [self.survey.questions objectAtIndex:nextQuestionIndex];
    BOOL isLastQuestion = [self.survey isQuestionWithIndexLastQuestion:nextQuestionIndex];
    
    // If we already have a next question view, and we're just updating ity
    if (self.nextQuestionView)
    {
        self.nextQuestionView.tag = nextQuestionIndex;
        [self.nextQuestionView setupViewWithQuestion:question isLastQuestion:isLastQuestion delegate:self];
    }
    else
    {
        // If not, we should set up a new one
        if (self.reusableQuestionView)
        {
            self.nextQuestionView = self.reusableQuestionView;
            self.reusableQuestionView = nil;
        }
        else
        {
            self.nextQuestionView = [[LIOSurveyQuestionView alloc] initWithFrame:self.scrollView.bounds];
        }
        [self.scrollView addSubview:self.nextQuestionView];
        
        self.nextQuestionView.tag = nextQuestionIndex;
        [self.nextQuestionView setupViewWithQuestion:question isLastQuestion:isLastQuestion delegate:self];
        [self.nextQuestionView reloadTableViewDataIfNeeded];
    }
    
    return YES;
}

- (void)updateScrollView
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];

    CGSize contentSize = self.scrollView.contentSize;
    CGPoint contentOffset = self.scrollView.contentOffset;
    CGRect previousFrame = self.previousQuestionView.frame;
    CGRect currentFrame = self.currentQuestionView.frame;
    CGRect nextFrame = self.nextQuestionView.frame;
    
    CGFloat viewWidth = self.scrollView.bounds.size.width;
    
    if (!padUI)
    {
        if (self.previousQuestionView && self.nextQuestionView)
        {
            contentSize.width = viewWidth * 3;
            contentOffset.x = viewWidth;
            previousFrame.origin.x = 0;
            currentFrame.origin.x = viewWidth;
            nextFrame.origin.x = viewWidth * 2;
            
            previousFrame.size = self.view.bounds.size;
            nextFrame.size = self.view.bounds.size;
        }
        else
        {
            if (self.previousQuestionView)
            {
                contentSize.width = viewWidth * 2;
                contentOffset.x = viewWidth;
                previousFrame.origin.x = 0;
                currentFrame.origin.x = viewWidth;
                previousFrame.size = self.view.bounds.size;
            }
            if (self.nextQuestionView)
            {
                contentSize.width = viewWidth * 2;
                contentOffset.x = 0;
                currentFrame.origin.x = 0;
                nextFrame.origin.x = viewWidth;
                nextFrame.size = self.view.bounds.size;
            }
            if (!self.nextQuestionView && !self.previousQuestionView)
            {
                contentSize.width = viewWidth;
                contentOffset.x = 0;
                currentFrame.origin.x = 0;
                currentFrame.size = self.view.bounds.size;
            }
        }

        self.scrollView.contentSize = contentSize;
        self.scrollView.contentOffset = contentOffset;
        self.previousQuestionView.frame = previousFrame;
        self.currentQuestionView.frame = currentFrame;
        self.nextQuestionView.frame = nextFrame;
    }
    
    if (padUI)
    {
        self.currentQuestionView.transform = CGAffineTransformIdentity;
        self.currentQuestionView.frame = [self frameForIpadScrollView:LIOIpadSurveyQuestionCurrent];
        self.currentQuestionView.alpha = 1.0;

        self.nextQuestionView.transform = CGAffineTransformIdentity;
        self.nextQuestionView.frame = [self frameForIpadScrollView:LIOIpadSurveyQuestionNext];
        self.nextQuestionView.transform = CGAffineTransformMakeScale(LIOSurveyViewiPadNextQuestionScale, LIOSurveyViewiPadNextQuestionScale);
        self.nextQuestionView.alpha = LIOSurveyViewiPadNextQuestionAlpha;
        
        self.previousQuestionView.transform = CGAffineTransformIdentity;
        self.previousQuestionView.frame = [self frameForIpadScrollView:LIOIpadSurveyQuestionPrevious];
        self.previousQuestionView.transform = CGAffineTransformMakeScale(LIOSurveyViewiPadNextQuestionScale, LIOSurveyViewiPadNextQuestionScale);
        self.previousQuestionView.alpha = LIOSurveyViewiPadNextQuestionAlpha;
        
        [self.view bringSubviewToFront:self.currentQuestionView];
    }
    
}

- (CGRect)frameForIpadScrollView:(LIOIpadSurveyQuestion)surveyQuestion
{
    UIInterfaceOrientation currentInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    BOOL landscape = UIInterfaceOrientationIsLandscape(currentInterfaceOrientation);

    CGRect aFrame = CGRectZero;
    CGFloat offset;
    aFrame.origin.y = landscape ? 20 : 135;
    aFrame.size.width = landscape ? 400 : 450;
    aFrame.size.height = landscape ? 350 : 460;
    aFrame.origin.x = (self.view.bounds.size.width - aFrame.size.width)/2;

    switch (surveyQuestion) {
        case LIOIpadSurveyQuestionCurrent:
            break;
            
        case LIOIpadSurveyQuestionNext:
            offset = landscape ? LIOSurveyViewiPadNextQuestionOffsetLandscape : LIOSurveyViewiPadNextQuestionOffsetPortrait;
            aFrame.origin.x = (self.view.bounds.size.width - aFrame.size.width)/2 + self.view.bounds.size.width*offset;
            break;
            
        case LIOIpadSurveyQuestionPrevious:
            offset = landscape ? LIOSurveyViewiPadNextQuestionOffsetLandscape : LIOSurveyViewiPadNextQuestionOffsetPortrait;
            aFrame.origin.x = (self.view.bounds.size.width - aFrame.size.width)/2 - self.view.bounds.size.width*offset;
            break;
            
        case LIOIpadSurveyQuestionNextNext:
            aFrame.origin.x = self.view.bounds.size.width + aFrame.size.width;
            break;
            
        case LIOIpadSurveyQuestionPreviousPrevious:
            aFrame.origin.x = -self.view.bounds.size.width - aFrame.size.width;
            break;
            
        default:
            break;
    }
    
    return aFrame;
}

- (void)switchToPreviousQuestion
{
    self.isLastQuestion = NO;
    
    if (self.validationView)
    {
        [self.validationTimer stopTimer];
        [self validationTimerDidFire];
    }
    
    if (LIOSurveyQuestionViewKeyboard == self.currentQuestionView.questionViewType && LIOSurveyQuestionViewKeyboard == self.previousQuestionView.questionViewType)
        self.isAnimatingBetweenTwoKeyboardViews = YES;
    else
        self.isAnimatingBetweenTwoKeyboardViews = NO;
    
    [self.currentQuestionView endEditing:YES];
    [self.previousQuestionView setNeedsLayout];
    [self.previousQuestionView becomeFirstResponder];
    
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    if (!padUI)
    {
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            CGPoint contentOffset = self.scrollView.contentOffset;
            contentOffset.x = 0;
            self.scrollView.contentOffset = contentOffset;
        } completion:^(BOOL finished) {
            self.currentQuestionIndex = self.previousQuestionView.tag;
            self.pageControl.currentPage -= 1;
            
            LIOSurveyQuestionView *tempView = nil;
            if (self.nextQuestionView)
            {
                [self.nextQuestionView removeFromSuperview];
                tempView = self.nextQuestionView;
            }
            self.nextQuestionView = self.currentQuestionView;
            self.currentQuestionView = self.previousQuestionView;
            self.previousQuestionView = nil;
            [self setupPreviousQuestionScrollView];
            
            [self updateScrollView];
            
            if (tempView)
            {
                self.reusableQuestionView = tempView;
                self.reusableQuestionView.tag = -1000;
                
            }
            
            [self.nextQuestionView questionViewDidDisappear];
            self.survey.lastSeenQuestionIndex = self.currentQuestionIndex;
        }];
    }
    else
    {
        [self.view bringSubviewToFront:self.currentQuestionView];
        
        LIOSurveyQuestionView *tempView = self.nextQuestionView;
        self.nextQuestionView = self.currentQuestionView;
        self.currentQuestionView = self.previousQuestionView;
        self.previousQuestionView = nil;
        
        self.pageControl.currentPage -= 1;
        
        self.currentQuestionIndex = self.currentQuestionView.tag;
        [self setupPreviousQuestionScrollView];
        self.previousQuestionView.frame = [self frameForIpadScrollView:LIOIpadSurveyQuestionPreviousPrevious];
        [self.scrollView addSubview:self.previousQuestionView];
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self updateScrollView];
            tempView.frame = [self frameForIpadScrollView:LIOIpadSurveyQuestionNextNext];
        } completion:^(BOOL finished) {
            self.previousQuestionView.userInteractionEnabled = NO;
            self.currentQuestionView.userInteractionEnabled = YES;
            self.nextQuestionView.userInteractionEnabled = NO;
            
            [self.nextQuestionView questionViewDidDisappear];
            self.survey.lastSeenQuestionIndex = self.currentQuestionIndex;
            
            if (tempView)
            {
                [tempView removeFromSuperview];
                self.reusableQuestionView = tempView;
                self.reusableQuestionView.tag = -1000;
                self.reusableQuestionView.transform = CGAffineTransformIdentity;
            }
        }];
    }
}

- (void)switchToNextQuestion
{
    if (self.validationView)
    {
        [self.validationTimer stopTimer];
        [self validationTimerDidFire];
    }

    if (LIOSurveyQuestionViewKeyboard == self.currentQuestionView.questionViewType && LIOSurveyQuestionViewKeyboard == self.nextQuestionView.questionViewType)
        self.isAnimatingBetweenTwoKeyboardViews = YES;
    else
        self.isAnimatingBetweenTwoKeyboardViews = NO;
    
    [self.currentQuestionView endEditing:YES];
    [self.nextQuestionView reloadTableViewDataIfNeeded];
    [self.nextQuestionView setNeedsLayout];
    [self.nextQuestionView becomeFirstResponder];
    
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];

    if (!padUI)
    {
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            CGPoint contentOffset = self.scrollView.contentOffset;
            if (self.previousQuestionView)
            {
                contentOffset.x = self.scrollView.bounds.size.width * 2;
            }
            else
            {
                contentOffset.x = self.scrollView.bounds.size.width;
            }
            self.scrollView.contentOffset = contentOffset;
        } completion:^(BOOL finished) {
            self.currentQuestionIndex = self.nextQuestionView.tag;
            self.pageControl.currentPage += 1;
            
            LIOSurveyQuestionView *tempView = nil;
            if (self.previousQuestionView)
            {
                [self.previousQuestionView removeFromSuperview];
                tempView = self.previousQuestionView;
            }
            self.previousQuestionView = self.currentQuestionView;
            self.currentQuestionView = self.nextQuestionView;
            self.nextQuestionView = nil;
            self.isLastQuestion = ![self setupNextQuestionScrollView];
            
            [self updateScrollView];
            
            if (tempView)
            {
                self.reusableQuestionView = tempView;
                self.reusableQuestionView.tag = -1000;
            }
            
            [self.currentQuestionView questionViewDidAppear];
            [self.previousQuestionView questionViewDidDisappear];
            self.survey.lastSeenQuestionIndex = self.currentQuestionIndex;
        }];
    }
    else
    {
        [self.view bringSubviewToFront:self.currentQuestionView];

        LIOSurveyQuestionView *tempView = self.previousQuestionView;
        self.previousQuestionView = self.currentQuestionView;
        self.currentQuestionView = self.nextQuestionView;
        self.nextQuestionView = nil;

        self.pageControl.currentPage += 1;

        self.currentQuestionIndex = self.currentQuestionView.tag;
        self.isLastQuestion = ![self setupNextQuestionScrollView];
        self.nextQuestionView.frame = [self frameForIpadScrollView:LIOIpadSurveyQuestionNextNext];
        [self.scrollView addSubview:self.nextQuestionView];
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self updateScrollView];
            tempView.frame = [self frameForIpadScrollView:LIOIpadSurveyQuestionPreviousPrevious];
        } completion:^(BOOL finished) {
            self.previousQuestionView.userInteractionEnabled = NO;
            self.currentQuestionView.userInteractionEnabled = YES;
            self.nextQuestionView.userInteractionEnabled = NO;

            [self.currentQuestionView questionViewDidAppear];
            [self.previousQuestionView questionViewDidDisappear];
            self.survey.lastSeenQuestionIndex = self.currentQuestionIndex;

            if (tempView)
            {
                [tempView removeFromSuperview];
                self.reusableQuestionView = tempView;
                self.reusableQuestionView.tag = -1000;
                self.reusableQuestionView.transform = CGAffineTransformIdentity;
            }
        }];
    }
}

#pragma mark
#pragma mark Validation view methods

- (void)showAlertWithMessage:(NSString *)aMessage
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    [self.validationView removeFromSuperview];
    self.validationView = nil;
    
    self.validationView = [[LIOSurveyValidationView alloc] init];
    CGRect aFrame = self.validationView.frame;
    aFrame.origin.y = 0;
    aFrame.size.width = self.view.bounds.size.width;
    if (padUI)
    {
        aFrame.size.width = self.currentQuestionView.bounds.size.width - 2.0;
        aFrame.origin.x = 1.0;
        aFrame.origin.y = 1.0;
    }
    
    self.validationView.frame = aFrame;
    self.validationView.label.text = aMessage;
    self.validationView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    if (padUI)
    {
        [self.currentQuestionView addSubview:self.validationView];
        self.validationView.layer.cornerRadius = 3.0;
        self.validationView.clipsToBounds = YES;
    }
    else
    {
        [self.view addSubview:self.validationView];
    }
    
    [self.validationView layoutSubviews];
    [self.validationView showAnimated];
    
    [self.validationTimer stopTimer];
    self.validationTimer = [[LIOTimerProxy alloc] initWithTimeInterval:LIOSurveyViewControllerValidationDuration
                                                                target:self
                                                              selector:@selector(validationTimerDidFire)];
}


- (void)validationTimerDidFire
{
    [self.validationTimer stopTimer];
    self.validationTimer = nil;
    
    self.validationView.delegate = self;
    [self.validationView hideAnimated];
}

- (void)surveyValidationViewDidFinishDismissalAnimation:(LIOSurveyValidationView *)aView
{
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.validationView removeFromSuperview];
        self.validationView = nil;
    });
}

- (BOOL)validateAndRegisterCurrentAnswerAndShowAlert:(BOOL)showAlert
{
    if (self.currentQuestionIndex == LIOSurveyViewControllerIndexForIntroPage)
        return YES;
    
    LIOSurveyQuestion *currentQuestion = [self.survey.questions objectAtIndex:self.currentQuestionIndex];
    
    if (LIOSurveyQuestionDisplayTypeTextField == currentQuestion.displayType || LIOSurveyQuestionDisplayTypeTextArea == currentQuestion.displayType)
    {
        NSString* stringResponse = @"";
        if (LIOSurveyQuestionDisplayTypeTextField == currentQuestion.displayType)
        {
            stringResponse = self.currentQuestionView.textField.text;
        }
        if (LIOSurveyQuestionDisplayTypeTextArea == currentQuestion.displayType)
        {
            stringResponse = self.currentQuestionView.textView.text;
        }
        
        currentQuestion.lastKnownValue = stringResponse;
        
        if (0 == [stringResponse length])
        {
            // An empty response is okay for optional questions.
            if (NO == currentQuestion.mandatory)
            {
                self.survey.lastCompletedQuestionIndex = self.currentQuestionIndex;
                return YES;
            }
            else
            {
                if (showAlert)
                    [self showAlertWithMessage:LIOLocalizedString(@"LIOSurveyViewController.ResponseAlertBody")];
                return NO;
            }
        }
        else
        {
            BOOL validated = NO;
            
            if (LIOSurveyQuestionValidationTypeAlphanumeric == currentQuestion.validationType) {
                NSString* responseAfterEliminatingSpaces = [stringResponse stringByReplacingOccurrencesOfString:@" " withString:@""];
                if (![responseAfterEliminatingSpaces isEqualToString:@""])
                {
                    validated = YES;
                }
                else
                {
                    if (showAlert)
                        [self showAlertWithMessage:LIOLocalizedString(@"LIOSurveyViewController.ResponseAlertBody")];
                }
            }
            
            if (LIOSurveyQuestionValidationTypeNumeric == currentQuestion.validationType)
            {
                NSCharacterSet *unwantedCharacters = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
                if ([stringResponse rangeOfCharacterFromSet:unwantedCharacters].location == NSNotFound)
                {
                    validated = YES;
                }
                else
                {
                    if (showAlert)
                        [self showAlertWithMessage:LIOLocalizedString(@"LIOSurveyViewController.NumericValidationAlertBody")];
                }
            }
            
            if (LIOSurveyQuestionValidationTypeEmail == currentQuestion.validationType)
            {
                BOOL stricterFilter = YES; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
                NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
                NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
                NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
                NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
                if ([emailTest evaluateWithObject:stringResponse])
                {
                    validated = YES;
                }
                else
                {
                    if (showAlert)
                        [self showAlertWithMessage:LIOLocalizedString(@"LIOSurveyViewController.EmailValidationAlertBody")];
                }
            }
            
            if (validated)
            {
                [self.survey registerAnswerObject:stringResponse withQuestionIndex:self.currentQuestionIndex];
                
                self.survey.lastCompletedQuestionIndex = self.currentQuestionIndex;
                
                return YES;
            }
            else
            {
                return NO;
            }
        }
    }
    else
    {
        // We have to make an exception for checkbox type questions, because they can be submitted without an answer
        if (currentQuestion.mandatory && 0 == [currentQuestion.selectedIndices count] && currentQuestion.displayType != LIOSurveyQuestionDisplayTypeMultiselect)
        {
            [self.survey clearAnswerForQuestionIndex:self.currentQuestionIndex];
            if (showAlert)
                [self showAlertWithMessage:LIOLocalizedString(@"LIOSurveyViewController.ResponseAlertBody")];
            return NO;
        }
        else
        {
            if (LIOSurveyQuestionDisplayTypeMultiselect == currentQuestion.displayType)
            {
                // If this is a checkbox (=multiselect), and the user hasn't checked anything, we should report an empty string
                if (currentQuestion.selectedIndices.count == 0)
                {
                    [self.survey registerAnswerObject:@"" withQuestionIndex:self.currentQuestionIndex];
                }
                else
                {
                    NSMutableArray* selectedAnswers = [NSMutableArray array];
                    for (NSIndexPath* indexPath in currentQuestion.selectedIndices)
                    {
                        LIOSurveyPickerEntry* selectedPickerEntry = (LIOSurveyPickerEntry*)[currentQuestion.pickerEntries objectAtIndex:indexPath.row];
                        [selectedAnswers addObject:selectedPickerEntry.label];
                    }
                    [self.survey registerAnswerObject:selectedAnswers withQuestionIndex:self.currentQuestionIndex];
                }
            }
            
            if (LIOSurveyQuestionDisplayTypePicker == currentQuestion.displayType)
            {
                if (currentQuestion.selectedIndices.count == 1)
                {
                    NSIndexPath* indexPath = (NSIndexPath*)[currentQuestion.selectedIndices objectAtIndex:0];
                    LIOSurveyPickerEntry* selectedPickerEntry = (LIOSurveyPickerEntry*)[currentQuestion.pickerEntries objectAtIndex:indexPath.row];
                    [self.survey registerAnswerObject:selectedPickerEntry.label withQuestionIndex:self.currentQuestionIndex];
                }
                else
                {
                    [self.survey clearAnswerForQuestionIndex:self.currentQuestionIndex];
                }
            }
            
            self.survey.lastCompletedQuestionIndex = self.currentQuestionIndex;
            
            return YES;
        }
    }
    
    return NO;
}

#pragma mark
#pragma mark UITableViewDelegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LIOSurveyQuestionView *questionView = [(LIOSurveyQuestionView *)[tableView superview] superview];
    NSInteger tableViewQuestionIndex = questionView.tag;
    LIOSurveyQuestion *question = [self.survey.questions objectAtIndex:tableViewQuestionIndex];
    LIOSurveyPickerEntry* entry = [question.pickerEntries objectAtIndex:indexPath.row];
    
    UIFont *font = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementSurveyList];
    
    CGSize expectedSize = [entry.label sizeWithFont:font constrainedToSize:CGSizeMake(tableView.bounds.size.width - 50.0, 9999) lineBreakMode:UILineBreakModeWordWrap];
    
    return expectedSize.height + 33.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    LIOSurveyQuestionView *questionView = [(LIOSurveyQuestionView *)[tableView superview] superview];
    NSInteger tableViewQuestionIndex = questionView.tag;
    
    if (tableViewQuestionIndex > self.survey.questions.count)
    {
        NSLog(@"Breakpoint");
        return 0;
    }
    
    LIOSurveyQuestion *question = [self.survey.questions objectAtIndex:tableViewQuestionIndex];
    return question.pickerEntries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    UIView* scrollView = [[tableView superview] superview];
    NSInteger tableViewQuestionIndex = scrollView.tag;
    
    static NSString *CellIdentifier = @"TableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        
        UILabel* textLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 17.0, tableView.bounds.size.width - 40.0, 19.0)];
        textLabel.tag = LIOSurveyViewTableCellLabelTag;
        textLabel.font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementSurveyList];
        textLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementSurveyList];
        textLabel.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:textLabel];
                
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIImageView* backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(9.0, 0, tableView.bounds.size.width - 20.0, 55.0)];
        backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        cell.backgroundView = backgroundImageView;
    }
    
    LIOSurveyQuestion *question = [self.survey.questions objectAtIndex:tableViewQuestionIndex];
    
    // This is an error check, but should not ever be a problem
    if (indexPath.row > question.pickerEntries.count)
    {
        NSLog(@"Breakpoint - check this");
        return cell;
    }
    
    LIOSurveyPickerEntry* pickerEntry = [question.pickerEntries objectAtIndex:indexPath.row];    
    
    UILabel* textLabel = (UILabel*)[cell.contentView viewWithTag:LIOSurveyViewTableCellLabelTag];
    
    BOOL isRowSelected = NO;
    for (NSIndexPath* selectedIndexPath in question.selectedIndices)
    {
        if (indexPath.row == selectedIndexPath.row)
        {
            isRowSelected = YES;
        }
    }
    
    if (!padUI)
    {
        if (isRowSelected)
        {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            textLabel.font = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementSurveyList];
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            textLabel.font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementSurveyList];
        }
    }
    else
    {
        if (tableViewQuestionIndex == self.currentQuestionIndex)
        {
            if (isRowSelected)
            {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                textLabel.font = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementSurveyList];
            }
            else
            {
                cell.accessoryType = UITableViewCellAccessoryNone;
                textLabel.font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementSurveyList];
            }
        }
    }
    
    textLabel.text = pickerEntry.label;
    textLabel.numberOfLines = 0;
    CGSize expectedSize = [pickerEntry.label sizeWithFont:textLabel.font constrainedToSize:CGSizeMake(tableView.bounds.size.width - 40.0, 9999) lineBreakMode:UILineBreakModeWordWrap];
    CGRect aFrame = textLabel.frame;
    aFrame.size = expectedSize;
    textLabel.frame = aFrame;
    
    return cell;
}

- (void)starRatingView:(LIOStarRatingView *)aView didUpdateRating:(NSInteger)aRating
{
    LIOSurveyQuestionView *questionView = (LIOSurveyQuestionView *)[[aView superview] superview];
    NSInteger tableViewQuestionIndex = questionView.tag;
    
    LIOSurveyQuestion *question = [self.survey.questions objectAtIndex:tableViewQuestionIndex];

    [question.selectedIndices removeAllObjects];
    if (aRating > 0 && aRating < 6)
        [question.selectedIndices addObject:[NSIndexPath indexPathForRow:(5 - aRating) inSection:0]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LIOSurveyQuestionView *questionView = [(LIOSurveyQuestionView *)[tableView superview] superview];
    NSInteger tableViewQuestionIndex = questionView.tag;
    
    LIOSurveyQuestion *question = [self.survey.questions objectAtIndex:tableViewQuestionIndex];
    
    NSIndexPath* existingIndexPath = nil;
    for (NSIndexPath* selectedIndexPath in question.selectedIndices)
    {
        if (indexPath.row == selectedIndexPath.row)
        {
            existingIndexPath = selectedIndexPath;
        }
    }
    
    if (LIOSurveyQuestionDisplayTypePicker == question.displayType)
    {
        if (existingIndexPath) // Deselect
        {
            [question.selectedIndices removeObject:existingIndexPath];
        }
        else
        {
            [question.selectedIndices removeAllObjects];
            [question.selectedIndices addObject:indexPath];
        }
    }
    
    if (LIOSurveyQuestionDisplayTypeMultiselect == question.displayType)
    {
        if (existingIndexPath) // Deselect
        {
            [question.selectedIndices removeObject:existingIndexPath];
        }
        else
        {
            [question.selectedIndices addObject:indexPath];
        }
    }
    
    [self surveyQuestionViewAnswerDidChange:self.currentQuestionView];
    
    [tableView reloadData];
}

#pragma mark
#pragma mark UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self surveyQuestionViewDidTapNextButton:self.currentQuestionView];
    
    return NO;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
	if ([text isEqualToString:@"\n"]) {
        [self surveyQuestionViewDidTapNextButton:self.currentQuestionView];
        return NO;
    }
    return YES;
}

#pragma mark -
#pragma mark Rotation Methods

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self updateScrollView];
    
    if (self.currentQuestionView)
    {
        [self.currentQuestionView reloadTableViewDataIfNeeded];
        [self.currentQuestionView setNeedsLayout];
    }
    if (self.nextQuestionView)
    {
        [self.nextQuestionView reloadTableViewDataIfNeeded];
        [self.nextQuestionView setNeedsLayout];
    }
    if (self.previousQuestionView)
    {
        [self.previousQuestionView reloadTableViewDataIfNeeded];
        [self.previousQuestionView setNeedsLayout];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    if (!padUI)
    {
        CGRect frame = self.currentQuestionView.scrollView.frame;
        frame.size.width = self.view.frame.size.width;
        frame.size.height = self.view.bounds.size.height - self.lastKeyboardHeight;
        self.currentQuestionView.scrollView.frame = frame;
        
        frame = self.nextQuestionView.scrollView.frame;
        frame.size.width = self.view.frame.size.width;
        frame.size.height = self.view.bounds.size.height - self.lastKeyboardHeight;
        self.nextQuestionView.scrollView.frame = frame;
        
        frame = self.previousQuestionView.scrollView.frame;
        frame.size.width = self.view.frame.size.width;
        frame.size.height = self.view.bounds.size.height - self.lastKeyboardHeight;
        self.previousQuestionView.scrollView.frame = frame;
        
    }
    
    
}


@end
