//
//  LIODraggableButton.m
//  LookIO
//
//  Created by Yaron Karasik on 12/9/13.
//
//

#import "LIODraggableButton.h"
#import "LIOBundleManager.h"
#import "LIOBrandingManager.h"

#define LIODraggleButtonSize 50.0

#define HEXCOLOR(c) [UIColor colorWithRed:((c>>16)&0xFF)/255.0 \
                     green:((c>>8)&0xFF)/255.0 \
                     blue:((c)&0xFF)/255.0 \
                     alpha:1.0]

@interface LIODraggableButton ()

@property (nonatomic, assign) BOOL isDragging;
@property (nonatomic, assign) BOOL isVisible;
@property (nonatomic, assign) BOOL isAttachedToRight;

@property (nonatomic, assign) CGPoint panPoint;
@property (nonatomic, assign) CGPoint preDragPosition;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

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
            [self.activityIndicatorView stopAnimating];
            [self setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOSurveyIcon" withTint:contentColor] forState:UIControlStateNormal];
            break;
            
        case LIOButtonModeChat:
            [self.activityIndicatorView stopAnimating];
            [self setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOSpeechBubble" withTint:contentColor] forState:UIControlStateNormal];
            break;
            
        case LIOButtonModeLoading:
            [self setImage:nil forState:UIControlStateNormal];
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
    frame.size = CGSizeMake(LIODraggleButtonSize, LIODraggleButtonSize);
    
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
