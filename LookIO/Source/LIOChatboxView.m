//
//  LIOChatboxView.m
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "LIOChatboxView.h"

@implementation LIOChatboxView

@synthesize messageView, canTakeInput, delegate, inputField;

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
        inputField = [[UITextField alloc] initWithFrame:CGRectMake(10.0, frame.size.height - (size.height + 10.0), frame.size.width - 20.0, size.height)];
        inputField.font = messageView.font;
        inputField.backgroundColor = [UIColor whiteColor];
        inputField.hidden = YES;
        inputField.delegate = self;
        inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:inputField];
        
        UIButton *buttonOverlay = [UIButton buttonWithType:UIButtonTypeCustom];
        buttonOverlay.frame = self.bounds;
        [buttonOverlay addTarget:self action:@selector(buttonOverlayWasTapped) forControlEvents:UIControlEventTouchUpInside];
        buttonOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:buttonOverlay];
    }
    
    return self;
}

- (void)dealloc
{
    [inputField release];
    [bubbleView release];
    [messageView release];
    
    [super dealloc];
}

- (void)takeInput
{
    inputField.hidden = NO;
    [inputField becomeFirstResponder];
}

#pragma mark -
#pragma mark UIControl actions

- (void)buttonOverlayWasTapped
{
    if (canTakeInput && NO == [self isFirstResponder])
        [self takeInput];
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
    
    inputField.hidden = YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [delegate chatboxViewDidReturn:self withText:textField.text];
    
    return YES;
}

@end
