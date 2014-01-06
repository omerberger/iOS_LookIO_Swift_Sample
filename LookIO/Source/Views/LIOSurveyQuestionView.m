//
//  LIOSurveyQuestionView.m
//  LookIO
//
//  Created by Yaron Karasik on 12/31/13.
//
//

#import "LIOSurveyQuestionView.h"
#import "LIOSurveyQuestion.h"
#import "LIOBundleManager.h"
#import "LIOBrandingManager.h"
#import "LIOSurveyPickerEntry.h"
#import "LIOStarRatingView.h"

#import <QuartzCore/QuartzCore.h>

#define LIOSurveyViewPageControlHeight          15.0
#define LIOSurveyViewTopMarginPortrait          40.0
#define LIOSurveyViewTopMarginLandscape         30.0
#define LIOSurveyViewSideMargin                 10.0
#define LIOSurveyViewSideMarginiPad             25.0
#define LIOSurveyViewPageControlOriginY         265.0

#define LIOSurveyViewIntroButtonMargin          15.0
#define LIOSurveyViewIntroTopMarginPortrait     90.0
#define LIOSurveyViewIntroTopMarginLandscape    50.0

#define LIOSurveyViewiPadNextQuestionAlpha      0.5
#define LIOSurveyViewiPadNextQuestionScale      0.8
#define LIOSurveyViewiPadNextQuestionOffset     0.55

#define LIOSurveyViewControllerValidationDuration 5.0

#define LIOIndexForSurveyIntroPage  -1

@interface LIOSurveyQuestionView () <UITextFieldDelegate, UITextViewDelegate, LIOStarRatingViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *textFieldBackground;
@property (nonatomic, strong) LIOStarRatingView *starRatingView;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;

@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UIButton *cancelButton;

@property (nonatomic, strong) LIOSurveyQuestion *question;

@end

@implementation LIOSurveyQuestionView

#pragma mark
#pragma mark Initial setup methods

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
        
        self.tag = -1;
        if (padUI) {
            self.frame = [self frameForIpadScrollView];
            self.scrollEnabled = NO;
        }
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        UIColor *backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementSurveyCard];
        CGFloat backgroundAlpha = [[LIOBrandingManager brandingManager] backgroundAlphaForElement:LIOBrandingElementSurveyCard];
        self.backgroundView.backgroundColor = [backgroundColor colorWithAlphaComponent:backgroundAlpha];
        self.backgroundView.layer.borderColor = [[[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementSurveyCard] CGColor];
        self.backgroundView.layer.borderWidth = 1.0;
        self.backgroundView.layer.cornerRadius = 5.0;
        [self addSubview:self.backgroundView];
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.font = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementSurveyCardTitle];
        self.titleLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementSurveyCardTitle];
        self.titleLabel.textAlignment = UITextAlignmentCenter;
        self.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:self.titleLabel];
        
        self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.subtitleLabel.backgroundColor = [UIColor clearColor];
        self.subtitleLabel.font = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementSurveyCardSubtitle];
        self.subtitleLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementSurveyCardSubtitle];
        self.subtitleLabel.numberOfLines = 0;
        self.subtitleLabel.text = LIOLocalizedString(@"LIOSurveyViewController.MandatoryQuestionsTitle");
        self.subtitleLabel.textAlignment = UITextAlignmentCenter;
        self.subtitleLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:self.subtitleLabel];
        
        self.textFieldBackground = [[UIView alloc] init];
        self.textFieldBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.textFieldBackground.alpha = 0.85;
        UIColor *textFieldBackgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementSurveyTextField];
        CGFloat textFieldBackgroundAlpha = [[LIOBrandingManager brandingManager] backgroundAlphaForElement:LIOBrandingElementSurveyTextField];
        self.textFieldBackground.backgroundColor = [textFieldBackgroundColor colorWithAlphaComponent:textFieldBackgroundAlpha];
        self.textFieldBackground.layer.borderColor = [[[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementSurveyTextField] CGColor];
        self.textFieldBackground.layer.borderWidth = 1.0;
        self.textFieldBackground.layer.cornerRadius = 5.0;
        [self addSubview:self.textFieldBackground];
        
        self.textField = [[UITextField alloc] init];
        self.textField.delegate = self;
        self.textField.backgroundColor = [UIColor clearColor];
        self.textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.textField.font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementSurveyTextField];
        self.textField.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementSurveyTextField];
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.keyboardAppearance = UIKeyboardAppearanceDefault;
        [self.textFieldBackground addSubview:self.textField];
        
        self.textView = [[UITextView alloc] init];
        self.textView.delegate = self;
        self.textView.backgroundColor = [UIColor clearColor];
        self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.textView.font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementSurveyTextField];
        self.textView.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementSurveyTextField];
        self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        [self.textFieldBackground addSubview:self.textView];
        
        self.starRatingView = [[LIOStarRatingView alloc] initWithFrame:CGRectZero];
        // TODO Star rating customization
        [self addSubview:self.starRatingView];
        
        self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        self.tableView.backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementSurveyList];
        self.tableView.layer.borderColor = [[[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementSurveyList] CGColor];
        self.tableView.layer.borderWidth = 1.0;
        self.tableView.separatorColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementSurveyList];
        self.tableView.layer.cornerRadius = 5.0;
        self.tableView.backgroundView = nil;
        self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.tableView.showsVerticalScrollIndicator = NO;
        [self addSubview:self.tableView];
        
        self.nextButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [self.nextButton addTarget:self action:@selector(nextButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        self.nextButton.titleLabel.font = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementSurveyCardNextButton];
        UIColor *nextButtonColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementSurveyCardNextButton];
        [self.nextButton setTitleColor:nextButtonColor forState:UIControlStateNormal];
        [self.nextButton setTitleColor:[nextButtonColor colorWithAlphaComponent:0.3f] forState:UIControlStateNormal | UIControlStateHighlighted];
        self.nextButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self.nextButton setTitle:LIOLocalizedString(@"LIOSurveyView.NextButtonTitle") forState:UIControlStateNormal];
        [self addSubview:self.nextButton];
        
        self.cancelButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [self.cancelButton addTarget:self action:@selector(cancelButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        self.cancelButton.titleLabel.font = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementSurveyCardCancelButton];
        UIColor *cancelButtonColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementSurveyCardCancelButton];
        [self.cancelButton setTitleColor:cancelButtonColor forState:UIControlStateNormal];
        [self.cancelButton setTitleColor:[cancelButtonColor colorWithAlphaComponent:0.3f] forState:UIControlStateNormal | UIControlStateHighlighted];
        self.cancelButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self.cancelButton setTitle:LIOLocalizedString(@"LIOSurveyView.CancelButtonTitle") forState:UIControlStateNormal];
        [self addSubview:self.cancelButton];
        
        UIGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapBackground:)];
        tapGestureRecognizer.delegate = self;
        [self addGestureRecognizer:tapGestureRecognizer];
    }
    
    return self;
}

- (void)setupViewWithQuestion:(LIOSurveyQuestion *)question existingResponse:(id)existingResponse isLastQuestion:(BOOL)isLastQuestion delegate:(id)delegate
{
    self.delegate = delegate;
    self.question = question;
    
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    self.titleLabel.text = question.label;
    if (question.mandatory)
        self.titleLabel.text = [NSString stringWithFormat:@"%@ *", self.titleLabel.text];
    
    self.subtitleLabel.hidden = YES;
    self.nextButton.hidden = YES;
    self.cancelButton.hidden = YES;

    if (LIOSurveyQuestionDisplayTypeIntro == question.displayType)
    {
        self.subtitleLabel.hidden = NO;
        self.nextButton.hidden = NO;
        self.cancelButton.hidden = NO;
    }
    
    self.textFieldBackground.hidden = YES;
    self.textField.hidden = YES;
    self.textView.hidden = YES;

    if (LIOSurveyQuestionDisplayTypeTextField == question.displayType)
    {
        self.textFieldBackground.hidden = NO;
        self.textField.hidden = NO;
        
        NSString* buttonTitle;
        if (isLastQuestion)
        {
            self.textField.returnKeyType = UIReturnKeyDone;
            buttonTitle = LIOLocalizedString(@"LIOSurveyView.DoneButtonTitle");
        }
        else
        {
            self.textField.returnKeyType = UIReturnKeyNext;
            buttonTitle = LIOLocalizedString(@"LIOSurveyView.NextButtonTitle");
        }

        if (LIOSurveyQuestionValidationTypeEmail == question.validationType)
        {
            self.textField.keyboardType = UIKeyboardTypeEmailAddress;
            self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        }
        
        if (LIOSurveyQuestionValidationTypeNumeric == question.validationType)
        {
            self.textField.keyboardType = UIKeyboardTypeNumberPad;
        }
        
        if (!padUI)
        {
            UIToolbar* numberToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 50)];
            numberToolbar.barStyle = UIBarStyleDefault;
            
            UIButton *nextBarButton = [[UIButton alloc] initWithFrame:CGRectZero];
            nextBarButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
            [nextBarButton addTarget:self action:@selector(nextButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
            nextBarButton.titleLabel.font = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementSurveyCardNextButton];
            UIColor *nextButtonColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementSurveyCardNextButton];
            [nextBarButton setTitleColor:nextButtonColor forState:UIControlStateNormal];
            [nextBarButton setTitleColor:[nextButtonColor colorWithAlphaComponent:0.3f] forState:UIControlStateNormal | UIControlStateHighlighted];
            [nextBarButton setTitle:buttonTitle forState:UIControlStateNormal];
            [nextBarButton sizeToFit];
            
            numberToolbar.items = [NSArray arrayWithObjects:
                                   [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                   [[UIBarButtonItem alloc] initWithCustomView:nextBarButton],
                                   nil];
            [numberToolbar sizeToFit];
            self.textField.inputAccessoryView = numberToolbar;
        }
        
        // If the user has answered this survey, we should display their answer
        if (existingResponse && [existingResponse isKindOfClass:[NSString class]])
        {
            NSString *responseString = (NSString *)existingResponse;
            self.textField.text = existingResponse;
        }
        // If user hasn't answered, let's see if there's a last known response to populate
        else
        {
            if (question.lastKnownValue)
                self.textField.text = question.lastKnownValue;
        }
    }
    else
    {
        self.textFieldBackground.hidden = YES;
    }

    if (LIOSurveyQuestionDisplayTypeTextArea == question.displayType) {
        self.textFieldBackground.hidden = NO;
        self.textView.hidden = NO;

        NSString *buttonTitle;
        if (isLastQuestion)
        {
            self.textView.returnKeyType = UIReturnKeyDone;
            buttonTitle = LIOLocalizedString(@"LIOSurveyView.DoneButtonTitle");
        }
        else
        {
            self.textView.returnKeyType = UIReturnKeyNext;
            buttonTitle = LIOLocalizedString(@"LIOSurveyView.NextButtonTitle");
        }
        self.textView.keyboardAppearance = UIKeyboardAppearanceDefault;
        
        if (LIOSurveyQuestionValidationTypeEmail == question.validationType)
        {
            self.textView.keyboardType = UIKeyboardTypeEmailAddress;
            self.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        }
        
        if (LIOSurveyQuestionValidationTypeNumeric == question.validationType)
        {
            self.textView.keyboardType = UIKeyboardTypeNumberPad;
        }
        
        if (!padUI)
        {
            UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 50)];
            numberToolbar.barStyle = UIBarStyleDefault;
            
            numberToolbar.items = [NSArray arrayWithObjects:
                                   [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                   [[UIBarButtonItem alloc]initWithTitle:buttonTitle style:UIBarButtonItemStyleDone target:self action:@selector(nextButtonWasTapped:)],
                                   nil];
            [numberToolbar sizeToFit];
            self.textView.inputAccessoryView = numberToolbar;
        }
        
        // If the user has answered this survey, we should display their answer
        if ((existingResponse) && [existingResponse isKindOfClass:[NSString class]])
        {
            NSString *responseString = (NSString *)existingResponse;
            self.textView.text = existingResponse;
        }
        // If user hasn't answered, let's see if there's a last known response to populate
        else
        {
            if (question.lastKnownValue)
                self.textView.text = question.lastKnownValue;
        }
    }

    if ((LIOSurveyQuestionDisplayTypePicker == question.displayType || LIOSurveyQuestionDisplayTypeMultiselect == question.displayType) || padUI)
    {
        self.nextButton.hidden = NO;

        if (isLastQuestion)
            [self.nextButton setTitle:LIOLocalizedString(@"LIOSurveyView.DoneButtonTitle") forState:UIControlStateNormal];
        else
            [self.nextButton setTitle:LIOLocalizedString(@"LIOSurveyView.NextButtonTitle") forState:UIControlStateNormal];
    }

    self.starRatingView.hidden = YES;
    self.tableView.hidden = YES;
    
    if (LIOSurveyQuestionDisplayTypePicker == question.displayType || LIOSurveyQuestionDisplayTypeMultiselect == question.displayType)
    {
        if (question.shouldUseStarRatingView)
        {
            self.starRatingView.hidden = NO;
            self.starRatingView.delegate = delegate;
            [self.starRatingView setValueLabels:question.pickerEntryTitles];
        }
        else
        {
            self.tableView.hidden = NO;
            self.tableView.delegate = delegate;
            self.tableView.dataSource = delegate;
        }
    }
}

- (void)becomeFirstResponder
{
    if (LIOSurveyQuestionDisplayTypeTextField == self.question.displayType)
        [self.textField becomeFirstResponder];
    if (LIOSurveyQuestionDisplayTypeTextArea == self.question.displayType)
        [self.textView becomeFirstResponder];
}

#pragma mark
#pragma mark Question view setup methods

- (CGRect)frameForIpadScrollView
{
    UIInterfaceOrientation currentInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    BOOL landscape = UIInterfaceOrientationIsLandscape(currentInterfaceOrientation);
    
    CGRect aFrame = CGRectZero;
    aFrame.origin.y = landscape ? 20 : 135;
    aFrame.size.width = landscape ? 400 : 450;
    aFrame.size.height = landscape ? 360 : 460;
    aFrame.origin.x = (self.bounds.size.width - aFrame.size.width)/2;
    
    return aFrame;
}

- (void)layoutSubviews
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    UIInterfaceOrientation currentInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    BOOL landscape = UIInterfaceOrientationIsLandscape(currentInterfaceOrientation);
    
    CGRect aFrame;
    CGRect referenceFrame = self.bounds;
    
    if (!self.titleLabel.hidden)
    {
        aFrame.origin.x = padUI ? LIOSurveyViewSideMarginiPad : LIOSurveyViewSideMargin;
        aFrame.origin.y = (landscape && !padUI) ? LIOSurveyViewTopMarginLandscape : LIOSurveyViewTopMarginPortrait;
        aFrame.size.width = referenceFrame.size.width - (padUI ? LIOSurveyViewSideMarginiPad : LIOSurveyViewSideMargin)*2;
        if (!padUI)
        {
            aFrame.origin.x = LIOSurveyViewSideMargin * 4;
            if (landscape)
                aFrame.origin.y = LIOSurveyViewTopMarginLandscape + 10;
            aFrame.size.width = referenceFrame.size.width - (LIOSurveyViewSideMargin * 2 * 4);
        }
        CGSize expectedLabelSize = [self.titleLabel.text sizeWithFont:self.titleLabel.font constrainedToSize:CGSizeMake(aFrame.size.width, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
        aFrame.size.height = expectedLabelSize.height;
        self.titleLabel.frame = aFrame;
        
        self.titleLabel.numberOfLines = 0;
        [self.titleLabel sizeThatFits:expectedLabelSize];
    }
    
    if (!self.subtitleLabel.hidden)
    {
        aFrame.origin.x = LIOSurveyViewSideMargin;
        // TODO Base origin here on the actual text which can be localized
        aFrame.origin.y = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height - (landscape ? -15.0 : 10.0);
        aFrame.size.width = referenceFrame.size.width - 2*LIOSurveyViewSideMargin;
        if (!padUI)
        {
            aFrame.origin.x = LIOSurveyViewSideMargin * 4;
            aFrame.size.width = referenceFrame.size.width - (LIOSurveyViewSideMargin * 2 * 4);
        }
        self.subtitleLabel.frame = aFrame;
        
        self.nextButton.hidden = NO;
        aFrame.origin.x = referenceFrame.size.width/2 + LIOSurveyViewIntroButtonMargin;
        aFrame.origin.y = self.subtitleLabel.frame.origin.y + self.subtitleLabel.frame.size.height - (landscape ? 0 : 20.0);
        aFrame.size.width = 92.0;
        aFrame.size.height = 44.0;
        self.nextButton.frame = aFrame;
        
        self.cancelButton.hidden = NO;
        aFrame.origin.x = referenceFrame.size.width/2 - LIOSurveyViewIntroButtonMargin - 92.0;
        aFrame.origin.y = self.subtitleLabel.frame.origin.y + self.subtitleLabel.frame.size.height - (landscape ? 0 : 20.0);
        aFrame.size.width = 92.0;
        aFrame.size.height = 44.0;
        self.cancelButton.frame = aFrame;
        
        CGSize aSize;
        aSize.width = self.frame.size.width;
        aSize.height = self.nextButton.frame.origin.y + self.nextButton.frame.size.height + (landscape ? 8.0 : 45.0);
        self.contentSize = aSize;
    }
    
    if (!self.textField.hidden)
    {
        aFrame = self.textFieldBackground.frame;
        aFrame.origin.x = padUI ? 25.0 : 10.0;
        aFrame.size.width = referenceFrame.size.width - 20.0 - (padUI ? 30.0 : 0);
        aFrame.size.height = landscape ? 43.0 : 43.0;
        aFrame.origin.y = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + (landscape ? 12.0 : 15.0);
        if (!padUI)
        {
            aFrame.origin.x = LIOSurveyViewSideMargin * 3;
            aFrame.size.width = referenceFrame.size.width - (LIOSurveyViewSideMargin * 2 * 3);
        }
        self.textFieldBackground.frame = aFrame;
        
        aFrame.origin.x = 15.0;
        aFrame.origin.y = landscape ? 10.0 : 10.0;
        aFrame.size.width = self.textFieldBackground.frame.size.width - 20.0;
        aFrame.size.height = 28.0;
        
        // iOS 7.0: Remove 3px for the textfield in iOS 7.0
        if (LIOIsUIKitFlatMode())
            aFrame.origin.y -= 3.0;
        
        self.textField.frame = aFrame;
        
        // Set up the scroll view to allow scrolling down to the text field if needed
        CGSize aSize;
        aSize.width = self.frame.size.width;
        aSize.height = self.textFieldBackground.frame.origin.y + self.textFieldBackground.frame.size.height + 65.0;
        self.contentSize = aSize;
        
        if (padUI) {
            CGFloat contentHeight = self.textFieldBackground.frame.origin.y + self.textFieldBackground.frame.size.height;
            CGFloat startPoint = self.bounds.size.height/2 - contentHeight/2;
            
            aFrame = self.titleLabel.frame;
            aFrame.origin.y = startPoint;
            self.titleLabel.frame = aFrame;
            
            aFrame = self.textFieldBackground.frame;
            aFrame.origin.y = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + (landscape ? 12.0 : 15.0);
            self.textFieldBackground.frame = aFrame;
            
            if (!self.nextButton.hidden) {
                aFrame.origin.x = referenceFrame.size.width - LIOSurveyViewSideMarginiPad - 92.0;
                aFrame.origin.y = referenceFrame.size.height - 44.0 - 27.0;
                aFrame.size.width = 92.0;
                aFrame.size.height = 44.0;
                self.nextButton.frame = aFrame;
                
                // Set up the scroll view to allow scrolling down to the text field if needed
                CGSize aSize;
                aSize.width = self.frame.size.width;
                aSize.height = self.nextButton.frame.origin.y + self.nextButton.frame.size.height + 30.0;
                self.contentSize = aSize;
            }
        }
    }
    
    if (!self.textView.hidden)
    {
        aFrame = self.textFieldBackground.frame;
        aFrame.origin.x = padUI ? 25.0 : 10.0;
        aFrame.size.width = referenceFrame.size.width - 20.0 - (padUI ? 30.0 : 0);
        aFrame.size.height = landscape ? 75.0 : 105.0;
        aFrame.origin.y = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + (landscape ? 12.0 : 15.0);
        
        if (!padUI)
        {
            aFrame.origin.x = 30.0;
            aFrame.size.width = referenceFrame.size.width - 60;
        }
        self.textFieldBackground.frame = aFrame;
        
        aFrame.origin.x = 5.0;
        aFrame.origin.y = landscape ? 7.0 : 5.0;
        aFrame.size.width = self.textFieldBackground.frame.size.width - 20.0;
        aFrame.size.height = landscape ? 60.0 : 88.0;
        self.textView.frame = aFrame;
        
        // Set up the scroll view to allow scrolling down to the text field if needed
        CGSize aSize;
        aSize.width = self.frame.size.width;
        aSize.height = self.textFieldBackground.frame.origin.y + self.textFieldBackground.frame.size.height + 30.0;
        self.contentSize = aSize;
        
        if (padUI)
        {
            CGFloat contentHeight = self.textFieldBackground.frame.origin.y + self.textFieldBackground.frame.size.height;
            CGFloat startPoint = self.bounds.size.height/2 - contentHeight/2;
            
            aFrame = self.titleLabel.frame;
            aFrame.origin.y = startPoint;
            self.titleLabel.frame = aFrame;
            
            aFrame = self.textFieldBackground.frame;
            aFrame.origin.y = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + (landscape ? 12.0 : 15.0);
            self.textFieldBackground.frame = aFrame;
            
            if (!self.nextButton.isHidden)
            {
                aFrame.origin.x = referenceFrame.size.width - LIOSurveyViewSideMarginiPad - 92.0;
                aFrame.origin.y = referenceFrame.size.height - 44.0 - 27.0;
                aFrame.size.width = 92.0;
                aFrame.size.height = 44.0;
                self.nextButton.frame = aFrame;
                
                // Set up the scroll view to allow scrolling down to the text field if needed
                CGSize aSize;
                aSize.width = self.frame.size.width;
                aSize.height = self.nextButton.frame.origin.y + self.nextButton.frame.size.height + 30.0;
                self.contentSize = aSize;
            }
        }
    }
    
    if (!padUI)
    {
        CGRect frame = self.backgroundView.frame;
        if (!landscape)
        {
            frame.origin.x = 10;
            frame.size.width = self.bounds.size.width - 20;
            frame.size.height = self.contentSize.height - 70;
            frame.origin.y = 25;
        }
        else
        {
            frame.origin.x = 10;
            frame.size.width = self.bounds.size.width - 20;
            frame.size.height = self.contentSize.height - 30;
            frame.origin.y = 25;
        }
        self.backgroundView.frame = frame;
    }
    
    if (!self.starRatingView.hidden)
    {
        aFrame.size.width = self.frame.size.width;
        aFrame.size.height = 60.0;
        aFrame.origin.x = self.bounds.size.width/2.0 - aFrame.size.width/2.0;
        aFrame.origin.y = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 20;
        self.starRatingView.frame = aFrame;
        
        if (padUI)
        {
            CGFloat contentHeight = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + self.starRatingView.frame.size.height;
            CGFloat startPoint = self.bounds.size.height/2 - contentHeight/2;
            
            aFrame = self.titleLabel.frame;
            aFrame.origin.y = startPoint;
            self.titleLabel.frame = aFrame;
            
            aFrame = self.starRatingView.frame;
            aFrame.origin.y = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 20;
            self.starRatingView.frame = aFrame;
        }
        
        aFrame.origin.x = referenceFrame.size.width - (padUI ? LIOSurveyViewSideMarginiPad : LIOSurveyViewSideMargin*2) - 92.0;
        if (padUI)
        {
            aFrame.origin.y = referenceFrame.size.height - 44.0 - 27.0;
        }
        else
        {
            if (landscape) {
                aFrame.origin.x = referenceFrame.size.width - 95.0;
                aFrame.origin.y = self.starRatingView.frame.origin.y + self.starRatingView.frame.size.height - 5;
            } else {
                aFrame.origin.x = referenceFrame.size.width - 95.0;
                aFrame.origin.y = self.starRatingView.frame.origin.y + self.starRatingView.frame.size.height + 25;
            }
        }
        aFrame.size.width = 92.0;
        aFrame.size.height = 44.0;
        self.nextButton.frame = aFrame;
        
        if (!padUI)
        {
            CGRect frame = self.backgroundView.frame;
            if (!landscape) {
                frame.origin.x = 10;
                frame.size.width = self.bounds.size.width - 20;
                frame.origin.y = 65;
            }
            else {
                frame.origin.x = 10;
                frame.size.width = self.bounds.size.width - 20;
                frame.origin.y = 25;
            }
            self.backgroundView.frame = frame;
        }
    }
    
    if (!self.tableView.isHidden)
    {
        [self.tableView reloadData];
        
        CGFloat tableViewContentHeight = [self heightForTableView:self.tableView];
        
        CGFloat maxHeight = referenceFrame.size.height - self.titleLabel.bounds.size.height - (!padUI ? 140.0 : 140.0) ;
        
        if (tableViewContentHeight > maxHeight)
        {
            self.tableView.scrollEnabled = YES;
            tableViewContentHeight = maxHeight;
        }
        else
        {
            self.tableView.scrollEnabled = NO;
            
            if (padUI)
            {
                CGFloat contentHeight = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + tableViewContentHeight;
                CGFloat startPoint = self.bounds.size.height/2 - contentHeight/2 + 10;
                
                aFrame = self.titleLabel.frame;
                aFrame.origin.y = startPoint;
                self.titleLabel.frame = aFrame;
            }
        }
        
        self.tableView.frame = CGRectMake((padUI ? LIOSurveyViewSideMarginiPad : LIOSurveyViewSideMargin), self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 15.0, referenceFrame.size.width - (padUI ? LIOSurveyViewSideMarginiPad + 2: LIOSurveyViewSideMargin)*2, tableViewContentHeight);
        
        if (!padUI)
        {
            CGRect frame = self.tableView.frame;
            frame.origin.x = 25;
            frame.size.width = self.bounds.size.width - 50;
            self.tableView.frame = frame;
        }
        
        aFrame.origin.x = referenceFrame.size.width - (padUI ? LIOSurveyViewSideMarginiPad : LIOSurveyViewSideMargin*2) - 92.0;
        if (landscape) {
            aFrame.origin.x = referenceFrame.size.width - 95.0;
            aFrame.origin.y = self.tableView.frame.origin.y + self.tableView.frame.size.height;
        } else {
            aFrame.origin.x = referenceFrame.size.width - 95.0;
            aFrame.origin.y = self.tableView.frame.origin.y + self.tableView.frame.size.height + 2;
        }
        aFrame.size.width = 92.0;
        aFrame.size.height = 44.0;
        self.nextButton.frame = aFrame;
        
        if (!padUI)
        {
            CGRect frame = self.backgroundView.frame;
            if (!landscape) {
                frame.origin.x = 10;
                frame.size.width = self.bounds.size.width - 20;
                frame.size.height = self.tableView.frame.origin.y + tableViewContentHeight - 20 + 50;
                frame.origin.y = 25;
            }
            else {
                frame.origin.x = 10;
                frame.size.width = self.bounds.size.width - 20;
                frame.size.height = self.tableView.frame.origin.y + tableViewContentHeight - 20 + 45;
                frame.origin.y = 25;
            }
            self.backgroundView.frame = frame;
        }
    }
}

- (CGFloat)heightForTableView:(UITableView*)tableView
{
    CGFloat tableViewContentHeight = 0.0;
    NSInteger numberOfTableRows = [self.tableView.delegate tableView:self.tableView numberOfRowsInSection:0];
    for (int i=0; i<numberOfTableRows; i++) {
        tableViewContentHeight += [self.tableView.delegate tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    
    return tableViewContentHeight;
}

#pragma mark -
#pragma mark UIControl Methods

- (void)cancelButtonWasTapped:(id)sender
{
    [self.delegate surveyQuestionViewDidTapCancelButton:self];
}

- (void)nextButtonWasTapped:(id)sender
{
    [self.delegate surveyQuestionViewDidTapNextButton:self];
}

#pragma mark -
#pragma mark UITextField/UITextView delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.delegate surveyQuestionViewDidTapNextButton:self];
    
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [self.delegate surveyQuestionViewAnswerDidChange:self];
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
	if ([text isEqualToString:@"\n"])
    {
        [self.delegate surveyQuestionViewDidTapNextButton:self];
        return NO;
    }
    
    [self.delegate surveyQuestionViewAnswerDidChange:self];
    
    return YES;
}

#pragma mark -
#pragma mark UIGestureRecognizer Methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (touch.view == self)
        return YES;
    
    return NO;
}

- (void)didTapBackground:(id)sender
{
    [self.delegate surveyQuestionViewDidTapCancelButton:self];
}

@end
