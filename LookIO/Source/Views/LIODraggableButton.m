//
//  LIODraggableButton.m
//  LookIO
//
//  Created by Yaron Karasik on 12/9/13.
//
//

#import "LIODraggableButton.h"

#import "LIOBundleManager.h"

typedef enum
{
    LIOButtonModeChat = 0,
    LIOButtonModeLoading,
    LIOButtonModeSurvey
} LIOButtonMode;

#define LIODraggleButtonSize 50.0


#define HEXCOLOR(c) [UIColor colorWithRed:((c>>16)&0xFF)/255.0 \
                     green:((c>>8)&0xFF)/255.0 \
                     blue:((c)&0xFF)/255.0 \
                     alpha:1.0]

@interface LIODraggableButton ()

@property (nonatomic, assign) LIOButtonMode buttonMode;
@property (nonatomic, assign) BOOL isDragging;
@property (nonatomic, assign) BOOL isVisible;
@property (nonatomic, assign) BOOL isAttachedToRight;

@property (nonatomic, assign) CGPoint panPoint;
@property (nonatomic, assign) CGPoint preDragPosition;

@end

@implementation LIODraggableButton

#pragma mark Initialization Methods

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.textColor = @"000000";
        self.fillColor = @"ffffff";

        self.buttonMode = LIOButtonModeChat;
        [self updateButtonIcon];
        
        self.layer.cornerRadius = 5.0;
        self.layer.borderWidth = 1.0;
        self.backgroundColor = [UIColor whiteColor];
        self.layer.borderColor = [UIColor colorWithWhite:0.75 alpha:1.0].CGColor;
        
        [self addTarget:self action:@selector(draggableButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *surveyTabPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(buttonDidPan:)];
        [self addGestureRecognizer:surveyTabPanGestureRecognizer];
        
        self.isVisible = NO;
        self.isAttachedToRight = YES;
        
        [self resetFrame];
    }
    return self;
}

#pragma mark Setup Methods

- (void)updateButtonColors
{
    unsigned int fillColorValue;
    [[NSScanner scannerWithString:self.fillColor] scanHexInt:&fillColorValue];
    UIColor *translatedFillColor = HEXCOLOR(fillColorValue);
    
    self.backgroundColor = [translatedFillColor colorWithAlphaComponent:0.7];
    
    const CGFloat *rgba = CGColorGetComponents(translatedFillColor.CGColor);
    CGFloat lightness = (rgba[0] + rgba[1] + rgba[2])/3;
    CGFloat borderRed = lightness < 0.5 ? (1.0 + rgba[0])/2 : (0.0 + rgba[0])/2;
    CGFloat borderGreen = lightness < 0.5 ? (1.0 + rgba[1])/2 : (0.0 + rgba[1])/2;
    CGFloat borderBlue = lightness < 0.5 ? (1.0 + rgba[2])/2 : (0.0 + rgba[2])/2;
    
    self.layer.borderColor = [[UIColor alloc] initWithRed:borderRed green:borderGreen blue:borderBlue alpha:1.0].CGColor;
}

- (void)updateButtonIcon
{
    unsigned int textColorValue;
    [[NSScanner scannerWithString:self.textColor] scanHexInt:&textColorValue];
    UIColor *translatedTextColor = HEXCOLOR(textColorValue);
    translatedTextColor = [translatedTextColor colorWithAlphaComponent:0.9];
    
    switch (self.buttonMode) {
        case LIOButtonModeChat:
            [self setImage:[self imageWithTintedColor:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOSpeechBubble"] withTint:translatedTextColor] forState:UIControlStateNormal];
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

#pragma mark Tint Color Methods

- (UIImage *)imageWithTintedColor:(UIImage *)image withTint:(UIColor *)color {
    UIGraphicsBeginImageContext(image.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [color setFill];
    
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    CGContextDrawImage(context, rect, image.CGImage);
    
    CGContextClipToMask(context, rect, image.CGImage);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context,kCGPathFill);
    
    UIImage *coloredImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return coloredImage;
}



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

#pragma mark UIControl Methods

- (void)draggableButtonWasTapped:(id)sender
{
    [self.delegate draggableButtonWasTapped:self];
}

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
