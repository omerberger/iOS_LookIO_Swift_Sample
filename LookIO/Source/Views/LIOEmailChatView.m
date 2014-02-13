//
//  LIOEmailChatView.m
//  LookIO
//
//  Created by Yaron Karasik on 1/8/14.
//
//

#import "LIOEmailChatView.h"

#import "LIOBrandingManager.h"
#import "LIOBundleManager.h"

#define LIOEmailChatViewOuterMarginPhone 10
#define LIOEmailChatViewInnerMargin 25
#define LIOEmailChatViewTextFieldMargin 30


@interface LIOEmailChatView () <UITextFieldDelegate>

@property (nonatomic, strong) UIView *backgroundView;

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *submitButton;

@property (nonatomic, strong) UIView *emailTextFieldBackgroundView;
@property (nonatomic, strong) UITextField *emailTextField;

@property (nonatomic, strong) UIAlertView *alertView;

@property (nonatomic, assign) CGFloat lastKeyboardHeight;

@end

@implementation LIOEmailChatView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
        
        self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.showsVerticalScrollIndicator = NO;
        [self addSubview:self.scrollView];
        
        UIButton *tappableDismissBackgroundButton = [[UIButton alloc] initWithFrame:self.bounds];
        tappableDismissBackgroundButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [tappableDismissBackgroundButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:tappableDismissBackgroundButton];
                
        self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.backgroundView.backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementEmailChatCard];
        self.backgroundView.layer.borderColor = [[[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementEmailChatCard] CGColor];
        self.backgroundView.layer.borderWidth = 1.0;
        self.backgroundView.layer.cornerRadius = 5.0;
        [self.scrollView addSubview:self.backgroundView];

        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.font = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementEmailChatTitle];
        self.titleLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementEmailChatTitle];
        self.titleLabel.text = LIOLocalizedString(@"LIOEmailHistoryViewController.HeaderTextLong");
        self.titleLabel.textAlignment = UITextAlignmentCenter;
        self.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
        [self.backgroundView addSubview:self.titleLabel];
        
        self.emailTextFieldBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        UIColor *textFieldBackgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementEmailChatTextField];
        CGFloat textFieldAlpha = [[LIOBrandingManager brandingManager] backgroundAlphaForElement:LIOBrandingElementEmailChatTextField];
        self.emailTextFieldBackgroundView.backgroundColor = [textFieldBackgroundColor colorWithAlphaComponent:textFieldAlpha];
        self.emailTextFieldBackgroundView.layer.borderColor = [[[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementEmailChatTextField] CGColor];
        self.emailTextFieldBackgroundView.layer.borderWidth = 1.0;
        self.emailTextFieldBackgroundView.layer.cornerRadius = 5.0;
        [self.backgroundView addSubview:self.emailTextFieldBackgroundView];
        
        self.emailTextField = [[UITextField alloc] initWithFrame:self.emailTextFieldBackgroundView.bounds];
        self.emailTextField.font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementEmailChatTextField];
        self.emailTextField.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementEmailChatTextField];
        self.emailTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.emailTextField.returnKeyType = UIReturnKeySend;
        self.emailTextField.delegate = self;
        self.emailTextField.textAlignment = UITextAlignmentCenter;
        self.emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
        self.emailTextField.keyboardAppearance = [[LIOBrandingManager brandingManager] keyboardTypeForElement:LIOBrandingElementKeyboardType];
        self.emailTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [self.emailTextFieldBackgroundView addSubview:self.emailTextField];
        self.emailTextField.placeholder = LIOLocalizedString(@"LIOEmailPlaceholder");
        
        if (!LIOIsUIKitFlatMode())
        {
            CGRect frame = self.emailTextField.frame;
            frame.origin.y = 8.0;
            self.emailTextField.frame = frame;
        }
        
        self.cancelButton = [[UIButton alloc] initWithFrame:CGRectZero];
        self.cancelButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        [self.cancelButton setTitle:LIOLocalizedString(@"LIOEmailHistoryViewController.NavLeftButton") forState:UIControlStateNormal];
        [self.cancelButton addTarget:self action:@selector(cancelButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        UIColor *cancelButtonColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementEmailChatCancelButton];
        [self.cancelButton setTitleColor:cancelButtonColor forState:UIControlStateNormal];
        [self.cancelButton setTitleColor:[cancelButtonColor colorWithAlphaComponent:0.3] forState:UIControlStateNormal | UIControlStateHighlighted];
        UIFont *buttonFont = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementEmailChatCancelButton];
        self.cancelButton.titleLabel.font = buttonFont;

        CGRect frame = self.cancelButton.frame;
        frame.size = [self.cancelButton.titleLabel.text sizeWithFont:buttonFont];
        self.cancelButton.frame = frame;
        
        self.submitButton = [[UIButton alloc] initWithFrame:CGRectZero];
        self.submitButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self.submitButton setTitle:LIOLocalizedString(@"LIOEmailHistoryViewController.SubmitButton") forState:UIControlStateNormal];
        [self.submitButton addTarget:self action:@selector(submitButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        UIColor *submitButtonColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementEmailChatSubmitButton];
        [self.submitButton setTitleColor:submitButtonColor forState:UIControlStateNormal];
        [self.submitButton setTitleColor:[submitButtonColor colorWithAlphaComponent:0.3] forState:UIControlStateNormal | UIControlStateHighlighted];
        self.submitButton.titleLabel.font = buttonFont;
        frame = self.submitButton.frame;
        frame.size = [self.submitButton.titleLabel.text sizeWithFont:   buttonFont];
        self.submitButton.frame = frame;
        
        if (!padUI)
        {
            
            UIToolbar* numberToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 50)];
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
            
            numberToolbar.items = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithCustomView:self.cancelButton],
                                   [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                   [[UIBarButtonItem alloc] initWithCustomView:self.submitButton],
                                   nil];
            [numberToolbar sizeToFit];
            self.emailTextField.inputAccessoryView = numberToolbar;
        }
        else
        {
            [self.backgroundView addSubview:self.cancelButton];
            [self.backgroundView addSubview:self.submitButton];
        }
    }
    
    return self;
}

- (void)layoutSubviews
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    UIInterfaceOrientation actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    BOOL landscape = UIInterfaceOrientationIsLandscape(actualInterfaceOrientation);

    CGRect frame = self.backgroundView.frame;
    if (padUI)
    {
        frame.origin.y = landscape ? 20 : 135;
        frame.size.width = landscape ? 400 : 450;
        frame.size.height = landscape ? 350 : 460;
        frame.origin.x = (self.superview.frame.size.width - frame.size.width)/2;
    }
    else
    {
        frame.origin.x = LIOEmailChatViewOuterMarginPhone;
        frame.origin.y = landscape ? 10.0 : 25.0;
        frame.size.width = self.bounds.size.width - 2*LIOEmailChatViewOuterMarginPhone;
    }
    self.backgroundView.frame = frame;

    
    frame = self.titleLabel.frame;
    CGSize expectedSize = [self.titleLabel.text sizeWithFont:self.titleLabel.font constrainedToSize:CGSizeMake(self.backgroundView.bounds.size.width - 2*LIOEmailChatViewInnerMargin, self.backgroundView.bounds.size.height - 2*LIOEmailChatViewInnerMargin) lineBreakMode:UILineBreakModeWordWrap];
    frame.origin.x = (self.backgroundView.bounds.size.width - expectedSize.width)/2;
    frame.origin.y = 10.0;
    frame.size = expectedSize;
    self.titleLabel.frame = frame;
    self.titleLabel.numberOfLines = 0;
    [self.titleLabel sizeToFit];
    
    frame = self.emailTextFieldBackgroundView.frame;
    frame.origin.x = LIOEmailChatViewTextFieldMargin;
    frame.origin.y = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 10.0;
    frame.size.width = self.backgroundView.frame.size.width - 2*LIOEmailChatViewTextFieldMargin;
    frame.size.height = 40.0;
    self.emailTextFieldBackgroundView.frame = frame;
    
    if (!padUI)
    {
        frame = self.backgroundView.frame;
        if (!landscape)
        {
            frame.size.height = self.emailTextFieldBackgroundView.frame.origin.y + self.emailTextFieldBackgroundView.frame.size.height + 15.0;
        }
        else
        {
            frame.size.height = self.emailTextFieldBackgroundView.frame.origin.y + self.emailTextFieldBackgroundView.frame.size.height + 15.0;
        }
        self.backgroundView.frame = frame;
    }
    
    
    if (padUI)
    {
        CGFloat contentHeight = self.emailTextFieldBackgroundView.frame.origin.y + self.emailTextFieldBackgroundView.frame.size.height;
        CGFloat startPoint = self.backgroundView.frame.size.height/2 - contentHeight/2;
        
        frame = self.titleLabel.frame;
        frame.origin.y = startPoint;
        self.titleLabel.frame = frame;
        
        frame = self.emailTextFieldBackgroundView.frame;
        frame.origin.y = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + (landscape ? 12.0 : 15.0);
        self.emailTextFieldBackgroundView.frame = frame;
        
        frame = self.submitButton.frame;
        CGSize expectedSubmitButtonSize = [LIOLocalizedString(@"LIOEmailHistoryViewController.SubmitButton") sizeWithFont:self.submitButton.titleLabel.font];
        
        frame.origin.x = self.backgroundView.frame.size.width - expectedSubmitButtonSize.width - 33.0;
        frame.origin.y = self.backgroundView.frame.size.height - expectedSubmitButtonSize.height - 40.0;
        frame.size = expectedSubmitButtonSize;
        self.submitButton.frame = frame;
        
        frame = self.cancelButton.frame;
        CGSize expectedCancelButtonSize = [LIOLocalizedString(@"LIOEmailHistoryViewController.NavLeftButton") sizeWithFont:self.cancelButton.titleLabel.font];
        
        frame.origin.x = 33.0;
        frame.origin.y = self.backgroundView.frame.size.height - expectedCancelButtonSize.height - 40.0;
        frame.size = expectedCancelButtonSize;
        self.cancelButton.frame = frame;
    }
    
    [self updateScrollView];
}

- (void)updateScrollView
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];

    if (!padUI)
    {
        self.scrollView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height - self.lastKeyboardHeight);
        self.scrollView.contentSize = CGSizeMake(self.bounds.size.width, self.backgroundView.frame.origin.y + self.backgroundView.bounds.size.height + 10.0);
    }
    else
    {
        self.scrollView.contentSize = self.bounds.size;
    }
}

#pragma mark -
#pragma mark UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self submitButtonWasTapped:self];
    return NO;
}

#pragma mark -
#pragma mark Action Methods

- (void)present
{
    self.emailChatViewResult = LIOEmailChatViewResultNone;
    
    [self registerForKeyboardNotifications];
    [self.emailTextField becomeFirstResponder];
}

- (void)dismiss
{
    self.emailChatViewResult = LIOEmailChatViewResultCancel;

    [self.emailTextField resignFirstResponder];
}

- (void)forceDismiss
{
    self.emailChatViewResult = LIOEmailChatViewResultCancel;
    
    [self unregisterForKeyboardNotifications];
    [self.delegate emailChatViewDidForceDismiss:self];
}

- (void)cleanup
{
    [self unregisterForKeyboardNotifications];
}

- (void)cancelButtonWasTapped:(id)sender
{
    [self.delegate emailChatViewDidCancel:self];
}

- (void)submitButtonWasTapped:(id)sender
{
    if (self.emailTextField.text.length == 0)
    {
        self.emailChatViewResult = LIOEmailChatViewResultCancel;
        
        [self.delegate emailChatViewDidCancel:self];
    }
    else
    {
        // Validate the email, and if valid, submit
        BOOL stricterFilter = YES; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
        NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
        NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
        NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        if ([emailTest evaluateWithObject:self.emailTextField.text])
        {
            self.emailChatViewResult = LIOEmailChatViewResultSubmit;
            
            [self.delegate emailChatView:self didSubmitEmail:self.emailTextField.text];
            [self dismiss];
        }
        else
        {
            [self dismissExistingAlertView];
            self.alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOEmailHistoryViewController.InvalidAlertTitle") message:LIOLocalizedString(@"LIOEmailHistoryViewController.InvalidAlertBody") delegate:nil cancelButtonTitle:LIOLocalizedString(@"LIOEmailHistoryViewController.InvalidAlertButton") otherButtonTitles:nil];
            [self.alertView show];
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
#pragma mark Keyboard Methods

- (void)registerForKeyboardNotifications
{
    // Register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)unregisterForKeyboardNotifications
{
    // Unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

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
    
    UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;
    self.lastKeyboardHeight = UIInterfaceOrientationIsPortrait(actualOrientation) ? keyboardRect.size.height : keyboardRect.size.width;
    
    [UIView animateWithDuration:duration delay:0.0 options:(curve << 16) animations:^{
        CGRect frame = self.frame;
        frame.origin.y = 0;
        self.frame = frame;
    } completion:^(BOOL finished) {
        [self updateScrollView];
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
    
    self.lastKeyboardHeight = 0.0;
    
    [UIView animateWithDuration:duration delay:0.0 options:(curve << 16) animations:^{
        CGRect frame = self.frame;
        frame.origin.y = -frame.size.height;
        self.frame = frame;
    } completion:^(BOOL finished) {
        if (LIOEmailChatViewResultNone != self.emailChatViewResult)
        {
            [self unregisterForKeyboardNotifications];
            [self.delegate emailChatViewDidFinishDismissAnimation:self];
        }
    }];
}


@end
