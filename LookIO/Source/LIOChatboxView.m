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
        
        CGSize size = [@"jpqQABTY" sizeWithFont:messageView.font];
        size.height = 24.0;
        inputField = [[LIONiceTextField alloc] initWithFrame:CGRectMake(10.0, frame.size.height - (size.height + 15.0), frame.size.width - 87.0, size.height + 5.0)];
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
        
        Class $UIGlassButton = NSClassFromString(@"UIGlassButton");
        
        settingsButton = [[$UIGlassButton alloc] initWithFrame:CGRectZero];
        [settingsButton setImage:[UIImage imageNamed:@"LIOSettingsIcon"] forState:UIControlStateNormal];
        [settingsButton setTintColor:[UIColor colorWithWhite:0.1 alpha:1.0]];
        //[settingsButton imageView].contentMode = 
        //[settingsButton sizeToFit];
        [settingsButton addTarget:self action:@selector(settingsButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
        aFrame = CGRectZero;
        aFrame.size.width = 40.0;
        aFrame.size.height = 40.0;
        aFrame.origin.x = self.frame.size.width - aFrame.size.width - 7.0;
        aFrame.origin.y = 7.0;
        [settingsButton setFrame:aFrame];
        [settingsButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
        //[settingsButton layer].shadowColor = [UIColor whiteColor].CGColor;
        //[settingsButton layer].shadowOpacity = 0.7;
        //[settingsButton layer].shadowOffset = CGSizeMake(0.0, 1.0);
        //[settingsButton layer].shadowRadius = 1.0;
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
    
    [super dealloc];
}

- (void)populateMessageViewWithText:(NSString *)aString
{
    CGSize maxSize = CGSizeMake(inputField.frame.size.width, FLT_MAX);
    CGSize boxSize = [aString sizeWithFont:messageView.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    messageView.text = aString;
    messageView.numberOfLines = 0;
    messageView.frame = CGRectMake(10.0, 10.0, boxSize.width, boxSize.height);
    
    //CGRectMake(10.0, frame.size.height - (size.height + 15.0), frame.size.width - 87.0, size.height + 5.0)    
    CGRect aFrame = inputField.frame;
    aFrame.origin.y = messageView.frame.origin.y + messageView.frame.size.height + 5.0;
    inputField.frame = aFrame;
    
    sendButton.frame = CGRectMake(inputField.frame.origin.x + inputField.frame.size.width + 6.0, inputField.frame.origin.y + 1.0, 59.0, 27.0);
    
    aFrame = self.frame;
    aFrame.size.height = boxSize.height + 10.0 + inputField.frame.size.height + 10.0 + 5.0;
    self.frame = aFrame;
    
    // This is pretty dumb!
    if (aFrame.size.height < LIOChatboxViewMinHeight)
    {
        aFrame = self.frame;
        aFrame.size.height = LIOChatboxViewMinHeight;
        self.frame = aFrame;
        
        aFrame = inputField.frame;
        aFrame.origin.y = self.frame.size.height - aFrame.size.height - 10.0;
        inputField.frame = aFrame;
        
        sendButton.frame = CGRectMake(inputField.frame.origin.x + inputField.frame.size.width + 6.0, inputField.frame.origin.y + 1.0, 59.0, 27.0);    
    }
}

#pragma mark -
#pragma mark UIControl actions

- (void)sendButtonWasTapped
{
    NSString *text = inputField.text;
    inputField.text = [NSString string];
    [delegate chatboxView:self didReturnWithText:text];
}

- (void)settingsButtonWasTapped
{
    [delegate chatboxViewDidTapSettingsButton:self];
}

#pragma mark -
#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self sendButtonWasTapped];
    
    return YES;
}

@end
