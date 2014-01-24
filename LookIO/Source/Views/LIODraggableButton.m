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

#define LIODraggableButtonSize 50.0
#define LIODraggableButtonMessageTime 5.0

#define HEXCOLOR(c) [UIColor colorWithRed:((c>>16)&0xFF)/255.0 \
                     green:((c>>8)&0xFF)/255.0 \
                     blue:((c)&0xFF)/255.0 \
                     alpha:1.0]

@interface LIODraggableButton ()

@property (nonatomic, assign) BOOL isDragging;
@property (nonatomic, assign) BOOL isVisible;
@property (nonatomic, assign) BOOL isAttachedToRight;
@property (nonatomic, assign) BOOL isShowingMessage;

@property (nonatomic, assign) CGPoint panPoint;
@property (nonatomic, assign) CGPoint preDragPosition;

@property (nonatomic, strong) UIImageView *statusImageView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic, strong) UILabel *messageLabel;
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
        self.buttonMode = LIOButtonModeChat;
        [self updateButtonBranding];
        
        self.layer.cornerRadius = 5.0;
        self.layer.borderWidth = 1.0;
        
        [self addTarget:self action:@selector(draggableButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *surveyTabPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(buttonDidPan:)];
        [self addGestureRecognizer:surveyTabPanGestureRecognizer];
        
        self.isVisible = NO;
        self.isAttachedToRight = YES;
        
        self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:self.bounds];
        self.activityIndicatorView.userInteractionEnabled = NO;
        [self addSubview:self.activityIndicatorView];
        
        self.statusImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, LIODraggableButtonSize - 20.0, LIODraggableButtonSize - 20.0)];
        self.statusImageView.userInteractionEnabled = NO;
        [self addSubview:self.statusImageView];
        
        self.numberOfUnreadMessages = 0;
        
        self.badgeView = [[LIOBadgeView alloc] initWithFrame:CGRectMake(30, 5, 20, 20)];
        [self.badgeView setBadgeNumber:1];
        self.badgeView.hidden = YES;
        [self addSubview:self.badgeView];
        
        self.messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.messageLabel.backgroundColor = [UIColor clearColor];
        self.messageLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorContent forElement:LIOBrandingElementControlButton];
        self.messageLabel.hidden = YES;
        self.messageLabel.userInteractionEnabled = NO;
        [self addSubview:self.messageLabel];

        self.clipsToBounds = YES;
        
        [self resetFrame];
    }
    return self;
}

#pragma mark -
#pragma mark Setup Methods

- (void)updateButtonBranding
{
    self.alpha = [[LIOBrandingManager brandingManager] alphaForElement:LIOBrandingElementControlButton];
    self.backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementControlButton];
    self.layer.borderColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementControlButton].CGColor;
    UIColor *contentColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorContent forElement:LIOBrandingElementControlButton];
    
    
    switch (self.buttonMode) {
        case LIOButtonModeSurvey:
            self.statusImageView.hidden = NO;
            [self.activityIndicatorView stopAnimating];
            [self.statusImageView setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOSurveyIcon" withTint:contentColor]];
            break;
            
        case LIOButtonModeChat:
            self.statusImageView.hidden = NO;
            [self.activityIndicatorView stopAnimating];
            [self.statusImageView setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOSpeechBubble" withTint:contentColor]];
            break;
            
        case LIOButtonModeLoading:
            self.statusImageView.hidden = YES;
            self.activityIndicatorView.frame = self.bounds;
            [self.activityIndicatorView startAnimating];
            break;
            
        default:
            break;
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
    UIInterfaceOrientation actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    UIWindow *buttonWindow = (UIWindow *)self.superview;
    CGSize screenSize = [buttonWindow bounds].size;

    CGRect frame = self.frame;
    frame.size.width = LIODraggableButtonSize;
    frame.size.height = LIODraggableButtonSize;
    if (UIInterfaceOrientationPortrait == actualInterfaceOrientation)
    {
        if (self.isAttachedToRight)
            frame.origin.x = screenSize.width - frame.size.width + 3.0;
        else
            frame.origin.x = -3;
    }
    if (UIInterfaceOrientationLandscapeLeft == actualInterfaceOrientation) // Home button left
    {
        if (self.isAttachedToRight)
            frame.origin.y = -3.0;
        else
            frame.origin.y = screenSize.height - frame.size.height + 3.0;
    }
    if (UIInterfaceOrientationPortraitUpsideDown == actualInterfaceOrientation)
    {
        if (self.isAttachedToRight)
            frame.origin.x = -3.0;
        else
            frame.origin.x = screenSize.width - frame.size.width + 3.0;
    }
    if (UIInterfaceOrientationLandscapeRight == actualInterfaceOrientation)
    {
        if (self.isAttachedToRight)
            frame.origin.y = screenSize.height - frame.size.height + 3.0;
        else
            frame.origin.y = -3.0;
    }

    self.frame = frame;
}

- (void)setHiddenFrame
{
    UIInterfaceOrientation actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
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
    if (NO == [self.superview isKindOfClass:[UIWindow class]])
        return;
    
    CGRect frame = self.frame;
    frame.size = CGSizeMake(LIODraggableButtonSize, LIODraggableButtonSize);
    
    UIWindow *buttonWindow = (UIWindow *)self.superview;
    CGSize screenSize = [buttonWindow bounds].size;
    
    UIInterfaceOrientation actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    [self setTransformForInterfaceOrienation:actualInterfaceOrientation];

    CGPoint position = frame.origin;
    if (UIInterfaceOrientationPortrait == actualInterfaceOrientation)
    {
        position.y = (screenSize.height / 2.0) - (frame.size.height / 2.0);
    }
    if (UIInterfaceOrientationLandscapeLeft == actualInterfaceOrientation) // Home button left
    {
        position.x = (screenSize.width / 2.0) - (frame.size.width / 2.0);
    }
    if (UIInterfaceOrientationPortraitUpsideDown == actualInterfaceOrientation)
    {
        position.y = (screenSize.height / 2.0) - (frame.size.height / 2.0);
    }
    if (UIInterfaceOrientationLandscapeRight == actualInterfaceOrientation)
    {
        position.x = (screenSize.width / 2.0) - (frame.size.width / 2.0);
    }
    frame.origin = position;
    
    self.frame = frame;

    if (self.isVisible)
        [self setVisibleFrame];
    else
        [self setHiddenFrame];
}

- (void)setFrameForMessagedWithWidth:(CGFloat)width
{
    CGRect frame = self.frame;
    UIInterfaceOrientation actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];

    if (UIInterfaceOrientationPortrait == actualInterfaceOrientation)
    {
        if (self.isAttachedToRight)
        {
            frame.origin.x = self.frame.origin.x - width - 10.0;
            frame.size.width = LIODraggableButtonSize + width + 10.0;
        }
        else
        {
            frame.size.width = LIODraggableButtonSize + width + 10.0;
        }
    }
    
    self.frame = frame;
}

#pragma mark -
#pragma mark Visibility Methods

- (void)show:(BOOL)animated
{
    self.isVisible = YES;
 
    if (animated)
    {
        [UIView animateWithDuration:0.3 animations:^{
            [self setVisibleFrame];
        }];
    }
    else
    {
        [self setVisibleFrame];
    }
}

- (void)hide:(BOOL)animated
{
    self.isVisible = NO;
 
    if (animated)
    {
        [UIView animateWithDuration:0.5 animations:^{
            [self setHiddenFrame];
        }];
    }
    else
    {
        [self setHiddenFrame];
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


- (void)presentMessage:(NSString *)message
{
    self.isShowingMessage = YES;
    
    self.messageLabel.text = message;
    
    CGSize expectedSize;
    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        CGRect expectedTextRect = [message boundingRectWithSize:CGSizeMake(self.superview.bounds.size.width, self.bounds.size.height)
                                                     options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                  attributes:@{NSFontAttributeName:self.messageLabel.font}
                                                     context:nil];
        expectedSize = expectedTextRect.size;
    }
    else
    {
        expectedSize = [message sizeWithFont:self.messageLabel.font constrainedToSize:CGSizeMake(self.superview.bounds.size.width, self.bounds.size.height) lineBreakMode:UILineBreakModeTailTruncation];
    }
    
    CGRect frame = self.messageLabel.frame;
    frame.origin.x = self.bounds.size.width;
    frame.origin.y = 0;
    frame.size.width = expectedSize.width;
    frame.size.height = self.bounds.size.height;
    self.messageLabel.frame = frame;
    self.messageLabel.hidden = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        [self setFrameForMessagedWithWidth:expectedSize.width];
    } completion:^(BOOL finished) {
        self.messageTimer = [[LIOTimerProxy alloc] initWithTimeInterval:LIODraggableButtonMessageTime target:self selector:@selector(messageTimerDidFire)];
    }];
}

- (void)messageTimerDidFire
{
    if (self.messageTimer)
    {
        [self.messageTimer stopTimer];
        self.messageTimer = nil;
    }

    [UIView animateWithDuration:0.3 animations:^{
        [self setVisibleFrame];
    } completion:^(BOOL finished) {
        self.isShowingMessage = NO;
    }];
}

#pragma mark -
#pragma mark Button Mode Methods

- (void)setLoadingMode
{
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

#pragma mark -
#pragma mark Gesture Recognizer Methods

- (void)buttonDidPan:(id)sender {
    UIView *superview = [self superview];
    UIPanGestureRecognizer *panGestureRecognizer = (UIPanGestureRecognizer*)sender;
    CGPoint translatedPoint = [panGestureRecognizer translationInView:superview];
    
    if ([panGestureRecognizer state] == UIGestureRecognizerStateBegan) {
        self.isDragging = YES;
        self.preDragPosition = self.frame.origin;
        self.panPoint = CGPointMake([[sender view] center].x, [[sender view] center].y);
        
        [self.delegate draggableButtonDidBeginDragging:self];
    }
    
    translatedPoint = CGPointMake(self.panPoint.x + translatedPoint.x, self.panPoint.y + translatedPoint.y);
    [[sender view] setCenter:translatedPoint];
    
    if ([panGestureRecognizer state] == UIGestureRecognizerStateEnded) {
        self.isDragging = NO;
        
        UIInterfaceOrientation actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (actualInterfaceOrientation == UIInterfaceOrientationPortrait) {
            if (self.frame.origin.x + self.frame.size.width > self.superview.bounds.size.width - 10)
            {
                self.preDragPosition = CGPointMake(self.superview.bounds.size.width - self.bounds.size.width + 3, self.frame.origin.y);
                self.isAttachedToRight = YES;
            }
            if (self.frame.origin.x < 10)
            {
                self.preDragPosition = CGPointMake(-3, self.frame.origin.y);
                self.isAttachedToRight = NO;
            }
            if (self.frame.origin.y < self.frame.size.height)
            {
                self.preDragPosition = CGPointMake(self.preDragPosition.x, self.frame.size.height);
            }
            if (self.frame.origin.y > self.superview.bounds.size.height - self.frame.size.height)
            {
                self.preDragPosition = CGPointMake(self.preDragPosition.x, self.superview.bounds.size.height - self.frame.size.height*2);
            }
        }
        if (actualInterfaceOrientation == UIInterfaceOrientationLandscapeLeft)
        {
            if (self.frame.origin.y + self.frame.size.height > self.superview.bounds.size.height - 10)
            {
                self.preDragPosition = CGPointMake(self.frame.origin.x, self.superview.bounds.size.height - self.bounds.size.height + 3);
                self.isAttachedToRight = NO;
            }
            if (self.frame.origin.y < 10)
            {
                self.preDragPosition = CGPointMake(self.frame.origin.x, -3);
                self.isAttachedToRight = YES;
            }
            if (self.frame.origin.x < self.frame.size.width)
            {
                self.preDragPosition = CGPointMake(self.frame.size.width, self.preDragPosition.y);
            }
            if (self.frame.origin.x > self.superview.bounds.size.width - self.frame.size.width)
            {
                self.preDragPosition = CGPointMake(self.superview.bounds.size.width - self.frame.size.width*2, self.preDragPosition.y);
            }
        }
        if (actualInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        {
            if (self.frame.origin.x + self.frame.size.width > self.superview.bounds.size.width - 10)
            {
                self.preDragPosition = CGPointMake(self.superview.bounds.size.width - self.bounds.size.width + 3, self.frame.origin.y);
                self.isAttachedToRight = NO;
            }
            if (self.frame.origin.x < 10)
            {
                self.preDragPosition = CGPointMake(-3, self.frame.origin.y);
                self.isAttachedToRight = YES;
            }
        }
        if (actualInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
        {
            if (self.frame.origin.y + self.frame.size.height > self.superview.bounds.size.height - 10)
            {
                self.preDragPosition = CGPointMake(self.frame.origin.x, self.superview.bounds.size.height - self.bounds.size.height + 3);
                self.isAttachedToRight = YES;
            }
            if (self.frame.origin.y < 10)
            {
                self.preDragPosition = CGPointMake(self.frame.origin.x, -3);
                self.isAttachedToRight = NO;
            }
            if (self.frame.origin.x < self.frame.size.width)
            {
                self.preDragPosition = CGPointMake(self.frame.size.width, self.preDragPosition.y);
            }
            if (self.frame.origin.x > self.superview.bounds.size.width - self.frame.size.width)
            {
                self.preDragPosition = CGPointMake(self.superview.bounds.size.width - self.frame.size.width*2, self.preDragPosition.y);
            }
        }
        
        [UIView animateWithDuration:0.3 animations:^{
            CGRect frame = self.frame;
            frame.origin = self.preDragPosition;
            self.frame = frame;
        }];
        
        [self.delegate draggableButtonDidEndDragging:self];
    }
}


@end
