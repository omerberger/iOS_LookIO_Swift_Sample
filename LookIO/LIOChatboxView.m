//
//  LIOChatboxView.m
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "LIOChatboxView.h"

@implementation LIOChatboxView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        /*
        CGRect aFrame = CGRectZero;
        aFrame.size.width = frame.size.width;
        aFrame.size.height = frame.size.height * 0.75;
         */
        historyView = [[UITextView alloc] initWithFrame:frame];
        historyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        historyView.text = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut at diam. Sed odio odio, aliquet ac, luctus ac, suscipit sit amet, sem. Nulla jus";
        [self addSubview:historyView];
        
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

#pragma mark -
#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    return YES;
}

@end
