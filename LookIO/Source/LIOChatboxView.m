//
//  LIOChatboxView.m
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import "LIOChatboxView.h"

@implementation LIOChatboxView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.alpha = 0.8;
        
        CGRect aFrame = CGRectZero;
        aFrame.size.width = frame.size.width;
        aFrame.size.height = frame.size.height;
        historyView = [[UITextView alloc] initWithFrame:aFrame];
        historyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        historyView.font = [UIFont systemFontOfSize:16.0];
        //historyView.text = @"oh\nhi\nthere";
        historyView.backgroundColor = [UIColor whiteColor];
        historyView.editable = NO;
        historyView.scrollEnabled = YES;
        historyView.contentInset = UIEdgeInsetsMake(2.0, 5.0, 2.0, 5.0);
        [self addSubview:historyView];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.backgroundColor = [UIColor clearColor];
        button.frame = historyView.frame;
        button.autoresizingMask = historyView.autoresizingMask;
        button.backgroundColor = [UIColor clearColor];
        [button addTarget:self action:@selector(buttonWasTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        
        /*
        aFrame = CGRectZero;
        inputField = [[UITextField alloc] initWithFrame:aFrame];
        inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        inputField.delegate = self;
        [self addSubview:inputField];
         */
    }
    
    return self;
}

- (void)dealloc
{
    [historyView release];
    [inputField release];
    
    [super dealloc];
}

- (void)addText:(NSString *)someText
{
    historyView.text = [NSString stringWithFormat:@"%@\n%@", historyView.text, someText];    
    
    CGFloat offsetY = historyView.contentSize.height - 20.0;
    if (offsetY < 0) offsetY = 0;
    [historyView scrollRectToVisible:CGRectMake(0.0, offsetY, historyView.contentSize.width, 20.0) animated:NO];
}

- (void)buttonWasTapped
{
    [delegate chatboxViewWasTapped:self];
}

#pragma mark -
#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    return YES;
}

@end
