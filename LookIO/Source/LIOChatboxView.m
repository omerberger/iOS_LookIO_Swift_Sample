//
//  LIOChatboxView.m
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "LIOChatboxView.h"
#import "LIOSexuallyAppealingTextField.h"

@implementation LIOChatboxView

@synthesize messageView, canTakeInput, delegate, inputField, sendButton;

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
        bubbleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:bubbleView];
        
        CGRect aFrame = bubbleView.bounds;
        aFrame.origin.x = 5.0;
        aFrame.size.width = aFrame.size.width - 10.0;
        aFrame.origin.y = 5.0;
        aFrame.size.height = aFrame.size.height - 10.0;
        
        messageView = [[UITextView alloc] initWithFrame:aFrame];
        messageView.backgroundColor = [UIColor clearColor];
        messageView.textColor = [UIColor whiteColor];
        messageView.font = [UIFont systemFontOfSize:14.0];
        messageView.editable = NO;
        messageView.scrollEnabled = NO;
        messageView.clipsToBounds = YES;
        messageView.layer.shadowColor = [UIColor blackColor].CGColor;
        messageView.layer.shadowOpacity = 1.0;
        messageView.layer.shadowOffset = CGSizeMake(2.0, 2.0);
        messageView.layer.shadowRadius = 1.0;
        messageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:messageView];
        
        CGSize size = [@"jpqQABTY" sizeWithFont:messageView.font];
        size.height = 24.0;
        inputField = [[LIOSexuallyAppealingTextField alloc] initWithFrame:CGRectMake(10.0, frame.size.height - (size.height + 15.0), frame.size.width - 87.0, size.height + 5.0)];
        inputField.font = messageView.font;
        inputField.delegate = self;
        inputField.placeholder = @"Tap here to chat";
        inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        inputField.returnKeyType = UIReturnKeySend;
        inputField.hidden = YES;
        [self addSubview:inputField];
        
        sendButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        [sendButton setBackgroundImage:[UIImage imageNamed:@"LIOSendActive"] forState:UIControlStateNormal];
        sendButton.frame = CGRectMake(inputField.frame.origin.x + inputField.frame.size.width + 6.0, inputField.frame.origin.y + 1.0, 59.0, 27.0);
        [sendButton addTarget:self action:@selector(sendButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
        sendButton.hidden = YES;
        [self addSubview:sendButton];
    }
    
    return self;
}

- (void)dealloc
{
    [inputField release];
    [bubbleView release];
    [messageView release];
    [sendButton release];
    
    [super dealloc];
}

- (void)takeInput
{
    [inputField becomeFirstResponder];
}

#pragma mark -
#pragma mark UIControl actions

/*
- (void)buttonOverlayWasTapped
{
    if (canTakeInput && NO == [self isFirstResponder])
        [self takeInput];
}
*/

- (void)sendButtonWasTapped
{
    NSString *text = inputField.text;
    inputField.text = [NSString string];
    [delegate chatboxViewDidReturn:self withText:text];
}

#pragma mark -
#pragma mark UITextFieldDelegate methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    CGRect aFrame = messageView.frame;
    //aFrame.origin.y -= inputField.frame.size.height;
    aFrame.size.height -= inputField.frame.size.height;
    messageView.frame = aFrame;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    CGRect aFrame = messageView.frame;
    //aFrame.origin.y += inputField.frame.size.height;
    aFrame.size.height += inputField.frame.size.height;
    messageView.frame = aFrame;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self sendButtonWasTapped];
    
    return YES;
}

@end
