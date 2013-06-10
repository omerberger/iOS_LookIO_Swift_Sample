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
#import <QuartzCore/QuartzCore.h>

#define LIOSurveyViewPrePageControlHeight     15.0
#define LIOSurveyViewPreTopMarginPortrait     65.0
#define LIOSurveyViewPreTopMarginLandscape    10.0
#define LIOSurveyViewPreSideMargin            10.0
#define LIOSurveyViewPrePageControlOriginY    265.0

#define LIOSurveyViewPreTitleLabelTag          1001
#define LIOSurveyViewPreInputTextFieldTag      1002
#define LIOSurveyViewPreInputBackgroundTag     1003
#define LIOSurveyViewPreTableViewTag           1004
#define LIOSurveyViewPreButtonTag              1005
#define LIOSurveyViewPreTableCellBackgroundTag 1006

#define LIOSurveyViewControllerValidationDuration 5.0

@implementation LIOSurveyViewPre

@synthesize delegate, currentSurvey, headerString;

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
    currentScrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    currentScrollView.alpha = 0.0;
    currentScrollView.transform = CGAffineTransformMakeTranslation(0.0, -self.bounds.size.height);
    currentScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:currentScrollView];
    [currentScrollView release];
    
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

    CGRect aFrame;
    aFrame.origin.x = LIOSurveyViewPreSideMargin;
    aFrame.origin.y = LIOSurveyViewPreTopMarginPortrait;
    aFrame.size.width = self.bounds.size.width - 2*LIOSurveyViewPreSideMargin;
    CGSize expectedLabelSize = [headerLabel.text sizeWithFont:headerLabel.font constrainedToSize:CGSizeMake(aFrame.size.width, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    aFrame.size.height = expectedLabelSize.height;
    headerLabel.frame = aFrame;
    [currentScrollView addSubview:headerLabel];
    [headerLabel release];
    
    UIButton* nextButton = [[UIButton alloc] initWithFrame:CGRectZero];
    UIImage *buttonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableGrayButton"];
    UIImage *stretchableGrayButton = [buttonImage stretchableImageWithLeftCapWidth:2 topCapHeight:0];
    [nextButton setBackgroundImage:stretchableGrayButton forState:UIControlStateNormal];
    [nextButton addTarget:self action:@selector(dismissIntroView:) forControlEvents:UIControlEventTouchUpInside];
    nextButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0];
    nextButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [nextButton setTitle:@"Next" forState:UIControlStateNormal];
    
    aFrame.origin.x = LIOSurveyViewPreSideMargin;
    aFrame.origin.y = headerLabel.frame.origin.y + headerLabel.frame.size.height + 20;
    aFrame.size.width = self.bounds.size.width - 2*LIOSurveyViewPreSideMargin;
    aFrame.size.height = 53.0;
    nextButton.frame = aFrame;
    [currentScrollView addSubview:nextButton];
    [nextButton release];    
    
    CGRect pageControlFrame;
    pageControlFrame.origin.x = 0;
    pageControlFrame.origin.y = self.bounds.size.height - 20.0;
    pageControlFrame.size.width = self.bounds.size.width;
    pageControlFrame.size.height = 20.0;
    
    pageControl = [[UIPageControl alloc] initWithFrame:pageControlFrame];
    pageControl.numberOfPages = [currentSurvey.questions count];
    pageControl.alpha = 0.0;
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

-(void)layoutSubviews {
    UIInterfaceOrientation currentInterfaceOrientation = (UIInterfaceOrientation)[[UIDevice currentDevice] orientation];
    BOOL landscape = UIInterfaceOrientationIsLandscape(currentInterfaceOrientation);

    if (!isAnimating && currentScrollView != nil)
        [self rejiggerSurveyScrollView:currentScrollView];
    
    CGRect pageControlFrame = pageControl.frame;
    pageControlFrame.origin.y = self.bounds.size.height - keyboardHeight - 20.0;
    pageControl.frame = pageControlFrame;
 
    if (validationView != nil) {
        CGRect aFrame = validationView.frame;
        aFrame.origin.y = landscape ? 0 : 32;
        validationView.frame = aFrame;
    }
}

-(void)rejiggerSurveyScrollView:(UIScrollView*)scrollView {
    UIInterfaceOrientation currentInterfaceOrientation = (UIInterfaceOrientation)[[UIDevice currentDevice] orientation];
    BOOL landscape = UIInterfaceOrientationIsLandscape(currentInterfaceOrientation);

    CGRect aFrame;

    UILabel* questionLabel = (UILabel*)[scrollView viewWithTag:LIOSurveyViewPreTitleLabelTag];
    if (questionLabel) {
        aFrame.origin.x = LIOSurveyViewPreSideMargin;
        aFrame.origin.y = landscape ? LIOSurveyViewPreTopMarginLandscape : LIOSurveyViewPreTopMarginPortrait;
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

-(void)dismissIntroView:(id)sender {
    isAnimating = YES;
    
    UIScrollView* nextQuestionScrollView = [self scrollViewForQuestionAtIndex:0];
    nextQuestionScrollView.transform = CGAffineTransformMakeTranslation(self.superview.bounds.size.width, 0.0);
    [self addSubview:nextQuestionScrollView];
    
    [UIView animateWithDuration:0.3 animations:^{
        nextQuestionScrollView.transform = CGAffineTransformIdentity;
        currentScrollView.transform = CGAffineTransformMakeTranslation(-self.bounds.size.width, 0.0);
        pageControl.alpha = 1.0;
    } completion:^(BOOL finished) {
        [currentScrollView removeFromSuperview];
        currentScrollView = nextQuestionScrollView;

        leftSwipeGestureRecognizer = [[[UISwipeGestureRecognizer alloc]
                                       initWithTarget:self action:@selector(handleLeftSwipeGesture:)] autorelease];
        leftSwipeGestureRecognizer.direction =  UISwipeGestureRecognizerDirectionLeft;
        [self addGestureRecognizer:leftSwipeGestureRecognizer];
        
        rightSwipeGestureRecognizer = [[[UISwipeGestureRecognizer alloc]
                                        initWithTarget:self action:@selector(handleRightSwipeGesture:)] autorelease];
        rightSwipeGestureRecognizer.direction =  UISwipeGestureRecognizerDirectionRight;
        [self addGestureRecognizer:rightSwipeGestureRecognizer];
        
        isAnimating = NO;
        
    }];
}

-(void)handleLeftSwipeGesture:(UISwipeGestureRecognizer*)sender
{
    [self switchToNextQuestion];
}

-(void)handleRightSwipeGesture:(UISwipeGestureRecognizer*)sender
{
    if (currentQuestionIndex == 0)
        [self bounceViewLeft];
    else
        [self switchToPreviousQuestion];
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



-(UIScrollView*)scrollViewForQuestionAtIndex:(int)index {
    int numberOfQuestions = [currentSurvey.questions count];
    if (index > numberOfQuestions - 1 || index < 0)
        return nil;
    
    LIOSurveyQuestion *question = [currentSurvey.questions objectAtIndex:index];

    UIScrollView* scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
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
        if (question.validationType == LIOSurveyQuestionValidationTypeNumeric) {
            inputField.keyboardType = UIKeyboardTypeNumberPad;

            NSString* buttonTitle = @"Next";
            if (currentQuestionIndex == numberOfQuestions - 1)
                buttonTitle = @"Done";

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
        
        id aResponse = [[LIOSurveyManager sharedSurveyManager] answerObjectForSurveyType:LIOSurveyManagerSurveyTypePre withQuestionIndex:index];
        if (aResponse && [aResponse isKindOfClass:[NSString class]])
        {
            NSString *responseString = (NSString *)aResponse;
            inputField.text = responseString;
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
        
        
        id aResponse = [[LIOSurveyManager sharedSurveyManager] answerObjectForSurveyType:LIOSurveyManagerSurveyTypePre withQuestionIndex:index];
        if (aResponse && [aResponse isKindOfClass:[NSArray class]])
        {
            NSMutableArray *arrayResponse = (NSMutableArray*)aResponse;
            selectedIndices = arrayResponse;
        } else
            selectedIndices = [[NSMutableArray alloc] init];


    }
    
    [self rejiggerSurveyScrollView:scrollView];
    return [scrollView autorelease];
}

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
    aFrame.origin.y = landscape ? 0 : 32;
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
                NSMutableCharacterSet* wantedCharacters = [NSMutableCharacterSet alphanumericCharacterSet];
                [wantedCharacters formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
                NSCharacterSet *unwantedCharacters = [wantedCharacters invertedSet];
                if ([stringResponse rangeOfCharacterFromSet:unwantedCharacters].location == NSNotFound)
                    validated = YES;
                else
                    [self showAlertWithMessage:LIOLocalizedString(@"LIOSurveyViewController.AlphanumericValidationAlertBody")];
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
            [surveyManager registerAnswerObject:selectedIndices forSurveyType:LIOSurveyManagerSurveyTypePre withQuestionIndex:currentQuestionIndex];
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


-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self switchToNextQuestion];
    
    return NO;
}

-(void)switchToNextQuestion {
    int numberOfQuestions = [currentSurvey.questions count];
    
    if (currentQuestionIndex == numberOfQuestions - 1) {
        pageControl.alpha = 0.0;
        [delegate surveyViewDidFinish:self];
    }
    
    if (currentQuestionIndex > numberOfQuestions - 2)
        return;
    
    if (![self validateAndRegisterCurrentAnswer]) {
        [self bounceViewRight];
        return;
    } else {
        currentQuestionIndex += 1;
        
        if (validationView) {
            [validationTimer stopTimer];
            [validationTimer release];
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
            pageControl.currentPage += 1;
            
        } completion:^(BOOL finished) {
            [currentScrollView removeFromSuperview];
            currentScrollView = nextQuestionScrollView;
            
            isAnimating = NO;
        }];
    }
}

-(void)switchToPreviousQuestion {
    currentQuestionIndex -= 1;
    LIOSurveyQuestion *question = [currentSurvey.questions objectAtIndex:currentQuestionIndex];
    
    UIScrollView* previousQuestionScrollView = [self scrollViewForQuestionAtIndex:currentQuestionIndex];
    previousQuestionScrollView.transform = CGAffineTransformMakeTranslation(-self.bounds.size.width, 0.0);
    [self addSubview:previousQuestionScrollView];
    
    isAnimating = YES;
    [UIView animateWithDuration:0.3 animations:^{
        [currentScrollView endEditing:YES];

        previousQuestionScrollView.transform = CGAffineTransformIdentity;
        currentScrollView.transform = CGAffineTransformMakeTranslation(self.bounds.size.width, 0.0);

        pageControl.currentPage -= 1;

    } completion:^(BOOL finished) {
        [currentScrollView removeFromSuperview];
        currentScrollView = previousQuestionScrollView;
        
        isAnimating = NO;
    }];
}

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

- (void)keyboardWillHide:(NSNotification *)aNotification
{
    keyboardHeight = 0.0;
}


@end
