//
//  LIOSurveyView.m
//  LookIO
//
//  Created by Yaron Karasik on 5/30/13.
//
//

#import "LIOSurveyView.h"
#import "LIOSurveyManager.h"
#import "LIOSurveyTemplate.h"
#import "LIOSurveyQuestion.h"
#import "LIOBundleManager.h"
#import "LIOSurveyPickerEntry.h"
#import "LIOSurveyValidationView.h"
#import "LIOTimerProxy.h"
#import "LIOStarRatingView.h"

#import <QuartzCore/QuartzCore.h>

#define LIOSurveyViewPageControlHeight          15.0
#define LIOSurveyViewTopMarginPortrait          70.0
#define LIOSurveyViewTopMarginLandscape         10.0
#define LIOSurveyViewSideMargin                 10.0
#define LIOSurveyViewPageControlOriginY         265.0

#define LIOSurveyViewIntroButtonMargin          15.0
#define LIOSurveyViewIntroTopMarginPortrait     90.0
#define LIOSurveyViewIntroTopMarginLandscape    50.0

#define LIOSurveyViewTitleLabelTag              1001
#define LIOSurveyViewInputTextFieldTag          1002
#define LIOSurveyViewInputBackgroundTag         1003
#define LIOSurveyViewTableViewTag               1004
#define LIOSurveyViewButtonTag                  1005
#define LIOSurveyViewTableCellBackgroundTag     1006
#define LIOSurveyViewTableCellLabelTag          1007
#define LIOSurveyViewInputTextViewTag           1008
#define LIOSurveyViewStarRatingViewTag          1009

#define LIOSurveyViewIntroHeaderLabel           1101
#define LIOSurveyViewIntroRequiredLabel         1102
#define LIOSurveyViewIntroNextButton            1103
#define LIOSurveyViewIntroCancelButton          1104
#define LIOSurveyViewIntroNeedHelpLabel         1105
#define LIOSurveyViewIntroLiveChatButton        1106

#define LIOSurveyViewControllerValidationDuration 5.0

#define LIOIndexForSurveyIntroPage  -1

@implementation LIOSurveyView

@synthesize delegate, currentSurvey, headerString, currentQuestionIndex,currentSurveyType;

#pragma mark
#pragma mark Initial setup methods

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
                
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [currentScrollView removeFromSuperview];
    currentScrollView = nil;
    
    [pageControl removeFromSuperview];
    pageControl = nil;
    
    [backgroundDismissableArea removeFromSuperview];
    backgroundDismissableArea = nil;

    delegate = nil;
    
    currentSurvey = nil;
    
    [headerString release];
    headerString = nil;
    
    [selectedIndices removeAllObjects];
    [selectedIndices release];
    selectedIndices = nil;

    leftSwipeGestureRecognizer = nil;
    rightSwipeGestureRecognizer = nil;
    tapGestureRecognizer = nil;

    [validationView removeFromSuperview];
    [validationView release];
    validationView = nil;
    
    [validationTimer stopTimer];
    [validationTimer release];
    validationTimer = nil;
    
    [super dealloc];
}

-(void)setupViews {
    leftSwipeGestureRecognizer = [[[UISwipeGestureRecognizer alloc]
                                   initWithTarget:self action:@selector(handleLeftSwipeGesture:)] autorelease];
    leftSwipeGestureRecognizer.direction =  UISwipeGestureRecognizerDirectionLeft;
    [self addGestureRecognizer:leftSwipeGestureRecognizer];
    
    rightSwipeGestureRecognizer = [[[UISwipeGestureRecognizer alloc]
                                    initWithTarget:self action:@selector(handleRightSwipeGesture:)] autorelease];
    rightSwipeGestureRecognizer.direction =  UISwipeGestureRecognizerDirectionRight;
    [self addGestureRecognizer:rightSwipeGestureRecognizer];
    
    tapGestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)] autorelease];
    [backgroundDismissableArea addGestureRecognizer:tapGestureRecognizer];
    
    if (LIOIndexForSurveyIntroPage == currentQuestionIndex) {
//        if (currentSurveyType == LIOSurveyManagerSurveyTypePost)
//            currentScrollView = [self scrollViewForRatingView];
//        else
            currentScrollView = [self scrollViewForIntroView];
    }
    else
        currentScrollView = [self scrollViewForQuestionAtIndex:currentQuestionIndex];
    
    currentScrollView.transform = CGAffineTransformMakeTranslation(0.0, -self.bounds.size.height);
    currentScrollView.alpha = 0.0;
    [self addSubview:currentScrollView];

    CGRect pageControlFrame;
    pageControlFrame.origin.x = 0;
    pageControlFrame.origin.y = self.bounds.size.height - 20.0;
    pageControlFrame.size.width = self.bounds.size.width;
    pageControlFrame.size.height = 20.0;
    
    pageControl = [[UIPageControl alloc] initWithFrame:pageControlFrame];
    pageControl.numberOfPages = [[LIOSurveyManager sharedSurveyManager] numberOfQuestionsWithLogicForSurveyType:currentSurveyType] + 1;
    if (currentQuestionIndex == LIOIndexForSurveyIntroPage)
        pageControl.currentPage = 0;
    else
        pageControl.currentPage = [[LIOSurveyManager sharedSurveyManager] realIndexWithLogicOfQuestionAtIndex:currentQuestionIndex forSurveyType:currentSurveyType] + 1;
    [self addSubview:pageControl];
    [pageControl release];
    
    isAnimating = YES;
    [UIView animateWithDuration:0.5 animations:^{
        currentScrollView.alpha = 1.0;
        currentScrollView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        isAnimating = NO;
    }];

}

#pragma mark
#pragma mark Intro view setup methods

-(void)layoutSubviews {
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    UIInterfaceOrientation currentInterfaceOrientation = (UIInterfaceOrientation)[[UIDevice currentDevice] orientation];
    BOOL landscape = UIInterfaceOrientationIsLandscape(currentInterfaceOrientation);
    
    if (currentQuestionIndex == LIOIndexForSurveyIntroPage) {
        if (currentSurveyType == LIOSurveyManagerSurveyTypePost)
            [self rejiggerRatingScrollView:currentScrollView];
        else
            [self rejiggerIntroScrollView:currentScrollView];
    } else {
        if (!isAnimating && currentScrollView != nil)
            [self rejiggerSurveyScrollView:currentScrollView];
    }
    
    CGRect pageControlFrame = pageControl.frame;
    if (padUI)
        pageControlFrame.origin.y = self.bounds.size.height - 20.0;
    else
        pageControlFrame.origin.y = self.bounds.size.height - keyboardHeight - 20.0;
    pageControl.frame = pageControlFrame;
    
    if (validationView != nil) {
        CGRect aFrame = validationView.frame;
        aFrame.origin.y = (landscape || padUI) ? 0 : 32;
        
        validationView.frame = aFrame;
    }
}

-(UIScrollView*)scrollViewForRatingView {
    UIScrollView* scrollView = [[[UIScrollView alloc] initWithFrame:self.bounds] autorelease];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UIView* dismissBackgroundView = [[UIView alloc] initWithFrame:scrollView.bounds];
    dismissBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [dismissBackgroundView addGestureRecognizer:tapGestureRecognizer];
    [scrollView addSubview:dismissBackgroundView];
    [dismissBackgroundView release];
    
    UILabel* headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    headerLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    headerLabel.layer.shadowRadius = 1.0;
    headerLabel.layer.shadowOpacity = 1.0;
    headerLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.textColor = [UIColor whiteColor];
    headerLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0];
    headerLabel.numberOfLines = 0;
    headerLabel.text = LIOLocalizedString(@"LIOSurveyView.DefaultPostSurveyTitle");
    headerLabel.textAlignment = UITextAlignmentCenter;
    headerLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    headerLabel.tag = LIOSurveyViewIntroHeaderLabel;
    [scrollView addSubview:headerLabel];
    [headerLabel release];
    
    UILabel* requiredLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    requiredLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    requiredLabel.layer.shadowRadius = 1.0;
    requiredLabel.layer.shadowOpacity = 1.0;
    requiredLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    requiredLabel.backgroundColor = [UIColor clearColor];
    requiredLabel.textColor = [UIColor whiteColor];
    requiredLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
    requiredLabel.numberOfLines = 0;
    requiredLabel.text = LIOLocalizedString(@"LIOSurveyView.DefaultPostSurveyRateTitle");
    requiredLabel.textAlignment = UITextAlignmentCenter;
    requiredLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    requiredLabel.tag = LIOSurveyViewIntroRequiredLabel;
    [scrollView addSubview:requiredLabel];
    [requiredLabel release];
    
    LIOStarRatingView* starRatingView = [[LIOStarRatingView alloc] initWithFrame:CGRectZero];
    starRatingView.tag = LIOSurveyViewStarRatingViewTag;
    starRatingView.delegate = self;
    [scrollView addSubview:starRatingView];
    [starRatingView release];
    
    UIButton* nextButton = [[UIButton alloc] initWithFrame:CGRectZero];
    UIImage *buttonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableGrayButton"];
    UIImage *stretchableGrayButton = [buttonImage stretchableImageWithLeftCapWidth:5 topCapHeight:0];
    [nextButton setBackgroundImage:stretchableGrayButton forState:UIControlStateNormal];
    [nextButton addTarget:self action:@selector(handleLeftSwipeGesture:) forControlEvents:UIControlEventTouchUpInside];
    nextButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
    nextButton.titleLabel.shadowColor = [UIColor colorWithWhite:0.75 alpha:1.0];
    nextButton.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    nextButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [nextButton setTitle:LIOLocalizedString(@"LIOSurveyView.DefaultPostSurveySubmitButton") forState:UIControlStateNormal];
    nextButton.tag = LIOSurveyViewIntroNextButton;
    [scrollView addSubview:nextButton];
    [nextButton release];
    
    UIButton* cancelButton = [[UIButton alloc] initWithFrame:CGRectZero];
    UIImage *cancelButtonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableRedButton"];
    UIImage *stretchableCancelButtonImage = [cancelButtonImage stretchableImageWithLeftCapWidth:5 topCapHeight:0];
    [cancelButton setBackgroundImage:stretchableCancelButtonImage forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
    cancelButton.titleLabel.shadowColor = [UIColor colorWithWhite:0.75 alpha:1.0];
    cancelButton.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    cancelButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [cancelButton setTitle:LIOLocalizedString(@"LIOSurveyView.DefaultPostSurveyCancelButton") forState:UIControlStateNormal];
    cancelButton.tag = LIOSurveyViewIntroCancelButton;
    [scrollView addSubview:cancelButton];
    [cancelButton release];

    UILabel* needHelpLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    needHelpLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    needHelpLabel.layer.shadowRadius = 1.0;
    needHelpLabel.layer.shadowOpacity = 1.0;
    needHelpLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    needHelpLabel.backgroundColor = [UIColor clearColor];
    needHelpLabel.textColor = [UIColor whiteColor];
    needHelpLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
    needHelpLabel.numberOfLines = 0;
    needHelpLabel.text = LIOLocalizedString(@"LIOSurveyView.DefaultPostNeedHelpTitle");
    needHelpLabel.textAlignment = UITextAlignmentCenter;
    needHelpLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    needHelpLabel.tag = LIOSurveyViewIntroNeedHelpLabel;
    [scrollView addSubview:needHelpLabel];
    [needHelpLabel release];
    
    UIButton* liveChatButton = [[UIButton alloc] initWithFrame:CGRectZero];
    UIImage *liveChatButtonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableGrayButton"];
    UIImage *liveChatStretchableGrayButton = [liveChatButtonImage stretchableImageWithLeftCapWidth:5 topCapHeight:0];
    [liveChatButton setBackgroundImage:liveChatStretchableGrayButton forState:UIControlStateNormal];
    [liveChatButton addTarget:self action:@selector(cancelButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    liveChatButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
    liveChatButton.titleLabel.shadowColor = [UIColor colorWithWhite:0.75 alpha:1.0];
    liveChatButton.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    liveChatButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [liveChatButton setTitle:LIOLocalizedString(@"LIOSurveyView.DefaultPostSurveyLiveChatButton") forState:UIControlStateNormal];
    liveChatButton.tag = LIOSurveyViewIntroLiveChatButton;
    [scrollView addSubview:liveChatButton];
    [liveChatButton release];
    
    [scrollView setNeedsLayout];
    [self rejiggerRatingScrollView:scrollView];
    
    return scrollView;
}


-(void)rejiggerRatingScrollView:(UIScrollView*)scrollView {
    UIInterfaceOrientation currentInterfaceOrientation = (UIInterfaceOrientation)[[UIDevice currentDevice] orientation];
    BOOL landscape = UIInterfaceOrientationIsLandscape(currentInterfaceOrientation);
    
    CGRect aFrame;
    
    UILabel* headerLabel = (UILabel*)[scrollView viewWithTag:LIOSurveyViewIntroHeaderLabel];
    
    aFrame.origin.x = LIOSurveyViewSideMargin;
    aFrame.origin.y = landscape ? LIOSurveyViewIntroTopMarginLandscape : LIOSurveyViewIntroTopMarginPortrait;
    aFrame.size.width = self.bounds.size.width - 2*LIOSurveyViewSideMargin;
    CGSize expectedLabelSize = [headerLabel.text sizeWithFont:headerLabel.font constrainedToSize:CGSizeMake(aFrame.size.width, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    aFrame.size.height = expectedLabelSize.height;
    headerLabel.frame = aFrame;
    
    UILabel* requiredLabel = (UILabel*)[scrollView viewWithTag:LIOSurveyViewIntroRequiredLabel];
    
    aFrame.origin.x = LIOSurveyViewSideMargin;
    aFrame.origin.y = headerLabel.frame.origin.y + headerLabel.frame.size.height + 15.0;
    aFrame.size.width = self.bounds.size.width - 2*LIOSurveyViewSideMargin;
    expectedLabelSize = [requiredLabel.text sizeWithFont:requiredLabel.font constrainedToSize:CGSizeMake(aFrame.size.width, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    aFrame.size.height = expectedLabelSize.height;
    requiredLabel.frame = aFrame;
    
    LIOStarRatingView* starRatingView = (LIOStarRatingView*)[scrollView viewWithTag:LIOSurveyViewStarRatingViewTag];
    aFrame.size.width = 150.0;
    aFrame.size.height = 40.0;
    aFrame.origin.x = scrollView.bounds.size.width/2.0 - aFrame.size.width/2.0;
    aFrame.origin.y = requiredLabel.frame.origin.y + requiredLabel.frame.size.height + 20;
    starRatingView.frame = aFrame;    
    
    UIButton* nextButton = (UIButton*)[scrollView viewWithTag:LIOSurveyViewIntroNextButton];
    
    aFrame.origin.x = self.bounds.size.width/2 + LIOSurveyViewIntroButtonMargin;
    aFrame.origin.y = requiredLabel.frame.origin.y + requiredLabel.frame.size.height + 100;
    aFrame.size.width = 92.0;
    aFrame.size.height = 44.0;
    nextButton.frame = aFrame;
    
    UIButton* cancelButton = (UIButton*)[scrollView viewWithTag:LIOSurveyViewIntroCancelButton];
    
    aFrame.origin.x = self.bounds.size.width/2 - LIOSurveyViewIntroButtonMargin - 92.0;
    aFrame.origin.y = requiredLabel.frame.origin.y + requiredLabel.frame.size.height + 100;
    aFrame.size.width = 92.0;
    aFrame.size.height = 44.0;
    cancelButton.frame = aFrame;
    
    UILabel* needhelpLabel = (UILabel*)[scrollView viewWithTag:LIOSurveyViewIntroNeedHelpLabel];
    
    aFrame.origin.x = LIOSurveyViewSideMargin;
    aFrame.origin.y = requiredLabel.frame.origin.y + requiredLabel.frame.size.height + 250;
    aFrame.size.width = self.bounds.size.width - 2*LIOSurveyViewSideMargin;
    aFrame.size.height = 16.0;
    needhelpLabel.frame = aFrame;
    

    UIButton* liveChatButton = (UIButton*)[scrollView viewWithTag:LIOSurveyViewIntroLiveChatButton];
    
    aFrame.origin.x = self.bounds.size.width/2 - 92.0/2.0;
    aFrame.origin.y = requiredLabel.frame.origin.y + requiredLabel.frame.size.height + 275;
    aFrame.size.width = 92.0;
    aFrame.size.height = 44.0;
    liveChatButton.frame = aFrame;
    
    
}

-(UIScrollView*)scrollViewForIntroView {
    UIScrollView* scrollView = [[[UIScrollView alloc] initWithFrame:self.bounds] autorelease];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UIView* dismissBackgroundView = [[UIView alloc] initWithFrame:scrollView.bounds];
    dismissBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [dismissBackgroundView addGestureRecognizer:tapGestureRecognizer];
    [scrollView addSubview:dismissBackgroundView];
    [dismissBackgroundView release];
    
    UILabel* headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    headerLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    headerLabel.layer.shadowRadius = 1.0;
    headerLabel.layer.shadowOpacity = 1.0;
    headerLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.textColor = [UIColor whiteColor];
    headerLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0];
    headerLabel.numberOfLines = 0;
    headerLabel.text = headerString;
    headerLabel.textAlignment = UITextAlignmentCenter;
    headerLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    headerLabel.tag = LIOSurveyViewIntroHeaderLabel;
    [scrollView addSubview:headerLabel];
    [headerLabel release];
    
    UILabel* requiredLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    requiredLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    requiredLabel.layer.shadowRadius = 1.0;
    requiredLabel.layer.shadowOpacity = 1.0;
    requiredLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    requiredLabel.backgroundColor = [UIColor clearColor];
    requiredLabel.textColor = [UIColor whiteColor];
    requiredLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0];
    requiredLabel.numberOfLines = 0;
    requiredLabel.text = LIOLocalizedString(@"LIOSurveyViewController.MandatoryQuestionsTitle");
    requiredLabel.textAlignment = UITextAlignmentCenter;
    requiredLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    requiredLabel.tag = LIOSurveyViewIntroRequiredLabel;
    [scrollView addSubview:requiredLabel];
    [requiredLabel release];
    
    UIButton* nextButton = [[UIButton alloc] initWithFrame:CGRectZero];
    UIImage *buttonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableGrayButton"];
    UIImage *stretchableGrayButton = [buttonImage stretchableImageWithLeftCapWidth:5 topCapHeight:0];
    [nextButton setBackgroundImage:stretchableGrayButton forState:UIControlStateNormal];
    [nextButton addTarget:self action:@selector(handleLeftSwipeGesture:) forControlEvents:UIControlEventTouchUpInside];
    nextButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
    nextButton.titleLabel.shadowColor = [UIColor colorWithWhite:0.75 alpha:1.0];
    nextButton.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    nextButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [nextButton setTitle:LIOLocalizedString(@"LIOSurveyView.NextButtonTitle") forState:UIControlStateNormal];
    nextButton.tag = LIOSurveyViewIntroNextButton;
    [scrollView addSubview:nextButton];
    [nextButton release];

    UIButton* cancelButton = [[UIButton alloc] initWithFrame:CGRectZero];
    UIImage *cancelButtonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableRedButton"];
    UIImage *stretchableCancelButtonImage = [cancelButtonImage stretchableImageWithLeftCapWidth:5 topCapHeight:0];
    [cancelButton setBackgroundImage:stretchableCancelButtonImage forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
    cancelButton.titleLabel.shadowColor = [UIColor colorWithWhite:0.75 alpha:1.0];
    cancelButton.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    cancelButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [cancelButton setTitle:LIOLocalizedString(@"LIOSurveyView.CancelButtonTitle") forState:UIControlStateNormal];
    cancelButton.tag = LIOSurveyViewIntroCancelButton;
    [scrollView addSubview:cancelButton];
    [cancelButton release];
    
    [self rejiggerIntroScrollView:scrollView];
    
    return scrollView;
}


-(void)rejiggerIntroScrollView:(UIScrollView*)scrollView {
    UIInterfaceOrientation currentInterfaceOrientation = (UIInterfaceOrientation)[[UIDevice currentDevice] orientation];
    BOOL landscape = UIInterfaceOrientationIsLandscape(currentInterfaceOrientation);
    
    CGRect aFrame;
    
    UILabel* headerLabel = (UILabel*)[scrollView viewWithTag:LIOSurveyViewIntroHeaderLabel];

    aFrame.origin.x = LIOSurveyViewSideMargin;
    aFrame.origin.y = landscape ? LIOSurveyViewIntroTopMarginLandscape : LIOSurveyViewIntroTopMarginPortrait;
    aFrame.size.width = self.bounds.size.width - 2*LIOSurveyViewSideMargin;
    CGSize expectedLabelSize = [headerLabel.text sizeWithFont:headerLabel.font constrainedToSize:CGSizeMake(aFrame.size.width, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    aFrame.size.height = expectedLabelSize.height;
    headerLabel.frame = aFrame;
    
    UILabel* requiredLabel = (UILabel*)[scrollView viewWithTag:LIOSurveyViewIntroRequiredLabel];
    
    aFrame.origin.x = LIOSurveyViewSideMargin;
    aFrame.origin.y = headerLabel.frame.origin.y + headerLabel.frame.size.height + 15.0;
    aFrame.size.width = self.bounds.size.width - 2*LIOSurveyViewSideMargin;
    expectedLabelSize = [requiredLabel.text sizeWithFont:requiredLabel.font constrainedToSize:CGSizeMake(aFrame.size.width, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    aFrame.size.height = expectedLabelSize.height;
    requiredLabel.frame = aFrame;
    
    UIButton* nextButton = (UIButton*)[scrollView viewWithTag:LIOSurveyViewIntroNextButton];
    aFrame.origin.x = self.bounds.size.width/2 + LIOSurveyViewIntroButtonMargin;
    aFrame.origin.y = requiredLabel.frame.origin.y + requiredLabel.frame.size.height + 25;
    aFrame.size.width = 92.0;
    aFrame.size.height = 44.0;
    nextButton.frame = aFrame;
    
    UIButton* cancelButton = (UIButton*)[scrollView viewWithTag:LIOSurveyViewIntroCancelButton];
    
    aFrame.origin.x = self.bounds.size.width/2 - LIOSurveyViewIntroButtonMargin - 92.0;
    aFrame.origin.y = requiredLabel.frame.origin.y + requiredLabel.frame.size.height + 25;
    aFrame.size.width = 92.0;
    aFrame.size.height = 44.0;
    cancelButton.frame = aFrame;
}

#pragma mark
#pragma mark Question view setup methods

-(UIScrollView*)scrollViewForQuestionAtIndex:(int)index {
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    int numberOfQuestions = [currentSurvey.questions count];
    if (index > numberOfQuestions - 1 || index < 0)
        return nil;
    
    LIOSurveyQuestion *question = [currentSurvey.questions objectAtIndex:index];
    
    CGRect aFrame = self.bounds;
    aFrame.size.height = aFrame.size.height - keyboardHeight;
    UIScrollView* scrollView = [[[UIScrollView alloc] initWithFrame:self.bounds] autorelease];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    scrollView.showsVerticalScrollIndicator = NO;
    
    UIView* dismissBackgroundView = [[UIView alloc] initWithFrame:scrollView.bounds];
    dismissBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [dismissBackgroundView addGestureRecognizer:tapGestureRecognizer];
    [scrollView addSubview:dismissBackgroundView];
    [dismissBackgroundView release];
    
    UILabel* questionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    questionLabel.tag = LIOSurveyViewTitleLabelTag;
    questionLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    questionLabel.layer.shadowRadius = 1.0;
    questionLabel.layer.shadowOpacity = 1.0;
    questionLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    questionLabel.backgroundColor = [UIColor clearColor];
    questionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0];
    questionLabel.textColor = [UIColor whiteColor];
    questionLabel.numberOfLines = 0;
    questionLabel.text = question.label;
    if (question.mandatory)
        questionLabel.text = [NSString stringWithFormat:@"%@ *", questionLabel.text];
    questionLabel.textAlignment = UITextAlignmentCenter;
    [scrollView addSubview:questionLabel];
    [questionLabel release];
    
    if (LIOSurveyQuestionDisplayTypeTextField == question.displayType) {
        UIImage *fieldImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableWhiteTextField"];
        UIImage *stretchableFieldImage = [fieldImage stretchableImageWithLeftCapWidth:5 topCapHeight:0];
        
        UIImageView *fieldBackground = [[[UIImageView alloc] initWithImage:stretchableFieldImage] autorelease];
        fieldBackground.tag = LIOSurveyViewInputBackgroundTag;
        fieldBackground.userInteractionEnabled = YES;
        fieldBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        fieldBackground.alpha = 0.85;
        [scrollView addSubview:fieldBackground];
        
        UITextField *inputField = [[[UITextField alloc] init] autorelease];
        inputField.tag = LIOSurveyViewInputTextFieldTag;
        inputField.delegate = self;
        inputField.backgroundColor = [UIColor clearColor];
        inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        inputField.font = [UIFont fontWithName:@"HelveticaNeue" size:17.0];
        inputField.textColor = [UIColor colorWithWhite:41.0/255.0 alpha:1.0];
        inputField.autocorrectionType = UITextAutocorrectionTypeNo;
        if (currentQuestionIndex == numberOfQuestions - 1)
            inputField.returnKeyType = UIReturnKeyDone;
        else
            inputField.returnKeyType = UIReturnKeyNext;
        inputField.keyboardAppearance = UIKeyboardAppearanceAlert;
        
        if (LIOSurveyQuestionValidationTypeEmail == question.validationType) {
            inputField.keyboardType = UIKeyboardTypeEmailAddress;
            inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            
        }
        if (LIOSurveyQuestionValidationTypeNumeric == question.validationType) {
            inputField.keyboardType = UIKeyboardTypeNumberPad;
            
            NSString* buttonTitle = LIOLocalizedString(@"LIOSurveyView.NextButtonTitle");
            if (currentQuestionIndex == numberOfQuestions - 1)
                buttonTitle = LIOLocalizedString(@"LIOSurveyView.DoneButtonTitle");
            
            if (!padUI) {
                UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
                numberToolbar.barStyle = UIBarStyleBlackTranslucent;
                numberToolbar.items = [NSArray arrayWithObjects:
                                       [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
                                       [[[UIBarButtonItem alloc]initWithTitle:buttonTitle style:UIBarButtonItemStyleDone target:self action:@selector(switchToNextQuestion)] autorelease],
                                       nil];
                [numberToolbar sizeToFit];
                inputField.inputAccessoryView = numberToolbar;
                [numberToolbar release];
            }
        }
        
        // If the user has answered this survey, we should display their answer        
        id aResponse = [[LIOSurveyManager sharedSurveyManager] answerObjectForSurveyType:currentSurveyType withQuestionIndex:index];
        if (aResponse && [aResponse isKindOfClass:[NSString class]])
        {
            NSString *responseString = (NSString *)aResponse;
            inputField.text = responseString;
        }
        // If user hasn't answered, let's see if there's a last known response to populate
        else {
            if (question.lastKnownValue)
                inputField.text = question.lastKnownValue;
        }
        
        
        [fieldBackground addSubview:inputField];
        [inputField becomeFirstResponder];
    }
    
    if (LIOSurveyQuestionDisplayTypeTextArea == question.displayType) {
        UIImage *fieldImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableWhiteTextField"];
        UIImage *stretchableFieldImage = [fieldImage stretchableImageWithLeftCapWidth:5 topCapHeight:5];
        
        UIImageView *fieldBackground = [[[UIImageView alloc] initWithImage:stretchableFieldImage] autorelease];
        fieldBackground.tag = LIOSurveyViewInputBackgroundTag;
        fieldBackground.userInteractionEnabled = YES;
        fieldBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        fieldBackground.alpha = 0.85;
        [scrollView addSubview:fieldBackground];
        
        UITextView *inputField = [[[UITextView alloc] init] autorelease];
        inputField.tag = LIOSurveyViewInputTextViewTag;
        inputField.delegate = self;
        inputField.backgroundColor = [UIColor clearColor];
        inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        inputField.font = [UIFont fontWithName:@"HelveticaNeue" size:17.0];
        inputField.textColor = [UIColor colorWithWhite:41.0/255.0 alpha:1.0];
        inputField.autocorrectionType = UITextAutocorrectionTypeNo;
        if (currentQuestionIndex == numberOfQuestions - 1)
            inputField.returnKeyType = UIReturnKeyDone;
        else
            inputField.returnKeyType = UIReturnKeyNext;
        inputField.keyboardAppearance = UIKeyboardAppearanceAlert;
        
        if (LIOSurveyQuestionValidationTypeEmail == question.validationType) {
            inputField.keyboardType = UIKeyboardTypeEmailAddress;
            inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        }
        if (LIOSurveyQuestionValidationTypeNumeric == question.validationType) {
            inputField.keyboardType = UIKeyboardTypeNumberPad;
            
            NSString* buttonTitle = LIOLocalizedString(@"LIOSurveyView.NextButtonTitle");
            if (currentQuestionIndex == numberOfQuestions - 1)
                buttonTitle = LIOLocalizedString(@"LIOSurveyView.DoneButtonTitle");
            
            if (!padUI) {
                UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
                numberToolbar.barStyle = UIBarStyleBlackTranslucent;
                numberToolbar.items = [NSArray arrayWithObjects:
                                       [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
                                       [[[UIBarButtonItem alloc]initWithTitle:buttonTitle style:UIBarButtonItemStyleDone target:self action:@selector(switchToNextQuestion)] autorelease],
                                       nil];
                [numberToolbar sizeToFit];
                inputField.inputAccessoryView = numberToolbar;
                [numberToolbar release];
            }
        }
        
        // If the user has answered this survey, we should display their answer
        id aResponse = [[LIOSurveyManager sharedSurveyManager] answerObjectForSurveyType:currentSurveyType withQuestionIndex:index];
        if (aResponse && [aResponse isKindOfClass:[NSString class]])
        {
            NSString *responseString = (NSString *)aResponse;
            inputField.text = responseString;
        }
        // If user hasn't answered, let's see if there's a last known response to populate
        else {
            if (question.lastKnownValue)
                inputField.text = question.lastKnownValue;
        }
        
        
        [fieldBackground addSubview:inputField];
        [inputField becomeFirstResponder];
    }
    
    if (LIOSurveyQuestionDisplayTypePicker == question.displayType || LIOSurveyQuestionDisplayTypeMultiselect == question.displayType) {
        if (question.shouldUseStarRatingView) {
            LIOStarRatingView* starRatingView = [[LIOStarRatingView alloc] initWithFrame:CGRectZero];
            starRatingView.tag = LIOSurveyViewStarRatingViewTag;
            starRatingView.delegate = self;
            [starRatingView setValueLabels:question.pickerEntryTitles];
            [scrollView addSubview:starRatingView];
            [starRatingView release];
            
            UIButton* nextButton = [[UIButton alloc] initWithFrame:CGRectZero];
            nextButton.tag = LIOSurveyViewButtonTag;
            UIImage *buttonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableGrayButton"];
            UIImage *stretchableGrayButton = [buttonImage stretchableImageWithLeftCapWidth:5 topCapHeight:0];
            nextButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
            nextButton.titleLabel.shadowColor = [UIColor colorWithWhite:0.75 alpha:1.0];
            nextButton.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
            [nextButton setBackgroundImage:stretchableGrayButton forState:UIControlStateNormal];
            [nextButton addTarget:self action:@selector(handleLeftSwipeGesture:) forControlEvents:UIControlEventTouchUpInside];
            nextButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
            nextButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            if (currentQuestionIndex == numberOfQuestions - 1)
                [nextButton setTitle:LIOLocalizedString(@"LIOSurveyView.DoneButtonTitle") forState:UIControlStateNormal];
            else
                [nextButton setTitle:LIOLocalizedString(@"LIOSurveyView.NextButtonTitle") forState:UIControlStateNormal];
            [scrollView addSubview:nextButton];
            [nextButton release];
        } else {
            UITableView* tableView = [[UITableView alloc]
                                      initWithFrame:CGRectZero style:UITableViewStylePlain];
            CGFloat tableViewContentHeight = [self heightForTableView:tableView];
            tableView.frame = CGRectMake(0, 0, self.bounds.size.width - 34.0, tableViewContentHeight);
            
            tableView.tag = LIOSurveyViewTableViewTag;
            tableView.delegate = self;
            tableView.dataSource = self;
            tableView.backgroundColor = [UIColor clearColor];
            tableView.backgroundView = nil;
            tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
            tableView.showsVerticalScrollIndicator = NO;
            [scrollView addSubview:tableView];
            [tableView release];
            
            UIButton* nextButton = [[UIButton alloc] initWithFrame:CGRectZero];
            nextButton.tag = LIOSurveyViewButtonTag;
            UIImage *buttonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableGrayButton"];
            UIImage *stretchableGrayButton = [buttonImage stretchableImageWithLeftCapWidth:5 topCapHeight:0];
            nextButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
            nextButton.titleLabel.shadowColor = [UIColor colorWithWhite:0.75 alpha:1.0];
            nextButton.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
            [nextButton setBackgroundImage:stretchableGrayButton forState:UIControlStateNormal];
            [nextButton addTarget:self action:@selector(handleLeftSwipeGesture:) forControlEvents:UIControlEventTouchUpInside];
            nextButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
            nextButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            if (currentQuestionIndex == numberOfQuestions - 1)
                [nextButton setTitle:LIOLocalizedString(@"LIOSurveyView.DoneButtonTitle") forState:UIControlStateNormal];
            else
                [nextButton setTitle:LIOLocalizedString(@"LIOSurveyView.NextButtonTitle") forState:UIControlStateNormal];
            [scrollView addSubview:nextButton];
            [nextButton release];
        }
        
        if (selectedIndices) {
            [selectedIndices removeAllObjects];
            [selectedIndices release];
            selectedIndices = nil;
        }
        selectedIndices = [[NSMutableArray alloc] init];
        
        // If the user has answered this survey, we should display their answer
        
        id aResponse = [[LIOSurveyManager sharedSurveyManager] answerObjectForSurveyType:currentSurveyType withQuestionIndex:index];
        if (aResponse) {
            NSMutableArray* answersArray;
            
            if (aResponse && [aResponse isKindOfClass:[NSString class]]) {
                NSString* answerString = (NSString*)aResponse;
                answersArray = [[[NSMutableArray alloc] initWithObjects:answerString, nil] autorelease];
            }
            
            if (aResponse && [aResponse isKindOfClass:[NSArray class]])
                answersArray = (NSMutableArray*)aResponse;
            
            for (NSString* answer in answersArray)
                for (LIOSurveyPickerEntry* pickerEntry in question.pickerEntries)
                    if ([pickerEntry.label isEqualToString:answer]) {
                        int questionRow = [question.pickerEntries indexOfObject:pickerEntry];
                        [selectedIndices addObject:[NSIndexPath indexPathForRow:questionRow inSection:0]];
                    }
        }
        // If not, we should see if any of the answers are set to be checked by default
        else {
            BOOL questionHasInitiallyCheckedAnswer = NO;
            for (LIOSurveyPickerEntry* pickerEntry in question.pickerEntries) {
                if (pickerEntry.initiallyChecked) {
                    questionHasInitiallyCheckedAnswer = YES;
                    
                    int questionRow = [question.pickerEntries indexOfObject:pickerEntry];
                    if (question.shouldUseStarRatingView)
                        [selectedIndices addObject:[NSIndexPath indexPathForRow:(5-questionRow) inSection:0]];
                    else
                        [selectedIndices addObject:[NSIndexPath indexPathForRow:questionRow inSection:0]];                    
                }
            }
            
            // Finally, if no answers are set for a rating view, we should set the 5 star answer as the correct answer
            if (question.shouldUseStarRatingView && !questionHasInitiallyCheckedAnswer)
                [selectedIndices addObject:[NSIndexPath indexPathForRow:0 inSection:0]];

        }
    }
    
    [self rejiggerSurveyScrollView:scrollView];
    return scrollView;
}

-(void)rejiggerSurveyScrollView:(UIScrollView*)scrollView {
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    UIInterfaceOrientation currentInterfaceOrientation = (UIInterfaceOrientation)[[UIDevice currentDevice] orientation];
    BOOL landscape = UIInterfaceOrientationIsLandscape(currentInterfaceOrientation);

    CGRect aFrame;
    
    if (!padUI) {
        aFrame = scrollView.frame;
        aFrame.size.height = self.frame.size.height - keyboardHeight;
        currentScrollView.frame = aFrame;
    }

    UILabel* questionLabel = (UILabel*)[scrollView viewWithTag:LIOSurveyViewTitleLabelTag];
    if (questionLabel) {
        aFrame.origin.x = LIOSurveyViewSideMargin;
        aFrame.origin.y = (landscape && !padUI) ? LIOSurveyViewTopMarginLandscape : LIOSurveyViewTopMarginPortrait;
        aFrame.size.width = self.bounds.size.width - LIOSurveyViewSideMargin*2;
        CGSize expectedLabelSize = [questionLabel.text sizeWithFont:questionLabel.font constrainedToSize:CGSizeMake(aFrame.size.width, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
        aFrame.size.height = expectedLabelSize.height;
        
        questionLabel.frame = aFrame;
    }
    
    UITextField* inputField = (UITextField*)[scrollView viewWithTag:LIOSurveyViewInputTextFieldTag];
    if (inputField) {
        UIImageView* fieldBackground = (UIImageView*)[scrollView viewWithTag:LIOSurveyViewInputBackgroundTag];
        if (fieldBackground) {
            aFrame = fieldBackground.frame;
            aFrame.origin.x = 10.0;
            aFrame.size.width = self.bounds.size.width - 20.0;
            aFrame.size.height = landscape ? 43.0 : 43.0;
            aFrame.origin.y = questionLabel.frame.origin.y + questionLabel.frame.size.height + (landscape ? 12.0 : 15.0);
            fieldBackground.frame = aFrame;
        }
        
        aFrame.origin.x = 15.0;
        aFrame.origin.y = landscape ? 10.0 : 10.0;
        aFrame.size.width = fieldBackground.frame.size.width - 20.0;
        aFrame.size.height = 28.0;
        
        // iOS 7.0: Remove 3px for the textfield in iOS 7.0
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
            if (![[UIApplication sharedApplication] isStatusBarHidden])
                aFrame.origin.y -= 3.0;
        
        inputField.frame = aFrame;
        
        // Set up the scroll view to allow scrolling down to the text field if needed
        CGSize aSize;
        aSize.width = scrollView.frame.size.width;
        aSize.height = fieldBackground.frame.origin.y + fieldBackground.frame.size.height + 30.0;
        scrollView.contentSize = aSize;        
    }
    
    
    UITextView* textView = (UITextView*)[scrollView viewWithTag:LIOSurveyViewInputTextViewTag];
    if (textView) {
        UIImageView* fieldBackground = (UIImageView*)[scrollView viewWithTag:LIOSurveyViewInputBackgroundTag];
        if (fieldBackground) {
            aFrame = fieldBackground.frame;
            aFrame.origin.x = 10.0;
            aFrame.size.width = self.bounds.size.width - 20.0;
            aFrame.size.height = landscape ? 75.0 : 105.0;
            aFrame.origin.y = questionLabel.frame.origin.y + questionLabel.frame.size.height + (landscape ? 12.0 : 15.0);
            fieldBackground.frame = aFrame;
        }
        
        aFrame.origin.x = 5.0;
        aFrame.origin.y = landscape ? 7.0 : 5.0;
        aFrame.size.width = fieldBackground.frame.size.width - 20.0;
        aFrame.size.height = landscape ? 60.0 : 88.0;
        textView.frame = aFrame;
        
        // Set up the scroll view to allow scrolling down to the text field if needed
        CGSize aSize;
        aSize.width = scrollView.frame.size.width;
        aSize.height = fieldBackground.frame.origin.y + fieldBackground.frame.size.height + 30.0;
        scrollView.contentSize = aSize;
    }
    
    LIOStarRatingView* starRatingView = (LIOStarRatingView*)[scrollView viewWithTag:LIOSurveyViewStarRatingViewTag];
    if (starRatingView) {
        aFrame.size.width = scrollView.frame.size.width;
        aFrame.size.height = 40.0;
        aFrame.origin.x = scrollView.bounds.size.width/2.0 - aFrame.size.width/2.0;
        aFrame.origin.y = questionLabel.frame.origin.y + questionLabel.frame.size.height + 20;
        starRatingView.frame = aFrame;
        
        UIButton* nextButton = (UIButton*)[scrollView viewWithTag:LIOSurveyViewButtonTag];
        aFrame.origin.x = self.bounds.size.width - LIOSurveyViewSideMargin*2 - 92.0;
        aFrame.origin.y = starRatingView.frame.origin.y + starRatingView.frame.size.height + 30;
        aFrame.size.width = 92.0;
        aFrame.size.height = 44.0;
        nextButton.frame = aFrame;

    }
    
    UITableView* tableView = (UITableView*)[scrollView viewWithTag:LIOSurveyViewTableViewTag];
    if (tableView) {
        [tableView reloadData];

        CGFloat tableViewContentHeight = [self heightForTableView:tableView];
        
        CGFloat maxHeight = self.bounds.size.height - 53.0 - questionLabel.bounds.size.height - 50.0 - (landscape && !padUI ? 0 : 60.0);
        if (tableViewContentHeight > maxHeight) {
            tableView.scrollEnabled = YES;
            tableViewContentHeight = maxHeight;
        } else {
            tableView.scrollEnabled = NO;
        }
    
        tableView.frame = CGRectMake(15.0, questionLabel.frame.origin.y + questionLabel.frame.size.height + 10.0, self.bounds.size.width - 34.0, tableViewContentHeight);
        
        UIButton* nextButton = (UIButton*)[scrollView viewWithTag:LIOSurveyViewButtonTag];
        aFrame.origin.x = self.bounds.size.width - LIOSurveyViewSideMargin*2 - 92.0;
        aFrame.origin.y = tableView.frame.origin.y + tableView.frame.size.height + 15;
        aFrame.size.width = 92.0;
        aFrame.size.height = 44.0;
        nextButton.frame = aFrame;
    }

}

-(CGFloat)heightForTableView:(UITableView*)tableView {
    CGFloat tableViewContentHeight = 0.0;
    int numberOfTableRows = [self tableView:tableView numberOfRowsInSection:0];
    for (int i=0; i<numberOfTableRows; i++) {
        tableViewContentHeight += [self tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    
    return tableViewContentHeight;
}

#pragma mark
#pragma mark Gesture handling methods

-(void)handleLeftSwipeGesture:(UISwipeGestureRecognizer*)sender
{
    [self switchToNextQuestion];
}

-(void)handleRightSwipeGesture:(UISwipeGestureRecognizer*)sender
{
    if (currentQuestionIndex == LIOIndexForSurveyIntroPage)
        [self bounceViewLeft];
    else
        [self switchToPreviousQuestion];
}

-(void)cancelButtonWasTapped:(id)sender {
    if (delegate) {
        pageControl.alpha = 0.0;
        [delegate surveyViewDidCancel:self];
    }
}

-(void)handleTapGesture:(UITapGestureRecognizer*)sender {
    if (delegate) {
        pageControl.alpha = 0.0;
        [delegate surveyViewDidCancel:self];
    }
}

-(void)bounceViewLeft {
    isAnimating = YES;
    [UIView animateWithDuration:0.1 animations:^{
        currentScrollView.transform = CGAffineTransformMakeTranslation(30.0, 0.0);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            currentScrollView.transform = CGAffineTransformMakeTranslation(-10.0, 0.0);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 animations:^{
                currentScrollView.transform = CGAffineTransformMakeTranslation(20.0, 0.0);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.1 animations:^{
                    currentScrollView.transform = CGAffineTransformMakeTranslation(0.0, 0.0);
                } completion:^(BOOL finished) {
                    isAnimating = NO;
                }];
            }];
        }];
    }];
}

-(void)bounceViewRight {
    isAnimating = YES;
    [UIView animateWithDuration:0.1 animations:^{
        currentScrollView.transform = CGAffineTransformMakeTranslation(-30.0, 0.0);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            currentScrollView.transform = CGAffineTransformMakeTranslation(10.0, 0.0);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 animations:^{
                currentScrollView.transform = CGAffineTransformMakeTranslation(-20.0, 0.0);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.1 animations:^{
                    currentScrollView.transform = CGAffineTransformMakeTranslation(0.0, 0.0);
                } completion:^(BOOL finished) {
                    isAnimating = NO;
                }];
            }];
        }];
    }];
}

-(void)switchToNextQuestion {
    int numberOfQuestions = [currentSurvey.questions count];
    
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
                pageControl.alpha = 0.0;
                [delegate surveyViewDidFinish:self];
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
            
        isAnimating = YES;
        [UIView animateWithDuration:0.3 animations:^{
            [currentScrollView endEditing:YES];
                
            nextQuestionScrollView.transform = CGAffineTransformIdentity;
            currentScrollView.transform = CGAffineTransformMakeTranslation(-self.bounds.size.width, 0.0);

            pageControl.numberOfPages = [[LIOSurveyManager sharedSurveyManager] numberOfQuestionsWithLogicForSurveyType:currentSurveyType] + 1;
            pageControl.currentPage = [[LIOSurveyManager sharedSurveyManager] realIndexWithLogicOfQuestionAtIndex:currentQuestionIndex forSurveyType:currentSurveyType] + 1;
        } completion:^(BOOL finished) {
            [currentScrollView removeFromSuperview];
            currentScrollView = nil;
            currentScrollView = nextQuestionScrollView;
                
            isAnimating = NO;
        }];
    }
}

-(void)switchToPreviousQuestion {
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

    UIScrollView* previousQuestionScrollView;
    
    if (LIOIndexForSurveyIntroPage == currentQuestionIndex) {
//        if (currentSurveyType == LIOSurveyManagerSurveyTypePost)
///            previousQuestionScrollView = [self scrollViewForRatingView];
//        else
            previousQuestionScrollView = [self scrollViewForIntroView];
    }
    else
        previousQuestionScrollView = [self scrollViewForQuestionAtIndex:currentQuestionIndex];
    
    previousQuestionScrollView.transform = CGAffineTransformMakeTranslation(-self.bounds.size.width, 0.0);
    [self addSubview:previousQuestionScrollView];
    
    isAnimating = YES;
    [UIView animateWithDuration:0.3 animations:^{
        [currentScrollView endEditing:YES];
        
        previousQuestionScrollView.transform = CGAffineTransformIdentity;
        currentScrollView.transform = CGAffineTransformMakeTranslation(self.bounds.size.width, 0.0);
        
        pageControl.numberOfPages = [[LIOSurveyManager sharedSurveyManager] numberOfQuestionsWithLogicForSurveyType:currentSurveyType] + 1;

        if (currentQuestionIndex == LIOIndexForSurveyIntroPage)
            pageControl.currentPage = 0;
        else
            pageControl.currentPage = [[LIOSurveyManager sharedSurveyManager] realIndexWithLogicOfQuestionAtIndex:currentQuestionIndex forSurveyType:currentSurveyType] + 1;
        
        if (validationView) {
            [validationTimer stopTimer];
            [self validationTimerDidFire];
        }
        
        
    } completion:^(BOOL finished) {
        [currentScrollView removeFromSuperview];
        currentScrollView = nil;
        currentScrollView = previousQuestionScrollView;
        
        isAnimating = NO;
    }];
}

#pragma mark
#pragma mark Validation view methods

- (void)showAlertWithMessage:(NSString *)aMessage
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    UIInterfaceOrientation currentInterfaceOrientation = (UIInterfaceOrientation)[[UIDevice currentDevice] orientation];
    BOOL landscape = UIInterfaceOrientationIsLandscape(currentInterfaceOrientation);

    [validationView removeFromSuperview];
    [validationView release];
    validationView = nil;
    
    validationView = [[LIOSurveyValidationView alloc] init];
    CGRect aFrame = validationView.frame;
    aFrame.origin.y = (landscape || padUI) ? 0 : 32;
    validationView.verticallyMirrored = YES;
    aFrame.size.width = self.frame.size.width;
        
    validationView.frame = aFrame;
    validationView.label.text = aMessage;
    validationView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
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

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isRowSelected = NO;
    
    for (NSIndexPath* selectedIndexPath in selectedIndices) {
        if (indexPath.row == selectedIndexPath.row) {
            isRowSelected = YES;
        }
    }

    UIFont* font = [UIFont fontWithName:@"HelveticaNeue" size:17.0];
    if (isRowSelected)
        font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0];

    LIOSurveyQuestion *question = [currentSurvey.questions objectAtIndex:currentQuestionIndex];
    LIOSurveyPickerEntry* entry = [question.pickerEntries objectAtIndex:indexPath.row];
    
    CGSize expectedSize = [entry.label sizeWithFont:font constrainedToSize:CGSizeMake(tableView.bounds.size.width - 40.0, 9999) lineBreakMode:UILineBreakModeWordWrap];
    
    return expectedSize.height + 33.0;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    LIOSurveyQuestion *question = [currentSurvey.questions objectAtIndex:currentQuestionIndex];
    return question.pickerEntries.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.backgroundColor = [UIColor clearColor];
        
        UILabel* textLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 17.0, tableView.bounds.size.width - 40.0, 19.0)];
        textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:17.0];
        textLabel.textColor = [UIColor colorWithWhite:41.0/255.0 alpha:1.0];
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
    
    LIOSurveyQuestion *question = [currentSurvey.questions objectAtIndex:currentQuestionIndex];
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
    
    if (isRowSelected) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0];
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:17.0];
    }

    textLabel.text = pickerEntry.label;
    textLabel.numberOfLines = 0;
    CGSize expectedSize = [pickerEntry.label sizeWithFont:textLabel.font constrainedToSize:CGSizeMake(tableView.bounds.size.width - 40.0, 9999) lineBreakMode:UILineBreakModeWordWrap];
    CGRect aFrame = textLabel.frame;
    aFrame.size = expectedSize;
    textLabel.frame = aFrame;
    
    return cell;
}

-(void)starRatingView:(LIOStarRatingView *)aView didUpdateRating:(int)aRating {
    [selectedIndices removeAllObjects];
    [selectedIndices addObject:[NSIndexPath indexPathForRow:(5 - aRating) inSection:0]];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    LIOSurveyQuestion *question = [currentSurvey.questions objectAtIndex:currentQuestionIndex];

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
    
}

- (void)keyboardDidShow:(NSNotification *)aNotification
{
    
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
    keyboardHeight = 0.0;
    
}


@end
