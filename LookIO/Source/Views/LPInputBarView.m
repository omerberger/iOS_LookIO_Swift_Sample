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

@interface LPInputBarView () <UITextViewDelegate>

@property (nonatomic, strong) UIView *textViewBackgroundView;
@property (nonatomic, strong) UIButton *plusButton;
@property (nonatomic, strong) UIButton *sendButton;

@end

@implementation LPInputBarView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.plusButton = [[UIButton alloc] initWithFrame:CGRectMake(0, (self.frame.size.height - 50)/2, 50, 50)];
        [self.plusButton setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"InputBarPlusButton"] forState:UIControlStateNormal];
        self.plusButton.imageView.clipsToBounds = NO;
        self.plusButton.imageView.contentMode = UIViewContentModeCenter;
        [self.plusButton addTarget:self action:@selector(plusButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        self.plusButton.imageView.transform = CGAffineTransformMakeRotation(M_PI * -45 / 180.0);
        self.plusButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self addSubview:self.plusButton];
        
        self.textViewBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(50, 5, self.bounds.size.width - 115, self.frame.size.height - 10)];
        self.textViewBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self addSubview:self.textViewBackgroundView];
        
        self.textView = [[UITextView alloc] initWithFrame:self.textViewBackgroundView.bounds];
        self.textView.keyboardAppearance = UIKeyboardAppearanceAlert;
        self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.textView.font = [UIFont systemFontOfSize:16.0];
        self.textView.textColor = [UIColor darkGrayColor];
        self.textView.backgroundColor = [UIColor clearColor];
        self.textView.returnKeyType = UIReturnKeySend;
        self.textView.delegate = self;
        self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.textView.contentInset = UIEdgeInsetsMake(2, 0, 0, 0);
        [self.textViewBackgroundView addSubview:self.textView];
        
        self.sendButton = [[UIButton alloc] initWithFrame:CGRectMake(self.bounds.size.width - 64, (self.frame.size.height - 30)/2, 60, 30)];
        [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
        [self.sendButton setTitleColor: [UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        [self.sendButton setTitleColor: [UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:0.3] forState:UIControlStateNormal | UIControlStateHighlighted];
        [self.sendButton addTarget:self action:@selector(sendButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        self.sendButton.showsTouchWhenHighlighted = YES;
        self.sendButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
        [self addSubview:self.sendButton];
        
        self.backgroundColor = [UIColor colorWithWhite:245.0/255.0 alpha:0.8];
    }
    return self;
}

- (void)layoutSubviews {
    CGSize expectedSize = [self.textView.text sizeWithFont:self.textView.font constrainedToSize:CGSizeMake(self.textView.bounds.size.width - 12.0, 80) lineBreakMode:UILineBreakModeWordWrap];
    
    [self.delegate inputBar:self wantsNewHeight:expectedSize.height + 30];
}

-(void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *lineColor = [UIColor colorWithRed:180.0/255.0 green:184.0/255 blue:190.0/255.0 alpha:1.0];
    UIColor *shadowColor = [UIColor colorWithRed:232.0/255.0 green:232.0/255 blue:232.0/255.0 alpha:1.0];
    
    CGContextSaveGState(context);
    CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
    CGContextSetShadowWithColor(context, CGSizeMake(1.0, 1.0), 0.0, shadowColor.CGColor);
    CGContextSetLineWidth(context, 1.0);
    CGContextMoveToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, self.bounds.size.width, 0);
    CGContextStrokePath(context);
    
    CGContextRestoreGState(context);
}

#pragma mark TextFieldDelegate methods
- (void)textViewDidChange:(UITextView *)aTextView {
    [self setNeedsLayout];
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

#pragma mark Action methods

- (void)sendButtonWasTapped:(id)sender {
    [self setNeedsLayout];
    [self.delegate inputBarViewSendButtonWasTapped:self];
}

- (void)plusButtonWasTapped:(id)sender {
    [self.delegate inputBarViewPlusButtonWasTapped:self];
}

@end
