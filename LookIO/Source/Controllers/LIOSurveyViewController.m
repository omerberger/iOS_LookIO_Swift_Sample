//
//  LIOSurveyViewController.m
//  LookIO
//
//  Created by Joseph Toscano on 7/9/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import "LIOSurveyViewController.h"
#import "LIOBundleManager.h"
#import "LIOSurveyManager.h"
#import "LIOSurveyTemplate.h"
#import "LIOSurveyQuestion.h"
#import "LIOSurveyPickerEntry.h"
#import "LIOSurveyPickerView.h"
#import <QuartzCore/QuartzCore.h>
#import "LIOLogManager.h"
#import "LIONavigationBar.h"

@interface LIOSurveyViewController ()
- (void)prepareNextScrollView;
@end

@implementation LIOSurveyViewController

@synthesize delegate, currentSurvey, headerString, currentQuestionIndex;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
    }
    
    return self;
}

- (void)loadView
{
    [super loadView];
    
    navBar = [[LIONavigationBar alloc] init];
    CGRect aFrame = navBar.frame;
    aFrame.size.width = self.view.frame.size.width;
    navBar.frame = aFrame;
    navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    navBar.leftButtonText = @"Cancel";
    navBar.rightButtonText = @"Next";
    navBar.delegate = self;
    [navBar layoutSubviews];
    [self.view addSubview:navBar];
    
    [self prepareNextScrollView];
    currentQuestionIndex++;
    
    currentScrollView = nextScrollView;
    nextScrollView = nil;

    [self.view addSubview:currentScrollView];

    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (currentInputField)
            [currentInputField becomeFirstResponder];
    });
    
    if (currentPickerView)
        [self.view bringSubviewToFront:currentPickerView];
    
    [self.view bringSubviewToFront:navBar];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [currentScrollView release];
    [headerString release];
    [currentSurvey release];
    
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [delegate surveyViewController:self shouldRotateToInterfaceOrientation:interfaceOrientation];
}

- (void)prepareNextScrollView
{
    if (nextScrollView)
        return;
    
    int numQuestions = [currentSurvey.questions count];
    if (currentQuestionIndex >= numQuestions - 1)
        return;
    
    currentInputField = nil;
    currentQuestionLabel = nil;
    
    int nextQuestionIndex = currentQuestionIndex + 1;
    
    LIOSurveyQuestion *nextQuestion = [currentSurvey.questions objectAtIndex:nextQuestionIndex];
    
    UIColor *textColor = [UIColor colorWithWhite:0.25 alpha:1.0];
    
    nextScrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    CGRect aFrame = nextScrollView.frame;
    aFrame.origin.y = navBar.frame.size.height;
    aFrame.size.height -= aFrame.origin.y;
    nextScrollView.frame = aFrame;
    nextScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UIImage *texture = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIORepeatableSurveyBackgroundTexture"];
    //texture = [texture stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    
    UIImageView *backgroundView = [[[UIImageView alloc] init] autorelease];
    //backgroundView.image = texture;
    backgroundView.backgroundColor = [UIColor colorWithPatternImage:texture];
    aFrame = CGRectZero;
    aFrame.size.width = self.view.bounds.size.width;
    aFrame.origin.y = self.view.bounds.size.height * -2.0;
    aFrame.size.height = self.view.bounds.size.height * 4.0;
    backgroundView.frame = aFrame;
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [nextScrollView addSubview:backgroundView];
    
    UILabel *headerLabel = [[[UILabel alloc] init] autorelease];
    headerLabel.text = headerString;
    headerLabel.textColor = textColor;
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.font = [UIFont systemFontOfSize:14.0];
    headerLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    headerLabel.textAlignment = UITextAlignmentCenter;
    headerLabel.numberOfLines = 0;
    headerLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    headerLabel.layer.shadowOffset = CGSizeMake(1.0, 1.0);
    headerLabel.layer.shadowOpacity = 0.33;
    headerLabel.layer.shadowRadius = 0.75;
    CGSize headerLabelSize = [headerLabel.text sizeWithFont:headerLabel.font constrainedToSize:CGSizeMake(self.view.bounds.size.width - 20.0, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    aFrame = headerLabel.frame;
    aFrame.size = headerLabelSize;
    aFrame.origin.y = 10.0;
    aFrame.origin.x = 10.0;
    headerLabel.frame = aFrame;
    [nextScrollView addSubview:headerLabel];
    
    UILabel *questionNumberLabel = [[[UILabel alloc] init] autorelease];
    questionNumberLabel.font = [UIFont boldSystemFontOfSize:14.0];
    questionNumberLabel.textColor = textColor;
    questionNumberLabel.backgroundColor = [UIColor clearColor];
    questionNumberLabel.numberOfLines = 1;
    questionNumberLabel.text = [NSString stringWithFormat:@"Question %d of %d:", nextQuestionIndex + 1, currentSurvey.questions.count];
    questionNumberLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    questionNumberLabel.layer.shadowOffset = CGSizeMake(1.0, 1.0);
    questionNumberLabel.layer.shadowOpacity = 0.33;
    questionNumberLabel.layer.shadowRadius = 0.75;
    [questionNumberLabel sizeToFit];
    aFrame = questionNumberLabel.frame;
    aFrame.origin.x = 10.0;
    aFrame.origin.y = headerLabel.frame.origin.y + headerLabel.frame.size.height + 10.0;
    questionNumberLabel.frame = aFrame;
    [nextScrollView addSubview:questionNumberLabel];
    
    UILabel *questionLabel = [[[UILabel alloc] init] autorelease];
    questionLabel.text = nextQuestion.label;
    questionLabel.textColor = textColor;
    questionLabel.backgroundColor = [UIColor clearColor];
    questionLabel.font = [UIFont systemFontOfSize:16.0];
    questionLabel.numberOfLines = 0;
    questionLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    questionLabel.layer.shadowOffset = CGSizeMake(1.0, 1.0);
    questionLabel.layer.shadowOpacity = 0.33;
    questionLabel.layer.shadowRadius = 0.75;
    CGSize questionLabelSize = [questionLabel.text sizeWithFont:questionLabel.font constrainedToSize:CGSizeMake(self.view.bounds.size.width - 20.0, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    aFrame = questionLabel.frame;
    aFrame.size = questionLabelSize;
    aFrame.origin.x = 10.0;
    aFrame.origin.y = questionNumberLabel.frame.origin.y + questionNumberLabel.frame.size.height;
    questionLabel.frame = aFrame;
    [nextScrollView addSubview:questionLabel];
    
    currentQuestionLabel = questionLabel;
    
    if (nextQuestionIndex + 1 >= [currentSurvey.questions count])
    {
        navBar.rightButtonText = @" Start Chat "; // FIXME: aaaaaaaahahahaha
        [navBar layoutSubviews];
    }
    
    if (LIOSurveyQuestionDisplayTypeText == nextQuestion.displayType)
    {
        UIImage *fieldImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOAboutStretchableInputField"];
        UIImage *stretchableFieldImage = [fieldImage stretchableImageWithLeftCapWidth:11 topCapHeight:0];
        
        UIImageView *fieldBackground = [[[UIImageView alloc] initWithImage:stretchableFieldImage] autorelease];
        fieldBackground.userInteractionEnabled = YES;
        aFrame = fieldBackground.frame;
        aFrame.origin.x = 10.0;
        aFrame.size.width = self.view.bounds.size.width - 20.0;
        aFrame.size.height = 48.0;
        aFrame.origin.y = questionLabel.frame.origin.y + questionLabel.frame.size.height + 10.0;
        fieldBackground.frame = aFrame;
        fieldBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [nextScrollView addSubview:fieldBackground];
        
        currentInputFieldBackground = fieldBackground;
        
        UITextField *inputField = [[[UITextField alloc] init] autorelease];
        inputField.delegate = self;
        inputField.backgroundColor = [UIColor clearColor];
        aFrame.origin.x = 10.0;
        aFrame.origin.y = 14.0;
        aFrame.size.width = fieldBackground.frame.size.width - 20.0;
        aFrame.size.height = 28.0;
        inputField.frame = aFrame;
        inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        inputField.font = [UIFont systemFontOfSize:14.0];
        inputField.returnKeyType = UIReturnKeyNext;
        inputField.keyboardAppearance = UIKeyboardAppearanceAlert;
        [fieldBackground addSubview:inputField];
        
        if (LIOSurveyQuestionValidationTypeEmail == nextQuestion.validationType)
        {
            inputField.placeholder = @"name@example.com";
            inputField.keyboardType = UIKeyboardTypeEmailAddress;
            inputField.autocorrectionType = UITextAutocorrectionTypeNo;
            inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        }
        else if (LIOSurveyQuestionValidationTypeNumeric == nextQuestion.validationType)
        {
            inputField.placeholder = @"12345";
            inputField.keyboardType = UIKeyboardTypeNumberPad;
            inputField.autocorrectionType = UITextAutocorrectionTypeNo;
            inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        }
        
        if (nextQuestionIndex + 1 >= [currentSurvey.questions count])
            inputField.returnKeyType = UIReturnKeyDone;
        
        currentInputField = inputField;
        
        nextScrollView.contentSize = CGSizeMake(0.0, inputField.frame.origin.y + inputField.frame.size.height);
    }
    else if (LIOSurveyQuestionDisplayTypePicker == nextQuestion.displayType || LIOSurveyQuestionDisplayTypeMultiselect == nextQuestion.displayType)
    {
        currentPickerView = [[[LIOSurveyPickerView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, 0.0)] autorelease];
        currentPickerView.surveyQuestion = nextQuestion;
        currentPickerView.delegate = self;
        
        if (LIOSurveyQuestionDisplayTypePicker == nextQuestion.displayType)
            currentPickerView.currentMode = LIOSurveyPickerViewModeSingle;
        else if (LIOSurveyQuestionDisplayTypeMultiselect == nextQuestion.displayType)
            currentPickerView.currentMode = LIOSurveyPickerViewModeMulti;
        
        [self.view addSubview:currentPickerView];
        [currentPickerView layoutSubviews];
        
        CGRect aFrame = currentPickerView.frame;
        aFrame.origin.y = self.view.bounds.size.height - aFrame.size.height;
        currentPickerView.frame = aFrame;
        
        [currentPickerView showAnimated];
        
        if (nextQuestionIndex + 1 >= [currentSurvey.questions count])
        {
            [currentPickerView.doneButton setTitle:@"Start Chat" forState:UIControlStateNormal];
        }
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (keyboardUnderlay)
        keyboardUnderlay.hidden = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self rejiggerInterface];
    
    if (keyboardUnderlay)
        keyboardUnderlay.hidden = NO;
}

- (void)switchToNextQuestion
{
    if (currentQuestionIndex + 1 >= [currentSurvey.questions count])
    {
        [self.view endEditing:YES];
        [delegate surveyViewControllerDidFinishSurvey:self];
        return;
    }
    
    if (currentPickerView)
    {
        [currentPickerView hideAnimated];
        oldPickerView = currentPickerView;
    }
    
    UIScrollView *oldScrollView = currentScrollView;
    [self prepareNextScrollView];
    currentScrollView = nextScrollView;
    nextScrollView = nil;
    
    currentQuestionIndex++;
    
    CGRect startingFrame = currentScrollView.frame;
    startingFrame.origin.x = self.view.bounds.size.width;
    currentScrollView.frame = startingFrame;
    
    [self.view addSubview:currentScrollView];
    if (currentPickerView)
    {
        [self.view endEditing:YES];
        [self.view bringSubviewToFront:currentPickerView];
    }
    
    CGRect targetFrameForNew = currentScrollView.frame;
    targetFrameForNew.origin.x = 0.0;
    
    CGRect targetFrameForOld = oldScrollView.frame;
    targetFrameForOld.origin.x = -self.view.bounds.size.width;
    
    [UIView animateWithDuration:0.33
                          delay:0.0
                        options:UIViewAnimationCurveEaseInOut
                     animations:^{
                         currentScrollView.frame = targetFrameForNew;
                         oldScrollView.frame = targetFrameForOld;
                     } completion:^(BOOL finished) {
                         [oldScrollView removeFromSuperview];
                         [oldScrollView release];
                         
                         if (currentInputField)
                             [currentInputField becomeFirstResponder];
                     }];
    
    [self.view bringSubviewToFront:navBar];
}

- (void)showAlertWithMessage:(NSString *)aMessage
{
    [self.view endEditing:YES];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:aMessage
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Dismiss", nil];
    [alertView show];
    [alertView autorelease];
}

- (void)rejiggerInterface
{
    [navBar layoutSubviews];

    CGRect aFrame = currentScrollView.frame;
    aFrame.origin.y = navBar.bounds.size.height;
    if (keyboardShown)
    {
        aFrame.size.height = self.view.bounds.size.height - keyboardFrame.size.height - navBar.bounds.size.height;
    }
    else if (currentPickerView)
    {
        [currentPickerView layoutSubviews];
        CGRect pickerFrame = currentPickerView.frame;
        pickerFrame.origin.y = self.view.bounds.size.height - pickerFrame.size.height;
        pickerFrame.origin.x = 0.0;
        pickerFrame.size.width = self.view.bounds.size.width;
        currentPickerView.frame = pickerFrame;
        
        aFrame.size.height = self.view.bounds.size.height - currentPickerView.bounds.size.height - navBar.bounds.size.height;
    }
    else
    {
        aFrame.size.height = self.view.bounds.size.height - navBar.bounds.size.height;
    }
    currentScrollView.frame = aFrame;
    
    if (currentInputField)
    {
        CGSize blah = CGSizeMake(0.0, currentInputFieldBackground.frame.origin.y + currentInputFieldBackground.frame.size.height + 10.0);
        currentScrollView.contentSize = blah;
        
        [currentScrollView scrollRectToVisible:currentInputFieldBackground.frame animated:NO];
    }
    else if (currentQuestionLabel)
    {
        CGSize blah = CGSizeMake(0.0, currentQuestionLabel.frame.origin.y + currentQuestionLabel.frame.size.height + 10.0);
        currentScrollView.contentSize = blah;
        
        [currentScrollView scrollRectToVisible:currentQuestionLabel.frame animated:NO];
    }
    
    if (keyboardUnderlay)
        keyboardUnderlay.frame = keyboardFrame;
}

#pragma mark - UITextFieldDelegate methods -

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self navigationBarDidTapRightButton:navBar];
    return NO;
}

#pragma mark - UIAlertViewDelegate methods -

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (currentInputField)
        [currentInputField becomeFirstResponder];
}

#pragma mark - LIOSurveyPickerViewDelegate methods -

- (void)surveyPickerViewDidTapSelect:(LIOSurveyPickerView *)aView;
{
    [self navigationBarDidTapRightButton:navBar];
}

- (void)surveyPickerViewDidFinishDismissalAnimation:(LIOSurveyPickerView *)aView
{
    if (oldPickerView)
    {
        [oldPickerView removeFromSuperview];
        oldPickerView = nil;
    }
}

#pragma mark -
#pragma mark Notification handlers

- (void)keyboardDidShow:(NSNotification *)aNotification
{
    if (keyboardShown)
        return;
    
    keyboardShown = YES;
        
    NSDictionary *userInfo = [aNotification userInfo];
    
    NSTimeInterval animationDuration;
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [animationDurationValue getValue:&animationDuration];
    
    UIViewAnimationCurve animationCurve;
    NSValue *animationCurveValue = [userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    [animationCurveValue getValue:&animationCurve];
    
    NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardBounds = [self.view convertRect:[keyboardBoundsValue CGRectValue] fromView:nil];
    keyboardFrame = keyboardBounds;
    
    if (UIUserInterfaceIdiomPhone == [[UIDevice currentDevice] userInterfaceIdiom])
    {
        keyboardUnderlay = [[[UIView alloc] initWithFrame:keyboardFrame] autorelease];
        keyboardUnderlay.backgroundColor = [UIColor blackColor];
        [self.view addSubview:keyboardUnderlay];
    }
    
    [self rejiggerInterface];
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
    if (NO == keyboardShown)
        return;
    
    [keyboardUnderlay removeFromSuperview];
    keyboardUnderlay = nil;
}

- (void)keyboardDidHide:(NSNotification *)aNotification
{
    if (NO == keyboardShown)
        return;
    
    keyboardShown = NO;
    
    NSDictionary *userInfo = [aNotification userInfo];
    
    NSTimeInterval animationDuration;
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [animationDurationValue getValue:&animationDuration];
    
    UIViewAnimationCurve animationCurve;
    NSValue *animationCurveValue = [userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    [animationCurveValue getValue:&animationCurve];
    
    //NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    [self rejiggerInterface];
}

#pragma mark - LIONavigationBarDelegate methods -

- (void)navigationBarDidTapLeftButton:(LIONavigationBar *)aBar
{
    [delegate surveyViewControllerDidCancel:self];
}

- (void)navigationBarDidTapRightButton:(LIONavigationBar *)aBar
{
    id aResponse = nil;
    if (currentInputField)
        aResponse = currentInputField.text;
    else if (currentPickerView)
    {
        [currentPickerView recalculateResults];
        aResponse = currentPickerView.results;
    }
    
    NSString *stringResponse = nil;
    NSArray *indexArrayResponse = nil;
    if ([aResponse isKindOfClass:[NSString class]])
        stringResponse = (NSString *)aResponse;
    else if ([aResponse isKindOfClass:[NSArray class]])
        indexArrayResponse = (NSArray *)aResponse;
    else
    {
        LIOLog(@"what: %@", NSStringFromClass([aResponse class]));
        return;
    }
    
    LIOSurveyManager *surveyManager = [LIOSurveyManager sharedSurveyManager];
    LIOSurveyQuestion *currentQuestion = [currentSurvey.questions objectAtIndex:currentQuestionIndex];
    
    if (stringResponse)
    {
        if (0 == [stringResponse length])
        {
            // An empty response is okay for optional questions.
            if (NO == currentQuestion.mandatory)
            {
                surveyManager.lastCompletedQuestionIndexPre = currentQuestionIndex;
                [self switchToNextQuestion];
            }
            else
            {
                [self showAlertWithMessage:@"Please enter a response for this question."];
            }
        }
        else
        {
            BOOL validated = NO;
            
            if (LIOSurveyQuestionValidationTypeAlphanumeric == currentQuestion.validationType)
            {
                // Kinda weird. This is just a passthrough, I guess.
                validated = YES;
            }
            else if (LIOSurveyQuestionValidationTypeEmail == currentQuestion.validationType)
            {
                // Cheap e-mail validation: does the string contain one @ symbol?
                NSRegularExpression *emailRegex = [NSRegularExpression regularExpressionWithPattern:@"@" options:0 error:nil];
                if (1 == [emailRegex numberOfMatchesInString:stringResponse options:0 range:NSMakeRange(0, [stringResponse length])])
                    validated = YES;
                else
                    [self showAlertWithMessage:@"Please enter a valid e-mail address."];
            }
            else if (LIOSurveyQuestionValidationTypeNumeric == currentQuestion.validationType)
            {
                // TODO: Make this better. Currently just looks for any digit and says OK! THAT'S NUMERIC! if there is one.
                NSRegularExpression *numericRegex = [NSRegularExpression regularExpressionWithPattern:@"\\d+" options:0 error:nil];
                NSArray *matches = [numericRegex matchesInString:stringResponse options:0 range:NSMakeRange(0, [stringResponse length])];
                if ([matches count])
                    validated = YES;
                else
                    [self showAlertWithMessage:@"Please enter a valid number."];
            }
            else if ([currentQuestion.validationRegexp length])
            {
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:currentQuestion.validationRegexp options:0 error:nil];
                NSArray *matches = [regex matchesInString:stringResponse options:0 range:NSMakeRange(0, [stringResponse length])];
                if ([matches count])
                    validated = YES;
                else
                    [self showAlertWithMessage:@"Please check your input and try again."];
            }
            
            if (validated)
            {
                [surveyManager registerAnswerObject:stringResponse forSurveyType:LIOSurveyManagerSurveyTypePre withQuestionIndex:currentQuestionIndex];
                surveyManager.lastCompletedQuestionIndexPre = currentQuestionIndex;
                [self switchToNextQuestion];                
            }
        }
    }
    else if (indexArrayResponse)
    {
        if (currentQuestion.mandatory && 0 == [indexArrayResponse count])
        {
            [self showAlertWithMessage:@"Please enter a response for this question."];
        }
        else
        {
            [surveyManager registerAnswerObject:indexArrayResponse forSurveyType:LIOSurveyManagerSurveyTypePre withQuestionIndex:currentQuestionIndex];
            surveyManager.lastCompletedQuestionIndexPre = currentQuestionIndex;
            [self switchToNextQuestion];
        }
    }
}

@end