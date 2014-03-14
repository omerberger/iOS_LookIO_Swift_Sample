//
//  LPInputBarView.m
//  LookIO
//
//  Created by Yaron Karasik on 12/20/13.
//
//

#import "LPInputBarView.h"

#import "LIOLookIOManager.h"

#import "LIOBundleManager.h"
#import "LIOBrandingManager.h"

#define LIOInputBarViewMaxLinesPortrait     4
#define LIOInputBarViewMaxLinesLandscape    2
#define LIOInputBarViewMaxTextLength        150
#define LIOInputBarViewMaxTextLength_iPad   300

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
@property (nonatomic, strong) UIButton *sendButton;

@property (nonatomic, assign) NSInteger previousTextLength;

@property (nonatomic, assign) BOOL hasCustomBranding;

@property (nonatomic, strong) UILabel *characterCountLabel;
@property (nonatomic, strong) UILabel *placeholderLabel;

@end

@implementation LPInputBarView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];

        UIColor *backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementSendBar];
        CGFloat backgroundAlpha = [[LIOBrandingManager brandingManager] backgroundAlphaForElement:LIOBrandingElementSendBar];
        self.backgroundColor = [backgroundColor colorWithAlphaComponent:backgroundAlpha];
        
        CGFloat inputBarHeight = padUI ? LIOInputBarViewHeightIpad : LIOInputBarViewHeightIphone;
        
        self.hasCustomBranding = NO;
        if (padUI)
        {
            UIImageView *brandingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 8.0, 140.0, self.bounds.size.height - 16.0)];
            brandingImageView.contentMode = UIViewContentModeScaleAspectFit;
            brandingImageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            [self addSubview:brandingImageView];
            self.hasCustomBranding = YES;
            
            [[LIOBundleManager sharedBundleManager] cachedImageForBrandingElement:LIOBrandingElementLogo withBlock:^(BOOL success, UIImage *image) {
                if (success)
                {
                    brandingImageView.image = image;
                }
                else
                {
                    [brandingImageView setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOBigLivePersonLogo"]];
                }
            }];
        }

        CGFloat plusButtonXMargin = padUI ? 12.0 : 0.0;
        CGFloat plusButtonYMargin = padUI ? 19.0 : 5.0;
        self.plusButton = [[UIButton alloc] initWithFrame:CGRectMake(self.hasCustomBranding ? 150.0 : plusButtonXMargin, plusButtonYMargin + (padUI ? 2.0 : 0.0), inputBarHeight - plusButtonXMargin, self.frame.size.height - 2*plusButtonYMargin)];
        self.plusButton.accessibilityLabel = LIOLocalizedString(@"LIOLookIOManager.KeyboardMenuPlusButton");
        UIColor *buttonTintColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorColor forElement:LIOBrandingElementSendBarPlusButton];
        if (padUI)
            [self.plusButton setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOPlusIconBig" withTint:buttonTintColor] forState:UIControlStateNormal];
        else
            [self.plusButton setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOPlusIcon" withTint:buttonTintColor] forState:UIControlStateNormal];
        self.plusButton.imageView.clipsToBounds = NO;
        self.plusButton.imageView.contentMode = UIViewContentModeCenter;
        [self.plusButton addTarget:self action:@selector(plusButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        self.plusButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self addSubview:self.plusButton];
        
        if (padUI)
        {
            self.plusButton.layer.borderWidth = 1.0;
            self.plusButton.layer.cornerRadius = 5.0;
            UIColor *borderColor = [[[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementSendBarPlusButton] colorWithAlphaComponent:0.5];
            self.plusButton.layer.borderColor = [borderColor CGColor];
            
            
            // Create the path (with only the top-left corner rounded)
            UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.plusButton.bounds
                                                           byRoundingCorners:UIRectCornerAllCorners
                                                                 cornerRadii:CGSizeMake(5.0, 5.0)];
            
            // Create the shape layer and set its path
            CAShapeLayer *maskLayer = [CAShapeLayer layer];
            maskLayer.frame = self.plusButton.bounds;
            maskLayer.path = maskPath.CGPath;
            
            // Set the newly created shape layer as the mask for the image view's layer
            self.plusButton.layer.mask = maskLayer;

        }
        
        self.textViewBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(self.plusButton.frame.origin.x + inputBarHeight, padUI ? 10 : 5, self.bounds.size.width - 2*inputBarHeight - 15.0 - self.plusButton.frame.origin.x, self.frame.size.height - 10)];
        self.textViewBackgroundView.backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementSendBarTextField];
        self.textViewBackgroundView.layer.borderColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementSendBarTextField].CGColor;
        self.textViewBackgroundView.layer.cornerRadius = 5.0;
        self.textViewBackgroundView.layer.borderWidth = 1.0;
        self.textViewBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.textViewBackgroundView.clipsToBounds = YES;
        [self addSubview:self.textViewBackgroundView];
        
        self.textView = [[UITextView alloc] initWithFrame:self.textViewBackgroundView.bounds];
        self.textView.keyboardAppearance = [[LIOBrandingManager brandingManager] keyboardTypeForElement:LIOBrandingElementKeyboard];
        self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.textView.font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementSendBarTextField];
        self.textView.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementSendBarTextField];
        self.textView.backgroundColor = [UIColor clearColor];
        self.textView.returnKeyType = UIReturnKeySend;
        self.textView.delegate = self;
        self.textView.accessibilityLabel = LIOLocalizedString(@"LIOInputBarView.TextFieldAccessibilityLabel");
        self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.textView.contentInset = UIEdgeInsetsMake(padUI ? 6.0 : 2.0, 0, 0, 0);
        [self.textViewBackgroundView addSubview:self.textView];
        
        CGFloat xPlaceholderMargin = 7.0;
        if (LIOIsUIKitFlatMode())
            xPlaceholderMargin = 5.0;
        
        self.placeholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(xPlaceholderMargin, 10, self.textViewBackgroundView.bounds.size.width - xPlaceholderMargin*2, self.textViewBackgroundView.bounds.size.height - 20.0)];
        self.placeholderLabel.isAccessibilityElement = NO;
        self.placeholderLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.placeholderLabel.text = LIOLocalizedString(@"LIOInputBarView.Placeholder");
        self.placeholderLabel.font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementSendBarTextFieldPlaceholder];
        self.placeholderLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementSendBarTextFieldPlaceholder];
        self.placeholderLabel.numberOfLines = 1;
        self.placeholderLabel.hidden = NO;
        self.placeholderLabel.backgroundColor = [UIColor clearColor];
        [self.textViewBackgroundView addSubview:self.placeholderLabel];
        
        self.sendButton = [[UIButton alloc] initWithFrame:CGRectMake(self.bounds.size.width - inputBarHeight - 12, (self.frame.size.height - 30)/2, inputBarHeight + 10.0, 30)];
        [self.sendButton setTitle:LIOLocalizedString(@"LIOInputBarView.SendButton") forState:UIControlStateNormal];
        [self.sendButton.titleLabel setFont:[[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementSendBarSendButton]];
        UIColor *sendButtonColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementSendBarSendButton];
        [self.sendButton setTitleColor:sendButtonColor forState:UIControlStateNormal];
        [self.sendButton setTitleColor:[sendButtonColor colorWithAlphaComponent:0.3] forState:UIControlStateNormal | UIControlStateHighlighted];
        self.sendButton.titleLabel.textAlignment = UITextAlignmentCenter;
        [self.sendButton addTarget:self action:@selector(sendButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        self.sendButton.showsTouchWhenHighlighted = YES;
        self.sendButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.sendButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
        [self addSubview:self.sendButton];
        
        self.characterCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.sendButton.frame.origin.x, self.sendButton.frame.origin.y + self.sendButton.frame.size.height, self.sendButton.frame.size.width, 20)];
        self.characterCountLabel.text = @"(20/300)";
        self.characterCountLabel.textAlignment = UITextAlignmentCenter;
        self.characterCountLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
        self.characterCountLabel.font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementSendBarCharacterCount];
        self.characterCountLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementSendBarCharacterCount];
        self.characterCountLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:self.characterCountLabel];
        
    }
    return self;
}

- (void)layoutSubviews {
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    CGSize singleLineSize = [@"A" sizeWithFont:self.textView.font constrainedToSize:CGSizeMake(self.textView.bounds.size.width - 12.0, padUI ? 80.0 : 80.0) lineBreakMode:UILineBreakModeWordWrap];
    
    CGSize expectedSize;
    if (self.textView.text.length > 0)
        expectedSize = [self.textView.text sizeWithFont:self.textView.font constrainedToSize:CGSizeMake(self.textView.bounds.size.width - 12.0, padUI ? 80.0 : 80.0) lineBreakMode:UILineBreakModeWordWrap];
    else
        expectedSize = singleLineSize;
    
    if (expectedSize.height != self.lastCalculatedExpectedHeight)
    {
        [self.delegate inputBar:self wantsNewHeight:expectedSize.height + (padUI ? 50.0 : 30.0)];
        self.lastCalculatedExpectedHeight = expectedSize.height;
    }
    
    CGRect frame = self.textViewBackgroundView.frame;
    frame.size.height = expectedSize.height + (padUI ? 30.0 : 20.0);
    self.textViewBackgroundView.frame = frame;
    
    frame = self.placeholderLabel.frame;
    frame.size.height = self.textViewBackgroundView.bounds.size.height - 20.0;
    self.placeholderLabel.frame = frame;
    
    NSInteger numberOfLines = expectedSize.height / singleLineSize.height;
    NSInteger maxCharacters = padUI ? LIOInputBarViewMaxTextLength_iPad : LIOInputBarViewMaxTextLength;
    
    self.characterCountLabel.frame = CGRectMake(self.sendButton.frame.origin.x, self.sendButton.frame.origin.y + self.sendButton.frame.size.height, self.sendButton.frame.size.width, 20);
    self.characterCountLabel.hidden = (numberOfLines < 3);
    self.characterCountLabel.text = [NSString stringWithFormat:@"(%ld/%ld)", (long)self.textView.text.length, (long)maxCharacters];
    
    if (self.textView.text.length == 0)
        self.placeholderLabel.hidden = NO;
    else
        self.placeholderLabel.hidden = YES;
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
    
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    NSInteger maxCharacters = padUI ? LIOInputBarViewMaxTextLength_iPad : LIOInputBarViewMaxTextLength;

    // Limit the length, and make sure there isn't any marekd text first
    if (currentTextLength > maxCharacters && self.textView.markedTextRange == nil)
    {
        NSString *newText = [aTextView.text substringToIndex:maxCharacters];
        aTextView.text = newText;
        currentTextLength = [newText length];
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
