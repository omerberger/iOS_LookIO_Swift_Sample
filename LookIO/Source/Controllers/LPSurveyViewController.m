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

#import "LIOTimerProxy.h"
#import "LIOBundleManager.h"

#define LIOSurveyViewControllerIndexForIntroPage   -1
#define LIOSurveyViewControllerValidationDuration   5

#define LIOSurveyViewTableCellLabelTag 100


@interface LPSurveyViewController () <UIScrollViewDelegate>

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

@property (nonatomic, strong) NSMutableArray* selectedIndices;
@property (nonatomic, strong) UIImageView* previousQuestionImageView, *nextQuestionImageView, *currentQuestionImageView;
@property (nonatomic, strong) UIPageControl* pageControl;
@property (nonatomic, strong) UIView* backgroundDismissableArea;

@property (nonatomic, strong) UITapGestureRecognizer* tapGestureRecognizer, *iPadBackgroundGestureRecognizer;

@property (nonatomic, assign) BOOL isAnimatingTransition;
/*
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
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.delegate = self;
    self.scrollView.scrollEnabled = NO;
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scrollView];
    
    self.selectedIndices = [[NSMutableArray alloc] init];
    
    self.currentQuestionIndex = LIOSurveyViewControllerIndexForIntroPage;
    LIOSurveyQuestion *introQuestion = [self.survey questionForIntroView];
    
    self.currentQuestionView = [[LIOSurveyQuestionView alloc] initWithFrame:self.scrollView.bounds];
    self.currentQuestionView.tag = self.currentQuestionIndex;
    [self.currentQuestionView setupViewWithQuestion:introQuestion existingResponse:nil isLastQuestion:NO delegate:self];
    [self.scrollView addSubview:self.currentQuestionView];
    [self.currentQuestionView becomeFirstResponder];
    
    // Set up the next question; If we get a FALSE response, we're at the last question
    self.isLastQuestion = ![self setupNextQuestionScrollView];
    self.previousQuestionView = nil;
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
    return;
    
    CGRect frame = self.scrollView.frame;
    frame.size.height = self.view.bounds.size.height - self.lastKeyboardHeight;
    self.scrollView.frame = frame;
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
        [self.currentQuestionView setNeedsLayout];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    // Acquire keyboard info
    NSDictionary *info = [notification userInfo];
    
    UIViewAnimationCurve curve;
    [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&curve];
    
    NSTimeInterval duration;
    [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&duration];
    
    CGRect keyboardRect;
    [[info objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardRect];
    
    UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;
    self.lastKeyboardHeight = UIInterfaceOrientationIsPortrait(actualOrientation) ? keyboardRect.size.height : keyboardRect.size.width;
    
    [UIView animateWithDuration:duration delay:0.0 options:(curve << 16) animations:^{
        [self updateSubviewFrames];
    } completion:^(BOOL finished) {
        [self.currentQuestionView setNeedsLayout];
    }];
}

#pragma mark -
#pragma mark LIOSurveyQuestionView Delegate

- (void)surveyQuestionViewAnswerDidChange:(LIOSurveyQuestionView *)surveyQuestionView
{
    [self validateAndRegisterCurrentAnswerAndShowAlert:NO];
}

- (void)surveyQuestionViewDidTapNextButton:(LIOSurveyQuestionView *)surveyQuestionView
{
    if (self.isLastQuestion)
    {
        [self completeSurvey];
        return;
    }
    
    BOOL isAnswerValid = [self validateAndRegisterCurrentAnswerAndShowAlert:YES];
    if (isAnswerValid)
    {
        [self switchToNextQuestion];
    }
}

- (void)surveyQuestionViewDidTapCancelButton:(LIOSurveyQuestionView *)surveyQuestionView
{
    
}

/*
 -(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
 if (buttonIndex == 1)
 [self cancelSurveyView];
 }
 
 - (void)cancelSurveyView {
 if (delegate) {
 pageControl.alpha = 0.0;
 BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
 
 if (!padUI) {
 [self.superview endEditing:YES];
 
 [UIView animateWithDuration:0.3 animations:^{
 currentScrollView.transform = CGAffineTransformMakeTranslation(0.0, -self.bounds.size.height/2);
 currentScrollView.alpha = 0.0;
 if (kLPChatThemeFlat == [LIOLookIOManager sharedLookIOManager].selectedChatTheme) {
 backgroundDismissableArea.alpha = 0.0;
 }
 } completion:^(BOOL finished) {
 [delegate surveyViewDidCancel:self];
 }];
 } else {
 [delegate surveyViewDidCancel:self];
 }
 }
 }
 
 */

- (void)completeSurvey {
    self.pageControl.alpha = 0.0;
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    if (!padUI)
    {
        [self.view endEditing:YES];
        [UIView animateWithDuration:0.3 animations:^{
            self.scrollView.transform = CGAffineTransformMakeTranslation(0.0, -self.scrollView.bounds.size.height/2);
            self.scrollView.alpha = 0.0;
        } completion:^(BOOL finished) {
            [self.delegate surveyViewController:self didCompleteSurvey:self.survey];
        }];
    } else
    {
        [self.delegate surveyViewController:self didCompleteSurvey:self.survey];
    }
}

/*
 
 -(void)handleTapGesture:(UITapGestureRecognizer*)sender {
 if (self.currentSurveyType == LIOSurveyManagerSurveyTypeOffline || self.currentSurveyType == LIOSurveyManagerSurveyTypePost) {
 alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOSurveyView.LeaveSurveyAlertTitle") message:LIOLocalizedString(@"LIOSurveyView.LeaveSurveyAlertBody") delegate:self cancelButtonTitle:LIOLocalizedString(@"LIOSurveyView.LeaveSurveyAlertNoButton") otherButtonTitles:LIOLocalizedString(@"LIOSurveyView.LeaveSurveyAlertYesButton"), nil];
 [alertView show];
 
 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
 } else {
 if (!isAnimatingTransition && !isAnimatingEntrance)
 [self cancelSurveyView];
 }
 }
 
 - (void) applicationDidEnterBackground:(id) sender {
 // Remove alertView if going to background
 if (alertView) {
 [alertView dismissWithClickedButtonIndex:-1 animated:NO];
 }
 }
 
 -(void)bounceViewLeft {
 isAnimatingTransition = YES;
 
 BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
 
 if (!padUI) {
 [UIView animateWithDuration:0.1 animations:^{
 CGRect aFrame = currentScrollView.frame;
 aFrame.origin.x += 30;
 currentScrollView.frame = aFrame;
 } completion:^(BOOL finished) {
 [UIView animateWithDuration:0.1 animations:^{
 CGRect aFrame = currentScrollView.frame;
 aFrame.origin.x -= 40;
 currentScrollView.frame = aFrame;
 } completion:^(BOOL finished) {
 [UIView animateWithDuration:0.1 animations:^{
 CGRect aFrame = currentScrollView.frame;
 aFrame.origin.x += 30;
 currentScrollView.frame = aFrame;
 } completion:^(BOOL finished) {
 [UIView animateWithDuration:0.1 animations:^{
 CGRect aFrame = currentScrollView.frame;
 aFrame.origin.x -= 20;
 currentScrollView.frame = aFrame;
 } completion:^(BOOL finished) {
 isAnimatingTransition = NO;
 }];
 }];
 }];
 }];
 } else {
 [UIView animateWithDuration:0.15 animations:^{
 CGRect aFrame = currentScrollView.frame;
 aFrame.origin.x += 70;
 currentScrollView.frame = aFrame;
 if (nextQuestionImageView) {
 CGRect aFrame = nextQuestionImageView.frame;
 aFrame.origin.x += 35;
 nextQuestionImageView.frame = aFrame;
 }
 if (previousQuestionImageView) {
 CGRect aFrame = previousQuestionImageView.frame;
 aFrame.origin.x += 35;
 previousQuestionImageView.frame = aFrame;
 }
 } completion:^(BOOL finished) {
 [UIView animateWithDuration:0.2 delay:0.05 options:UIViewAnimationOptionCurveEaseInOut animations:^{
 CGRect aFrame = currentScrollView.frame;
 aFrame.origin.x -= 70;
 currentScrollView.frame = aFrame;
 if (nextQuestionImageView) {
 CGRect aFrame = nextQuestionImageView.frame;
 aFrame.origin.x -= 35;
 nextQuestionImageView.frame = aFrame;
 }
 if (previousQuestionImageView) {
 CGRect aFrame = previousQuestionImageView.frame;
 aFrame.origin.x -= 35;
 previousQuestionImageView.frame = aFrame;
 }
 
 } completion:^(BOOL finished) {
 isAnimatingTransition = NO;
 }];
 }];
 }
 }
 
 */

- (void)bounceViewRight
{
    self.isAnimatingTransition = YES;
    
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
                        self.isAnimatingTransition = NO;
                    }];
                }];
            }];
        }];
    }
    
    /*
     else {
     [UIView animateWithDuration:0.15 animations:^{
     CGRect aFrame = currentScrollView.frame;
     aFrame.origin.x -= 70;
     currentScrollView.frame = aFrame;
     if (nextQuestionImageView) {
     CGRect aFrame = nextQuestionImageView.frame;
     aFrame.origin.x -= 35;
     nextQuestionImageView.frame = aFrame;
     }
     if (previousQuestionImageView) {
     CGRect aFrame = previousQuestionImageView.frame;
     aFrame.origin.x -= 35;
     previousQuestionImageView.frame = aFrame;
     }
     } completion:^(BOOL finished) {
     [UIView animateWithDuration:0.2 delay:0.05 options:UIViewAnimationOptionCurveEaseInOut animations:^{
     CGRect aFrame = currentScrollView.frame;
     aFrame.origin.x += 70;
     currentScrollView.frame = aFrame;
     if (nextQuestionImageView) {
     CGRect aFrame = nextQuestionImageView.frame;
     aFrame.origin.x += 35;
     nextQuestionImageView.frame = aFrame;
     }
     if (previousQuestionImageView) {
     CGRect aFrame = previousQuestionImageView.frame;
     aFrame.origin.x += 35;
     previousQuestionImageView.frame = aFrame;
     }
     
     } completion:^(BOOL finished) {
     isAnimatingTransition = NO;
     }];
     }];
     }
     */
}

- (BOOL)setupNextQuestionScrollView
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
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
            self.nextQuestionView = nil;
            return NO;
        }
        
        // Mode to the next question, but check if we should show it taking into account logic issues
        nextQuestionIndex += 1;
        if ([self.survey shouldShowQuestion:nextQuestionIndex])
            foundNextPage = YES;
    }
    
    if (self.validationView)
    {
        [self.validationTimer stopTimer];
        [self validationTimerDidFire];
    }
    
    LIOSurveyQuestion *question = [self.survey.questions objectAtIndex:nextQuestionIndex];
    
    // If we already have a next question view, and we're just updating ity
    if (self.nextQuestionView)
    {
        self.nextQuestionView.tag = nextQuestionIndex;
        [self.nextQuestionView setupViewWithQuestion:question existingResponse:nil isLastQuestion:NO delegate:self];
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
        [self.nextQuestionView setupViewWithQuestion:question existingResponse:nil isLastQuestion:NO delegate:self];
    }
    
    return YES;
}

- (void)updateScrollView
{
    CGSize contentSize = self.scrollView.contentSize;
    CGPoint contentOffset = self.scrollView.contentOffset;
    CGRect previousFrame = self.previousQuestionView.frame;
    CGRect currentFrame = self.currentQuestionView.frame;
    CGRect nextFrame = self.nextQuestionView.frame;
    
    CGFloat viewWidth = self.scrollView.bounds.size.width;
    
    if (self.previousQuestionView && self.nextQuestionView)
    {
        contentSize.width = viewWidth * 3;
        contentOffset.x = viewWidth;
        previousFrame.origin.x = 0;
        currentFrame.origin.x = viewWidth;
        nextFrame.origin.x = viewWidth * 2;
    }
    else
    {
        if (self.previousQuestionView)
        {
            contentSize.width = viewWidth * 2;
            contentOffset.x = viewWidth;
            previousFrame.origin.x = 0;
            currentFrame.origin.x = viewWidth;
        }
        if (self.nextQuestionView)
        {
            contentSize.width = viewWidth * 2;
            contentOffset.x = 0;
            currentFrame.origin.x = 0;
            nextFrame.origin.x = viewWidth;
        }
        if (!self.nextQuestionView && !self.previousQuestionView)
        {
            contentSize.width = viewWidth;
            contentOffset.x = 0;
            currentFrame.origin.x = 0;
        }
    }
    
    self.scrollView.contentSize = contentSize;
    self.scrollView.contentOffset = contentOffset;
    self.previousQuestionView.frame = previousFrame;
    self.currentQuestionView.frame = currentFrame;
    self.nextQuestionView.frame = nextFrame;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    
}

- (void)switchToNextQuestion
{
    [self.currentQuestionView endEditing:YES];
    [self.nextQuestionView setNeedsLayout];
    [self.nextQuestionView becomeFirstResponder];
    
    [UIView animateWithDuration:0.3 animations:^{
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
        self.currentQuestionIndex += 1;
        
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
        }
        
        [self.selectedIndices removeAllObjects];
    }];
    
    /*
     
     if (padUI) {
     isAnimatingTransition = YES;
     
     CGAffineTransform scale = CGAffineTransformMakeScale(LIOSurveyViewiPadNextQuestionScale, LIOSurveyViewiPadNextQuestionScale);
     CGAffineTransform translate = CGAffineTransformMakeTranslation(self.bounds.size.width*LIOSurveyViewiPadNextQuestionOffset, 0.0);
     nextQuestionScrollView.transform = CGAffineTransformConcat(scale, translate);
     nextQuestionScrollView.alpha = LIOSurveyViewiPadNextQuestionAlpha;
     
     if (nextQuestionImageView) {
     [nextQuestionImageView removeFromSuperview];
     nextQuestionImageView = nil;
     }
     
     if (currentQuestionIndex < currentSurvey.questions.count) {
     int futureQuestionIndex = currentQuestionIndex;
     BOOL foundFutureQuestion = NO;
     
     while (futureQuestionIndex < currentSurvey.questions.count - 1 && !foundFutureQuestion) {
     futureQuestionIndex += 1;
     if ([[LIOSurveyManager sharedSurveyManager] shouldShowQuestion:futureQuestionIndex surveyType:currentSurveyType])
     foundFutureQuestion = YES;
     }
     
     if (foundFutureQuestion) {
     UIScrollView* futureQuestionScrollView = [self scrollViewForQuestionAtIndex:futureQuestionIndex];
     
     nextQuestionImageView = [[UIImageView alloc] initWithFrame:currentScrollView.frame];
     CGAffineTransform scale = CGAffineTransformMakeScale(0.2, 0.2);
     CGAffineTransform translate = CGAffineTransformMakeTranslation(self.bounds.size.width*LIOSurveyViewiPadNextQuestionOffset, 0.0);
     nextQuestionImageView.transform = CGAffineTransformConcat(scale, translate);
     nextQuestionImageView.alpha = 0.0;
     [self addSubview:nextQuestionImageView];
     [nextQuestionImageView release];
     
     UIGraphicsBeginImageContext(futureQuestionScrollView.frame.size);
     [[futureQuestionScrollView layer] renderInContext:UIGraphicsGetCurrentContext()];
     nextQuestionImageView.image = UIGraphicsGetImageFromCurrentImageContext();
     UIGraphicsEndImageContext();
     }
     }
     
     if (currentQuestionImageView) {
     [currentQuestionImageView removeFromSuperview];
     currentQuestionImageView = nil;
     }
     currentQuestionImageView = [[UIImageView alloc] initWithFrame:currentScrollView.frame];
     
     UIGraphicsBeginImageContext(currentScrollView.frame.size);
     [[currentScrollView layer] renderInContext:UIGraphicsGetCurrentContext()];
     currentQuestionImageView.image = UIGraphicsGetImageFromCurrentImageContext();
     UIGraphicsEndImageContext();
     
     [currentScrollView removeFromSuperview];
     currentScrollView = nil;
     
     [self addSubview:currentQuestionImageView];
     [currentQuestionImageView release];
     
     [UIView animateWithDuration:0.3 animations:^{
     nextQuestionScrollView.transform = CGAffineTransformIdentity;
     nextQuestionScrollView.alpha = 1.0;
     
     CGAffineTransform scale = CGAffineTransformMakeScale(LIOSurveyViewiPadNextQuestionScale, LIOSurveyViewiPadNextQuestionScale);
     CGAffineTransform translate = CGAffineTransformMakeTranslation(-self.bounds.size.width*LIOSurveyViewiPadNextQuestionOffset, 0.0);
     currentQuestionImageView.transform = CGAffineTransformConcat(scale, translate);
     currentQuestionImageView.alpha = LIOSurveyViewiPadNextQuestionAlpha;
     
     if (previousQuestionImageView) {
     CGAffineTransform scale = CGAffineTransformMakeScale(0.2, 0.2);
     CGAffineTransform translate = CGAffineTransformMakeTranslation(-self.bounds.size.width*LIOSurveyViewiPadNextQuestionOffset, 0.0);
     previousQuestionImageView.transform = CGAffineTransformConcat(scale, translate);
     previousQuestionImageView.alpha = 0.0;
     }
     
     if (nextQuestionImageView) {
     CGAffineTransform scale = CGAffineTransformMakeScale(LIOSurveyViewiPadNextQuestionScale, LIOSurveyViewiPadNextQuestionScale);
     CGAffineTransform translate = CGAffineTransformMakeTranslation(self.bounds.size.width*LIOSurveyViewiPadNextQuestionOffset, 0.0);
     nextQuestionImageView.transform = CGAffineTransformConcat(scale, translate);
     nextQuestionImageView.alpha = LIOSurveyViewiPadNextQuestionAlpha;
     }
     
     pageControl.numberOfPages = [[LIOSurveyManager sharedSurveyManager] numberOfQuestionsWithLogicForSurveyType:currentSurveyType] + 1;
     pageControl.currentPage = [[LIOSurveyManager sharedSurveyManager] realIndexWithLogicOfQuestionAtIndex:currentQuestionIndex forSurveyType:currentSurveyType] + 1;
     
     [self rejiggerPageControlFrame];
     
     } completion:^(BOOL finished) {
     currentScrollView = nextQuestionScrollView;
     isAnimatingTransition = NO;
     
     [previousQuestionImageView removeFromSuperview];
     previousQuestionImageView = nil;
     
     previousQuestionImageView = currentQuestionImageView;
     currentQuestionImageView = nil;
     
     LIOSurveyQuestion *currentQuestion = [currentSurvey.questions objectAtIndex:currentQuestionIndex];
     if (currentQuestion.shouldUseStarRatingView) {
     LIOStarRatingView* starRatingView = (LIOStarRatingView*)[currentScrollView viewWithTag:LIOSurveyViewStarRatingViewTag];
     if (starRatingView)
     [starRatingView showIntroAnimation];
     }
     }];
     } else {
     isAnimatingTransition = YES;
     [UIView animateWithDuration:0.3 animations:^{
     [currentScrollView endEditing:YES];
     
     nextQuestionScrollView.transform = CGAffineTransformIdentity;
     currentScrollView.transform = CGAffineTransformMakeTranslation(-self.bounds.size.width, 0.0);
     
     pageControl.numberOfPages = [[LIOSurveyManager sharedSurveyManager] numberOfQuestionsWithLogicForSurveyType:currentSurveyType] + 1;
     pageControl.currentPage = [[LIOSurveyManager sharedSurveyManager] realIndexWithLogicOfQuestionAtIndex:currentQuestionIndex forSurveyType:currentSurveyType] + 1;
     
     [self rejiggerPageControlFrame];
     
     } completion:^(BOOL finished) {
     [currentScrollView removeFromSuperview];
     currentScrollView = nil;
     currentScrollView = nextQuestionScrollView;
     
     isAnimatingTransition = NO;
     
     LIOSurveyQuestion *currentQuestion = [currentSurvey.questions objectAtIndex:currentQuestionIndex];
     if (currentQuestion.shouldUseStarRatingView) {
     LIOStarRatingView* starRatingView = (LIOStarRatingView*)[currentScrollView viewWithTag:LIOSurveyViewStarRatingViewTag];
     if (starRatingView)
     [starRatingView showIntroAnimation];
     }
     }];
     }
     }
     }
     
     */
}

/*
 
 -(void)switchToPreviousQuestion {
 BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
 BOOL foundPreviousPage = NO;
 
 while (!foundPreviousPage) {
 // If we're at the intro screen, just bounce the screen
 if (currentQuestionIndex == LIOIndexForSurveyIntroPage) {
 [self bounceViewLeft];
 return;
 }
 
 // Mode to the previous question, but check if we should show it taking into account logic issues
 currentQuestionIndex -= 1;
 
 if (currentQuestionIndex == LIOIndexForSurveyIntroPage)
 foundPreviousPage = YES;
 else
 if ([[LIOSurveyManager sharedSurveyManager] shouldShowQuestion:currentQuestionIndex surveyType:currentSurveyType])
 foundPreviousPage = YES;
 }
 
 if (validationView) {
 [validationTimer stopTimer];
 [self validationTimerDidFire];
 }
 
 UIScrollView* previousQuestionScrollView;
 
 if (LIOIndexForSurveyIntroPage == currentQuestionIndex) {
 previousQuestionScrollView = [self scrollViewForIntroView];
 }
 else
 previousQuestionScrollView = [self scrollViewForQuestionAtIndex:currentQuestionIndex];
 
 previousQuestionScrollView.transform = CGAffineTransformMakeTranslation(-self.bounds.size.width, 0.0);
 [self addSubview:previousQuestionScrollView];
 
 if (padUI) {
 isAnimatingTransition = YES;
 
 CGAffineTransform scale = CGAffineTransformMakeScale(LIOSurveyViewiPadNextQuestionScale, LIOSurveyViewiPadNextQuestionScale);
 CGAffineTransform translate = CGAffineTransformMakeTranslation(-self.bounds.size.width*LIOSurveyViewiPadNextQuestionOffset, 0.0);
 previousQuestionScrollView.transform = CGAffineTransformConcat(scale, translate);
 previousQuestionScrollView.alpha = LIOSurveyViewiPadNextQuestionAlpha;
 
 if (previousQuestionImageView) {
 [previousQuestionImageView removeFromSuperview];
 previousQuestionImageView = nil;
 }
 
 if (currentQuestionIndex > -1) {
 BOOL foundPastQuestion = NO;
 int pastQuestionIndex = currentQuestionIndex;
 while (!foundPastQuestion && pastQuestionIndex >= -1) {
 pastQuestionIndex -= 1;
 
 // If we're at the intro screen, just bounce the screen
 if (pastQuestionIndex == LIOIndexForSurveyIntroPage) {
 foundPastQuestion = YES;
 }
 else {
 if ([[LIOSurveyManager sharedSurveyManager] shouldShowQuestion:pastQuestionIndex surveyType:currentSurveyType])
 foundPastQuestion = YES;
 }
 }
 
 if (foundPastQuestion) {
 UIScrollView* pastQuestionScrollView;
 if (pastQuestionIndex == -1)
 pastQuestionScrollView = [self scrollViewForIntroView];
 else
 pastQuestionScrollView = [self scrollViewForQuestionAtIndex:pastQuestionIndex];
 
 previousQuestionImageView = [[UIImageView alloc] initWithFrame:currentScrollView.frame];
 CGAffineTransform scale = CGAffineTransformMakeScale(0.2, 0.2);
 CGAffineTransform translate = CGAffineTransformMakeTranslation(-self.bounds.size.width*LIOSurveyViewiPadNextQuestionOffset, 0.0);
 previousQuestionImageView.transform = CGAffineTransformConcat(scale, translate);
 previousQuestionImageView.alpha = 0.0;
 [self addSubview:previousQuestionImageView];
 [previousQuestionImageView release];
 
 UIGraphicsBeginImageContext(pastQuestionScrollView.frame.size);
 [[pastQuestionScrollView layer] renderInContext:UIGraphicsGetCurrentContext()];
 previousQuestionImageView.image = UIGraphicsGetImageFromCurrentImageContext();
 UIGraphicsEndImageContext();
 }
 }
 
 if (currentQuestionImageView) {
 [currentQuestionImageView removeFromSuperview];
 currentQuestionImageView = nil;
 }
 currentQuestionImageView = [[UIImageView alloc] initWithFrame:currentScrollView.frame];
 
 UIGraphicsBeginImageContext(currentScrollView.frame.size);
 [[currentScrollView layer] renderInContext:UIGraphicsGetCurrentContext()];
 currentQuestionImageView.image = UIGraphicsGetImageFromCurrentImageContext();
 UIGraphicsEndImageContext();
 
 [currentScrollView removeFromSuperview];
 currentScrollView = nil;
 
 [self addSubview:currentQuestionImageView];
 [currentQuestionImageView release];
 
 [UIView animateWithDuration:0.3 animations:^{
 previousQuestionScrollView.transform = CGAffineTransformIdentity;
 previousQuestionScrollView.alpha = 1.0;
 
 CGAffineTransform scale = CGAffineTransformMakeScale(LIOSurveyViewiPadNextQuestionScale, LIOSurveyViewiPadNextQuestionScale);
 CGAffineTransform translate = CGAffineTransformMakeTranslation(self.bounds.size.width*LIOSurveyViewiPadNextQuestionOffset, 0.0);
 currentQuestionImageView.transform = CGAffineTransformConcat(scale, translate);
 currentQuestionImageView.alpha = LIOSurveyViewiPadNextQuestionAlpha;
 
 if (previousQuestionImageView) {
 CGAffineTransform scale = CGAffineTransformMakeScale(LIOSurveyViewiPadNextQuestionScale, LIOSurveyViewiPadNextQuestionScale);
 CGAffineTransform translate = CGAffineTransformMakeTranslation(-self.bounds.size.width*LIOSurveyViewiPadNextQuestionOffset, 0.0);
 previousQuestionImageView.transform = CGAffineTransformConcat(scale, translate);
 previousQuestionImageView.alpha = LIOSurveyViewiPadNextQuestionAlpha;
 }
 
 if (nextQuestionImageView) {
 CGAffineTransform scale = CGAffineTransformMakeScale(0.2, 0.2);
 CGAffineTransform translate = CGAffineTransformMakeTranslation(self.bounds.size.width*LIOSurveyViewiPadNextQuestionOffset, 0.0);
 nextQuestionImageView.transform = CGAffineTransformConcat(scale, translate);
 nextQuestionImageView.alpha = 0.0;
 }
 
 pageControl.numberOfPages = [[LIOSurveyManager sharedSurveyManager] numberOfQuestionsWithLogicForSurveyType:currentSurveyType] + 1;
 
 if (currentQuestionIndex == LIOIndexForSurveyIntroPage)
 pageControl.currentPage = 0;
 else
 pageControl.currentPage = [[LIOSurveyManager sharedSurveyManager] realIndexWithLogicOfQuestionAtIndex:currentQuestionIndex forSurveyType:currentSurveyType] + 1;
 
 [self rejiggerPageControlFrame];
 
 
 } completion:^(BOOL finished) {
 currentScrollView = previousQuestionScrollView;
 isAnimatingTransition = NO;
 
 [nextQuestionImageView removeFromSuperview];
 nextQuestionImageView = nil;
 
 nextQuestionImageView = currentQuestionImageView;
 currentQuestionImageView = nil;
 
 
 }];
 }
 else {
 
 isAnimatingTransition = YES;
 [UIView animateWithDuration:0.3 animations:^{
 [currentScrollView endEditing:YES];
 
 previousQuestionScrollView.transform = CGAffineTransformIdentity;
 currentScrollView.transform = CGAffineTransformMakeTranslation(self.bounds.size.width, 0.0);
 
 pageControl.numberOfPages = [[LIOSurveyManager sharedSurveyManager] numberOfQuestionsWithLogicForSurveyType:currentSurveyType] + 1;
 
 if (currentQuestionIndex == LIOIndexForSurveyIntroPage)
 pageControl.currentPage = 0;
 else
 pageControl.currentPage = [[LIOSurveyManager sharedSurveyManager] realIndexWithLogicOfQuestionAtIndex:currentQuestionIndex forSurveyType:currentSurveyType] + 1;
 
 [self rejiggerPageControlFrame];
 } completion:^(BOOL finished) {
 [currentScrollView removeFromSuperview];
 currentScrollView = nil;
 currentScrollView = previousQuestionScrollView;
 
 isAnimatingTransition = NO;
 }];
 }
 }
 
 */

#pragma mark
#pragma mark Validation view methods

- (void)showAlertWithMessage:(NSString *)aMessage
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    UIInterfaceOrientation currentInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    BOOL landscape = UIInterfaceOrientationIsLandscape(currentInterfaceOrientation);
    
    [self.validationView removeFromSuperview];
    self.validationView = nil;
    
    self.validationView = [[LIOSurveyValidationView alloc] init];
    CGRect aFrame = self.validationView.frame;
    aFrame.origin.y = (landscape || padUI) ? 0 : 32;
    self.validationView.verticallyMirrored = YES;
    aFrame.size.width = self.view.bounds.size.width;
    if (padUI)
    {
        aFrame.size.width = self.currentQuestionView.bounds.size.width - 15;
        aFrame.origin.x = self.currentQuestionView.bounds.origin.x + 8;
        aFrame.origin.y = self.currentQuestionView.bounds.origin.y + 4;
    }
    
    self.validationView.frame = aFrame;
    self.validationView.label.text = aMessage;
    self.validationView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    if (padUI)
    {
        [self.currentQuestionView addSubview:self.validationView];
        self.validationView.layer.cornerRadius = 5.0;
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
        if (currentQuestion.mandatory && 0 == [self.selectedIndices count] && currentQuestion.displayType != LIOSurveyQuestionDisplayTypeMultiselect)
        {
            if (showAlert)
                [self showAlertWithMessage:LIOLocalizedString(@"LIOSurveyViewController.ResponseAlertBody")];
            return NO;
        }
        else
        {
            if (LIOSurveyQuestionDisplayTypeMultiselect == currentQuestion.displayType)
            {
                // If this is a checkbox (=multiselect), and the user hasn't checked anything, we should report an empty string
                if (self.selectedIndices.count == 0)
                {
                    [self.survey registerAnswerObject:@"" withQuestionIndex:self.currentQuestionIndex];
                }
                else
                {
                    NSMutableArray* selectedAnswers = [NSMutableArray array];
                    for (NSIndexPath* indexPath in self.selectedIndices)
                    {
                        LIOSurveyPickerEntry* selectedPickerEntry = (LIOSurveyPickerEntry*)[currentQuestion.pickerEntries objectAtIndex:indexPath.row];
                        [selectedAnswers addObject:selectedPickerEntry.label];
                    }
                    [self.survey registerAnswerObject:selectedAnswers withQuestionIndex:self.currentQuestionIndex];
                }
            }
            
            if (LIOSurveyQuestionDisplayTypePicker == currentQuestion.displayType)
            {
                if (self.selectedIndices.count == 1)
                {
                    NSIndexPath* indexPath = (NSIndexPath*)[self.selectedIndices objectAtIndex:0];
                    LIOSurveyPickerEntry* selectedPickerEntry = (LIOSurveyPickerEntry*)[currentQuestion.pickerEntries objectAtIndex:indexPath.row];
                    [self.survey registerAnswerObject:selectedPickerEntry.label withQuestionIndex:self.currentQuestionIndex];
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
    LIOSurveyQuestionView *questionView = (LIOSurveyQuestionView *)[tableView superview];
    NSInteger tableViewQuestionIndex = questionView.tag;
    
    BOOL isRowSelected = NO;
    
    for (NSIndexPath* selectedIndexPath in self.selectedIndices)
    {
        if (indexPath.row == selectedIndexPath.row)
        {
            isRowSelected = YES;
        }
    }
    
    UIFont* font = [UIFont fontWithName:@"HelveticaNeue" size:17.0];
    if (isRowSelected)
        font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0];
    
    LIOSurveyQuestion *question = [self.survey.questions objectAtIndex:tableViewQuestionIndex];
    LIOSurveyPickerEntry* entry = [question.pickerEntries objectAtIndex:indexPath.row];
    
    CGSize expectedSize = [entry.label sizeWithFont:font constrainedToSize:CGSizeMake(tableView.bounds.size.width - 40.0, 9999) lineBreakMode:UILineBreakModeWordWrap];
    
    return expectedSize.height + 33.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    LIOSurveyQuestionView *questionView = (LIOSurveyQuestionView *)[tableView superview];
    NSInteger tableViewQuestionIndex = questionView.tag;
    
    LIOSurveyQuestion *question = [self.survey.questions objectAtIndex:tableViewQuestionIndex];
    return question.pickerEntries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    UIView* scrollView = tableView.superview;
    NSInteger tableViewQuestionIndex = scrollView.tag;
    
    static NSString *CellIdentifier = @"TableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        
        UILabel* textLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 17.0, tableView.bounds.size.width - 40.0, 19.0)];
        textLabel.tag = LIOSurveyViewTableCellLabelTag;
        textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:17.0];
        textLabel.textColor = [UIColor darkGrayColor];
        textLabel.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:textLabel];
                
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIImageView* backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(9.0, 0, tableView.bounds.size.width - 20.0, 55.0)];
        backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        cell.backgroundView = backgroundImageView;
        [backgroundImageView release];
    }
    
    LIOSurveyQuestion *question = [self.survey.questions objectAtIndex:tableViewQuestionIndex];
    LIOSurveyPickerEntry* pickerEntry = [question.pickerEntries objectAtIndex:indexPath.row];
    
    
    // TODO Design tableView
    /*
     UIImageView* backgroundImageView = (UIImageView*)cell.backgroundView;
     UIImage *backgroundImage;
     
     if (indexPath.row == 0) {
     if ([self tableView:tableView numberOfRowsInSection:0] == 1)
     backgroundImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableSurveyTableSingleCell"];
     else
     backgroundImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableSurveyTableTopCell"];
     } else {
     if (indexPath.row == question.pickerEntries.count - 1)
     backgroundImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableSurveyTableBottomCell"];
     else
     backgroundImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableSurveyTableMiddleCell"];
     }
     UIImage *stretchableBackgroundImage = [backgroundImage stretchableImageWithLeftCapWidth:142 topCapHeight:10];
     backgroundImageView.image = stretchableBackgroundImage;
     */
    
    UILabel* textLabel = (UILabel*)[cell.contentView viewWithTag:LIOSurveyViewTableCellLabelTag];
    
    BOOL isRowSelected = NO;
    for (NSIndexPath* selectedIndexPath in self.selectedIndices)
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
            textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0];
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:17.0];
        }
    }
    else
    {
        if (tableViewQuestionIndex == self.currentQuestionIndex)
        {
            if (isRowSelected)
            {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0];
            }
            else
            {
                cell.accessoryType = UITableViewCellAccessoryNone;
                textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:17.0];
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
    [self.selectedIndices removeAllObjects];
    if (aRating > 0 && aRating < 6)
        [self.selectedIndices addObject:[NSIndexPath indexPathForRow:(5 - aRating) inSection:0]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LIOSurveyQuestionView *questionView = (LIOSurveyQuestionView *)[tableView superview];
    NSInteger tableViewQuestionIndex = questionView.tag;
    
    LIOSurveyQuestion *question = [self.survey.questions objectAtIndex:tableViewQuestionIndex];
    
    NSIndexPath* existingIndexPath = nil;
    for (NSIndexPath* selectedIndexPath in self.selectedIndices)
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
            [self.selectedIndices removeObject:existingIndexPath];
        }
        else
        {
            [self.selectedIndices removeAllObjects];
            [self.selectedIndices addObject:indexPath];
        }
    }
    
    if (LIOSurveyQuestionDisplayTypeMultiselect == question.displayType)
    {
        if (existingIndexPath) // Deselect
        {
            [self.selectedIndices removeObject:existingIndexPath];
        }
        else
        {
            [self.selectedIndices addObject:indexPath];
        }
    }
    
    [tableView reloadData];
}

#pragma mark
#pragma mark UITextField delegate methods

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self switchToNextQuestion];
    
    return NO;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
{
	if ([text isEqualToString:@"\n"]) {
        [self switchToNextQuestion];
        return NO;
    }
    return YES;
}

#pragma mark -
#pragma mark Rotation Methods

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self updateScrollView];
}

@end
