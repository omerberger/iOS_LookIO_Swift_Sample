//
//  LIOChatBubbleView.m
//  LookIO
//
//  Created by Joseph Toscano on 12/5/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import "LIOChatBubbleView.h"
#import <QuartzCore/QuartzCore.h>
#import "LIOLookIOManager.h"

@implementation LIOChatBubbleView

@dynamic formattingMode;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        UIImage *stretchableBubble = [lookioImage(@"LIOStretchableChatBubble") stretchableImageWithLeftCapWidth:16 topCapHeight:36];
        backgroundImage = [[UIImageView alloc] initWithImage:stretchableBubble];
        [self addSubview:backgroundImage];
                                      
        messageView = [[UILabel alloc] initWithFrame:self.bounds];
        messageView.layer.shadowColor = [UIColor blackColor].CGColor;
        messageView.layer.shadowRadius = 1.0;
        messageView.layer.shadowOpacity = 1.0;
        messageView.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        messageView.backgroundColor = [UIColor clearColor];
        messageView.textColor = [UIColor whiteColor];
        [self addSubview:messageView];
        
        UILongPressGestureRecognizer *longPresser = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)] autorelease];
        [self addGestureRecognizer:longPresser];
    }
    
    return self;
}

- (void)dealloc
{
    [messageView release];
    [backgroundImage release];
    
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (LIOChatBubbleViewFormattingModeRemote == formattingMode)
    {
        messageView.font = [UIFont systemFontOfSize:16.0];
    }
    else
    {
        messageView.font = [UIFont boldSystemFontOfSize:16.0];
    }
    
    CGSize maxSize = CGSizeMake(LIOChatBubbleViewMaxTextWidth, FLT_MAX);
    CGSize boxSize = [messageView.text sizeWithFont:messageView.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    messageView.numberOfLines = 0;
    messageView.frame = CGRectMake(20.0, 10.0, boxSize.width, boxSize.height + 5.0);
    
    // This feels really wrong. >______>!
    CGRect aFrame = self.frame;
    aFrame.size.height = boxSize.height + 23.0;
    if (aFrame.size.height < LIOChatBubbleViewMinTextHeight) aFrame.size.height = LIOChatBubbleViewMinTextHeight;
    self.frame = aFrame;
    
    backgroundImage.frame = self.bounds;
}

- (void)populateMessageViewWithText:(NSString *)aString
{
    messageView.text = aString;
    [self layoutSubviews];
}

#pragma mark -
#pragma mark Dynamic accessor methods

- (LIOChatBubbleViewFormattingMode)formattingMode
{
    return formattingMode;
}

- (void)setFormattingMode:(LIOChatBubbleViewFormattingMode)aMode
{
    formattingMode = aMode;
    [self setNeedsLayout];
}

#pragma mark -
#pragma mark Gesture handlers

- (void)handleLongPress:(UILongPressGestureRecognizer *)aLongPresser
{
    
}

@end