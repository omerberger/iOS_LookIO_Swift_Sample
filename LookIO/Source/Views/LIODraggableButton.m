//
//  LIODraggableButton.m
//  LookIO
//
//  Created by Yaron Karasik on 12/9/13.
//
//

#import "LIODraggableButton.h"

// Managers
#import "LIOBundleManager.h"
#import "LIOBrandingManager.h"

// Helpers
#import "LIOTimerProxy.h"

// Views
#import "LIOBadgeView.h"
#import "LIOPopupLabel.h"

#define LIODraggableButtonSize 50.0
#define LIODraggableButtonMessageTime 5.0
#define LIODraggableButtonTextHeightRatio 1.5
#define LIODraggableButtonPopbackHeight 30.0

#define HEXCOLOR(c) [UIColor colorWithRed:((c>>16)&0xFF)/255.0 \
                     green:((c>>8)&0xFF)/255.0 \
                     blue:((c)&0xFF)/255.0 \
                     alpha:1.0]

@interface LIODraggableButton ()

@property (nonatomic, assign) CGSize baseSize;

@property (nonatomic, assign) BOOL isDragging;
@property (nonatomic, assign) BOOL isVisible;
@property (nonatomic, assign) BOOL isAttachedToRight;
@property (nonatomic, assign) BOOL isShowingMessage;

@property (nonatomic, assign) CGPoint panPoint;
@property (nonatomic, assign) CGPoint preDragPosition;

@property (nonatomic, strong) UIImageView *statusImageView;
@property (nonatomic, assign) LIOBrandingElement lastUsedImageIcon;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic, strong) UIView *borderView;
@property (nonatomic, strong) UILabel *buttonTitleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) LIOPopupLabel *externalMessageLabel;
@property (nonatomic, strong) LIOBadgeView *badgeView;

@property (nonatomic, strong) LIOTimerProxy *messageTimer;


@end

@implementation LIODraggableButton

#pragma mark -
#pragma mark Initialization Methods

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.isAccessibilityElement = YES;
        
        self.lastUsedImageIcon = -1;
        
        self.layer.cornerRadius = 5.0;
        self.layer.borderWidth = 0.0;
        self.buttonTitle = LIOLocalizedString(@"LIOControlButtonView.DefaultText");
        self.accessibilityLabel = LIOLocalizedString(@"LIOControlButtonView.DefaultText");
        
        [self addTarget:self action:@selector(draggableButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *surveyTabPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(buttonDidPan:)];
        [self addGestureRecognizer:surveyTabPanGestureRecognizer];
        
        self.isVisible = NO;
        self.hidden = YES;
        self.isAttachedToRight = YES;
        
        self.borderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width + 1, self.bounds.size.height + 1.0)];
        self.borderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.borderView.layer.borderWidth = 1.0;
        self.borderView.layer.cornerRadius = 5.0;
        self.borderView.userInteractionEnabled = NO;
        [self addSubview:self.borderView];
        
        self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:self.bounds];
        self.activityIndicatorView.userInteractionEnabled = NO;
        [self addSubview:self.activityIndicatorView];
        
        self.buttonKind = LIOButtonKindIcon;

        self.statusImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, LIODraggableButtonSize - 20.0, LIODraggableButtonSize - 20.0)];
        self.statusImageView.userInteractionEnabled = NO;
        [self addSubview:self.statusImageView];

        self.messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.messageLabel.backgroundColor = [UIColor clearColor];
        self.messageLabel.hidden = YES;
        self.messageLabel.userInteractionEnabled = NO;
        [self addSubview:self.messageLabel];
        
        self.externalMessageLabel = [[LIOPopupLabel alloc] initWithFrame:CGRectZero];
        self.externalMessageLabel.textAlignment = UITextAlignmentCenter;
        self.externalMessageLabel.hidden = YES;
        self.externalMessageLabel.userInteractionEnabled = YES;
        self.externalMessageLabel.lineBreakMode = (UILineBreakModeWordWrap | UILineBreakModeTailTruncation);
        [self addSubview:self.externalMessageLabel];
        
        UIButton *externalMessageLabelButton = [[UIButton alloc] init];
        externalMessageLabelButton.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [externalMessageLabelButton addTarget:self action:@selector(messageLabelButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.externalMessageLabel addSubview:externalMessageLabelButton];

        UIFont *font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementControlButton];
        CGSize expectedSize = [self.buttonTitle sizeWithFont:font constrainedToSize:CGSizeMake(200, LIODraggableButtonSize)];
        
        self.buttonTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, expectedSize.width, expectedSize.height)];
        self.buttonTitleLabel.backgroundColor = [UIColor clearColor];
        self.buttonTitleLabel.text = self.buttonTitle;
        self.buttonTitleLabel.font = font;
        self.buttonTitleLabel.userInteractionEnabled = NO;
        self.buttonTitleLabel.transform = CGAffineTransformMakeRotation(-M_PI/2);
        [self addSubview:self.buttonTitleLabel];
        
        self.numberOfUnreadMessages = 0;
        
        self.badgeView = [[LIOBadgeView alloc] initWithFrame:CGRectMake(30, 5, 20, 20) forBrandingElement:LIOBrandingElementControlButtonBadge];
        [self.badgeView setBadgeNumber:1];
        self.badgeView.hidden = YES;
        [self addSubview:self.badgeView];
        
        self.clipsToBounds = NO;
        
        self.buttonMode = LIOButtonModeChat;
        [self updateBaseValues];
    }
    return self;
}

#pragma mark -
#pragma mark Setup Methods

- (void)updateBaseValues
{
    self.accessibilityLabel = self.buttonTitle;

    if (LIOButtonKindIcon == self.buttonKind)
    {
        self.baseSize = CGSizeMake(LIODraggableButtonSize, LIODraggableButtonSize);
        
        self.statusImageView.hidden = NO;
//        self.messageLabel.hidden = NO;
        self.buttonTitleLabel.hidden = YES;
        
    }
    if (LIOButtonKindText == self.buttonKind)
    {
        UIFont *font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementControlButton];
        self.buttonTitleLabel.font = font;
        self.buttonTitleLabel.text = self.buttonTitle;

        CGSize expectedSize = [self.buttonTitle sizeWithFont:font constrainedToSize:CGSizeMake(200, LIODraggableButtonSize)];
        self.baseSize = CGSizeMake(expectedSize.height*LIODraggableButtonTextHeightRatio, expectedSize.width + 20.0);
        CGRect bounds = self.buttonTitleLabel.bounds;
        bounds.size = expectedSize;
        self.buttonTitleLabel.bounds = bounds;
        
        self.baseSize = CGSizeMake(expectedSize.height*LIODraggableButtonTextHeightRatio, expectedSize.width + 20.0);
        
        self.statusImageView.hidden = YES;
        self.messageLabel.hidden = YES;
        self.buttonTitleLabel.hidden = NO;
    }
    
    if (self.isAttachedToRight)
        self.badgeView.frame = CGRectMake(-10, -10, 20, 20);
    else
        self.badgeView.frame = CGRectMake(self.baseSize.width - 10.0, -10.0, 20, 20);
    
    self.isAttachedToRight = [[LIOBrandingManager brandingManager] attachedToRightForElement:LIOBrandingElementControlButton];

    [self resetFrame];
    [self resetTitleLabelRotationForAttachedToRight:self.isAttachedToRight];
}

- (void)updateButtonBranding
{
    self.alpha = [[LIOBrandingManager brandingManager] alphaForElement:LIOBrandingElementControlButton];
    self.backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementControlButton];
    self.borderView.layer.borderColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementControlButton].CGColor;
    UIColor *contentColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorContent forElement:LIOBrandingElementControlButton];

    self.messageLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorContent forElement:LIOBrandingElementControlButton];

    self.externalMessageLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementControlButtonMessageLabel];
    self.externalMessageLabel.font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementControlButtonMessageLabel];
    self.externalMessageLabel.backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementControlButtonMessageLabel];
    self.externalMessageLabel.arrowLayer.fillColor = [[[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementControlButtonMessageLabel] CGColor];
    self.externalMessageLabel.layer.borderColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementControlButtonMessageLabel].CGColor;
    self.externalMessageLabel.borderLayer.strokeColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementControlButtonMessageLabel].CGColor;
    self.buttonTitleLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementControlButton];

    if (LIOButtonModeSurvey == self.buttonMode)
    {
        [self.activityIndicatorView stopAnimating];
        if (LIOButtonKindIcon == self.buttonKind)
        {
            self.statusImageView.hidden = NO;
            
            if (self.lastUsedImageIcon != LIOBrandingElementControlButtonSurveyIcon)
            {
                self.lastUsedImageIcon = LIOBrandingElementControlButtonSurveyIcon;
                [[LIOBundleManager sharedBundleManager] cachedImageForBrandingElement:LIOBrandingElementControlButtonSurveyIcon withBlock:^(BOOL success, UIImage *image) {
                    if (success)
                        self.statusImageView.image = image;
                    else
                        [self.statusImageView setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOSurveyIcon" withTint:contentColor]];
                }];
            }
        }
    }
    
    if (LIOButtonModeChat == self.buttonMode)
    {
        [self.activityIndicatorView stopAnimating];
        if (LIOButtonKindIcon == self.buttonKind)
        {
            self.statusImageView.hidden = NO;
            
            if (self.lastUsedImageIcon != LIOBrandingElementControlButtonChatIcon)
            {
                self.lastUsedImageIcon = LIOBrandingElementControlButtonChatIcon;
                [[LIOBundleManager sharedBundleManager] cachedImageForBrandingElement:LIOBrandingElementControlButtonChatIcon withBlock:^(BOOL success, UIImage *image) {
                if (success)
                    self.statusImageView.image = image;
                else
                    [self.statusImageView setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOSpeechBubble" withTint:contentColor]];
                }];
            }
        }
    }
    
    if (LIOButtonModeLoading == self.buttonMode)
    {
        [self.activityIndicatorView startAnimating];
        if (LIOButtonKindIcon == self.buttonKind)
        {
            self.activityIndicatorView.frame = self.bounds;
            self.statusImageView.hidden = YES;
        }
    }
    
    if (LIOButtonKindText == self.buttonKind && self.isVisible)
    {
        self.hidden = NO;
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self setVisibleFrame];
        } completion:nil];
    }

}

- (void)setTransformForInterfaceOrienation:(UIInterfaceOrientation)orientation
{
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            self.transform = CGAffineTransformIdentity;
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            self.transform = CGAffineTransformMakeRotation(-90.0 * (M_PI / 180.0));
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            self.transform = CGAffineTransformMakeRotation(-180.0 * (M_PI / 180.0));
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            self.transform = CGAffineTransformMakeRotation(-270.0 * (M_PI / 180.0));
            break;
            
        default:
            break;
    }
}

- (void)setVisibleFrame
{
    [self setVisibleFrameWithMessageWidth:0.0];
}

- (void)setVisibleFrameWithMessageWidth:(CGFloat)messageWidth
{
    UIInterfaceOrientation actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (self.ignoreActualInterfaceOrientation)
        actualInterfaceOrientation = UIInterfaceOrientationPortrait;

    UIWindow *buttonWindow = (UIWindow *)self.superview;
    CGSize screenSize = [buttonWindow bounds].size;

    CGRect frame = self.frame;
    
    CGFloat messageWidthWithMargin = (messageWidth > 0.0 ? messageWidth + 10.0 : 0.0);
    CGFloat messageHeightMargin = ((LIOButtonModeLoading == self.buttonMode && LIOButtonKindText == self.buttonKind) ? self.baseSize.width*0.7 : 0.0);
    
    if (UIInterfaceOrientationPortrait == actualInterfaceOrientation)
    {
        if (self.isAttachedToRight)
        {
            frame.size.width = self.baseSize.width + messageWidthWithMargin;
            frame.size.height = self.baseSize.height + messageHeightMargin;
            frame.origin.x = screenSize.width - frame.size.width + 3.0;

        }
        else
        {
            frame.origin.x = -3.0;
            frame.size.width = self.baseSize.width + messageWidthWithMargin;
            frame.size.height = self.baseSize.height + messageHeightMargin;
        }
    }
    if (UIInterfaceOrientationLandscapeLeft == actualInterfaceOrientation) // Home button left
    {
        if (self.isAttachedToRight)
        {
            frame.origin.y = -3.0;
            frame.size.height = self.baseSize.width + messageWidthWithMargin;
            frame.size.width = self.baseSize.height + messageHeightMargin;
        }
        else
        {
            frame.size.height = self.baseSize.width + messageWidthWithMargin;
            frame.size.width = self.baseSize.height + messageHeightMargin;
            frame.origin.y = screenSize.height - frame.size.height + 3.0;
        }
    }
    if (UIInterfaceOrientationPortraitUpsideDown == actualInterfaceOrientation)
    {
        if (self.isAttachedToRight)
        {
            frame.origin.x = -3.0;
            frame.size.width = self.baseSize.width + messageWidthWithMargin;
            frame.size.height = self.baseSize.height + messageHeightMargin;
        }
        else
        {
            frame.size.width = self.baseSize.width + messageWidthWithMargin;
            frame.size.height = self.baseSize.height + messageHeightMargin;
            frame.origin.x = screenSize.width - frame.size.width + 3.0;
        }
    }
    if (UIInterfaceOrientationLandscapeRight == actualInterfaceOrientation)
    {
        if (self.isAttachedToRight)
        {
            frame.size.height = self.baseSize.width + messageWidthWithMargin;
            frame.size.width = self.baseSize.height + messageHeightMargin;
            frame.origin.y = screenSize.height - frame.size.height + 3.0;
        }
        else
        {
            frame.origin.y = -3.0;
            frame.size.height = self.baseSize.width + messageWidthWithMargin;
            frame.size.width = self.baseSize.height + messageHeightMargin;
        }
    }

    self.frame = frame;
    [self resetTitleLabelRotationForAttachedToRight:self.isAttachedToRight];
}

- (void)setHiddenFrame
{
    if (self.isShowingMessage)
    {
        [self messageTimerDidFire];
    }
    
    UIInterfaceOrientation actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (self.ignoreActualInterfaceOrientation)
        actualInterfaceOrientation = UIInterfaceOrientationPortrait;

    UIWindow *buttonWindow = (UIWindow *)self.superview;
    CGSize screenSize = [buttonWindow bounds].size;
    
    CGRect frame = self.frame;
    if (UIInterfaceOrientationPortrait == actualInterfaceOrientation)
    {
        if (self.isAttachedToRight)
            frame.origin.x = screenSize.width;
        else
            frame.origin.x = -frame.size.width;
    }
    if (UIInterfaceOrientationLandscapeLeft == actualInterfaceOrientation) // Home button left
    {
        if (self.isAttachedToRight)
            frame.origin.y = -frame.size.height;
        else
            frame.origin.y = screenSize.height;
    }
    if (UIInterfaceOrientationPortraitUpsideDown == actualInterfaceOrientation)
    {
        if (self.isAttachedToRight)
            frame.origin.x = -frame.size.width;
        else
            frame.origin.x = screenSize.width;
    }
    if (UIInterfaceOrientationLandscapeRight == actualInterfaceOrientation)
    {
        if (self.isAttachedToRight)
            frame.origin.y = screenSize.height;
        else
            frame.origin.y = -frame.size.height;
    }
    
    self.frame = frame;
}

- (void)resetFrame {
    CGRect frame = self.frame;
    
    UIView *buttonWindow = (UIView  *)self.superview;
    CGSize screenSize = [buttonWindow bounds].size;
    
    UIInterfaceOrientation actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (self.ignoreActualInterfaceOrientation)
        actualInterfaceOrientation = UIInterfaceOrientationPortrait;
    [self setTransformForInterfaceOrienation:actualInterfaceOrientation];
    
    CGFloat verticalPosition = [[LIOBrandingManager brandingManager] verticalPositionForElement:LIOBrandingElementControlButton];
    
    CGPoint position = frame.origin;
    if (UIInterfaceOrientationPortrait == actualInterfaceOrientation)
    {
        frame.size = self.baseSize;
        position.y = (screenSize.height * verticalPosition) - (frame.size.height / 2.0);
    }
    if (UIInterfaceOrientationLandscapeLeft == actualInterfaceOrientation) // Home button left
    {
        frame.size = CGSizeMake(self.baseSize.height, self.baseSize.width);
        position.x = (screenSize.width * verticalPosition) - (frame.size.width / 2.0);
    }
    if (UIInterfaceOrientationPortraitUpsideDown == actualInterfaceOrientation)
    {
        frame.size = self.baseSize;
        position.y = (screenSize.height * verticalPosition) - (frame.size.height / 2.0);
    }
    if (UIInterfaceOrientationLandscapeRight == actualInterfaceOrientation)
    {
        frame.size = CGSizeMake(self.baseSize.height, self.baseSize.width);
        position.x = (screenSize.width * (1 - verticalPosition)) - (frame.size.width / 2.0);
    }
    frame.origin = position;
    
    self.frame = frame;

    if (self.isVisible)
    {
        self.hidden = NO;
        [self setVisibleFrame];
    }
    else
    {
        [self setHiddenFrame];
        self.hidden = YES;
    }
}

- (void)resetTitleLabelRotationForAttachedToRight:(BOOL)attachedToRight
{
    UIInterfaceOrientation actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (self.ignoreActualInterfaceOrientation)
        actualInterfaceOrientation = UIInterfaceOrientationPortrait;

    UIFont *font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementControlButton];
    CGSize expectedSize = [self.buttonTitle sizeWithFont:font constrainedToSize:CGSizeMake(200, LIODraggableButtonSize)];
    CGFloat loadingExtra = LIOButtonModeLoading == self.buttonMode ? self.baseSize.width*0.7 : 0.0;
    
    if (attachedToRight)
    {
        self.buttonTitleLabel.center = CGPointMake(expectedSize.height*0.7, expectedSize.width/2 + 10.0);
        self.buttonTitleLabel.transform = CGAffineTransformMakeRotation(-M_PI/2);
        
        self.badgeView.frame = CGRectMake(-10, -10, 20, 20);

        if (LIOButtonKindText == self.buttonKind)
            self.activityIndicatorView.frame = CGRectMake(0, (UIInterfaceOrientationIsPortrait(actualInterfaceOrientation) ? self.frame.size.height : self.frame.size.width) - self.baseSize.width, self.baseSize.width, self.baseSize.width);
    }
    else
    {
        self.buttonTitleLabel.center = CGPointMake(expectedSize.height*0.8, expectedSize.width/2 + 10.0 + loadingExtra);
        self.buttonTitleLabel.transform = CGAffineTransformMakeRotation(M_PI/2);
        
        self.badgeView.frame = CGRectMake(self.baseSize.width - 10.0, -10.0, 20, 20);
        
        if (LIOButtonKindText == self.buttonKind)
            self.activityIndicatorView.frame = CGRectMake(0, 0, self.baseSize.width, self.baseSize.width);

    }
}

#pragma mark -
#pragma mark Visibility Methods

- (void)show:(BOOL)animated
{
    self.isVisible = YES;
 
    if (animated)
    {
        self.hidden = NO;
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self setVisibleFrame];
        } completion:nil];
    }
    else
    {
        self.hidden = NO;
        [self setVisibleFrame];
    }
}

- (void)hide:(BOOL)animated
{
    self.isVisible = NO;
 
    if (animated)
    {
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self setHiddenFrame];
        } completion:^(BOOL finished) {
            self.hidden = YES;
        }];
    }
    else
    {
        [self setHiddenFrame];
        self.hidden = YES;
    }
}

- (void)resetUnreadMessages
{
    self.numberOfUnreadMessages = 0;
    self.badgeView.hidden = YES;
}

- (void)reportUnreadMessage
{
    self.numberOfUnreadMessages += 1;

    [self.badgeView setBadgeNumber:self.numberOfUnreadMessages];
    self.badgeView.hidden = NO;
}

- (void)hideCurrentMessage
{
    if (self.messageTimer)
    {
        [self.messageTimer stopTimer];
        self.messageTimer = nil;

        [self messageTimerDidFire];
    }
}


- (void)presentMessage:(NSString *)message
{
    if (!self.isVisible)
        return;
    
    if (LIOButtonModeLoading == self.buttonMode)
        return;
    
    // Just to make sure, don't display a message from a hidden button
    if (self.hidden)
        return;
    
    // Also don't show messages on a dragged button
    if (self.isDragging)
        return;
    
    // Cancel any existing timers, in case a message is already being shown
    if (self.messageTimer)
    {
        [self.messageTimer stopTimer];
        self.messageTimer = nil;
    }
    
    BOOL wasPreviouslyShowingMessage = self.isShowingMessage;
    
    self.isShowingMessage = YES;
    
    self.messageLabel.text = message;
    self.externalMessageLabel.text = message;
    self.externalMessageLabel.isPointingRight = self.isAttachedToRight;
    
    CGFloat maxWidth = 220.0;

    CGSize expectedSize = [message sizeWithFont:self.externalMessageLabel.font constrainedToSize:CGSizeMake(maxWidth, self.bounds.size.height) lineBreakMode:(UILineBreakModeWordWrap | UILineBreakModeTailTruncation)];
    
    CGRect frame = self.messageLabel.frame;
    frame.origin.x = LIODraggableButtonSize;
    frame.origin.y = 0;
    frame.size.width = expectedSize.width;
    frame.size.height = LIODraggableButtonSize;
    self.messageLabel.frame = frame;
    
    frame = self.externalMessageLabel.frame;
    if (self.isAttachedToRight)
        frame.origin.x = -expectedSize.width - 35.0;
    else
        frame.origin.x = self.baseSize.width + 15.0;
    frame.origin.y = (self.baseSize.height - expectedSize.height - 20.0)/2;
    frame.size.width = expectedSize.width + 20.0;
    frame.size.height = expectedSize.height + 20.0;
    self.externalMessageLabel.numberOfLines = 0;
    self.externalMessageLabel.frame = frame;

    if (!wasPreviouslyShowingMessage)
    {
        if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
        {
            CGFloat translationFactor = self.isAttachedToRight ? self.externalMessageLabel.frame.size.width*0.6 : -self.externalMessageLabel.frame.size.width*0.6;
            self.externalMessageLabel.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(0.0, 0.0), CGAffineTransformMakeTranslation(translationFactor, 0));
            self.externalMessageLabel.hidden = NO;
        }
        else
        {
            self.externalMessageLabel.alpha = 0.0;
            self.externalMessageLabel.hidden = NO;
        }
    }
    
    [self.externalMessageLabel setNeedsLayout];
    
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
        {
            self.externalMessageLabel.transform = CGAffineTransformIdentity;
        }
        else
        {
            self.externalMessageLabel.alpha = 1.0;
        }
    } completion:^(BOOL finished) {
        if (self.messageTimer)
        {
            [self.messageTimer stopTimer];
            self.messageTimer = nil;
        }
        self.messageTimer = [[LIOTimerProxy alloc] initWithTimeInterval:LIODraggableButtonMessageTime target:self selector:@selector(messageTimerDidFire)];
    }];
    
    if (UIAccessibilityIsVoiceOverRunning())
    {
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, message);
    }
}

- (void)removeTimers
{
    if (self.messageTimer)
    {
        [self.messageTimer stopTimer];
        self.messageTimer = nil;
    }
}


- (void)messageTimerDidFire
{
    if (self.messageTimer)
    {
        [self.messageTimer stopTimer];
        self.messageTimer = nil;
    }

    CGFloat translationFactor = self.isAttachedToRight ? self.externalMessageLabel.frame.size.width*0.6 : -self.externalMessageLabel.frame.size.width*0.6;
    
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
        {
            self.externalMessageLabel.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(0.0, 0.0), CGAffineTransformMakeTranslation(translationFactor, 0));
        }
        else
        {
            self.externalMessageLabel.alpha = 0.0;
        }
    } completion:^(BOOL finished) {
        self.isShowingMessage = NO;
        self.externalMessageLabel.hidden = YES;
        self.externalMessageLabel.alpha = 1.0;
        self.externalMessageLabel.transform = CGAffineTransformIdentity;
    }];
}

#pragma mark -
#pragma mark Button Mode Methods

- (void)setLoadingMode
{
    if (self.isShowingMessage)
        [self messageTimerDidFire];
    
    self.buttonMode = LIOButtonModeLoading;
    [self updateButtonBranding];
}

- (void)setChatMode
{
    self.buttonMode = LIOButtonModeChat;
    [self updateButtonBranding];
}

- (void)setSurveyMode
{
    self.buttonMode = LIOButtonModeSurvey;
    [self updateButtonBranding];
}

#pragma mark -
#pragma mark UIControl Methods

- (void)draggableButtonWasTapped:(id)sender
{
    [self.delegate draggableButtonWasTapped:self];
}

- (void)messageLabelButtonWasTapped:(id)sender
{
    [self sendActionsForControlEvents: UIControlEventTouchUpInside];
}

#pragma mark -
#pragma mark Gesture Recognizer Methods

- (void)setAlphaForDraggedElements:(CGFloat)alpha
{
    self.buttonTitleLabel.alpha = alpha;
    self.badgeView.alpha = alpha;
    if (LIOButtonKindText == self.buttonKind)
        self.activityIndicatorView.alpha = alpha;
}

- (void)buttonDidPan:(id)sender {
    UIView *superview = [self superview];
    UIPanGestureRecognizer *panGestureRecognizer = (UIPanGestureRecognizer*)sender;
    CGPoint translatedPoint = [panGestureRecognizer translationInView:superview];
    
    if ([panGestureRecognizer state] == UIGestureRecognizerStateBegan) {
        self.isDragging = YES;
        self.preDragPosition = self.frame.origin;
        self.panPoint = CGPointMake([[sender view] center].x, [[sender view] center].y);
        
        if (self.isShowingMessage)
        {
            [self messageTimerDidFire];
        }
        
    }
    
    translatedPoint = CGPointMake(self.panPoint.x + translatedPoint.x, self.panPoint.y + translatedPoint.y);
    [[sender view] setCenter:translatedPoint];
    
    // Toggle text button alpha when dragging
    BOOL goingToAttachToRight = self.isAttachedToRight;
    UIInterfaceOrientation actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (self.ignoreActualInterfaceOrientation)
        actualInterfaceOrientation = UIInterfaceOrientationPortrait;

    if (actualInterfaceOrientation == UIInterfaceOrientationPortrait) {
        CGFloat verticalPercent = self.center.x/superview.bounds.size.width;
        if (verticalPercent < 0.5)
        {
            [self setAlphaForDraggedElements:1 - (verticalPercent*2)];
            goingToAttachToRight = NO;
        }
        else
        {
            [self setAlphaForDraggedElements:(verticalPercent*2) - 1];
            goingToAttachToRight = YES;
        }
    }
    if (actualInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown ) {
        CGFloat verticalPercent = self.center.x/superview.bounds.size.width;
        if (verticalPercent < 0.5)
        {
            [self setAlphaForDraggedElements:1 - (verticalPercent*2)];
            goingToAttachToRight = YES;
        }
        else
        {
            [self setAlphaForDraggedElements:(verticalPercent*2) - 1];
            goingToAttachToRight = NO;
        }
    }
    if (actualInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        CGFloat verticalPercent = self.center.y/superview.bounds.size.height;
        if (verticalPercent < 0.5)
        {
            [self setAlphaForDraggedElements:1 - (verticalPercent*2)];
            goingToAttachToRight = YES;
        }
        else
        {
            [self setAlphaForDraggedElements:(verticalPercent*2) - 1];
            goingToAttachToRight = NO;
        }
    }
    if (actualInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        CGFloat verticalPercent = self.center.y/superview.bounds.size.height;
        if (verticalPercent < 0.5)
        {
            [self setAlphaForDraggedElements:1 - (verticalPercent*2)];
            goingToAttachToRight = NO;
        }
        else
        {
            [self setAlphaForDraggedElements:(verticalPercent*2) - 1];
            goingToAttachToRight = YES;
        }
    }
    
    [self resetTitleLabelRotationForAttachedToRight:goingToAttachToRight];
    
    
    if ([panGestureRecognizer state] == UIGestureRecognizerStateEnded) {
        self.isDragging = NO;
        
        UIInterfaceOrientation actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (self.ignoreActualInterfaceOrientation)
            actualInterfaceOrientation = UIInterfaceOrientationPortrait;

        if (actualInterfaceOrientation == UIInterfaceOrientationPortrait) {
            if (self.center.x > superview.bounds.size.width/2)
            {
                self.preDragPosition = CGPointMake(self.superview.bounds.size.width - self.bounds.size.width + 3, self.frame.origin.y);
                self.isAttachedToRight = YES;
            }
            if (self.center.x < superview.bounds.size.width/2)
            {
                self.preDragPosition = CGPointMake(-3, self.frame.origin.y);
                self.isAttachedToRight = NO;
            }
            if (self.frame.origin.y < LIODraggableButtonPopbackHeight)
            {
                self.preDragPosition = CGPointMake(self.preDragPosition.x, LIODraggableButtonPopbackHeight);
            }
            if (self.frame.origin.y > self.superview.bounds.size.height - self.frame.size.height - LIODraggableButtonPopbackHeight)
            {
                self.preDragPosition = CGPointMake(self.preDragPosition.x, self.superview.bounds.size.height - self.frame.size.height - LIODraggableButtonPopbackHeight);
            }
        }
        if (actualInterfaceOrientation == UIInterfaceOrientationLandscapeLeft)
        {
            if (self.center.y > self.superview.bounds.size.height/2)
            {
                self.preDragPosition = CGPointMake(self.frame.origin.x, self.superview.bounds.size.height - self.bounds.size.width + 3);
                self.isAttachedToRight = NO;
            }
            if (self.center.y < superview.bounds.size.height/2)
            {
                self.preDragPosition = CGPointMake(self.frame.origin.x, -3);
                self.isAttachedToRight = YES;
            }
            if (self.frame.origin.x < self.frame.size.height)
            {
                self.preDragPosition = CGPointMake(LIODraggableButtonPopbackHeight, self.preDragPosition.y);
            }
            if (self.frame.origin.x > self.superview.bounds.size.width - self.frame.size.width - LIODraggableButtonPopbackHeight)
            {
                self.preDragPosition = CGPointMake(self.superview.bounds.size.width - self.frame.size.width - LIODraggableButtonPopbackHeight, self.preDragPosition.y);
            }
        }
        if (actualInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        {
            if (self.center.x > superview.bounds.size.width/2)
            {
                self.preDragPosition = CGPointMake(self.superview.bounds.size.width - self.bounds.size.width + 3, self.frame.origin.y);
                self.isAttachedToRight = NO;
            }
            if (self.center.x < superview.bounds.size.width/2)
            {
                self	.preDragPosition = CGPointMake(-3, self.frame.origin.y);
                self.isAttachedToRight = YES;
            }
            if (self.frame.origin.y < LIODraggableButtonPopbackHeight)
            {
                self.preDragPosition = CGPointMake(self.preDragPosition.x, LIODraggableButtonPopbackHeight);
            }
            if (self.frame.origin.y > self.superview.bounds.size.height - self.frame.size.height - LIODraggableButtonPopbackHeight)
            {
                self.preDragPosition = CGPointMake(self.preDragPosition.x, self.superview.bounds.size.height - self.frame.size.height - LIODraggableButtonPopbackHeight);
            }
        }
        if (actualInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
        {
            if (self.center.y > superview.frame.size.height/2)
            {
                self.preDragPosition = CGPointMake(self.frame.origin.x, self.superview.bounds.size.height - self.bounds.size.width + 3);
                self.isAttachedToRight = YES;
            }
            if (self.center.y < superview.frame.size.height/2)
            {
                self.preDragPosition = CGPointMake(self.frame.origin.x, -3);
                self.isAttachedToRight = NO;
            }
            if (self.frame.origin.x < self.frame.size.height)
            {
                self.preDragPosition = CGPointMake(LIODraggableButtonPopbackHeight, self.preDragPosition.y);
            }
            if (self.frame.origin.x > self.superview.bounds.size.width - self.frame.size.width - LIODraggableButtonPopbackHeight)
            {
                self.preDragPosition = CGPointMake(self.superview.bounds.size.width - self.frame.size.width - LIODraggableButtonPopbackHeight, self.preDragPosition.y);
            }
        }
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            CGRect frame = self.frame;
            frame.origin = self.preDragPosition;
            [self resetTitleLabelRotationForAttachedToRight:self.isAttachedToRight];
            self.frame = frame;
            
            [self setAlphaForDraggedElements:1.0];
        } completion:nil];
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (!self.clipsToBounds && !self.hidden && self.alpha > 0) {
        for (UIView *subview in self.subviews.reverseObjectEnumerator) {
            CGPoint subPoint = [subview convertPoint:point fromView:self];
            UIView *result = [subview hitTest:subPoint withEvent:event];
            if (result != nil) {
                return result;
                break;
            }
        }
    }
    
    // use this to pass the 'touch' onward in case no subviews trigger the touch
    return [super hitTest:point withEvent:event];
}

@end
