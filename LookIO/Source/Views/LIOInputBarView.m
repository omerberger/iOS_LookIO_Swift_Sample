//
//  LIOInputBarView.m
//  LookIO
//
//  Created by Joseph Toscano on 12/7/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import "LIOInputBarView.h"
#import "LIOLookIOManager.h"
#import "LIOBundleManager.h"

#define LIOInputBarViewMinHeight    35.0
#define LIOInputBarViewMinHeightPad 50.0

@implementation LIOInputBarView

@synthesize delegate, singleLineHeight, inputField, desiredHeight;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
        
        self.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.7];
                
        UIImage *sendButtonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableSendButton"];
        sendButtonImage = [sendButtonImage stretchableImageWithLeftCapWidth:5 topCapHeight:20];
        
        CGRect sendButtonFrame = CGRectZero;
        UIFont *sendButtonFont = nil;
        if (padUI)
        {
            sendButtonFrame.origin.x = self.bounds.size.width - 59.0 - 57.0;
            sendButtonFrame.origin.y = (self.bounds.size.height / 2.0) - 25.0;
            sendButtonFrame.size.width = 75.0;
            sendButtonFrame.size.height = 47.0;
            sendButtonFont = [UIFont boldSystemFontOfSize:16.0];
        }
        else
        {
            sendButtonFrame.origin.x = self.bounds.size.width - 59.0 - 5.0;
            sendButtonFrame.origin.y = (self.bounds.size.height / 2.0) - 14.0;
            sendButtonFrame.size.width = 59.0;
            sendButtonFrame.size.height = 36.0;
            sendButtonFont = [UIFont boldSystemFontOfSize:12.0];
        }
        
        sendButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        sendButton.accessibilityLabel = @"LIOSendButton";
        [sendButton setBackgroundImage:sendButtonImage forState:UIControlStateNormal];
        [sendButton setTitle:@"Send" forState:UIControlStateNormal];
        sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
        sendButton.frame = sendButtonFrame;
        [sendButton addTarget:self action:@selector(sendButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
        sendButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self addSubview:sendButton];
        
        if (padUI)
        {
            adLabel = [[UILabel alloc] init];
            adLabel.backgroundColor = [UIColor clearColor];
            adLabel.font = [UIFont boldSystemFontOfSize:12.0];
            adLabel.textColor = [UIColor whiteColor];
            adLabel.text = @"powered by";
            [adLabel sizeToFit];
            CGRect aFrame = adLabel.frame;
            aFrame.origin.x = 15.0;
            aFrame.origin.y = (self.frame.size.height / 2.0) - (aFrame.size.height / 2.0);
            adLabel.frame = aFrame;
            adLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            [self addSubview:adLabel];
            
            adLogo = [[UIImageView alloc] initWithImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOHeaderBarTinyLogo"]];
            aFrame = adLogo.frame;
            aFrame.origin.x = adLabel.frame.origin.x + adLabel.frame.size.width + 3.0;
            aFrame.origin.y = (self.frame.size.height / 2.0) - (aFrame.size.height / 2.0);
            adLogo.frame = aFrame;
            adLogo.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            [self addSubview:adLogo];
        }
        
        CGRect inputFieldBackgroundFrame = CGRectZero;
        if (padUI)
        {
            inputFieldBackgroundFrame.origin.x = adLogo.frame.origin.x + adLogo.frame.size.width + 20.0;
            inputFieldBackgroundFrame.size.width = 450.0;
            inputFieldBackgroundFrame.size.height = 50.0;
            inputFieldBackgroundFrame.origin.y = (self.frame.size.height / 2.0) - (inputFieldBackgroundFrame.size.height / 2.0) - 1.0;
        }
        else
        {
            inputFieldBackgroundFrame.size.width = self.frame.size.width - sendButton.frame.size.width - 15.0;
            inputFieldBackgroundFrame.size.height = 37.0;
            inputFieldBackgroundFrame.origin.y = (self.frame.size.height / 2.0) - (inputFieldBackgroundFrame.size.height / 2.0) + 4.0;
            inputFieldBackgroundFrame.origin.x = 5.0;
        }
        
        inputFieldBackground = [[UIImageView alloc] initWithFrame:inputFieldBackgroundFrame];
        inputFieldBackground.userInteractionEnabled = YES;
        inputFieldBackground.image = [[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableInputBar"] stretchableImageWithLeftCapWidth:8 topCapHeight:8];
        inputFieldBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        inputFieldBackground.clipsToBounds = YES;
        [self addSubview:inputFieldBackground];
        
        CGFloat fontSize = 14.0;
        if (padUI)
            fontSize = 20.0;
        
        inputField = [[UITextView alloc] initWithFrame:inputFieldBackground.bounds];
        inputField.keyboardAppearance = UIKeyboardAppearanceAlert;
        inputField.accessibilityLabel = @"LIOInputField";
        inputField.font = [UIFont systemFontOfSize:fontSize];
        inputField.delegate = self;
        inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        inputField.returnKeyType = UIReturnKeySend;
        inputField.backgroundColor = [UIColor clearColor];
        CGRect aFrame = inputFieldBackground.frame;
        aFrame.origin.y -= 3.0;
        aFrame.size.height = 4800.0;
        inputField.frame = aFrame;
        [self addSubview:inputField];
        
        CGSize size = [@"jpqQABTY" sizeWithFont:inputField.font];
        singleLineHeight = size.height;
        
        totalLines = 1;
    }
    
    return self;
}

- (void)dealloc
{
    [sendButton release];
    [inputField release];
    [inputFieldBackground release];
    [adLabel release];
    [adLogo release];
    
    [super dealloc];
}

- (void)layoutSubviews
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    CGRect aFrame = inputField.frame;
    aFrame.origin.x = inputFieldBackground.frame.origin.x - 3.0;
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
    
    CGFloat backgroundHeightMod = 12.0; // im not even really sure what this
    
    CGFloat maxWidth = inputField.frame.size.width - 16.0;
    CGSize newSize = [stringToMeasure sizeWithFont:inputField.font constrainedToSize:CGSizeMake(maxWidth, FLT_MAX)];
    NSInteger calculatedNumLines = newSize.height / singleLineHeight;
    if (calculatedNumLines > maxLines)
    {
        calculatedNumLines = maxLines;
        if (NO == inputField.scrollEnabled)
            inputField.scrollEnabled = YES;
        
        backgroundHeightMod = 24.0;
    }
    else if (calculatedNumLines < 1)
    {
        calculatedNumLines = 1;
        inputField.scrollEnabled = NO;
    }
    
    if (calculatedNumLines != totalLines)
    {
        //[delegate inputBarView:self didChangeNumberOfLines:(calculatedNumLines - totalLines)];
        totalLines = calculatedNumLines;
    }
    
    aFrame = inputField.frame;
    aFrame.size.height = (maxLines + 1) * singleLineHeight;
    inputField.frame = aFrame;
    
    CGFloat minHeight = LIOInputBarViewMinHeight;
    if (padUI) minHeight = LIOInputBarViewMinHeightPad;
    
    aFrame = inputFieldBackground.frame;
    aFrame.size.height = singleLineHeight * calculatedNumLines + backgroundHeightMod;
    if (aFrame.size.height < minHeight) aFrame.size.height = minHeight;
    inputFieldBackground.frame = aFrame;
    
    CGFloat bottomPadding = 5.0;
    if (padUI)
        bottomPadding = 12.0;
    
    desiredHeight = inputFieldBackground.frame.origin.y + inputFieldBackground.frame.size.height + bottomPadding;
    [delegate inputBarView:self didChangeDesiredHeight:desiredHeight];
}

#pragma mark -
#pragma mark UIControl actions

- (void)sendButtonWasTapped
{
    [inputField resignFirstResponder];
    NSString *text = inputField.text;
    inputField.text = [NSString string];
    [delegate inputBarView:self didReturnWithText:text];
    [self setNeedsLayout];
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
