//
//  LIOApprovePhotoView.m
//  LookIO
//
//  Created by Yaron Karasik on 1/8/14.
//
//

#import "LIOApprovePhotoView.h"

#import "LIOBrandingManager.h"
#import "LIOBundleManager.h"

#define LIOApprovePhotoViewOuterMarginPhone 10
#define LIOApprovePhotoViewInnerMargin 25
#define LIOApprovePhotoViewTextFieldMargin 30


@interface LIOApprovePhotoView () <UITextFieldDelegate>

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *submitButton;

@property (nonatomic, strong) UIView *backgroundView;

@end

@implementation LIOApprovePhotoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIButton *tappableDismissBackgroundButton = [[UIButton alloc] initWithFrame:self.bounds];
        tappableDismissBackgroundButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [tappableDismissBackgroundButton addTarget:self action:@selector(cancelButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:tappableDismissBackgroundButton];
        
        self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.backgroundView.backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementApprovePhotoCard];
        self.backgroundView.layer.borderColor = [[[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementApprovePhotoCard] CGColor];
        self.backgroundView.layer.borderWidth = 1.0;
        self.backgroundView.layer.cornerRadius = 5.0;
        [self addSubview:self.backgroundView];
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.font = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementApprovePhotoTitle];
        self.titleLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementApprovePhotoTitle];
        self.titleLabel.text = LIOLocalizedString(@"LIOAltChatViewController.AttachConfirmationBody");
        self.titleLabel.textAlignment = UITextAlignmentCenter;
        self.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
        [self.backgroundView addSubview:self.titleLabel];
        
        self.cancelButton = [[UIButton alloc] initWithFrame:CGRectZero];
        self.cancelButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        [self.cancelButton setTitle:LIOLocalizedString(@"LIOAltChatViewController.AttachConfirmationDontSend") forState:UIControlStateNormal];
        [self.cancelButton addTarget:self action:@selector(cancelButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        UIColor *cancelButtonColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementApprovePhotoCancelButton];
        [self.cancelButton setTitleColor:cancelButtonColor forState:UIControlStateNormal];
        [self.cancelButton setTitleColor:[cancelButtonColor colorWithAlphaComponent:0.3] forState:UIControlStateNormal | UIControlStateHighlighted];
        UIFont *buttonFont = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementApprovePhotoCancelButton];
        self.cancelButton.titleLabel.font = buttonFont;
        CGRect frame = self.cancelButton.frame;
        frame.size = [self.cancelButton.titleLabel.text sizeWithFont:buttonFont];
        self.cancelButton.frame = frame;
        [self.backgroundView addSubview:self.cancelButton];
        
        self.submitButton = [[UIButton alloc] initWithFrame:CGRectZero];
        self.submitButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self.submitButton setTitle:LIOLocalizedString(@"LIOAltChatViewController.AttachConfirmationSend") forState:UIControlStateNormal];
        [self.submitButton addTarget:self action:@selector(submitButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        UIColor *submitButtonColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementApprovePhotoSubmitButton];
        [self.submitButton setTitleColor:submitButtonColor forState:UIControlStateNormal];
        [self.submitButton setTitleColor:[submitButtonColor colorWithAlphaComponent:0.3] forState:UIControlStateNormal | UIControlStateHighlighted];
        self.submitButton.titleLabel.font = buttonFont;
        frame = self.submitButton.frame;
        frame.size = [self.submitButton.titleLabel.text sizeWithFont:   buttonFont];
        self.submitButton.frame = frame;
        [self.backgroundView addSubview:self.submitButton];
        
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.backgroundView addSubview:self.imageView];
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
        frame.size.width = landscape ? self.bounds.size.width - 160 : self.bounds.size.width - 40;
        frame.size.height = landscape ? 260 : 300;
        frame.origin.x = (self.superview.frame.size.width - frame.size.width)/2;
        frame.origin.y = (self.superview.frame.size.height - frame.size.height)/2;
    }
    self.backgroundView.frame = frame;
    
    frame = self.titleLabel.frame;
    CGSize expectedSize = [self.titleLabel.text sizeWithFont:self.titleLabel.font constrainedToSize:CGSizeMake(self.backgroundView.bounds.size.width - 2*LIOApprovePhotoViewInnerMargin, self.backgroundView.bounds.size.height - 2*LIOApprovePhotoViewInnerMargin) lineBreakMode:UILineBreakModeWordWrap];
    frame.origin.x = (self.backgroundView.bounds.size.width - expectedSize.width)/2;
    frame.origin.y = 0;
    frame.size = expectedSize;
    self.titleLabel.frame = frame;
    self.titleLabel.numberOfLines = 0;
    [self.titleLabel sizeToFit];
    
    frame = self.imageView.frame;
    frame.origin.x = 20.0;
    frame.origin.y = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 10.0;
    frame.size.width = self.backgroundView.bounds.size.width - 40.0;
    frame.size.height = 150.0;
    self.imageView.frame = frame;
    
    frame = self.submitButton.frame;
    CGSize expectedSubmitButtonSize = [LIOLocalizedString(@"LIOAltChatViewController.AttachConfirmationSend") sizeWithFont:self.submitButton.titleLabel.font];
    
    CGFloat buttonXDelta = padUI ? 33.0 : 10.0;
    CGFloat buttonYDelta = padUI ? 40.0 : 10.0;
    
    frame.origin.x = self.backgroundView.frame.size.width - expectedSubmitButtonSize.width - buttonXDelta;
    frame.origin.y = self.backgroundView.frame.size.height - expectedSubmitButtonSize.height - buttonYDelta;
    frame.size = expectedSubmitButtonSize;
    self.submitButton.frame = frame;
    
    frame = self.cancelButton.frame;
    CGSize expectedCancelButtonSize = [LIOLocalizedString(@"LIOAltChatViewController.AttachConfirmationDontSend") sizeWithFont:self.cancelButton.titleLabel.font];
    
    frame.origin.x = buttonXDelta;
    frame.origin.y = self.backgroundView.frame.size.height - expectedCancelButtonSize.height - buttonYDelta;
    frame.size = expectedCancelButtonSize;
    self.cancelButton.frame = frame;
    
    // Center the main view
    
    CGFloat contentHeight = self.imageView.frame.origin.y + self.imageView.frame.size.height;
    CGFloat startPoint = self.cancelButton.frame.origin.y/2 - contentHeight/2;
    
    frame = self.titleLabel.frame;
    frame.origin.y = startPoint;
    self.titleLabel.frame = frame;
    
    frame = self.imageView.frame;
    frame.origin.y = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 10.0;
    self.imageView.frame = frame;
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

- (void)cancelButtonWasTapped:(id)sender
{
    [self.delegate approvePhotoViewDidCancel:self];
}

- (void)submitButtonWasTapped:(id)sender
{

    [self.delegate approvePhotoViewDidApprove:self];
}


@end
