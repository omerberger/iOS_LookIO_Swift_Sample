//
//  LIOPreSurveyView.m
//  LookIO
//
//  Created by Yaron Karasik on 5/30/13.
//
//

#import "LIOSurveyViewPre.h"
#import "LIOSurveyManager.h"
#import "LIOSurveyTemplate.h"
#import "LIOSurveyQuestion.h"
#import "LIOBundleManager.h"
#import "LIOSurveyPickerEntry.h"
#import "LIOSurveyValidationView.h"
#import "LIOTimerProxy.h"
#import "LIOHeaderBarView.h"
#import <QuartzCore/QuartzCore.h>

#define LIOSurveyViewPrePageControlHeight     15.0
#define LIOSurveyViewPreTopMarginPortrait     70.0
#define LIOSurveyViewPreTopMarginLandscape    10.0
#define LIOSurveyViewPreSideMargin            10.0
#define LIOSurveyViewPrePageControlOriginY    265.0

#define LIOSurveyViewPreTitleLabelTag          1001
#define LIOSurveyViewPreInputTextFieldTag      1002
#define LIOSurveyViewPreInputBackgroundTag     1003
#define LIOSurveyViewPreTableViewTag           1004
#define LIOSurveyViewPreButtonTag              1005
#define LIOSurveyViewPreTableCellBackgroundTag 1006

#define LIOSurveyViewPreIntroHeaderLabel       1007
#define LIOSurveyViewPreIntroRequiredLabel     1008
#define LIOSurveyViewPreIntroNextButton        1009
#define LIOSurveyViewPreIntroCancelButton      1010

#define LIOSurveyViewControllerValidationDuration 5.0

#define LIOIndexForSurveyIntroPage  -1

@implementation LIOSurveyViewPre

@synthesize delegate, currentSurvey, headerString, currentQuestionIndex;

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
    
    NSLog(@"Current question index is %d", currentQuestionIndex);
    
    if (LIOIndexForSurveyIntroPage == currentQuestionIndex)
        currentScrollView = [self scrollViewForIntroView];
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
    pageControl.numberOfPages = [[LIOSurveyManager sharedSurveyManager] numberOfQuestionsWithLogicForSurveyType:LIOSurveyManagerSurveyTypePre] + 1;
    if (currentQuestionIndex == LIOIndexForSurveyIntroPage)
        pageControl.currentPage = 0;
    else
        pageControl.currentPage = [[LIOSurveyManager sharedSurveyManager] realIndexWithLogicOfQuestionAtIndex:currentQuestionIndex forSurveyType:LIOSurveyManagerSurveyTypePre] + 1;
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
        [self rejiggerIntroScrollView:currentScrollView];
    } else {
        if (!isAnimating && currentScrollView != nil)
            [self rejiggerSurveyScrollView:currentScrollView];
    }
    
    NSLog(@"Keyboard height is %f", keyboardHeight);
    
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


-(UIScrollView*)scrollViewForIntroView {
    UIScrollView* scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
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
    headerLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18.0];
    headerLabel.numberOfLines = 0;
    headerLabel.text = headerString;
    headerLabel.textAlignment = UITextAlignmentCenter;
    headerLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    headerLabel.tag = LIOSurveyViewPreIntroHeaderLabel;
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
    requiredLabel.tag = LIOSurveyViewPreIntroRequiredLabel;
    [scrollView addSubview:requiredLabel];
    [requiredLabel release];
    
    UIButton* nextButton = [[UIButton alloc] initWithFrame:CGRectZero];
    UIImage *buttonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableGrayButton"];
    UIImage *stretchableGrayButton = [buttonImage stretchableImageWithLeftCapWidth:2 topCapHeight:0];
    [nextButton setBackgroundImage:stretchableGrayButton forState:UIControlStateNormal];
    [nextButton addTarget:self action:@selector(handleLeftSwipeGesture:) forControlEvents:UIControlEventTouchUpInside];
    nextButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0];
    nextButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [nextButton setTitle:@"Next" forState:UIControlStateNormal];
    nextButton.tag = LIOSurveyViewPreIntroNextButton;
    [scrollView addSubview:nextButton];
    [nextButton release];

    UIButton* cancelButton = [[UIButton alloc] initWithFrame:CGRectZero];
    UIImage *cancelButtonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableGrayButton"];
    UIImage *stretchableCancelButtonImage = [cancelButtonImage stretchableImageWithLeftCapWidth:2 topCapHeight:0];
    [cancelButton setBackgroundImage:stretchableCancelButtonImage forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0];
    cancelButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    cancelButton.tag = LIOSurveyViewPreIntroCancelButton;
    [scrollView addSubview:cancelButton];
    [cancelButton release];
    
    [self rejiggerIntroScrollView:scrollView];
    
    return [scrollView autorelease];
}


-(void)rejiggerIntroScrollView:(UIScrollView*)scrollView {
    UIInterfaceOrientation currentInterfaceOrientation = (UIInterfaceOrientation)[[UIDevice currentDevice] orientation];
    BOOL landscape = UIInterfaceOrientationIsLandscape(currentInterfaceOrientation);
    
    CGRect aFrame;
    
    UILabel* headerLabel = (UILabel*)[scrollView viewWithTag:LIOSurveyViewPreIntroHeaderLabel];

    aFrame.origin.x = LIOSurveyViewPreSideMargin;
    aFrame.origin.y = landscape ? LIOSurveyViewPreTopMarginLandscape : LIOSurveyViewPreTopMarginPortrait;
    aFrame.size.width = self.bounds.size.width - 2*LIOSurveyViewPreSideMargin;
    CGSize expectedLabelSize = [headerLabel.text sizeWithFont:headerLabel.font constrainedToSize:CGSizeMake(aFrame.size.width, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    aFrame.size.height = expectedLabelSize.height;
    headerLabel.frame = aFrame;
    
    UILabel* requiredLabel = (UILabel*)[scrollView viewWithTag:LIOSurveyViewPreIntroRequiredLabel];
    
    aFrame.origin.x = LIOSurveyViewPreSideMargin;
    aFrame.origin.y = headerLabel.frame.origin.y + headerLabel.frame.size.height + 15.0;
    aFrame.size.width = self.bounds.size.width - 2*LIOSurveyViewPreSideMargin;
    expectedLabelSize = [requiredLabel.text sizeWithFont:requiredLabel.font constrainedToSize:CGSizeMake(aFrame.size.width, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    aFrame.size.height = expectedLabelSize.height;
    requiredLabel.frame = aFrame;
    
    UIButton* nextButton = (UILabel*)[scrollView viewWithTag:LIOSurveyViewPreIntroNextButton];
    
    aFrame.origin.x = LIOSurveyViewPreSideMargin;
    aFrame.origin.y = requiredLabel.frame.origin.y + requiredLabel.frame.size.height + 20;
    aFrame.size.width = self.bounds.size.width - 2*LIOSurveyViewPreSideMargin;
    aFrame.size.height = 53.0;
    nextButton.frame = aFrame;
    
    UIButton* cancelButton = (UILabel*)[scrollView viewWithTag:LIOSurveyViewPreIntroCancelButton];
    
    aFrame.origin.x = LIOSurveyViewPreSideMargin;
    aFrame.origin.y = nextButton.frame.origin.y + nextButton.frame.size.height + 20;
    aFrame.size.width = self.bounds.size.width - 2*LIOSurveyViewPreSideMargin;
    aFrame.size.height = 53.0;
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
    UIScrollView* scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    scrollView.showsVerticalScrollIndicator = NO;
    
    UIView* dismissBackgroundView = [[UIView alloc] initWithFrame:scrollView.bounds];
    dismissBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [dismissBackgroundView addGestureRecognizer:tapGestureRecognizer];
    [scrollView addSubview:dismissBackgroundView];
    [dismissBackgroundView release];
    
    UILabel* questionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    questionLabel.tag = LIOSurveyViewPreTitleLabelTag;
    questionLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    questionLabel.layer.shadowRadius = 1.0;
    questionLabel.layer.shadowOpacity = 1.0;
    questionLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    questionLabel.backgroundColor = [UIColor clearColor];
    questionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18.0];
    questionLabel.textColor = [UIColor whiteColor];
    questionLabel.numberOfLines = 0;
    questionLabel.text = question.label;
    if (question.mandatory)
        questionLabel.text = [NSString stringWithFormat:@"%@ *", questionLabel.text];
    questionLabel.textAlignment = UITextAlignmentCenter;
    [scrollView addSubview:questionLabel];
    [questionLabel release];
    
    if (LIOSurveyQuestionDisplayTypeText == question.displayType) {
        UIImage *fieldImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableWhiteTextField"];
        UIImage *stretchableFieldImage = [fieldImage stretchableImageWithLeftCapWidth:1 topCapHeight:0];
        
        UIImageView *fieldBackground = [[[UIImageView alloc] initWithImage:stretchableFieldImage] autorelease];
        fieldBackground.tag = LIOSurveyViewPreInputBackgroundTag;
        fieldBackground.userInteractionEnabled = YES;
        fieldBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [scrollView addSubview:fieldBackground];
        
        UITextField *inputField = [[[UITextField alloc] init] autorelease];
        inputField.tag = LIOSurveyViewPreInputTextFieldTag;
        inputField.delegate = self;
        inputField.backgroundColor = [UIColor clearColor];
        inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        inputField.font = [UIFont fontWithName:@"HelveticaNeue" size:18.0];
        inputField.textColor = [UIColor colorWithWhite:0.44 alpha:1.0];
        inputField.autocorrectionType = UITextAutocorrectionTypeNo;
        if (currentQuestionIndex == numberOfQuestions - 1)
            inputField.returnKeyType = UIReturnKeyDone;
        else
            inputField.returnKeyType = UIReturnKeyNext;
        inputField.keyboardAppearance = UIKeyboardAppearanceAlert;
        
        if (LIOSurveyQuestionValidationTypeEmail == question.validationType)
            inputField.keyboardType = UIKeyboardTypeEmailAddress;
        if (LIOSurveyQuestionValidationTypeNumeric == question.validationType) {
            inputField.keyboardType = UIKeyboardTypeNumberPad;
            
            NSString* buttonTitle = @"Next";
            if (currentQuestionIndex == numberOfQuestions - 1)
                buttonTitle = @"Done";
            
            if (!padUI) {
                UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
                numberToolbar.barStyle = UIBarStyleBlackTranslucent;
                numberToolbar.items = [NSArray arrayWithObjects:
                                       [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                       [[UIBarButtonItem alloc]initWithTitle:buttonTitle style:UIBarButtonItemStyleDone target:self action:@selector(switchToNextQuestion)],
                                       nil];
                [numberToolbar sizeToFit];
                inputField.inputAccessoryView = numberToolbar;
                [numberToolbar release];
            }
        }
        
        // If the user has answered this survey, we should display their answer        
        id aResponse = [[LIOSurveyManager sharedSurveyManager] answerObjectForSurveyType:LIOSurveyManagerSurveyTypePre withQuestionIndex:index];
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
        UITableView* tableView = [[UITableView alloc]
                                  initWithFrame:CGRectZero style:UITableViewStylePlain];
        tableView.tag = LIOSurveyViewPreTableViewTag;
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
        nextButton.tag = LIOSurveyViewPreButtonTag;
        UIImage *buttonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableGrayButton"];
        UIImage *stretchableGrayButton = [buttonImage stretchableImageWithLeftCapWidth:2 topCapHeight:0];
        [nextButton setBackgroundImage:stretchableGrayButton forState:UIControlStateNormal];
        [nextButton addTarget:self action:@selector(handleLeftSwipeGesture:) forControlEvents:UIControlEventTouchUpInside];
        nextButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0];
        nextButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        if (currentQuestionIndex == numberOfQuestions - 1)
            [nextButton setTitle:@"Done" forState:UIControlStateNormal];
        else
            [nextButton setTitle:@"Next" forState:UIControlStateNormal];
        [scrollView addSubview:nextButton];
        [nextButton release];
        
        selectedIndices = [[NSMutableArray alloc] init];
        
        // If the user has answered this survey, we should display their answer

        id aResponse = [[LIOSurveyManager sharedSurveyManager] answerObjectForSurveyType:LIOSurveyManagerSurveyTypePre withQuestionIndex:index];
        if (aResponse) {
            NSMutableArray* answersArray;
            
            if (aResponse && [aResponse isKindOfClass:[NSString class]]) {
                NSString* answerString = (NSString*)aResponse;
                answersArray = [[NSMutableArray alloc] initWithObjects:answerString, nil];
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
            for (LIOSurveyPickerEntry* pickerEntry in question.pickerEntries) {
                if (pickerEntry.initiallyChecked) {
                    int questionRow = [question.pickerEntries indexOfObject:pickerEntry];
                    [selectedIndices addObject:[NSIndexPath indexPathForRow:questionRow inSection:0]];
                }
            }
        }
    }
    
    [self rejiggerSurveyScrollView:scrollView];
    return [scrollView autorelease];
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

    UILabel* questionLabel = (UILabel*)[scrollView viewWithTag:LIOSurveyViewPreTitleLabelTag];
    if (questionLabel) {
        aFrame.origin.x = LIOSurveyViewPreSideMargin;
        aFrame.origin.y = (landscape && !padUI) ? LIOSurveyViewPreTopMarginLandscape : LIOSurveyViewPreTopMarginPortrait;
        aFrame.size.width = self.bounds.size.width - LIOSurveyViewPreSideMargin*2;
        CGSize expectedLabelSize = [questionLabel.text sizeWithFont:questionLabel.font constrainedToSize:CGSizeMake(aFrame.size.width, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
        aFrame.size.height = expectedLabelSize.height;
        questionLabel.frame = aFrame;
    }
    
    UIImageView* fieldBackground = (UIImageView*)[scrollView viewWithTag:LIOSurveyViewPreInputBackgroundTag];
    if (fieldBackground) {
        aFrame = fieldBackground.frame;
        aFrame.origin.x = 10.0;
        aFrame.size.width = self.bounds.size.width - 20.0;
        aFrame.size.height = landscape ? 40.0 : 48.0;
        aFrame.origin.y = questionLabel.frame.origin.y + questionLabel.frame.size.height + 10.0;
        fieldBackground.frame = aFrame;
    }
    
    UITextField* inputField = (UITextField*)[scrollView viewWithTag:LIOSurveyViewPreInputTextFieldTag];
    if (inputField) {
        aFrame.origin.x = 15.0;
        aFrame.origin.y = landscape ? 8.0 : 12.0;
        aFrame.size.width = fieldBackground.frame.size.width - 20.0;
        aFrame.size.height = 28.0;
        inputField.frame = aFrame;
        
        // Set up the scroll view to allow scrolling down to the text field if needed
        CGSize aSize;
        aSize.width = scrollView.frame.size.width;
        aSize.height = fieldBackground.frame.origin.y + fieldBackground.frame.size.height + 30.0;
        scrollView.contentSize = aSize;
        
        NSLog(@"Scroll view size is %f, %f and content size is %f, %f", scrollView.frame.size.width, scrollView.frame.size.height, aSize.width, aSize.height);
        
    }
    
    UITableView* tableView = (UITableView*)[scrollView viewWithTag:LIOSurveyViewPreTableViewTag];
    if (tableView) {
        CGFloat tableViewContentHeight = [self tableView:tableView heightForRowAtIndexPath:0]*[self tableView:tableView numberOfRowsInSection:0];
        CGFloat maxHeight = self.bounds.size.height - 53.0 - questionLabel.bounds.size.height - 60.0;
        if (tableViewContentHeight > maxHeight) {
            tableView.scrollEnabled = YES;
            tableViewContentHeight = maxHeight;
        } else {
            tableView.scrollEnabled = NO;
        }
    
        tableView.frame = CGRectMake(9.0, questionLabel.frame.origin.y + questionLabel.frame.size.height + 10.0, self.bounds.size.width - 18.0, tableViewContentHeight);
    
        UIButton* nextButton = (UIButton*)[scrollView viewWithTag:LIOSurveyViewPreButtonTag];
        aFrame.origin.x = (self.bounds.size.width - (302.0))/2.0;
        aFrame.origin.y = tableView.frame.origin.y + tableView.frame.size.height + 15;
        aFrame.size.width = 302.0;
        aFrame.size.height = 53.0;
        nextButton.frame = aFrame;
    }

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
            if ([[LIOSurveyManager sharedSurveyManager] shouldShowQuestion:currentQuestionIndex surveyType:LIOSurveyManagerSurveyTypePre])
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

            pageControl.numberOfPages = [[LIOSurveyManager sharedSurveyManager] numberOfQuestionsWithLogicForSurveyType:LIOSurveyManagerSurveyTypePre] + 1;
            pageControl.currentPage = [[LIOSurveyManager sharedSurveyManager] realIndexWithLogicOfQuestionAtIndex:currentQuestionIndex forSurveyType:LIOSurveyManagerSurveyTypePre] + 1;
        } completion:^(BOOL finished) {
            [currentScrollView removeFromSuperview];
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
            if ([[LIOSurveyManager sharedSurveyManager] shouldShowQuestion:currentQuestionIndex surveyType:LIOSurveyManagerSurveyTypePre])
                foundPreviousPage = YES;
    }

    UIScrollView* previousQuestionScrollView;
    
    if (LIOIndexForSurveyIntroPage == currentQuestionIndex)
        previousQuestionScrollView = [self scrollViewForIntroView];
    else
        previousQuestionScrollView = [self scrollViewForQuestionAtIndex:currentQuestionIndex];
    
    previousQuestionScrollView.transform = CGAffineTransformMakeTranslation(-self.bounds.size.width, 0.0);
    [self addSubview:previousQuestionScrollView];
    
    isAnimating = YES;
    [UIView animateWithDuration:0.3 animations:^{
        [currentScrollView endEditing:YES];
        
        previousQuestionScrollView.transform = CGAffineTransformIdentity;
        currentScrollView.transform = CGAffineTransformMakeTranslation(self.bounds.size.width, 0.0);
        
        pageControl.numberOfPages = [[LIOSurveyManager sharedSurveyManager] numberOfQuestionsWithLogicForSurveyType:LIOSurveyManagerSurveyTypePre] + 1;
        pageControl.currentPage = [[LIOSurveyManager sharedSurveyManager] realIndexWithLogicOfQuestionAtIndex:currentQuestionIndex forSurveyType:LIOSurveyManagerSurveyTypePre] + 1;
        
        if (validationView) {
            [validationTimer stopTimer];
            [self validationTimerDidFire];
        }
        
        
    } completion:^(BOOL finished) {
        [currentScrollView removeFromSuperview];
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
    
    if (LIOSurveyQuestionDisplayTypeText == currentQuestion.displayType)
    {
        UITextField* inputField = (UITextField*)[currentScrollView viewWithTag:LIOSurveyViewPreInputTextFieldTag];
        NSString* stringResponse = inputField.text;

        if (0 == [stringResponse length])
        {
            // An empty response is okay for optional questions.
            if (NO == currentQuestion.mandatory) {
                surveyManager.lastCompletedQuestionIndexPre = currentQuestionIndex;
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
                [surveyManager registerAnswerObject:stringResponse forSurveyType:LIOSurveyManagerSurveyTypePre withQuestionIndex:currentQuestionIndex];
                surveyManager.lastCompletedQuestionIndexPre = currentQuestionIndex;
                return YES;
            } else
                return NO;
        }
    }
    else 
    {
        if (currentQuestion.mandatory && 0 == [selectedIndices count])
        {
            [self showAlertWithMessage:LIOLocalizedString(@"LIOSurveyViewController.ResponseAlertBody")];
            return NO;
        }
        else
        {
            if (LIOSurveyQuestionDisplayTypeMultiselect) {
                NSMutableArray* selectedAnswers = [NSMutableArray array];
                for (NSIndexPath* indexPath in selectedIndices) {
                    LIOSurveyPickerEntry* selectedPickerEntry = (LIOSurveyPickerEntry*)[currentQuestion.pickerEntries objectAtIndex:indexPath.row];
                    [selectedAnswers addObject:selectedPickerEntry.label];
                }
                [surveyManager registerAnswerObject:selectedAnswers forSurveyType:LIOSurveyManagerSurveyTypePre withQuestionIndex:currentQuestionIndex];

            }
            
            if (LIOSurveyQuestionDisplayTypePicker) {
                if (selectedIndices.count == 1) {
                    NSIndexPath* indexPath = (NSIndexPath*)[selectedIndices objectAtIndex:0];
                    LIOSurveyPickerEntry* selectedPickerEntry = (LIOSurveyPickerEntry*)[currentQuestion.pickerEntries objectAtIndex:indexPath.row];
                    [surveyManager registerAnswerObject:selectedPickerEntry.label forSurveyType:LIOSurveyManagerSurveyTypePre withQuestionIndex:currentQuestionIndex];
                }                    
            }
            
            surveyManager.lastCompletedQuestionIndexPre = currentQuestionIndex;
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
    return 55;
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

        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:18.0];
        cell.textLabel.textColor = [UIColor colorWithWhite:0.43 alpha:1.0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIImageView* backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(9.0, 0, tableView.bounds.size.width - 20.0, 55.0)];
        backgroundImageView.tag = LIOSurveyViewPreTableCellBackgroundTag;
        backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        cell.backgroundView = backgroundImageView;
        [backgroundImageView release];
    }
    
    LIOSurveyQuestion *question = [currentSurvey.questions objectAtIndex:currentQuestionIndex];
    LIOSurveyPickerEntry* pickerEntry = [question.pickerEntries objectAtIndex:indexPath.row];
    
    UIImageView* backgroundImageView = (UIImageView*)cell.backgroundView;


    UIImage *backgroundImage;
    if (indexPath.row == 0) {
        backgroundImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableSurveyTableTopCell"];
    } else {
        if (indexPath.row == question.pickerEntries.count - 1)
            backgroundImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableSurveyTableBottomCell"];
        else
            backgroundImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableSurveyTableMiddleCell"];
    }
    UIImage *stretchableBackgroundImage = [backgroundImage stretchableImageWithLeftCapWidth:5 topCapHeight:55];
    backgroundImageView.image = stretchableBackgroundImage;
    
    cell.textLabel.text = pickerEntry.label;
    cell.textLabel.font = [UIFont systemFontOfSize:16.0];
    
    BOOL isRowSelected = NO;
        
    for (NSIndexPath* selectedIndexPath in selectedIndices) {
        if (indexPath.row == selectedIndexPath.row) {
            isRowSelected = YES;
        }
    }
        
    if (isRowSelected) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0];
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
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
}

#pragma mark
#pragma mark UITextField delegate methods

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self switchToNextQuestion];
    
    return NO;
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
