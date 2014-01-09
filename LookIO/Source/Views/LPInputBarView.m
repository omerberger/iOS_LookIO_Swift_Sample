//
//  LPInputBarView.m
//  LookIO
//
//  Created by Yaron Karasik on 12/20/13.
//
//

#import "LPInputBarView.h"

#import "LIOBundleManager.h"
#import "LIOBrandingManager.h"

@implementation LIOObservingInputAccessoryView

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (self.superview)
    {
        [self.superview removeObserver:self
                            forKeyPath:@"frame"];
    }
    
    [newSuperview addObserver:self
                   forKeyPath:@"frame"
                      options:0
                      context:NULL];
    
    [super willMoveToSuperview:newSuperview];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == self.superview && [keyPath isEqualToString:@"frame"])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:LIOObservingInputAccessoryViewSuperviewFrameDidChangeNotification
                                                            object:self];
    }
}

@end

@interface LPInputBarView () <UITextViewDelegate>

@property (nonatomic, strong) UIView *textViewBackgroundView;
@property (nonatomic, strong) UIButton *plusButton;
@property (nonatomic, strong) UIButton *sendButton;

@property (nonatomic, assign) NSInteger previousTextLength;

@end

@implementation LPInputBarView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        UIColor *backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementSendBar];
        CGFloat backgroundAlpha = [[LIOBrandingManager brandingManager] backgroundAlphaForElement:LIOBrandingElementSendBar];
        self.backgroundColor = [backgroundColor colorWithAlphaComponent:backgroundAlpha];
        
        self.plusButton = [[UIButton alloc] initWithFrame:CGRectMake(0, (self.frame.size.height - 50)/2, 50, 50)];
        UIColor *buttonTintColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorColor forElement:LIOBrandingElementSendBarPlusButton];
        [self.plusButton setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOPlusIcon" withTint:buttonTintColor] forState:UIControlStateNormal];
        self.plusButton.imageView.clipsToBounds = NO;
        self.plusButton.imageView.contentMode = UIViewContentModeCenter;
        [self.plusButton addTarget:self action:@selector(plusButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        self.plusButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self addSubview:self.plusButton];
        
        self.textViewBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(50, 5, self.bounds.size.width - 115, self.frame.size.height - 10)];
        self.textViewBackgroundView.backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementSendBarTextField];
        self.textViewBackgroundView.layer.borderColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementSendBarTextField].CGColor;
        self.textViewBackgroundView.layer.cornerRadius = 5.0;
        self.textViewBackgroundView.layer.borderWidth = 1.0;
        self.textViewBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self addSubview:self.textViewBackgroundView];
        
        self.textView = [[UITextView alloc] initWithFrame:self.textViewBackgroundView.bounds];
        self.textView.keyboardAppearance = UIKeyboardAppearanceDefault;
        self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.textView.font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementSendBarTextField];
        self.textView.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementSendBarTextField];
        self.textView.backgroundColor = [UIColor clearColor];
        self.textView.returnKeyType = UIReturnKeySend;
        self.textView.delegate = self;
        self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.textView.contentInset = UIEdgeInsetsMake(2, 0, 0, 0);
        [self.textViewBackgroundView addSubview:self.textView];
        
        self.sendButton = [[UIButton alloc] initWithFrame:CGRectMake(self.bounds.size.width - 62, (self.frame.size.height - 30)/2, 60, 30)];
        [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
        [self.sendButton.titleLabel setFont:[[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementSendBarSendButton]];
        UIColor *sendButtonColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementSendBarSendButton];
        [self.sendButton setTitleColor:sendButtonColor forState:UIControlStateNormal];
        [self.sendButton setTitleColor:[sendButtonColor colorWithAlphaComponent:0.3] forState:UIControlStateNormal | UIControlStateHighlighted];
        [self.sendButton addTarget:self action:@selector(sendButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        self.sendButton.showsTouchWhenHighlighted = YES;
        self.sendButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
        [self addSubview:self.sendButton];
        
    }
    return self;
}

- (void)layoutSubviews {
    CGSize expectedSize;
    if (self.textView.text.length > 0)
        expectedSize = [self.textView.text sizeWithFont:self.textView.font constrainedToSize:CGSizeMake(self.textView.bounds.size.width - 12.0, 80) lineBreakMode:UILineBreakModeWordWrap];
    else
        expectedSize = [@"A" sizeWithFont:self.textView.font constrainedToSize:CGSizeMake(self.textView.bounds.size.width - 12.0, 80) lineBreakMode:UILineBreakModeWordWrap];
    
    [self.delegate inputBar:self wantsNewHeight:expectedSize.height + 30];
    
    CGRect frame = self.textViewBackgroundView.frame;
    frame.size.height = expectedSize.height + 30 - 10;
    self.textViewBackgroundView.frame = frame;
}

-(void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *lineColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementSendBar];
    
    CGContextSaveGState(context);
    CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
    CGContextSetLineWidth(context, 1.0);
    CGContextMoveToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, self.bounds.size.width, 0);
    CGContextStrokePath(context);
    
    CGContextRestoreGState(context);
}

#pragma mark TextFieldDelegate methods

- (void)clearTextView
{
    self.previousTextLength = 0;
    self.textView.text = @"";
}

- (void)textViewDidChange:(UITextView *)aTextView {
    [self setNeedsLayout];
    
    NSUInteger currentTextLength = aTextView.text.length;
    if (0 == self.previousTextLength)
    {
        // "Typing" started.
        if (currentTextLength)
            [self.delegate inputBarDidStartTyping:self];
    }
    else
    {
        if (0 == currentTextLength)
            [self.delegate inputBarDidStopTyping:self];
    }
    
    self.previousTextLength = currentTextLength;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [self.delegate inputBarTextFieldDidBeginEditing:self];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"])
    {
        [self setNeedsLayout];
        
        [self.delegate inputBarViewSendButtonWasTapped:self];
        return NO;
    }
    return YES;
}

#pragma mark Plus button methods

- (void)rotatePlusButton
{
    self.plusButton.imageView.transform = CGAffineTransformMakeRotation(M_PI * -45 / 180.0);
}

- (void)unrotatePlusButton
{
    self.plusButton.imageView.transform = CGAffineTransformIdentity;
}

#pragma mark Action methods

- (void)sendButtonWasTapped:(id)sender {
    [self setNeedsLayout];
    [self.delegate inputBarViewSendButtonWasTapped:self];
}

- (void)plusButtonWasTapped:(id)sender {
    [self.delegate inputBarViewPlusButtonWasTapped:self];
}

@end
