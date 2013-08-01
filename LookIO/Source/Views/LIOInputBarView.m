//
//  LIOInputBarView.m
//  LookIO
//
//  Created by Joseph Toscano on 12/7/11.
//  Copyright (c) 2011 LivePerson, Inc. All rights reserved.
//

#import "LIOInputBarView.h"
#import "LIOLookIOManager.h"
#import "LIOBundleManager.h"
#import "LIOLogManager.h"
#import "LIONotificationArea.h"
#import <QuartzCore/QuartzCore.h>
#import "LIOTimerProxy.h"

@implementation LIOInputBarView

@synthesize delegate, singleLineHeight, inputField, desiredHeight, adArea, notificationArea, attachButton, sendButton;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
        BOOL attachNeeded = [[LIOLookIOManager sharedLookIOManager] enabledCollaborationComponents];
        
        if (kLPChatThemeFlat == [LIOLookIOManager sharedLookIOManager].selectedChatTheme)
            self.backgroundColor = [UIColor colorWithWhite:102.0/255.0 alpha:0.5];
        else
            self.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.7];
        
        UIImage *sendButtonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableSendButton-flat"];
        sendButtonImage = [sendButtonImage stretchableImageWithLeftCapWidth:5 topCapHeight:20];
        
        UIImage *attachImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOAttachIcon"];
        
        CGRect sendButtonFrame = CGRectZero;
        UIFont *sendButtonFont = nil;
        if (padUI)
        {
            sendButtonFrame.origin.x = self.bounds.size.width - 104.0 - 17.0;
            sendButtonFrame.origin.y = (self.bounds.size.height / 2.0) - 22.0;
            sendButtonFrame.size.width = 104.0;
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
            
            if (kLPChatThemeFlat == [LIOLookIOManager sharedLookIOManager].selectedChatTheme)
                sendButtonFont = [UIFont boldSystemFontOfSize:16.0];
            else
                sendButtonFont = [UIFont boldSystemFontOfSize:12.0];
        }
        
        sendButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        sendButton.accessibilityLabel = @"LIOInputBarView.sendButton";
        [sendButton setBackgroundImage:sendButtonImage forState:UIControlStateNormal];
        [sendButton setTitle:LIOLocalizedString(@"LIOInputBarView.SendButton") forState:UIControlStateNormal];
        sendButton.titleLabel.font = sendButtonFont;
        sendButton.frame = sendButtonFrame;
        [sendButton addTarget:self action:@selector(sendButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
        sendButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self addSubview:sendButton];
        
        CGRect attachButtonFrame = sendButton.frame;
        attachButtonFrame.origin.x = 5.0;
        if (padUI)
            attachButtonFrame.size.width = 64.0;
        else
            attachButtonFrame.size.width = 40.0;
        
        attachButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        attachButton.frame = attachButtonFrame;
        attachButton.hidden = NO == attachNeeded;
        [attachButton setBackgroundImage:sendButtonImage forState:UIControlStateNormal];
        [attachButton setImage:attachImage forState:UIControlStateNormal];
        [attachButton addTarget:self action:@selector(attachButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:attachButton];
        
        if (padUI)
        {
            CGRect notificationAreaFrame = CGRectZero;
            notificationAreaFrame.size.width = 160.0;
            notificationAreaFrame.size.height = self.bounds.size.height;
            notificationArea = [[LIONotificationArea alloc] initWithFrame:notificationAreaFrame];
            [self addSubview:notificationArea];
            
            UITapGestureRecognizer *tapper = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleAdAreaTap:)] autorelease];
            [notificationArea addGestureRecognizer:tapper];
            
            if (attachNeeded)
            {
                attachButtonFrame = attachButton.frame;
                attachButtonFrame.origin.x = notificationArea.frame.origin.x + notificationArea.frame.size.width;
                attachButton.frame = attachButtonFrame;
            }
        }
        
        CGRect inputFieldBackgroundFrame = CGRectZero;
        if (padUI)
        {
            if (attachNeeded)
            {
                inputFieldBackgroundFrame.origin.x = attachButton.frame.origin.x + attachButton.frame.size.width + 14.0;
                inputFieldBackgroundFrame.size.width = self.frame.size.width - sendButton.frame.size.width - attachButton.frame.size.width - 205.0;
                inputFieldBackgroundFrame.size.height = 50.0;
                inputFieldBackgroundFrame.origin.y = (self.frame.size.height / 2.0) - (inputFieldBackgroundFrame.size.height / 2.0) - 1.0;
            }
            else
            {
                inputFieldBackgroundFrame.origin.x = notificationArea.frame.origin.x + notificationArea.frame.size.width;
                inputFieldBackgroundFrame.size.width = self.frame.size.width - sendButton.frame.size.width - 192.0;
                inputFieldBackgroundFrame.size.height = 50.0;
                inputFieldBackgroundFrame.origin.y = (self.frame.size.height / 2.0) - (inputFieldBackgroundFrame.size.height / 2.0) - 1.0;
            }
        }
        else
        {
            // We need to shrink the input field if the attach button is present.
            if (attachNeeded)
            {
                inputFieldBackgroundFrame.size.width = self.frame.size.width - sendButton.frame.size.width - attachButton.frame.size.width - 13.0;
                inputFieldBackgroundFrame.size.height = 39.0;
                inputFieldBackgroundFrame.origin.y = (self.frame.size.height / 2.0) - (inputFieldBackgroundFrame.size.height / 2.0) + 3.0;
                inputFieldBackgroundFrame.origin.x = attachButton.frame.size.width + 7.0;
            }
            else
            {
                inputFieldBackgroundFrame.size.width = self.frame.size.width - sendButton.frame.size.width - 13.0;
                inputFieldBackgroundFrame.size.height = 39.0;
                inputFieldBackgroundFrame.origin.y = (self.frame.size.height / 2.0) - (inputFieldBackgroundFrame.size.height / 2.0) + 3.0;
                inputFieldBackgroundFrame.origin.x = 3.0;
            }
        }
        
        inputFieldBackground = [[UIImageView alloc] initWithFrame:inputFieldBackgroundFrame];
        inputFieldBackground.userInteractionEnabled = YES;
        inputFieldBackground.image = [[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableInputBar"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
        inputFieldBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        inputFieldBackground.clipsToBounds = YES;
        [self addSubview:inputFieldBackground];
        
        inputFieldBackgroundGlowing = [[UIImageView alloc] initWithImage:[[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableInputBarGlowing"] stretchableImageWithLeftCapWidth:10 topCapHeight:10]];
        inputFieldBackgroundGlowing.frame = inputFieldBackground.bounds;
        inputFieldBackgroundGlowing.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        inputFieldBackgroundGlowing.hidden = YES;
        [inputFieldBackground addSubview:inputFieldBackgroundGlowing];
                
        CGFloat fontSize = 14.0;
        if (padUI)
            fontSize = 20.0;
        
        inputField = [[UITextView alloc] initWithFrame:inputFieldBackground.bounds];
        if (kLPChatThemeFlat == [LIOLookIOManager sharedLookIOManager].selectedChatTheme)
            inputField.keyboardAppearance = UIKeyboardAppearanceDefault;
        else
            inputField.keyboardAppearance = UIKeyboardAppearanceAlert;
        inputField.accessibilityLabel = @"LIOInputBarView.inputField";
        inputField.font = [UIFont systemFontOfSize:fontSize];
        inputField.delegate = self;
        inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        inputField.returnKeyType = UIReturnKeySend;
        inputField.backgroundColor = [UIColor clearColor];
        CGRect aFrame = inputFieldBackground.frame;
        aFrame.origin.y = -3.0;
        aFrame.size.height = 4800.0;
        inputField.frame = aFrame;
        [self addSubview:inputField];
        
        placeholderText = [[UILabel alloc] init];
        placeholderText.backgroundColor = [UIColor clearColor];
        placeholderText.textColor = [UIColor lightGrayColor];
        placeholderText.font = inputField.font;
        placeholderText.text = LIOLocalizedString(@"LIOInputBarView.Placeholder");
        [placeholderText sizeToFit];
        aFrame = placeholderText.frame;
        aFrame.origin.x = 9.0;
        aFrame.origin.y = 7.5;
        placeholderText.frame = aFrame;
        [inputField addSubview:placeholderText];
        
        characterCount = [[UILabel alloc] init];
        characterCount.backgroundColor = [UIColor clearColor];
        characterCount.textColor = [UIColor lightGrayColor];
        characterCount.font = [UIFont italicSystemFontOfSize:12.0];
        [self addSubview:characterCount];
        
        CGSize size = [@"jpqQABTY" sizeWithFont:inputField.font];
        singleLineHeight = size.height;
        
        totalLines = 1;
    }
    
    return self;
}

- (void)dealloc
{
    [pulseTimer stopTimer];
    [pulseTimer release];
    pulseTimer = nil;
    
    [attachButton release];
    [sendButton release];
    [inputField release];
    [inputFieldBackground release];
    [inputFieldBackgroundGlowing release];
    [characterCount release];
    [placeholderText release];
    
    [super dealloc];
}

- (void)layoutSubviews
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    CGRect aFrame;
    if (padUI)
    {
        aFrame = inputField.frame;
        aFrame.origin.x = inputFieldBackground.frame.origin.x + 6.0;
        aFrame.size.width = inputFieldBackground.frame.size.width - 9.0;
        inputField.frame = aFrame;
    }
    else
    {
        aFrame = inputField.frame;
        aFrame.origin.x = inputFieldBackground.frame.origin.x;
        aFrame.size.width = inputFieldBackground.frame.size.width - 3.0;
        if (LIOIsUIKitFlatMode()) {
            aFrame.origin.x = inputFieldBackground.frame.origin.x + 6.0;
            aFrame.size.width = inputFieldBackground.frame.size.width - 12.0;
        }
        inputField.frame = aFrame;
    }
    
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
    CGFloat backgroundHeightMod = 14.0; // im not even really sure what this
    if (LIOIsUIKitFlatMode())
        backgroundHeightMod = 22.0;

    CGFloat maxWidth = inputField.frame.size.width - 16.0;
    
    CGSize newSize = [stringToMeasure sizeWithFont:inputField.font constrainedToSize:CGSizeMake(maxWidth, FLT_MAX)];
    
    NSInteger calculatedNumLines = newSize.height / singleLineHeight;
    if (LIOIsUIKitFlatMode())
        calculatedNumLines += 1;

    if (calculatedNumLines > maxLines)
    {
        calculatedNumLines = maxLines;
        if (NO == inputField.scrollEnabled)
            inputField.scrollEnabled = YES;
        
        backgroundHeightMod = 28.0;
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
    
    if (inputField.scrollEnabled)
    {
        aFrame = inputField.frame;
        aFrame.size.height = (maxLines + 1) * singleLineHeight;
        inputField.frame = aFrame;
    }
    else
    {
        aFrame = inputField.frame;
        aFrame.size.height = 4800.0;
        inputField.frame = aFrame;
    }
    
    CGFloat minHeight = LIOInputBarViewMinHeight;
    if (padUI) minHeight = LIOInputBarViewMinHeightPad;
    
    aFrame = inputFieldBackground.frame;
    aFrame.size.height = singleLineHeight * calculatedNumLines + backgroundHeightMod;
    if (aFrame.size.height < minHeight) aFrame.size.height = minHeight;
    inputFieldBackground.frame = aFrame;
    if (padUI)
    {
        aFrame = inputField.frame;
        if (1 == totalLines) aFrame.origin.y = 17.0;
        else if (inputField.scrollEnabled)
        {
            aFrame.origin.y = 14.0;
            aFrame.size.height -= 5.0;
        }
        else aFrame.origin.y = 6.0;
        inputField.frame = aFrame;
    }
    else
    {
        aFrame = inputField.frame;
        if (1 == totalLines) aFrame.origin.y = 7.0;
        else if (inputField.scrollEnabled) aFrame.origin.y = 8.0;
        else aFrame.origin.y = 2.0;
        inputField.frame = aFrame;
    }
    
    CGFloat bottomPadding = 5.0;
    if (padUI)
        bottomPadding = 12.0;
    
    desiredHeight = inputFieldBackground.frame.origin.y + inputFieldBackground.frame.size.height + bottomPadding;
    [delegate inputBarView:self didChangeDesiredHeight:desiredHeight];
    
    int maxTextLength = LIOInputBarViewMaxTextLength;
    if (padUI)
        maxTextLength = LIOInputBarViewMaxTextLength_iPad;
    
    characterCount.text = [NSString stringWithFormat:@"(%lu/%u)", (unsigned long)[inputField.text length], maxTextLength];
    [characterCount sizeToFit];
    characterCount.hidden = totalLines < 3;
    
    if (padUI)
    {
        aFrame = characterCount.frame;
        aFrame.origin.x = (sendButton.frame.origin.x + (sendButton.frame.size.width / 2.0)) - (aFrame.size.width / 2.0);
        aFrame.origin.y = sendButton.frame.origin.y + sendButton.frame.size.height + 5.0;
        characterCount.frame = aFrame;
    }
    else
    {
        aFrame = characterCount.frame;
        aFrame.origin.x = (sendButton.frame.origin.x + (sendButton.frame.size.width / 2.0)) - (aFrame.size.width / 2.0);
        aFrame.origin.y = self.bounds.size.height - aFrame.size.height - 5.0;
        characterCount.frame = aFrame;
    }
    
    placeholderText.hidden = [inputField.text length] > 0;
}

- (void)revealNotificationString:(NSString *)aString withAnimatedKeyboard:(BOOL)animated permanently:(BOOL)permanent
{
    notificationArea.keyboardIconVisible = animated;
    [notificationArea revealNotificationString:aString permanently:permanent];
}

- (void)startPulseAnimation
{
    [pulseTimer stopTimer];
    [pulseTimer release];
    pulseTimer = [[LIOTimerProxy alloc] initWithTimeInterval:5.0 target:self selector:@selector(pulseTimerDidFire)];
    
    inputFieldBackgroundGlowing.hidden = NO;
    inputFieldBackgroundGlowing.alpha = 0.0;
    
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:(UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse)
                     animations:^{
                         inputFieldBackgroundGlowing.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                     }];
}

- (void)stopPulseAnimation
{
    [pulseTimer stopTimer];
    [pulseTimer release];
    pulseTimer = nil;
    
    [inputFieldBackgroundGlowing.layer removeAllAnimations];
    inputFieldBackgroundGlowing.hidden = YES;
    
    [delegate inputBarViewDidStopPulseAnimation:self];
}

- (void)pulseTimerDidFire
{
    [self stopPulseAnimation];
}

- (void)forceAcceptanceOfAutocorrect
{
    NSRange end = NSMakeRange([inputField.text length], 0);
    inputField.selectedRange = end;
}

#pragma mark -
#pragma mark UIControl actions

- (void)sendButtonWasTapped
{
    //[inputField resignFirstResponder];
    [self forceAcceptanceOfAutocorrect];
    NSString *text = inputField.text;
    inputField.text = [NSString string];
    [delegate inputBarView:self didReturnWithText:text];
    [self setNeedsLayout];
}

- (void)attachButtonWasTapped
{
    [delegate inputBarViewDidTapAttachButton:self];
}

#pragma mark -
#pragma mark Gesture handlers

- (void)handleAdAreaTap:(UITapGestureRecognizer *)aTapper
{
    [delegate inputBarViewDidTapAdArea:self];
}

#pragma mark -
#pragma mark UITextViewDelegate methods

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"])
    {
        [self sendButtonWasTapped];
        return NO;
    }
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)aTextView
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    int maxTextLength = LIOInputBarViewMaxTextLength;
    if (padUI)
        maxTextLength = LIOInputBarViewMaxTextLength_iPad;
    
    // Clamp the length.
    NSUInteger newLen = [aTextView.text length];
    if (newLen > maxTextLength)
    {
        NSString *newText = [aTextView.text substringToIndex:(maxTextLength - 1)];
        aTextView.text = newText;
        newLen = [newText length];
    }
    
    [self setNeedsLayout];
    
    [delegate inputBarViewDidTypeStuff:self];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    placeholderText.hidden = [inputField.text length] > 0;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    placeholderText.hidden = [inputField.text length] > 0;
}

@end
