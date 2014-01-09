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
#define LIOEmailChatViewInnerMargin 10
#define LIOEmailChatViewTextFieldMargin 30


@interface LIOEmailChatView () <UITextFieldDelegate>

@property (nonatomic, strong) UIView *backgroundView;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;

@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *submitButton;

@property (nonatomic, strong) UIView *emailTextFieldBackgroundView;
@property (nonatomic, strong) UITextField *emailTextField;

@end

@implementation LIOEmailChatView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIColor *backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementEmailChat];
        CGFloat alpha = [[LIOBrandingManager brandingManager] backgroundAlphaForElement:LIOBrandingElementEmailChat];
        self.backgroundColor = [backgroundColor colorWithAlphaComponent:alpha];
        
        self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.backgroundView.backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementEmailChatCard];
        self.backgroundView.layer.borderColor = [[[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementEmailChatCard] CGColor];
        self.backgroundView.layer.borderWidth = 1.0;
        self.backgroundView.layer.cornerRadius = 5.0;
        [self addSubview:self.backgroundView];
        
        self.cancelButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [self.cancelButton setTitle:LIOLocalizedString(@"LIOEmailHistoryViewController.NavLeftButton") forState:UIControlStateNormal];
        [self.cancelButton addTarget:self action:@selector(cancelButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        UIColor *cancelButtonColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementEmailChatCancelButton];
        [self.cancelButton setTitleColor:cancelButtonColor forState:UIControlStateNormal];
        [self.cancelButton setTitleColor:[cancelButtonColor colorWithAlphaComponent:0.3] forState:UIControlStateNormal | UIControlStateHighlighted];
        self.cancelButton.titleLabel.font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementEmailChatCancelButton];
        [self.backgroundView addSubview:self.cancelButton];
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.titleLabel.font = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementEmailChatTitle];
        self.titleLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementEmailChatTitle];
        self.titleLabel.text = LIOLocalizedString(@"LIOEmailHistoryViewController.HeaderText");
        self.titleLabel.textAlignment = UITextAlignmentCenter;
        self.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
        [self.backgroundView addSubview:self.titleLabel];
        
        self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.subtitleLabel.font = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementEmailChatSubtitle];
        self.subtitleLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementEmailChatSubtitle];
        self.subtitleLabel.text = LIOLocalizedString(@"LIOEmailHistoryViewController.EmailHeader");
        self.subtitleLabel.textAlignment = UITextAlignmentCenter;
        self.subtitleLabel.lineBreakMode = UILineBreakModeWordWrap;
        [self.backgroundView addSubview:self.subtitleLabel];
        
        self.emailTextFieldBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        UIColor *textFieldBackgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementEmailChatTextField];
        CGFloat textFieldAlpha = [[LIOBrandingManager brandingManager] backgroundAlphaForElement:LIOBrandingElementEmailChatTextField];
        self.emailTextFieldBackgroundView.backgroundColor = [textFieldBackgroundColor colorWithAlphaComponent:textFieldAlpha];
        self.emailTextFieldBackgroundView.layer.borderColor = [[[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementEmailChatTextField] CGColor];
        self.emailTextFieldBackgroundView.layer.borderWidth = 1.0;
        self.emailTextFieldBackgroundView.layer.cornerRadius = 5.0;
        [self.backgroundView addSubview:self.emailTextFieldBackgroundView];
        
        self.emailTextField = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, self.emailTextFieldBackgroundView.bounds.size.width - 20, self.emailTextFieldBackgroundView.bounds.size.height)];
        self.emailTextField.font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementEmailChatTextField];
        self.emailTextField.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementEmailChatTextField];
        self.emailTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.emailTextField.returnKeyType = UIReturnKeySend;
        self.emailTextField.delegate = self;
        self.emailTextField.textAlignment = UITextAlignmentCenter;
        self.emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
        self.emailTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [self.emailTextFieldBackgroundView addSubview:self.emailTextField];
        
        self.submitButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [self.submitButton setTitle:LIOLocalizedString(@"LIOEmailHistoryViewController.SubmitButton") forState:UIControlStateNormal];
        [self.submitButton addTarget:self action:@selector(submitButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        UIColor *submitButtonColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementEmailChatSubmitButton];
        [self.submitButton setTitleColor:submitButtonColor forState:UIControlStateNormal];
        [self.submitButton setTitleColor:[submitButtonColor colorWithAlphaComponent:0.3] forState:UIControlStateNormal | UIControlStateHighlighted];
        self.submitButton.titleLabel.font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementEmailChatSubmitButton];
        [self.backgroundView addSubview:self.submitButton];
    }
    
    return self;
}

- (void)layoutSubviews
{
    CGRect frame = self.backgroundView.frame;
    frame.origin.x = LIOEmailChatViewOuterMarginPhone;
    frame.origin.y = LIOEmailChatViewOuterMarginPhone;
    frame.size.width = self.bounds.size.width - 2*LIOEmailChatViewOuterMarginPhone;
    frame.size.height = self.bounds.size.height - 2*LIOEmailChatViewOuterMarginPhone;
    self.backgroundView.frame = frame;
    
    frame = self.cancelButton.frame;
    CGSize expectedSize = [self.cancelButton.titleLabel.text sizeWithFont:self.cancelButton.titleLabel.font constrainedToSize:CGSizeMake(self.backgroundView.frame.size.width, self.backgroundView.frame.size.height) lineBreakMode:UILineBreakModeWordWrap];
    frame.origin.x = self.backgroundView.bounds.size.width - expectedSize.width - LIOEmailChatViewInnerMargin;
    frame.origin.y = LIOEmailChatViewInnerMargin;
    frame.size.width = expectedSize.width;
    frame.size.height = expectedSize.height;
    self.cancelButton.frame = frame;
    
    frame = self.titleLabel.frame;
    expectedSize = [self.titleLabel.text sizeWithFont:self.titleLabel.font constrainedToSize:CGSizeMake(self.backgroundView.bounds.size.width - 2*LIOEmailChatViewInnerMargin, self.backgroundView.bounds.size.height - 2*LIOEmailChatViewInnerMargin) lineBreakMode:UILineBreakModeWordWrap];
    frame.origin.x = (self.backgroundView.bounds.size.width - expectedSize.width)/2;
    BOOL isPhone5 = LIO_IS_IPHONE_5;
    frame.origin.y = LIO_IS_IPHONE_5 ? 50.0 : 30.0;
    frame.size = expectedSize;
    self.titleLabel.frame = frame;
    self.titleLabel.numberOfLines = 0;
    [self.titleLabel sizeToFit];
    
    frame = self.subtitleLabel.frame;
    expectedSize = [self.subtitleLabel.text sizeWithFont:self.subtitleLabel.font constrainedToSize:CGSizeMake(self.backgroundView.bounds.size.width - 2*LIOEmailChatViewInnerMargin, self.backgroundView.bounds.size.height - 2*LIOEmailChatViewInnerMargin) lineBreakMode:UILineBreakModeWordWrap];
    frame.origin.x = (self.backgroundView.bounds.size.width - expectedSize.width)/2;
    frame.origin.y = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + (LIO_IS_IPHONE_5 ? 70.0 : 20.0);
    frame.size = expectedSize;
    self.subtitleLabel.frame = frame;
    self.subtitleLabel.numberOfLines = 0;
    [self.subtitleLabel sizeToFit];
    
    frame = self.emailTextFieldBackgroundView.frame;
    frame.origin.x = LIOEmailChatViewTextFieldMargin;
    frame.origin.y = self.subtitleLabel.frame.origin.y + self.subtitleLabel.frame.size.height + 10.0;
    frame.size.width = self.backgroundView.frame.size.width - 2*LIOEmailChatViewTextFieldMargin;
    frame.size.height = 40.0;
    self.emailTextFieldBackgroundView.frame = frame;
    
    frame = self.submitButton.frame;
    expectedSize = [self.submitButton.titleLabel.text sizeWithFont:self.submitButton.titleLabel.font constrainedToSize:CGSizeMake(self.backgroundView.frame.size.width, self.backgroundView.frame.size.height) lineBreakMode:UILineBreakModeWordWrap];
    frame.origin.x = (self.backgroundView.bounds.size.width - expectedSize.width)/2;
    frame.origin.y = self.emailTextFieldBackgroundView.frame.origin.y + self.emailTextFieldBackgroundView.frame.size.height + 10.0;
    frame.size.width = expectedSize.width;
    frame.size.height = expectedSize.height;
    self.submitButton.frame = frame;
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
    [self.emailTextField becomeFirstResponder];
}

- (void)dismiss
{
    [self.emailTextField resignFirstResponder];
}

- (void)cancelButtonWasTapped:(id)sender
{
    [self.delegate emailChatViewDidCancel:self];
}

- (void)submitButtonWasTapped:(id)sender
{
    if (self.emailTextField.text.length == 0)
    {
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
            [self.delegate emailChatView:self didSubmitEmail:self.emailTextField.text];
        }
        else
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOEmailHistoryViewController.InvalidAlertTitle") message:LIOLocalizedString(@"LIOEmailHistoryViewController.InvalidAlertBody") delegate:nil cancelButtonTitle:LIOLocalizedString(@"LIOEmailHistoryViewController.InvalidAlertButton") otherButtonTitles:nil];
            [alertView show];
        }        
    }
}


@end
