//
//  LIOChatboxView.m
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "LIOChatboxView.h"
#import "LIONiceTextField.h"
#import "LIOLookIOManager.h"

#define LIOChatboxViewMinHeight 100.0

@implementation LIOChatboxView

@synthesize delegate, inputField, sendButton, settingsButton;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        
        bubbleView = [[UIView alloc] initWithFrame:self.bounds];
        bubbleView.backgroundColor = [UIColor blackColor];
        bubbleView.alpha = 0.7;
        bubbleView.layer.masksToBounds = YES;
        bubbleView.layer.cornerRadius = 12.0;
        bubbleView.layer.borderColor = [UIColor whiteColor].CGColor;
        bubbleView.layer.borderWidth = 2.0;
        bubbleView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:bubbleView];
        
        CGRect aFrame = bubbleView.bounds;
        aFrame.origin.x = 5.0;
        aFrame.size.width = aFrame.size.width - 10.0;
        aFrame.origin.y = 5.0;
        aFrame.size.height = aFrame.size.height - 10.0;
        
        messageView = [[UILabel alloc] initWithFrame:aFrame];
        messageView.backgroundColor = [UIColor clearColor];
        messageView.textColor = [UIColor whiteColor];
        messageView.font = [UIFont systemFontOfSize:14.0];
        messageView.clipsToBounds = YES;
        messageView.layer.shadowColor = [UIColor blackColor].CGColor;
        messageView.layer.shadowOpacity = 1.0;
        messageView.layer.shadowOffset = CGSizeMake(2.0, 2.0);
        messageView.layer.shadowRadius = 1.0;
        messageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:messageView];
        
        inputFieldBackground = [[UIImageView alloc] init];
        inputFieldBackground.userInteractionEnabled = YES;
        inputFieldBackground.image = [[UIImage imageNamed:@"LIOInputBar"] stretchableImageWithLeftCapWidth:13 topCapHeight:13];
        aFrame.origin.x = messageView.frame.origin.x + 3.0;
        aFrame.size.width = bubbleView.frame.size.width - 24.0;
        aFrame.origin.y = messageView.frame.origin.y + messageView.frame.size.height + 5.0;
        aFrame.size.height = 30.0;
        inputFieldBackground.frame = aFrame;
        inputFieldBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        inputFieldBackground.clipsToBounds = YES;
        [self addSubview:inputFieldBackground];
        
        CGSize size = [@"jpqQABTY" sizeWithFont:messageView.font];
        singleLineHeight = size.height;
        
        inputField = [[UITextView alloc] initWithFrame:inputFieldBackground.bounds];
        inputField.font = messageView.font;
        inputField.delegate = self;
        inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        inputField.returnKeyType = UIReturnKeySend;
        inputField.hidden = YES;
        inputField.backgroundColor = [UIColor clearColor];
        //inputField.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5];
        aFrame = inputField.frame;
        aFrame.origin.y = -3.0;
        aFrame.size.height = 4800.0;
        inputField.frame = aFrame;
        [inputFieldBackground addSubview:inputField];
        
        UIImage *greenButtonImage = [UIImage imageNamed:@"LIOGreenButton"];
        greenButtonImage = [greenButtonImage stretchableImageWithLeftCapWidth:16 topCapHeight:13];
        
        sendButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        [sendButton setBackgroundImage:greenButtonImage forState:UIControlStateNormal];
        [sendButton setTitle:@"Send" forState:UIControlStateNormal];
        sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
        sendButton.frame = CGRectMake(inputField.frame.origin.x + inputField.frame.size.width + 6.0, inputField.frame.origin.y + 1.0, 59.0, 27.0);
        [sendButton addTarget:self action:@selector(sendButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
        sendButton.hidden = YES;
        [self addSubview:sendButton];
        
        settingsButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [settingsButton setBackgroundImage:[UIImage imageNamed:@"LIOSettingsButton"] forState:UIControlStateNormal];
        [settingsButton addTarget:self action:@selector(settingsButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
        aFrame = CGRectZero;
        aFrame.size.width = 33.0;
        aFrame.size.height = 33.0;
        aFrame.origin.x = self.frame.size.width - aFrame.size.width - 10.0;
        aFrame.origin.y = 5.0;
        [settingsButton setFrame:aFrame];
        [settingsButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
        [self addSubview:(UIView *)settingsButton];
    }
    
    return self;
}

- (void)dealloc
{
    [inputField release];
    [bubbleView release];
    [messageView release];
    [sendButton release];
    [settingsButton release];
    [inputFieldBackground release];
    
    [super dealloc];
}

- (void)rejiggerLayout
{
    if (LIOChatboxViewModeMinimal == currentMode)
    {
        sendButton.hidden = YES;
        inputField.hidden = YES;
        inputFieldBackground.hidden = YES;
        [settingsButton setHidden:YES];
        messageView.hidden = NO;
        
        CGSize maxSize = CGSizeMake(bubbleView.frame.size.width - bubbleView.frame.origin.x - 20.0, FLT_MAX);
        CGSize boxSize = [messageView.text sizeWithFont:messageView.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
        messageView.numberOfLines = 0;
        messageView.frame = CGRectMake(10.0, 10.0, boxSize.width, boxSize.height);
        
        CGRect aFrame = self.frame;
        aFrame.size.height = boxSize.height + 20.0;
        self.frame = aFrame;
        
        if ([messageView.text isEqualToString:LIOChatboxViewAdTextTrigger])
        {
            messageView.hidden = YES;
            
            UILabel *topLabel = [[[UILabel alloc] init] autorelease];
            topLabel.textColor = [UIColor whiteColor];
            topLabel.backgroundColor = [UIColor clearColor];
            topLabel.font = [UIFont systemFontOfSize:14.0];
            topLabel.text = @"Live chat powered by";
            [topLabel sizeToFit];
            aFrame = topLabel.frame;
            aFrame.origin.x = bubbleView.frame.origin.x + ((bubbleView.frame.size.width / 2.0) - (aFrame.size.width / 2.0));
            aFrame.origin.y = 10.0;
            topLabel.frame = aFrame;
            topLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            topLabel.layer.shadowColor = [UIColor blackColor].CGColor;
            topLabel.layer.shadowOpacity = 1.0;
            topLabel.layer.shadowOffset = CGSizeMake(2.0, 2.0);
            topLabel.layer.shadowRadius = 1.0;
            [self addSubview:topLabel];
            
            UIImageView *logoImageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LIOFullLogo"]] autorelease];
            logoImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            aFrame = logoImageView.frame;
            aFrame.origin.x = bubbleView.frame.origin.x + ((bubbleView.frame.size.width / 2.0) - (aFrame.size.width / 2.0));
            aFrame.origin.y = topLabel.frame.origin.y + topLabel.frame.size.height + 10.0;
            logoImageView.frame = aFrame;
            [self addSubview:logoImageView];
            
            /*
            UILabel *bottomLabel = [[[UILabel alloc] init] autorelease];
            bottomLabel.textColor = [UIColor whiteColor];
            bottomLabel.backgroundColor = [UIColor clearColor];
            bottomLabel.font = [UIFont systemFontOfSize:14.0];
            bottomLabel.text = @"Tap to learn more!";
            [bottomLabel sizeToFit];
            aFrame = bottomLabel.frame;
            aFrame.origin.x = bubbleView.frame.origin.x + ((bubbleView.frame.size.width / 2.0) - (aFrame.size.width / 2.0));
            aFrame.origin.y = logoImageView.frame.origin.y + logoImageView.frame.size.height + 10.0;
            bottomLabel.frame = aFrame;
            bottomLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            topLabel.layer.shadowColor = [UIColor blackColor].CGColor;
            topLabel.layer.shadowOpacity = 1.0;
            topLabel.layer.shadowOffset = CGSizeMake(2.0, 2.0);
            topLabel.layer.shadowRadius = 1.0;
            [self addSubview:bottomLabel];
            */
            
            aFrame = self.frame;
            aFrame.size.height = logoImageView.frame.origin.y + logoImageView.frame.size.height + 20.0;
            self.frame = aFrame;
            
            UITapGestureRecognizer *tapper = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)] autorelease];
            [self addGestureRecognizer:tapper];
        }
    }
    else
    {
        sendButton.hidden = NO;
        inputField.hidden = NO;
        inputFieldBackground.hidden = NO;
        [settingsButton setHidden:NO];
        messageView.hidden = NO;
        
        CGRect aFrame = inputFieldBackground.frame;
        aFrame.size.width = bubbleView.frame.size.width - bubbleView.frame.origin.x - [settingsButton frame].size.width - 50.0;
        inputFieldBackground.frame = aFrame;
        
        aFrame = inputField.frame;
        aFrame.size.width = inputFieldBackground.frame.size.width;
        inputField.frame = aFrame;
        
        sendButton.frame = CGRectMake(inputFieldBackground.frame.origin.x + inputFieldBackground.frame.size.width + 6.0,
                                      inputFieldBackground.frame.origin.y + 1.0,
                                      59.0, 27.0);
        
        CGSize maxSize = CGSizeMake(inputField.frame.size.width, FLT_MAX);
        CGSize boxSize = [messageView.text sizeWithFont:messageView.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
        messageView.numberOfLines = 0;
        messageView.frame = CGRectMake(10.0, 10.0, boxSize.width, boxSize.height);
        
        CGFloat settingsSpacing = 0.0;
        if (messageView.frame.origin.y + messageView.frame.size.height < [settingsButton frame].origin.y + [settingsButton frame].size.height)
        {
            settingsSpacing = ([settingsButton frame].origin.y + [settingsButton frame].size.height) - (messageView.frame.origin.y + messageView.frame.size.height);
        }
        
        UIInterfaceOrientation currentInterfaceOrientation = [[UIDevice currentDevice] orientation];
        BOOL landscape = UIInterfaceOrientationIsLandscape(currentInterfaceOrientation);
        NSInteger maxLines = LIOChatboxViewMaxLinesPortrait;
        if (landscape)
            maxLines = LIOChatboxViewMaxLinesLandscape;
        
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
        
        aFrame = inputField.frame;
        aFrame.size.height = (maxLines + 1) * singleLineHeight;
        inputField.frame = aFrame;
        
        aFrame = inputFieldBackground.frame;
        aFrame.origin.y = messageView.frame.origin.y + messageView.frame.size.height + 8.0 + settingsSpacing;
        aFrame.size.height = singleLineHeight * calculatedNumLines + 12.0;
        inputFieldBackground.frame = aFrame;
        
        if (settingsSpacing)
        {
            sendButton.frame = CGRectMake(inputFieldBackground.frame.origin.x + inputFieldBackground.frame.size.width + 6.0,
                                          inputFieldBackground.frame.origin.y + 4.0,
                                          59.0, 27.0);
        }
        
        aFrame = self.frame;
        aFrame.size.height = inputFieldBackground.frame.origin.y + inputFieldBackground.frame.size.height + 8.0;
        self.frame = aFrame;
        
        UIView *blackLine = [[[UIView alloc] init] autorelease];
        blackLine.backgroundColor = [UIColor blackColor];
        aFrame = CGRectZero;
        aFrame.origin.x = 2.0;
        aFrame.origin.y = inputFieldBackground.frame.origin.y - 6.0;
        aFrame.size.height = 1.0;
        aFrame.size.width = self.frame.size.width - 4.0;
        blackLine.frame = aFrame;
        blackLine.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:blackLine];
        
        UIView *grayLine = [[[UIView alloc] init] autorelease];
        grayLine.backgroundColor = [UIColor darkGrayColor];
        aFrame = blackLine.frame;
        aFrame.origin.y = aFrame.origin.y + 1.0;
        grayLine.frame = aFrame;
        grayLine.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:grayLine];
    }
}

- (void)populateMessageViewWithText:(NSString *)aString
{
    messageView.text = aString;
    [self rejiggerLayout];
}

- (void)switchToMode:(LIOChatboxViewMode)aMode
{
    currentMode = aMode;
    [self rejiggerLayout];
}

- (void)layoutSubviews
{
    [self rejiggerLayout];    
}

#pragma mark -
#pragma mark UIControl actions

- (void)sendButtonWasTapped
{
    [inputField resignFirstResponder];
    NSString *text = inputField.text;
    inputField.text = [NSString string];
    [delegate chatboxView:self didReturnWithText:text];
}

- (void)settingsButtonWasTapped
{
    [delegate chatboxViewDidTapSettingsButton:self];
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
    if (newLen > LIOChatboxViewMaxTextLength)
    {
        NSString *newText = [aTextView.text substringToIndex:(LIOChatboxViewMaxTextLength - 1)];
        aTextView.text = newText;
        newLen = [newText length];
    }
    
    [self rejiggerLayout];
    
    [delegate chatboxViewDidTypeStuff:self];
}

#pragma mark -
#pragma mark Gesture handlers

- (void)handleTap:(UITapGestureRecognizer *)aTapper
{
    if (aTapper.state == UIGestureRecognizerStateEnded)
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://look.io"]];
}

@end
