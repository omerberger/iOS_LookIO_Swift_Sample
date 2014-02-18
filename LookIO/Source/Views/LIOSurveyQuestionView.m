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
#define LIOSurveyViewTopMarginLandscape         15.0
#define LIOSurveyViewSideMargin                 10.0
#define LIOSurveyViewSideMarginiPad             25.0
#define LIOSurveyViewPageControlOriginY         265.0

#define LIOSurveyViewIntroButtonMargin          15.0
#define LIOSurveyViewIntroTopMarginPortrait     90.0
#define LIOSurveyViewIntroTopMarginLandscape    50.0

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
@property (nonatomic, strong) NSString *nextButtonText;

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

        
        self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.showsVerticalScrollIndicator = NO;
        [self addSubview:self.scrollView];
        
        if (padUI) {
            self.scrollView.scrollEnabled = NO;
        }
        else
        {
            self.scrollView.scrollEnabled = YES;
            self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        }
        
        self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        UIColor *backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementSurveyCard];
        CGFloat backgroundAlpha = [[LIOBrandingManager brandingManager] backgroundAlphaForElement:LIOBrandingElementSurveyCard];
        self.backgroundView.backgroundColor = [backgroundColor colorWithAlphaComponent:backgroundAlpha];
        self.backgroundView.layer.borderColor = [[[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementSurveyCard] CGColor];
        self.backgroundView.layer.borderWidth = 1.0;
        self.backgroundView.layer.cornerRadius = 5.0;
        [self.scrollView addSubview:self.backgroundView];
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.font = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementSurveyCardTitle];
        self.titleLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementSurveyCardTitle];
        self.titleLabel.textAlignment = UITextAlignmentCenter;
        self.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self.scrollView addSubview:self.titleLabel];
        
        self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.subtitleLabel.backgroundColor = [UIColor clearColor];
        self.subtitleLabel.font = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementSurveyCardSubtitle];
        self.subtitleLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementSurveyCardSubtitle];
        self.subtitleLabel.numberOfLines = 0;
        self.subtitleLabel.text = LIOLocalizedString(@"LIOSurveyViewController.MandatoryQuestionsTitle");
        self.subtitleLabel.textAlignment = UITextAlignmentCenter;
        self.subtitleLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self.scrollView addSubview:self.subtitleLabel];
        
        self.textFieldBackground = [[UIView alloc] init];
        self.textFieldBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.textFieldBackground.alpha = 0.85;
        UIColor *textFieldBackgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementSurveyTextField];
        CGFloat textFieldBackgroundAlpha = [[LIOBrandingManager brandingManager] backgroundAlphaForElement:LIOBrandingElementSurveyTextField];
        self.textFieldBackground.backgroundColor = [textFieldBackgroundColor colorWithAlphaComponent:textFieldBackgroundAlpha];
        self.textFieldBackground.layer.borderColor = [[[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementSurveyTextField] CGColor];
        self.textFieldBackground.layer.borderWidth = 1.0;
        self.textFieldBackground.layer.cornerRadius = 5.0;
        [self.scrollView addSubview:self.textFieldBackground];
        
        self.textField = [[UITextField alloc] init];
        self.textField.delegate = self;
        self.textField.backgroundColor = [UIColor clearColor];
        self.textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.textField.font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementSurveyTextField];
        self.textField.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementSurveyTextField];
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.keyboardAppearance = [[LIOBrandingManager brandingManager] keyboardTypeForElement:LIOBrandingElementKeyboardType];
        [self.textFieldBackground addSubview:self.textField];
        
        self.textView = [[UITextView alloc] init];
        self.textView.delegate = self;
        self.textView.backgroundColor = [UIColor clearColor];
        self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.textView.font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementSurveyTextField];
        self.textView.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementSurveyTextField];
        self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textView.keyboardAppearance = [[LIOBrandingManager brandingManager] keyboardTypeForElement:LIOBrandingElementKeyboardType];
        [self.textFieldBackground addSubview:self.textView];
        
        self.starRatingView = [[LIOStarRatingView alloc] initWithFrame:CGRectZero];
        // TODO: Star color rating customization
        [self.scrollView addSubview:self.starRatingView];
        
        self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        self.tableView.backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementSurveyList];
        self.tableView.layer.borderColor = [[[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementSurveyList] CGColor];
        self.tableView.layer.borderWidth = 1.0;
        self.tableView.separatorColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementSurveyList];
        self.tableView.layer.cornerRadius = 5.0;
        self.tableView.backgroundView = nil;
        self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.tableView.showsVerticalScrollIndicator = NO;
        [self.scrollView addSubview:self.tableView];
        
        self.nextButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [self.nextButton addTarget:self action:@selector(nextButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        self.nextButton.titleLabel.font = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementSurveyCardNextButton];
        UIColor *nextButtonColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementSurveyCardNextButton];
        [self.nextButton setTitleColor:nextButtonColor forState:UIControlStateNormal];
        [self.nextButton setTitleColor:[nextButtonColor colorWithAlphaComponent:0.3f] forState:UIControlStateNormal | UIControlStateHighlighted];
        self.nextButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self.nextButton setTitle:LIOLocalizedString(@"LIOSurveyView.NextButtonTitle") forState:UIControlStateNormal];
        self.nextButtonText = LIOLocalizedString(@"LIOSurveyView.NextButtonTitle");
        [self.scrollView addSubview:self.nextButton];
        
        self.cancelButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [self.cancelButton addTarget:self action:@selector(cancelButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        self.cancelButton.titleLabel.font = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementSurveyCardCancelButton];
        UIColor *cancelButtonColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementSurveyCardCancelButton];
        [self.cancelButton setTitleColor:cancelButtonColor forState:UIControlStateNormal];
        [self.cancelButton setTitleColor:[cancelButtonColor colorWithAlphaComponent:0.3f] forState:UIControlStateNormal | UIControlStateHighlighted];
        self.cancelButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self.cancelButton setTitle:LIOLocalizedString(@"LIOSurveyView.CancelButtonTitle") forState:UIControlStateNormal];
        [self.scrollView addSubview:self.cancelButton];
        
        UIGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapBackground:)];
        tapGestureRecognizer.delegate = self;
        [self.scrollView addGestureRecognizer:tapGestureRecognizer];
    }
    
    return self;
}

- (void)setupViewWithQuestion:(LIOSurveyQuestion *)question isLastQuestion:(BOOL)isLastQuestion delegate:(id)delegate
{
    self.delegate = delegate;
    self.question = question;
    
    self.scrollView.frame = self.bounds;

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
        
        self.questionViewType = LIOSurveyQuestionViewNoKeyboard;
    }
    
    self.textFieldBackground.hidden = YES;
    self.textField.hidden = YES;
    self.textView.hidden = YES;

    if (LIOSurveyQuestionDisplayTypeTextField == question.displayType)
    {
        self.textFieldBackground.hidden = NO;
        self.textField.hidden = NO;
        self.questionViewType = LIOSurveyQuestionViewKeyboard;
        
        NSString* buttonTitle;
        if (isLastQuestion)
        {
            self.textField.returnKeyType = UIReturnKeyDone;
            buttonTitle = LIOLocalizedString(@"LIOSurveyView.DoneButtonTitle");
            self.nextButtonText = LIOLocalizedString(@"LIOSurveyView.DoneButtonTitle");
        }
        else
        {
            self.textField.returnKeyType = UIReturnKeyNext;
            buttonTitle = LIOLocalizedString(@"LIOSurveyView.NextButtonTitle");
            self.nextButtonText = LIOLocalizedString(@"LIOSurveyView.NextButtonTitle");
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
            UIToolbar* numberToolbar = [[UIToolbar alloc] init];
            numberToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            if (!LIOIsUIKitFlatMode())
            {
                numberToolbar.barStyle = UIBarStyleBlack;
            }
            else
            {
                
                if (UIKeyboardAppearanceLight == [[LIOBrandingManager brandingManager] keyboardTypeForElement:LIOBrandingElementKeyboardType])
                {
                    numberToolbar.barStyle = UIBarStyleDefault;
                }
                else
                {
                    numberToolbar.barStyle = UIBarStyleBlackTranslucent;
                }
            }
            
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

        // Populate last known value
        if (question.lastKnownValue)
            self.textField.text = question.lastKnownValue;
    }
    else
    {
        self.textFieldBackground.hidden = YES;
    }

    if (LIOSurveyQuestionDisplayTypeTextArea == question.displayType) {
        self.textFieldBackground.hidden = NO;
        self.textView.hidden = NO;
        self.questionViewType = LIOSurveyQuestionViewKeyboard;

        NSString *buttonTitle;
        if (isLastQuestion)
        {
            self.textView.returnKeyType = UIReturnKeyDone;
            buttonTitle = LIOLocalizedString(@"LIOSurveyView.DoneButtonTitle");
            self.nextButtonText = LIOLocalizedString(@"LIOSurveyView.DoneButtonTitle");
        }
        else
        {
            self.textView.returnKeyType = UIReturnKeyNext;
            buttonTitle = LIOLocalizedString(@"LIOSurveyView.NextButtonTitle");
            self.nextButtonText = LIOLocalizedString(@"LIOSurveyView.NextButtonTitle");
        }
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
            UIToolbar* numberToolbar = [[UIToolbar alloc] init];
            numberToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            if (!LIOIsUIKitFlatMode())
            {
                numberToolbar.barStyle = UIBarStyleBlack;
            }
            else
            {
                
                if (UIKeyboardAppearanceLight == [[LIOBrandingManager brandingManager] keyboardTypeForElement:LIOBrandingElementKeyboardType])
                {
                    numberToolbar.barStyle = UIBarStyleDefault;
                }
                else
                {
                    numberToolbar.barStyle = UIBarStyleBlackTranslucent;
                }
            }
            
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

            self.textView.inputAccessoryView = numberToolbar;
        }

        // Populate last known answer
        if (question.lastKnownValue)
            self.textView.text = question.lastKnownValue;
    }

    if ((LIOSurveyQuestionDisplayTypePicker == question.displayType || LIOSurveyQuestionDisplayTypeMultiselect == question.displayType) || padUI)
    {
        self.nextButton.hidden = NO;
        if (isLastQuestion)
        {
            [self.nextButton setTitle:LIOLocalizedString(@"LIOSurveyView.DoneButtonTitle") forState:UIControlStateNormal];
            self.nextButtonText = LIOLocalizedString(@"LIOSurveyView.DoneButtonTitle");
        }
        else
        {
            [self.nextButton setTitle:LIOLocalizedString(@"LIOSurveyView.NextButtonTitle") forState:UIControlStateNormal];
            self.nextButtonText = LIOLocalizedString(@"LIOSurveyView.NextButtonTitle");
        }
    }

    self.starRatingView.hidden = YES;
    self.tableView.hidden = YES;
    
    if (LIOSurveyQuestionDisplayTypePicker == question.displayType || LIOSurveyQuestionDisplayTypeMultiselect == question.displayType)
    {
        self.questionViewType = LIOSurveyQuestionViewNoKeyboard;

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

- (void)reloadTableViewDataIfNeeded
{
    if (!self.tableView.hidden)
        [self.tableView reloadData];
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
        aFrame.origin.y = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 10.0;
        aFrame.size.width = referenceFrame.size.width - 2*LIOSurveyViewSideMargin;
        if (!padUI)
        {
            aFrame.origin.x = LIOSurveyViewSideMargin * 4;
            aFrame.size.width = referenceFrame.size.width - (LIOSurveyViewSideMargin * 2 * 4);
        }
        self.subtitleLabel.frame = aFrame;

        self.nextButton.hidden = NO;
        aFrame.origin.x = referenceFrame.size.width/2 + LIOSurveyViewIntroButtonMargin;
        aFrame.origin.y = self.subtitleLabel.frame.origin.y + self.subtitleLabel.frame.size.height + 20;
        aFrame.size.width = 92.0;
        aFrame.size.height = 44.0;
        self.nextButton.frame = aFrame;
        
        self.cancelButton.hidden = NO;
        aFrame.origin.x = referenceFrame.size.width/2 - LIOSurveyViewIntroButtonMargin - 92.0;
        aFrame.origin.y = self.subtitleLabel.frame.origin.y + self.subtitleLabel.frame.size.height + 20;
        aFrame.size.width = 92.0;
        aFrame.size.height = 44.0;
        self.cancelButton.frame = aFrame;
        
        CGSize aSize;
        aSize.width = self.frame.size.width;
        aSize.height = self.nextButton.frame.origin.y + self.nextButton.frame.size.height + (landscape ? 20.0 : 45.0);
        self.scrollView.contentSize = aSize;
        
        if (padUI) {
            CGFloat contentHeight = self.subtitleLabel.frame.origin.y + self.subtitleLabel.frame.size.height;
            CGFloat startPoint = self.bounds.size.height/2 - contentHeight/2;
            
            aFrame = self.titleLabel.frame;
            aFrame.origin.y = startPoint;
            self.titleLabel.frame = aFrame;
            
            aFrame = self.subtitleLabel.frame;
            aFrame.origin.y = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 10.0;
            self.subtitleLabel.frame = aFrame;
            
            if (!self.nextButton.isHidden)
            {
                CGSize expectedNextButtonSize = [self.nextButtonText sizeWithFont:self.nextButton.titleLabel.font constrainedToSize:CGSizeMake(referenceFrame.size.width, FLT_MAX)];
                
                aFrame.origin.x = referenceFrame.size.width - LIOSurveyViewSideMarginiPad - expectedNextButtonSize.width - 18.0;
                aFrame.origin.y = referenceFrame.size.height - expectedNextButtonSize.height - 50.0;
                aFrame.size.width = expectedNextButtonSize.width + 20.0;
                aFrame.size.height = expectedNextButtonSize.height + 20.0;
                self.nextButton.frame = aFrame;
            }
            if (!self.cancelButton.isHidden)
            {
                CGSize expectedCancelButtonSize = [self.cancelButton.titleLabel.text sizeWithFont:self.cancelButton.titleLabel.font constrainedToSize:CGSizeMake(referenceFrame.size.width, FLT_MAX)];
                
                aFrame.origin.x = LIOSurveyViewSideMarginiPad - 2.0;
                aFrame.origin.y = referenceFrame.size.height - expectedCancelButtonSize.height - 50.0;
                aFrame.size.width = expectedCancelButtonSize.width + 20.0;
                aFrame.size.height = expectedCancelButtonSize.height + 20.0;
                self.cancelButton.frame = aFrame;
            }
        }
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
        self.scrollView.contentSize = aSize;
        
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
                CGSize expectedNextButtonSize = [self.nextButtonText sizeWithFont:self.nextButton.titleLabel.font constrainedToSize:CGSizeMake(referenceFrame.size.width, FLT_MAX)];

                aFrame.origin.x = referenceFrame.size.width - LIOSurveyViewSideMarginiPad - expectedNextButtonSize.width - 18.0;
                aFrame.origin.y = referenceFrame.size.height - expectedNextButtonSize.height - 50.0;
                aFrame.size.width = expectedNextButtonSize.width + 20.0;
                aFrame.size.height = expectedNextButtonSize.height + 20.0;
                self.nextButton.frame = aFrame;
                
                // Set up the scroll view to allow scrolling down to the text field if needed
                CGSize aSize;
                aSize.width = self.frame.size.width;
                aSize.height = self.nextButton.frame.origin.y + self.nextButton.frame.size.height + 30.0;
                self.scrollView.contentSize = aSize;
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
        aSize.height = self.textFieldBackground.frame.origin.y + self.textFieldBackground.frame.size.height + 65.0;
        self.scrollView.contentSize = aSize;
        
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
                CGSize expectedNextButtonSize = [self.nextButtonText sizeWithFont:self.nextButton.titleLabel.font constrainedToSize:CGSizeMake(referenceFrame.size.width, FLT_MAX)];

                aFrame.origin.x = referenceFrame.size.width - LIOSurveyViewSideMarginiPad - expectedNextButtonSize.width - 18.0;
                aFrame.origin.y = referenceFrame.size.height - expectedNextButtonSize.height - 50.0;
                aFrame.size.width = expectedNextButtonSize.width + 20.0;
                aFrame.size.height = expectedNextButtonSize.height + 20.0;
                self.nextButton.frame = aFrame;
                
                // Set up the scroll view to allow scrolling down to the text field if needed
                CGSize aSize;
                aSize.width = self.frame.size.width;
                aSize.height = self.nextButton.frame.origin.y + self.nextButton.frame.size.height + 30.0;
                self.scrollView.contentSize = aSize;
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
            frame.size.height = self.scrollView.contentSize.height - 70;
            frame.origin.y = 25;
        }
        else
        {
            frame.origin.x = 10;
            frame.size.width = self.bounds.size.width - 20;
            frame.size.height = self.scrollView.contentSize.height - 30;
            frame.origin.y = 10;
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
        
        
        CGSize expectedNextButtonSize = [self.nextButtonText sizeWithFont:self.nextButton.titleLabel.font constrainedToSize:CGSizeMake(referenceFrame.size.width, FLT_MAX)];

        aFrame.origin.x = referenceFrame.size.width - (padUI ? LIOSurveyViewSideMarginiPad : LIOSurveyViewSideMargin*2) - expectedNextButtonSize.width - 50.0;
        if (padUI)
        {
            aFrame.origin.x = referenceFrame.size.width - LIOSurveyViewSideMarginiPad - expectedNextButtonSize.width - 8.0;
            aFrame.origin.y = referenceFrame.size.height - expectedNextButtonSize.height - 40.0;
        }
        else
        {
            aFrame.origin.x = referenceFrame.size.width - expectedNextButtonSize.width - 35.0;
            if (landscape) {
                aFrame.origin.y = self.starRatingView.frame.origin.y + self.starRatingView.frame.size.height - 5;
            } else {
                aFrame.origin.y = self.starRatingView.frame.origin.y + self.starRatingView.frame.size.height + 15;
            }
        }
        aFrame.size.width = expectedNextButtonSize.width + 20.0;
        aFrame.size.height = expectedNextButtonSize.width + 20.0;
        self.nextButton.frame = aFrame;
        
        if (!padUI)
        {
            CGRect frame = self.backgroundView.frame;
            if (!landscape) {
                frame.origin.x = 10;
                frame.size.width = self.bounds.size.width - 20;
                frame.size.height = self.starRatingView.frame.origin.y + self.starRatingView.frame.size.height + 45;
                frame.origin.y = 25;
            }
            else {
                frame.origin.x = 10;
                frame.size.width = self.bounds.size.width - 20;
                frame.size.height = self.starRatingView.frame.origin.y + self.starRatingView.frame.size.height + 25;
                frame.origin.y = 10;
            }
            self.backgroundView.frame = frame;
        }
        
        self.scrollView.contentSize = self.backgroundView.frame.size;
    }
    
    if (!self.tableView.isHidden)
    {
        // We need to set the tableView width ahead of time, because it's used for the calculation of the row height
        CGRect frame = self.tableView.frame;
        frame.size.width = padUI ? (referenceFrame.size.width - LIOSurveyViewSideMarginiPad + 2) : (self.bounds.size.width - 50);
        self.tableView.frame = frame;
        
        CGFloat tableViewContentHeight = [self heightForTableView:self.tableView];

        CGFloat maxHeight;
        if (padUI)
        {
            maxHeight = referenceFrame.size.height - self.titleLabel.bounds.size.height - 140.0;
        }
        else
        {
            maxHeight = referenceFrame.size.height - self.titleLabel.bounds.size.height - (landscape ? 100.0 : 140.0);
        }
        
        if (tableViewContentHeight > maxHeight)
        {
            tableViewContentHeight = maxHeight;
        }
        else
        {
            if (padUI)
            {
                CGFloat contentHeight = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + tableViewContentHeight;
                CGFloat startPoint = self.bounds.size.height/2 - contentHeight/2 + 10;
                
                aFrame = self.titleLabel.frame;
                aFrame.origin.y = startPoint;
                self.titleLabel.frame = aFrame;
            }
        }
        
        self.tableView.frame = CGRectMake((padUI ? LIOSurveyViewSideMarginiPad : 25.0), self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 15.0, padUI ? (referenceFrame.size.width - LIOSurveyViewSideMarginiPad*2) : (self.bounds.size.width - 50), tableViewContentHeight);
        
        CGSize expectedNextButtonSize = [self.nextButtonText sizeWithFont:self.nextButton.titleLabel.font constrainedToSize:CGSizeMake(referenceFrame.size.width, FLT_MAX)];

        aFrame.origin.x = referenceFrame.size.width - LIOSurveyViewSideMarginiPad - expectedNextButtonSize.width - 18.0;
        if (padUI)
            aFrame.origin.y = referenceFrame.size.height - expectedNextButtonSize.height - 50.0;
        else
            aFrame.origin.y = landscape ? self.tableView.frame.origin.y + self.tableView.frame.size.height : self.tableView.frame.origin.y + self.tableView.frame.size.height + 5.0;
        aFrame.size.width = expectedNextButtonSize.width + 20.0;
        aFrame.size.height = expectedNextButtonSize.height + 20.0;
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
                frame.origin.y = 10;
            }
            self.backgroundView.frame = frame;
        }
        
        self.scrollView.contentSize = self.backgroundView.frame.size;
    }

}

- (CGFloat)heightForTableView:(UITableView*)tableView
{
    CGFloat tableViewContentHeight = 0.0;
    NSInteger numberOfTableRows = [self.tableView.dataSource tableView:self.tableView numberOfRowsInSection:0];
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

- (void)questionViewDidAppear
{
    if (!self.starRatingView.hidden)
        [self.starRatingView showIntroAnimation];
}

- (void)questionViewDidDisappear
{
    if (!self.starRatingView.hidden)
        [self.starRatingView stopAnimation];
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
    [textField setText:[textField.text stringByReplacingCharactersInRange:range withString:string]];
    
    [self.delegate surveyQuestionViewAnswerDidChange:self];
    return NO;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
	if ([text isEqualToString:@"\n"])
    {
        [self.delegate surveyQuestionViewDidTapNextButton:self];
        return NO;
    }

    [textView setText:[textView.text stringByReplacingCharactersInRange:range withString:text]];
    [self.delegate surveyQuestionViewAnswerDidChange:self];
    
    return NO   ;
}

#pragma mark -
#pragma mark UIGestureRecognizer Methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    if (padUI)
        return NO;

    if (touch.view == self.scrollView)
        return YES;
    
    return NO;
}

- (void)didTapBackground:(id)sender
{
    [self.delegate surveyQuestionViewDidTapCancelButton:self];
}

@end
