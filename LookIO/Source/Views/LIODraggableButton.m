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
    
    switch (self.buttonMode) {
        case LIOButtonModeChat:
            [self setImage:[self imageWithTintedColor:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOSpeechBubble"] withTint:translatedTextColor] forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
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

- (void)resetFrame {
    CGRect frame = self.frame;
    
    frame.size = CGSizeMake(50, 50);
    
    frame.origin.y = self.superview.bounds.size.height*0.25;
    
    if (self.isVisible)
    {
        if (self.isAttachedToRight)
            frame.origin.x = self.superview.bounds.size.width - self.frame.size.width + 3;
        else
            frame.origin.x = -3;
    }
    else
    {
        if (self.isAttachedToRight)
            frame.origin.x = self.superview.bounds.size.width;
        else
            frame.origin.x = -self.frame.size.width;
        self.frame = frame;
    }
    
    self.frame = frame;
}

#pragma mark Visibility Methods

- (void)show {
    self.isVisible = YES;
    
    [UIView animateWithDuration:0.3 animations:^{
        CGRect frame = self.frame;
        if (self.isAttachedToRight)
            frame.origin.x = self.superview.bounds.size.width - self.frame.size.width + 3;
        else
            frame.origin.x = -3;
        self.frame = frame;
    }];
}

- (void)hide {
    self.isVisible = NO;
    
    [UIView animateWithDuration:0.5 animations:^{
        CGRect frame = self.frame;
        if (self.isAttachedToRight)
            frame.origin.x = self.superview.bounds.size.width;
        else
            frame.origin.x = -self.frame.size.width;
        self.frame = frame;
    }];
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
        
        if (self.frame.origin.x + self.frame.size.width > self.superview.bounds.size.width - 10) {
            self.preDragPosition = CGPointMake(self.superview.bounds.size.width - self.bounds.size.width + 3, self.frame.origin.y);
            self.isAttachedToRight = YES;
        }
        if (self.frame.origin.x < 10) {
            self.preDragPosition = CGPointMake(-3, self.frame.origin.y);
            self.isAttachedToRight = NO;
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
