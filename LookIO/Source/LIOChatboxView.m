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

@synthesize messageView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        bubbleView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, frame.size.height)];
        bubbleView.backgroundColor = [UIColor blackColor];
        bubbleView.alpha = 0.75;
        bubbleView.layer.masksToBounds = YES;
        bubbleView.layer.cornerRadius = 0.4;
        [self addSubview:bubbleView];
        
        messageView = [[UITextView alloc] initWithFrame:bubbleView.bounds];
        messageView.backgroundColor = [UIColor clearColor];
        messageView.textColor = [UIColor whiteColor];
        [self addSubview:messageView];
        
        CGSize size = [@"Test" sizeWithFont:[UIFont systemFontOfSize:12.0]];
        inputField = [[UITextField alloc] initWithFrame:CGRectMake(5.0, frame.size.height - (size.height + 5.0), frame.size.width - 1.0, size.height)];
        inputField.backgroundColor = [UIColor whiteColor];
        inputField.hidden = YES;
        [self addSubview:inputField];
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
#pragma mark UITextFieldDelegate methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    CGRect aFrame = messageView.frame;
    aFrame.origin.y -= inputField.frame.size.height;
    aFrame.size.height -= inputField.frame.size.height;
    messageView.frame = aFrame;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    CGRect aFrame = messageView.frame;
    aFrame.origin.y += inputField.frame.size.height;
    aFrame.size.height += inputField.frame.size.height;
    messageView.frame = aFrame;
    
    inputField.hidden = YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    return YES;
}

@end
