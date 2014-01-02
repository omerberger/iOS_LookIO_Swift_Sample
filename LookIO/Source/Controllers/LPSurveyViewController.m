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

@interface LPSurveyViewController ()

@property (nonatomic, strong) LIOSurvey *survey;

@property (nonatomic, assign) NSInteger currentQuestionIndex;
@property (nonatomic, assign) NSInteger nextQuestionIndex;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) LIOSurveyQuestionView *currentQuestionView;
@property (nonatomic, strong) LIOSurveyQuestionView *nextQuestionView;
@property (nonatomic, strong) LIOSurveyQuestionView *previousQuestionView;
@property (nonatomic, strong) LIOSurveyQuestionView *reusableQuestionView;

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
        
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scrollView];
    
    self.currentQuestionIndex = 0;
    LIOSurveyQuestion *firstQuestion = [self.survey.questions objectAtIndex:self.currentQuestionIndex];
    
    self.currentQuestionView = [[LIOSurveyQuestionView alloc] initWithFrame:self.scrollView.bounds];
    [self.currentQuestionView setupViewWithQuestion:firstQuestion existingResponse:nil isLastQuestion:NO delegate:self];
    [self.scrollView addSubview:self.currentQuestionView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)keyboardWillShow:(NSNotification *)note
{
    
}

- (void)keyboardWillHide:(NSNotification *)note
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

- (void)finishSurveyView {
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
                [delegate surveyViewDidFinish:self];
            }];
        } else {
            [delegate surveyViewDidFinish:self];
        }
    }
}

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

-(void)bounceViewRight {
    isAnimatingTransition = YES;
    
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    if (!padUI) {
        [UIView animateWithDuration:0.1 animations:^{
            CGRect aFrame = currentScrollView.frame;
            aFrame.origin.x -= 30;
            currentScrollView.frame = aFrame;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 animations:^{
                CGRect aFrame = currentScrollView.frame;
                aFrame.origin.x += 40;
                currentScrollView.frame = aFrame;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.1 animations:^{
                    CGRect aFrame = currentScrollView.frame;
                    aFrame.origin.x -= 30;
                    currentScrollView.frame = aFrame;
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.1 animations:^{
                        CGRect aFrame = currentScrollView.frame;
                        aFrame.origin.x += 20;
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
}

-(void)switchToNextQuestion {
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    NSInteger numberOfQuestions = [currentSurvey.questions count];
    
    if (currentQuestionIndex > numberOfQuestions - 1)
        return;
    
    if (![self validateAndRegisterCurrentAnswer]) {
        [self bounceViewRight];
        return;
    } else {
        BOOL foundNextPage = NO;
        
        while (!foundNextPage) {
            // If we're at the last question, finish the survey
            if (currentQuestionIndex == numberOfQuestions - 1) {
                [self finishSurveyView];
                return;
            }
            
            // Mode to the next question, but check if we should show it taking into account logic issues
            currentQuestionIndex += 1;
            if ([[LIOSurveyManager sharedSurveyManager] shouldShowQuestion:currentQuestionIndex surveyType:currentSurveyType])
                foundNextPage = YES;
        }
        
        
        if (validationView) {
            [validationTimer stopTimer];
            [self validationTimerDidFire];
        }
        
        UIScrollView* nextQuestionScrollView = [self scrollViewForQuestionAtIndex:currentQuestionIndex];
        nextQuestionScrollView.transform = CGAffineTransformMakeTranslation(self.bounds.size.width, 0.0);
        [self addSubview:nextQuestionScrollView];
        [self setNeedsLayout];
        
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

#pragma mark
#pragma mark Validation view methods

- (void)showAlertWithMessage:(NSString *)aMessage
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    UIInterfaceOrientation currentInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    BOOL landscape = UIInterfaceOrientationIsLandscape(currentInterfaceOrientation);
    
    [validationView removeFromSuperview];
    [validationView release];
    validationView = nil;
    
    validationView = [[LIOSurveyValidationView alloc] init];
    CGRect aFrame = validationView.frame;
    aFrame.origin.y = (landscape || padUI) ? 0 : 32;
    validationView.verticallyMirrored = YES;
    aFrame.size.width = self.bounds.size.width;
    if (padUI) {
        aFrame.size.width = currentScrollView.bounds.size.width - 15;
        aFrame.origin.x = currentScrollView.bounds.origin.x + 8;
        aFrame.origin.y = currentScrollView.bounds.origin.y + 4;
    }
    
    // iOS 7.0: Add another 20px on top for the status bar
    if (LIOIsUIKitFlatMode())
        if (![[UIApplication sharedApplication] isStatusBarHidden] && !padUI)
            aFrame.origin.y += 20.0;
    
    validationView.frame = aFrame;
    validationView.label.text = aMessage;
    validationView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    if (padUI) {
        [currentScrollView addSubview:validationView];
        validationView.layer.cornerRadius = 5.0;
        validationView.clipsToBounds = YES;
    }
    else
        [self addSubview:validationView];
    
    [validationView layoutSubviews];
    [validationView showAnimated];
    
    [validationTimer stopTimer];
    [validationTimer release];
    validationTimer = [[LIOTimerProxy alloc] initWithTimeInterval:LIOSurveyViewControllerValidationDuration
                                                           target:self
                                                         selector:@selector(validationTimerDidFire)];
}

- (void)validationTimerDidFire
{
    [validationTimer stopTimer];
    [validationTimer release];
    validationTimer = nil;
    
    validationView.delegate = self;
    [validationView hideAnimated];
}

- (void)surveyValidationViewDidFinishDismissalAnimation:(LIOSurveyValidationView *)aView
{
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [validationView removeFromSuperview];
        [validationView release];
        validationView = nil;
    });
}

- (BOOL)validateAndRegisterCurrentAnswer {
    if (currentQuestionIndex == LIOIndexForSurveyIntroPage)
        return YES;
    
    LIOSurveyQuestion *currentQuestion = [currentSurvey.questions objectAtIndex:currentQuestionIndex];
    LIOSurveyManager *surveyManager = [LIOSurveyManager sharedSurveyManager];
    
    if (LIOSurveyQuestionDisplayTypeTextField == currentQuestion.displayType || LIOSurveyQuestionDisplayTypeTextArea == currentQuestion.displayType)
    {
        NSString* stringResponse = @"";
        if (LIOSurveyQuestionDisplayTypeTextField == currentQuestion.displayType) {
            UITextField* inputField = (UITextField*)[currentScrollView viewWithTag:LIOSurveyViewInputTextFieldTag];
            stringResponse = inputField.text;
        }
        if (LIOSurveyQuestionDisplayTypeTextArea == currentQuestion.displayType) {
            UITextView* textView = (UITextView*)[currentScrollView viewWithTag:LIOSurveyViewInputTextViewTag];
            stringResponse = textView.text;
        }
        
        if (0 == [stringResponse length])
        {
            // An empty response is okay for optional questions.
            if (NO == currentQuestion.mandatory) {
                if (currentSurveyType == LIOSurveyManagerSurveyTypePre)
                    surveyManager.lastCompletedQuestionIndexPre = currentQuestionIndex;
                if (currentSurveyType == LIOSurveyManagerSurveyTypePost)
                    surveyManager.lastCompletedQuestionIndexPost = currentQuestionIndex;
                if (currentSurveyType == LIOSurveyManagerSurveyTypeOffline)
                    surveyManager.lastCompletedQuestionIndexOffline = currentQuestionIndex;
                
                return YES;
            }
            else
            {
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
                    validated = YES;
                else
                    [self showAlertWithMessage:LIOLocalizedString(@"LIOSurveyViewController.ResponseAlertBody")];
            }
            
            if (LIOSurveyQuestionValidationTypeNumeric == currentQuestion.validationType)
            {
                NSCharacterSet *unwantedCharacters = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
                if ([stringResponse rangeOfCharacterFromSet:unwantedCharacters].location == NSNotFound)
                    validated = YES;
                else
                    [self showAlertWithMessage:LIOLocalizedString(@"LIOSurveyViewController.NumericValidationAlertBody")];
            }
            
            if (LIOSurveyQuestionValidationTypeEmail == currentQuestion.validationType)
            {
                BOOL stricterFilter = YES; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
                NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
                NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
                NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
                NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
                if ([emailTest evaluateWithObject:stringResponse])
                    validated = YES;
                else
                    [self showAlertWithMessage:LIOLocalizedString(@"LIOSurveyViewController.EmailValidationAlertBody")];
            }
            
            if (validated)
            {
                [surveyManager registerAnswerObject:stringResponse forSurveyType:currentSurveyType withQuestionIndex:currentQuestionIndex];
                if (currentSurveyType == LIOSurveyManagerSurveyTypePre)
                    surveyManager.lastCompletedQuestionIndexPre = currentQuestionIndex;
                if (currentSurveyType == LIOSurveyManagerSurveyTypePost)
                    surveyManager.lastCompletedQuestionIndexPost = currentQuestionIndex;
                if (currentSurveyType == LIOSurveyManagerSurveyTypeOffline)
                    surveyManager.lastCompletedQuestionIndexOffline = currentQuestionIndex;
                return YES;
            } else
                return NO;
        }
    }
    else
    {
        // We have to make an exception for checkbox type questions, because they can be submitted without an answer
        if (currentQuestion.mandatory && 0 == [selectedIndices count] && currentQuestion.displayType != LIOSurveyQuestionDisplayTypeMultiselect)
        {
            [self showAlertWithMessage:LIOLocalizedString(@"LIOSurveyViewController.ResponseAlertBody")];
            return NO;
        }
        else
        {
            if (LIOSurveyQuestionDisplayTypeMultiselect) {
                // If this is a checkbox (=multiselect), and the user hasn't checked anything, we should report an empty string
                if (selectedIndices.count == 0)
                    [surveyManager registerAnswerObject:@"" forSurveyType:currentSurveyType withQuestionIndex:currentQuestionIndex];
                else {
                    NSMutableArray* selectedAnswers = [NSMutableArray array];
                    for (NSIndexPath* indexPath in selectedIndices) {
                        LIOSurveyPickerEntry* selectedPickerEntry = (LIOSurveyPickerEntry*)[currentQuestion.pickerEntries objectAtIndex:indexPath.row];
                        [selectedAnswers addObject:selectedPickerEntry.label];
                    }
                    [surveyManager registerAnswerObject:selectedAnswers forSurveyType:currentSurveyType withQuestionIndex:currentQuestionIndex];
                }
            }
            
            if (LIOSurveyQuestionDisplayTypePicker) {
                if (selectedIndices.count == 1) {
                    NSIndexPath* indexPath = (NSIndexPath*)[selectedIndices objectAtIndex:0];
                    LIOSurveyPickerEntry* selectedPickerEntry = (LIOSurveyPickerEntry*)[currentQuestion.pickerEntries objectAtIndex:indexPath.row];
                    [surveyManager registerAnswerObject:selectedPickerEntry.label forSurveyType:currentSurveyType withQuestionIndex:currentQuestionIndex];
                }
            }
            
            if (currentSurveyType == LIOSurveyManagerSurveyTypePre)
                surveyManager.lastCompletedQuestionIndexPre = currentQuestionIndex;
            if (currentSurveyType == LIOSurveyManagerSurveyTypePost)
                surveyManager.lastCompletedQuestionIndexPost = currentQuestionIndex;
            if (currentSurveyType == LIOSurveyManagerSurveyTypeOffline)
                surveyManager.lastCompletedQuestionIndexOffline = currentQuestionIndex;
            return YES;
        }
    }
    
    return NO;
}

#pragma mark
#pragma mark UITableViewDelegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIView* scrollView = tableView.superview;
    NSInteger tableViewQuestionIndex = scrollView.tag;
    
    BOOL isRowSelected = NO;
    
    for (NSIndexPath* selectedIndexPath in selectedIndices) {
        if (indexPath.row == selectedIndexPath.row) {
            isRowSelected = YES;
        }
    }
    
    UIFont* font;
    if ([[LIOLookIOManager sharedLookIOManager] selectedChatTheme] == kLPChatThemeClassic) {
        font = [UIFont fontWithName:@"HelveticaNeue" size:17.0];
        if (isRowSelected)
            font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0];
    } else {
        font = [UIFont systemFontOfSize:17.0];
        if (isRowSelected)
            font = [UIFont boldSystemFontOfSize:17.0];
    }
    
    
    LIOSurveyQuestion *question = [currentSurvey.questions objectAtIndex:tableViewQuestionIndex];
    LIOSurveyPickerEntry* entry = [question.pickerEntries objectAtIndex:indexPath.row];
    
    CGSize expectedSize = [entry.label sizeWithFont:font constrainedToSize:CGSizeMake(tableView.bounds.size.width - 40.0, 9999) lineBreakMode:UILineBreakModeWordWrap];
    return expectedSize.height + 33.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    UIView* scrollView = tableView.superview;
    NSInteger tableViewQuestionIndex = scrollView.tag;
    
    LIOSurveyQuestion *question = [currentSurvey.questions objectAtIndex:tableViewQuestionIndex];
    return question.pickerEntries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    UIView* scrollView = tableView.superview;
    NSInteger tableViewQuestionIndex = scrollView.tag;
    
    static NSString *CellIdentifier = @"TableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.backgroundColor = [UIColor clearColor];
        
        UILabel* textLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 17.0, tableView.bounds.size.width - 40.0, 19.0)];
        if ([LIOLookIOManager sharedLookIOManager].selectedChatTheme == kLPChatThemeFlat) {
            textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:17.0];
            textLabel.textColor = [UIColor darkGrayColor];
            
        }
        else {
            textLabel.font = [UIFont systemFontOfSize:17.0];
            textLabel.textColor = [UIColor colorWithWhite:41.0/255.0 alpha:1.0];
        }
        textLabel.backgroundColor = [UIColor clearColor];
        textLabel.tag = LIOSurveyViewTableCellLabelTag;
        [cell.contentView addSubview:textLabel];
        [textLabel release];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIImageView* backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(9.0, 0, tableView.bounds.size.width - 20.0, 55.0)];
        backgroundImageView.tag = LIOSurveyViewTableCellBackgroundTag;
        backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        cell.backgroundView = backgroundImageView;
        [backgroundImageView release];
    }
    
    LIOSurveyQuestion *question = [currentSurvey.questions objectAtIndex:tableViewQuestionIndex];
    LIOSurveyPickerEntry* pickerEntry = [question.pickerEntries objectAtIndex:indexPath.row];
    
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
    
    UILabel* textLabel = (UILabel*)[cell.contentView viewWithTag:LIOSurveyViewTableCellLabelTag];
    
    BOOL isRowSelected = NO;
    
    for (NSIndexPath* selectedIndexPath in selectedIndices) {
        if (indexPath.row == selectedIndexPath.row) {
            isRowSelected = YES;
        }
    }
    
    if (!padUI) {
        if (isRowSelected) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            if ([LIOLookIOManager sharedLookIOManager].selectedChatTheme == kLPChatThemeFlat)
                textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0];
            else
                textLabel.font = [UIFont boldSystemFontOfSize:17.0];
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            if ([LIOLookIOManager sharedLookIOManager].selectedChatTheme == kLPChatThemeFlat)
                textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:17.0];
            else
                textLabel.font = [UIFont systemFontOfSize:17.0];        }
    }
    else {
        if (tableViewQuestionIndex == currentQuestionIndex) {
            if (isRowSelected) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                if ([LIOLookIOManager sharedLookIOManager].selectedChatTheme == kLPChatThemeFlat)
                    textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0];
                else
                    textLabel.font = [UIFont boldSystemFontOfSize:17.0];
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
                if ([LIOLookIOManager sharedLookIOManager].selectedChatTheme == kLPChatThemeFlat)
                    textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:17.0];
                else
                    textLabel.font = [UIFont systemFontOfSize:17.0];
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

-(void)starRatingView:(LIOStarRatingView *)aView didUpdateRating:(NSInteger)aRating {
    [selectedIndices removeAllObjects];
    if (aRating > 0 && aRating < 6)
        [selectedIndices addObject:[NSIndexPath indexPathForRow:(5 - aRating) inSection:0]];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIView* scrollView = tableView.superview;
    NSInteger tableViewQuestionIndex = scrollView.tag;
    
    LIOSurveyQuestion *question = [currentSurvey.questions objectAtIndex:tableViewQuestionIndex];
    
    NSIndexPath* existingIndexPath = nil;
    
    for (NSIndexPath* selectedIndexPath in selectedIndices) {
        if (indexPath.row == selectedIndexPath.row) {
            existingIndexPath = selectedIndexPath;
        }
    }
    
    if (LIOSurveyQuestionDisplayTypePicker == question.displayType) {
        if (existingIndexPath) // Deselect
            [selectedIndices removeObject:existingIndexPath];
        else {
            [selectedIndices removeAllObjects];
            [selectedIndices addObject:indexPath];
        }
    }
    
    if (LIOSurveyQuestionDisplayTypeMultiselect == question.displayType) {
        if (existingIndexPath) // Deselect
            [selectedIndices removeObject:existingIndexPath];
        else
            [selectedIndices addObject:indexPath];
    }
    
    [tableView reloadData];
    [self rejiggerSurveyScrollView:currentScrollView];
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

#pragma mark
#pragma mark Keyboard notifications

- (void)keyboardWillShow:(NSNotification *)aNotification
{
    NSDictionary *userInfo = [aNotification userInfo];
    
    UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    NSTimeInterval animationDuration;
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [animationDurationValue getValue:&animationDuration];
    
    UIViewAnimationCurve animationCurve;
    NSValue *animationCurveValue = [userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    [animationCurveValue getValue:&animationCurve];
    
    NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardBounds = [keyboardBoundsValue CGRectValue];
    
    keyboardHeight = keyboardBounds.size.height;
    if (UIInterfaceOrientationIsLandscape(actualOrientation))
        keyboardHeight = keyboardBounds.size.width;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
    
    [self rejiggerPageControlFrame];
    
    [UIView commitAnimations];
    
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
    NSDictionary *userInfo = [aNotification userInfo];
    
    NSTimeInterval animationDuration;
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [animationDurationValue getValue:&animationDuration];
    
    UIViewAnimationCurve animationCurve;
    NSValue *animationCurveValue = [userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    [animationCurveValue getValue:&animationCurve];
    
    keyboardHeight = 0.0;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
    
    [self rejiggerPageControlFrame];
    
    [UIView commitAnimations];
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isDescendantOfView:currentScrollView]) {
        return NO; // ignore the touch
    }
    
    return YES; // handle the touch
}
 
 */

@end
