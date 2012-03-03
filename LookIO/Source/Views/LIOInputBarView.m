//
//  LIOInputBarView.m
//  LookIO
//
//  Created by Joseph Toscano on 12/7/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import "LIOInputBarView.h"
#import "LIOLookIOManager.h"
#import "LIONiceTextField.h"

@implementation LIOInputBarView

@synthesize delegate, singleLineHeight, inputField;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.7];
        
        dividerLine = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.bounds.size.width, 1.0)];
        dividerLine.backgroundColor = [UIColor blackColor];
        dividerLine.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:dividerLine];
        
        UIImage *glassButtonImage = lookioImage(@"LIOGlassButton");
        glassButtonImage = [glassButtonImage stretchableImageWithLeftCapWidth:15 topCapHeight:15];
        
        sendButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        sendButton.accessibilityLabel = @"LIOSendButton";
        [sendButton setBackgroundImage:glassButtonImage forState:UIControlStateNormal];
        [sendButton setTitle:@"Send" forState:UIControlStateNormal];
        sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
        sendButton.frame = CGRectMake(self.bounds.size.width - 59.0 - 5.0, (self.bounds.size.height / 2.0) - 15.0, 59.0, 30.0);
        [sendButton addTarget:self action:@selector(sendButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
        sendButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self addSubview:sendButton];
        
        inputFieldBackground = [[UIImageView alloc] init];
        inputFieldBackground.userInteractionEnabled = YES;
        inputFieldBackground.image = [lookioImage(@"LIOInputBar") stretchableImageWithLeftCapWidth:13 topCapHeight:13];
        CGRect aFrame = CGRectZero;
        aFrame.size.width = self.frame.size.width;
        aFrame.origin.y = (self.frame.size.height / 2.0) - 15.0;
        aFrame.size.height = 30.0;
        inputFieldBackground.frame = aFrame;
        inputFieldBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        inputFieldBackground.clipsToBounds = YES;
        [self addSubview:inputFieldBackground];
        
        inputField = [[UITextView alloc] initWithFrame:inputFieldBackground.bounds];
        inputField.accessibilityLabel = @"LIOInputField";
        inputField.font = [UIFont systemFontOfSize:14.0];
        inputField.delegate = self;
        inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        inputField.returnKeyType = UIReturnKeySend;
        inputField.backgroundColor = [UIColor clearColor];
        aFrame = inputFieldBackground.frame;
        aFrame.origin.y -= 3.0;
        aFrame.size.height = 4800.0;
        inputField.frame = aFrame;
        [self addSubview:inputField];
        
        CGSize size = [@"jpqQABTY" sizeWithFont:[UIFont systemFontOfSize:14.0]];
        singleLineHeight = size.height;
        
        totalLines = 1;
    }
    
    return self;
}

- (void)dealloc
{
    [dividerLine release];
    [sendButton release];
    [inputField release];
    [inputFieldBackground release];
    
    [super dealloc];
}

- (void)layoutSubviews
{
    CGRect aFrame = inputFieldBackground.frame;
    aFrame.origin.x = 10.0;
    aFrame.size.width = self.frame.size.width - sendButton.frame.size.width - 20.0;
    inputFieldBackground.frame = aFrame;
    
    aFrame = inputField.frame;
    aFrame.origin.x = inputFieldBackground.frame.origin.x - 3.0;
    inputField.frame = aFrame;
    
    aFrame = inputField.frame;
    aFrame.size.width = inputFieldBackground.frame.size.width;
    inputField.frame = aFrame;
    
    UIInterfaceOrientation currentInterfaceOrientation = (UIInterfaceOrientation)[[UIDevice currentDevice] orientation];
    BOOL landscape = UIInterfaceOrientationIsLandscape(currentInterfaceOrientation);
    NSInteger maxLines = LIOInputBarViewMaxLinesPortrait;
    if (landscape)
        maxLines = LIOInputBarViewMaxLinesLandscape;
    
    // We slip in a character at the end of the string if the last character is a newline.
    // This is purely for the size calculation. If we DON'T do this, then pressing
    // return results in the cursor being below the input box.
    NSMutableString *stringToMeasure = [[inputField.text mutableCopy] autorelease];
    if ([stringToMeasure length] && [[stringToMeasure substringFromIndex:[stringToMeasure length] - 1] isEqualToString:@"\n"])
        [stringToMeasure replaceCharactersInRange:NSMakeRange([stringToMeasure length] - 1, 1) withString:@"\n "];
    
    CGFloat maxWidth = inputField.frame.size.width - 16.0;
    CGSize newSize = [stringToMeasure sizeWithFont:inputField.font constrainedToSize:CGSizeMake(maxWidth, FLT_MAX)];
    NSInteger calculatedNumLines = newSize.height / singleLineHeight;
    if (calculatedNumLines > maxLines)
    {
        calculatedNumLines = maxLines;
        if (NO == inputField.scrollEnabled)
            inputField.scrollEnabled = YES;
    }
    else if (calculatedNumLines < 1)
    {
        calculatedNumLines = 1;
        inputField.scrollEnabled = NO;
    }
    
    if (calculatedNumLines != totalLines)
    {
        [delegate inputBarView:self didChangeNumberOfLines:(calculatedNumLines - totalLines)];
        totalLines = calculatedNumLines;
    }
    
    aFrame = inputField.frame;
    aFrame.size.height = (maxLines + 1) * singleLineHeight;
    inputField.frame = aFrame;
    
    aFrame = inputFieldBackground.frame;
    aFrame.size.height = singleLineHeight * calculatedNumLines + 12.0;
    inputFieldBackground.frame = aFrame;
    
    aFrame = self.frame;
    aFrame.size.height = inputFieldBackground.frame.origin.y + inputFieldBackground.frame.size.height + 11.0;
    self.frame = aFrame;
}

#pragma mark -
#pragma mark UIControl actions

- (void)sendButtonWasTapped
{
    [inputField resignFirstResponder];
    NSString *text = inputField.text;
    inputField.text = [NSString string];
    [delegate inputBarView:self didReturnWithText:text];
}

#pragma mark -
#pragma mark UITextViewDelegate methods

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"])
        [self sendButtonWasTapped];
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)aTextView
{
    // Clamp the length.
    NSUInteger newLen = [aTextView.text length];
    if (newLen > LIOInputBarViewMaxTextLength)
    {
        NSString *newText = [aTextView.text substringToIndex:(LIOInputBarViewMaxTextLength - 1)];
        aTextView.text = newText;
        newLen = [newText length];
    }
    
    [self setNeedsLayout];
    
    [delegate inputBarViewDidTypeStuff:self];
}

@end
