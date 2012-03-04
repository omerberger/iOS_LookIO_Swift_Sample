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
        messageView.font = [UIFont systemFontOfSize:16.0];
        messageView.layer.shadowColor = [UIColor blackColor].CGColor;
        messageView.layer.shadowRadius = 1.0;
        messageView.layer.shadowOpacity = 1.0;
        messageView.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        messageView.backgroundColor = [UIColor clearColor];
        messageView.textColor = [UIColor whiteColor];
        [self addSubview:messageView];
        
        copiedLabel = [[UILabel alloc] init];
        copiedLabel.backgroundColor = [UIColor whiteColor];
        copiedLabel.textColor = [UIColor blackColor];
        copiedLabel.font = [UIFont boldSystemFontOfSize:18.0];
        copiedLabel.text = @"Copied!";
        [copiedLabel sizeToFit];
        copiedLabel.hidden = YES;
        copiedLabel.layer.cornerRadius = 3.0;
        copiedLabel.clipsToBounds = YES;
        [self addSubview:copiedLabel];
        
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
        
    CGSize maxSize = CGSizeMake(LIOChatBubbleViewMaxTextWidth, FLT_MAX);
    CGSize boxSize = [messageView.text sizeWithFont:messageView.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    messageView.numberOfLines = 0;
    messageView.frame = CGRectMake(20.0, 10.0, boxSize.width, boxSize.height);
    
    // This feels really wrong. >______>!
    CGRect aFrame = self.frame;
    aFrame.size.height = boxSize.height + 30.0;
    if (aFrame.size.height < LIOChatBubbleViewMinTextHeight) aFrame.size.height = LIOChatBubbleViewMinTextHeight;
    self.frame = aFrame;
    
    backgroundImage.frame = self.bounds;
    
    aFrame = copiedLabel.frame;
    aFrame.origin.x = (self.frame.size.width / 2.0) - (copiedLabel.frame.size.width / 2.0);
    aFrame.origin.y = (self.frame.size.height / 2.0) - (copiedLabel.frame.size.height / 2.0);
    copiedLabel.frame = aFrame;
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
    if (aLongPresser.state != UIGestureRecognizerStateBegan)
        return;
    
    copiedLabel.alpha = 0.0;
    copiedLabel.hidden = NO;
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.transform = CGAffineTransformMakeScale(1.5, 1.5);
                         copiedLabel.alpha = 1.0;
                         messageView.alpha = 0.5;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.3
                                               delay:0.0
                                             options:UIViewAnimationOptionCurveEaseInOut
                                          animations:^{
                                              self.transform = CGAffineTransformMakeScale(0.9, 0.9);
                                          }
                                          completion:^(BOOL finished) {
                                              [UIView animateWithDuration:0.2
                                                                    delay:0.0
                                                                  options:UIViewAnimationOptionCurveEaseIn
                                                               animations:^{
                                                                   self.transform = CGAffineTransformIdentity;
                                                                   copiedLabel.alpha = 0.0;
                                                                   messageView.alpha = 1.0;
                                                               }
                                                               completion:^(BOOL finished) {
                                                                   copiedLabel.hidden = YES;
                                                               }];
                                          }];
                     }];

    [UIPasteboard generalPasteboard].string = messageView.text;
}

@end