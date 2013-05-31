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
#import <QuartzCore/QuartzCore.h>

#define LIOSurveyViewPrePageControlHeight     15.0
#define LIOSurveyViewPreTopMargin             15.0
#define LIOSurveyViewPreSideMargin            10.0
#define LIOSurveyViewPrePageControlOriginY    265.0

@implementation LIOSurveyViewPre

@synthesize delegate, currentSurvey, headerString;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
    }
    return self;
}

-(void)setupViews {
    UILabel* headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    headerLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    headerLabel.layer.shadowRadius = 1.0;
    headerLabel.layer.shadowOpacity = 1.0;
    headerLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.textColor = [UIColor whiteColor];
    headerLabel.numberOfLines = 0;
    headerLabel.text = headerString;
    headerLabel.alpha = 0.0;
    headerLabel.textAlignment = UITextAlignmentCenter;
    CGRect aFrame;
    aFrame.origin.x = LIOSurveyViewPreSideMargin;
    aFrame.origin.y = LIOSurveyViewPreTopMargin;
    aFrame.size.width = self.bounds.size.width - 2*LIOSurveyViewPreSideMargin;
    CGSize expectedLabelSize = [headerLabel.text sizeWithFont:headerLabel.font constrainedToSize:CGSizeMake(aFrame.size.width, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    aFrame.size.height = expectedLabelSize.height;
    headerLabel.frame = aFrame;
    [self addSubview:headerLabel];
    [headerLabel release];
    
    CGRect pageControlFrame;
    pageControlFrame.origin.x = 0;
    pageControlFrame.origin.y = self.bounds.size.height - LIOSurveyViewPrePageControlHeight + 60.0;
    pageControlFrame.size.width = self.bounds.size.width;
    pageControlFrame.size.height = LIOSurveyViewPrePageControlHeight;
    
    pageControl = [[UIPageControl alloc] initWithFrame:pageControlFrame];
    pageControl.numberOfPages = [currentSurvey.questions count];
    pageControl.alpha = 0.0;
    pageControl.transform = CGAffineTransformMakeTranslation(0.0, -210.0);
    [self addSubview:pageControl];
    [pageControl release];
    
    currentScrollView = [self scrollViewForQuestionAtIndex:0];
    currentScrollView.transform = CGAffineTransformMakeTranslation(0.0, self.superview.bounds.size.height);
    [self addSubview:currentScrollView];
    
    [UIView animateWithDuration:0.4 delay:0.5 options:UIViewAnimationCurveLinear animations:^{
        headerLabel.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 delay:1.0 options:UIViewAnimationCurveLinear animations:^{
            headerLabel.transform = CGAffineTransformMakeTranslation(0.0, -self.frame.size.height);
            currentScrollView.transform = CGAffineTransformIdentity;
            pageControl.alpha = 1.0;
        } completion:^(BOOL finished) {
            [headerLabel removeFromSuperview];
            
            leftSwipeGestureRecognizer = [[[UISwipeGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLeftSwipeGesture:)] autorelease];
            leftSwipeGestureRecognizer.direction =  UISwipeGestureRecognizerDirectionLeft;
            [self addGestureRecognizer:leftSwipeGestureRecognizer];
            
            rightSwipeGestureRecognizer = [[[UISwipeGestureRecognizer alloc]
                                           initWithTarget:self action:@selector(handleRightSwipeGesture:)] autorelease];
            rightSwipeGestureRecognizer.direction =  UISwipeGestureRecognizerDirectionRight;
            [self addGestureRecognizer:rightSwipeGestureRecognizer];
            

        }];
    }];    
}

-(void)handleLeftSwipeGesture:(UISwipeGestureRecognizer*)sender
{
    [self switchToNextQuestion];
}

-(void)handleRightSwipeGesture:(UISwipeGestureRecognizer*)sender
{
    [self switchToPreviousQuestion];
}




-(UIScrollView*)scrollViewForQuestionAtIndex:(int)index {
    int numberOfQuestions = [currentSurvey.questions count];
    if (index > numberOfQuestions - 1 || index < 0)
        return nil;
    
    LIOSurveyQuestion *question = [currentSurvey.questions objectAtIndex:index];

    UIScrollView* scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    
    UILabel* questionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    questionLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    questionLabel.layer.shadowRadius = 1.0;
    questionLabel.layer.shadowOpacity = 1.0;
    questionLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    questionLabel.backgroundColor = [UIColor clearColor];
    questionLabel.textColor = [UIColor whiteColor];
    questionLabel.numberOfLines = 0;
    questionLabel.text = question.label;
    questionLabel.textAlignment = UITextAlignmentCenter;
    [scrollView addSubview:questionLabel];
    [questionLabel release];
    
    CGRect aFrame;
    aFrame.origin.x = LIOSurveyViewPreSideMargin;
    aFrame.origin.y = LIOSurveyViewPreTopMargin;
    aFrame.size.width = self.bounds.size.width - LIOSurveyViewPreSideMargin*2;
    CGSize expectedLabelSize = [questionLabel.text sizeWithFont:questionLabel.font constrainedToSize:CGSizeMake(aFrame.size.width, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    aFrame.size.height = expectedLabelSize.height;
    questionLabel.frame = aFrame;
    
    if (LIOSurveyQuestionDisplayTypeText == question.displayType) {
        UIImage *fieldImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOAboutStretchableInputField"];
        UIImage *stretchableFieldImage = [fieldImage stretchableImageWithLeftCapWidth:11 topCapHeight:0];
        
        UIImageView *fieldBackground = [[[UIImageView alloc] initWithImage:stretchableFieldImage] autorelease];
        fieldBackground.userInteractionEnabled = YES;
        aFrame = fieldBackground.frame;
        aFrame.origin.x = 10.0;
        aFrame.size.width = self.bounds.size.width - 20.0;
        aFrame.size.height = 48.0;
        aFrame.origin.y = questionLabel.frame.origin.y + questionLabel.frame.size.height + 10.0;
        fieldBackground.frame = aFrame;
        fieldBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [scrollView addSubview:fieldBackground];        
        
        UITextField *inputField = [[[UITextField alloc] init] autorelease];
        inputField.delegate = self;
        inputField.backgroundColor = [UIColor clearColor];
        aFrame.origin.x = 10.0;
        aFrame.origin.y = 14.0;
        aFrame.size.width = fieldBackground.frame.size.width - 20.0;
        aFrame.size.height = 28.0;
        inputField.frame = aFrame;
        inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        inputField.font = [UIFont systemFontOfSize:16.0];
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
        
        [fieldBackground addSubview:inputField];
        [inputField becomeFirstResponder];
    }
    
    if (LIOSurveyQuestionDisplayTypePicker == question.displayType) {
        /*
        UIPickerView* pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, questionLabel.frame.origin.y + questionLabel.frame.size.height + 10.0, 320, 300)];
        pickerView.showsSelectionIndicator = YES;
        pickerView.delegate = self;
        pickerView.backgroundColor = [UIColor clearColor];
        [scrollView addSubview:pickerView];
         */
        
        UITableView* tableView = [[UITableView alloc]
                                  initWithFrame:CGRectMake(0, questionLabel.frame.origin.y + questionLabel.frame.size.height + 5.0, 320, 300) style:UITableViewStyleGrouped];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.backgroundColor = [UIColor clearColor];
        tableView.backgroundView = nil;
        tableView.scrollEnabled = NO;
        [scrollView addSubview:tableView];
        [tableView release];

        /*

        NSString* buttonTitle = @"Next";
        if (currentQuestionIndex == numberOfQuestions - 1)
            buttonTitle = @"Done";
        
        UIToolbar* pickerToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, questionLabel.frame.origin.y + questionLabel.frame.size.height + 225.0, 320, 50)];
        [pickerToolbar setBackgroundImage:[[UIImage alloc] init] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
        pickerToolbar.barStyle = UIBarStyleBlackTranslucent;
        pickerToolbar.items = [NSArray arrayWithObjects:
                               [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                               [[UIBarButtonItem alloc]initWithTitle:buttonTitle style:UIBarButtonItemStyleDone target:self action:@selector(switchToNextQuestion)],
                               nil];
        [pickerToolbar sizeToFit];
        [scrollView addSubview:pickerToolbar];
         */
    }
    
    if (LIOSurveyQuestionDisplayTypeMultiselect == question.displayType) {
        UITableView* tableView = [[UITableView alloc]
                                  initWithFrame:CGRectMake(0, questionLabel.frame.origin.y + questionLabel.frame.size.height + 5.0, 320, 300) style:UITableViewStyleGrouped];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.backgroundColor = [UIColor clearColor];
        tableView.backgroundView = nil;
        tableView.scrollEnabled = NO;
        [scrollView addSubview:tableView];
        [tableView release];
        
        selectedIndices = [[NSMutableArray alloc] init];
        
        NSString* buttonTitle = @"Next";
        if (currentQuestionIndex == numberOfQuestions - 1)
            buttonTitle = @"Done";
        
        UIToolbar* pickerToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, questionLabel.frame.origin.y + questionLabel.frame.size.height + 200.0, 320, 50)];
        [pickerToolbar setBackgroundImage:[[UIImage alloc] init] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
        pickerToolbar.barStyle = UIBarStyleBlackTranslucent;
        pickerToolbar.items = [NSArray arrayWithObjects:
                               [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                               [[UIBarButtonItem alloc]initWithTitle:buttonTitle style:UIBarButtonItemStyleDone target:self action:@selector(switchToNextQuestion)],
                               nil];
        [pickerToolbar sizeToFit];
        [scrollView addSubview:pickerToolbar];
        [pickerToolbar autorelease];
    }
    
    return [scrollView autorelease];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
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
    }
    
    LIOSurveyQuestion *question = [currentSurvey.questions objectAtIndex:currentQuestionIndex];
    LIOSurveyPickerEntry* pickerEntry = [question.pickerEntries objectAtIndex:indexPath.row];
    
    cell.textLabel.text = pickerEntry.label;
    cell.textLabel.font = [UIFont systemFontOfSize:16.0];
    
    if (LIOSurveyQuestionDisplayTypeMultiselect == question.displayType) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
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
    }


    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    LIOSurveyQuestion *question = [currentSurvey.questions objectAtIndex:currentQuestionIndex];

    if (LIOSurveyQuestionDisplayTypePicker == question.displayType) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self switchToNextQuestion];
    }
    
    if (LIOSurveyQuestionDisplayTypeMultiselect == question.displayType) {
        NSIndexPath* existingIndexPath = nil;

        for (NSIndexPath* selectedIndexPath in selectedIndices) {
            if (indexPath.row == selectedIndexPath.row) {
                existingIndexPath = selectedIndexPath;
            }
        }
        
        if (existingIndexPath)
            [selectedIndices removeObject:existingIndexPath];
        else
            [selectedIndices addObject:indexPath];
        
        [tableView reloadData];
    }
}


-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    LIOSurveyQuestion *question = [currentSurvey.questions objectAtIndex:currentQuestionIndex];
    return question.pickerEntries.count;
}

-(NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    LIOSurveyQuestion *question = [currentSurvey.questions objectAtIndex:currentQuestionIndex];
    LIOSurveyPickerEntry* pickerEntry = [question.pickerEntries objectAtIndex:row];
    return pickerEntry.label;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    int numberOfQuestions = [currentSurvey.questions count];
    if (currentQuestionIndex <= numberOfQuestions - 2)
        [self switchToNextQuestion];
    
    return NO;
}

-(void)switchToNextQuestion {
    int numberOfQuestions = [currentSurvey.questions count];
    
    if (currentQuestionIndex == numberOfQuestions - 1)
        [delegate surveyViewDidFinish:self];
    
    if (currentQuestionIndex > numberOfQuestions - 2)
        return;
    
    currentQuestionIndex += 1;
    LIOSurveyQuestion *question = [currentSurvey.questions objectAtIndex:currentQuestionIndex];
    
    UIScrollView* nextQuestionScrollView = [self scrollViewForQuestionAtIndex:currentQuestionIndex];
    nextQuestionScrollView.transform = CGAffineTransformMakeTranslation(self.bounds.size.width, 0.0);
    [self addSubview:nextQuestionScrollView];
    
    
    [UIView animateWithDuration:0.3 animations:^{
        [currentScrollView endEditing:YES];

        nextQuestionScrollView.transform = CGAffineTransformIdentity;
        currentScrollView.transform = CGAffineTransformMakeTranslation(-self.bounds.size.width, 0.0);
        pageControl.currentPage += 1;

        if (question.displayType == LIOSurveyQuestionDisplayTypeText) {
            if (question.validationType == LIOSurveyQuestionValidationTypeAlphanumeric)
                pageControl.transform = CGAffineTransformMakeTranslation(0.0, -210.0);

            if (question.validationType == LIOSurveyQuestionValidationTypeNumeric)
                pageControl.transform = CGAffineTransformMakeTranslation(0.0, -254.0);
        } else {
            pageControl.transform = CGAffineTransformIdentity;
        }
        
    } completion:^(BOOL finished) {
        [currentScrollView removeFromSuperview];
        currentScrollView = nextQuestionScrollView;
        
    }];    
}

-(void)switchToPreviousQuestion {
    if (currentQuestionIndex == 0)
        return;
    
    currentQuestionIndex -= 1;
    LIOSurveyQuestion *question = [currentSurvey.questions objectAtIndex:currentQuestionIndex];
    
    UIScrollView* previousQuestionScrollView = [self scrollViewForQuestionAtIndex:currentQuestionIndex];
    previousQuestionScrollView.transform = CGAffineTransformMakeTranslation(-self.bounds.size.width, 0.0);
    [self addSubview:previousQuestionScrollView];
    
    [UIView animateWithDuration:0.3 animations:^{
        [currentScrollView endEditing:YES];

        previousQuestionScrollView.transform = CGAffineTransformIdentity;
        currentScrollView.transform = CGAffineTransformMakeTranslation(self.bounds.size.width, 0.0);

        pageControl.currentPage -= 1;

        if (question.displayType == LIOSurveyQuestionDisplayTypeText) {
            if (question.validationType == LIOSurveyQuestionValidationTypeAlphanumeric)
                pageControl.transform = CGAffineTransformMakeTranslation(0.0, -210.0);
            
            if (question.validationType == LIOSurveyQuestionValidationTypeNumeric)
                pageControl.transform = CGAffineTransformMakeTranslation(0.0, -254.0);
        } else {
            pageControl.transform = CGAffineTransformIdentity;
        }
        
    } completion:^(BOOL finished) {
        [currentScrollView removeFromSuperview];
        currentScrollView = previousQuestionScrollView;
    }];
}



@end
