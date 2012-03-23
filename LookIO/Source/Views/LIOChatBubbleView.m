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
#import "TTTAttributedLabel.h"

@implementation LIOChatBubbleView

@synthesize senderName;
@dynamic formattingMode;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        UIImage *stretchableBubble = [lookioImage(@"LIOStretchableChatBubble") stretchableImageWithLeftCapWidth:16 topCapHeight:36];
        backgroundImage = [[UIImageView alloc] initWithImage:stretchableBubble];
        [self addSubview:backgroundImage];
        
        messageView = [[TTTAttributedLabel_LIO alloc] initWithFrame:self.bounds];
        messageView.delegate = self;
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://555.555.5555"]])
            messageView.dataDetectorTypes = UIDataDetectorTypeLink | UIDataDetectorTypePhoneNumber;
        else
            messageView.dataDetectorTypes = UIDataDetectorTypeLink;
        messageView.font = [UIFont systemFontOfSize:16.0];
        messageView.layer.shadowColor = [UIColor blackColor].CGColor;
        messageView.layer.shadowRadius = 1.0;
        messageView.layer.shadowOpacity = 1.0;
        messageView.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        messageView.backgroundColor = [UIColor clearColor];
        messageView.textColor = [UIColor whiteColor];
        messageView.numberOfLines = 0;
        [self addSubview:messageView];
        
        UILongPressGestureRecognizer *aLongPresser = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)] autorelease];
        [self addGestureRecognizer:aLongPresser];
    }
    
    return self;
}

- (void)dealloc
{
    [messageView release];
    [backgroundImage release];
    [senderName release];
    
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
        
    CGSize maxSize = CGSizeMake(LIOChatBubbleViewMaxTextWidth, FLT_MAX);
    CGSize boxSize = [messageView sizeThatFits:maxSize];
    messageView.frame = CGRectMake(20.0, 10.0, boxSize.width, boxSize.height);
    
    // This feels really wrong. >______>!
    CGRect aFrame = self.frame;
    aFrame.size.height = boxSize.height + 30.0;
    if (aFrame.size.height < LIOChatBubbleViewMinTextHeight) aFrame.size.height = LIOChatBubbleViewMinTextHeight;
    self.frame = aFrame;
    
    backgroundImage.frame = self.bounds;
}

- (void)populateMessageViewWithText:(NSString *)aString
{
    [messageView setText:aString afterInheritingLabelAttributesAndConfiguringWithBlock:^ NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        
        if (0 == [senderName length])
            return mutableAttributedString;
        
        NSAttributedString *nameCallout = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ", senderName]];
        [mutableAttributedString insertAttributedString:nameCallout atIndex:0];
        
        NSRange boldRange = NSMakeRange(0, [nameCallout length]);
        
        UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:16.0]; 
        CTFontRef font = CTFontCreateWithName((CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
        if (font && boldRange.location != NSNotFound)
        {
            [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)font range:boldRange];
            [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)[UIColor whiteColor].CGColor range:boldRange];
            CFRelease(font);
        }
        
        return mutableAttributedString;
    }];    
    
    [self layoutSubviews];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return action == @selector(copy:);
}

- (void)copy:(id)sender
{
    [UIPasteboard generalPasteboard].string = messageView.text;
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

- (void)performBounceAnimation
{
    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.transform = CGAffineTransformMakeScale(1.2, 1.2);
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.25
                                               delay:0.0
                                             options:UIViewAnimationOptionCurveEaseInOut
                                          animations:^{
                                              self.transform = CGAffineTransformMakeScale(0.97, 0.97);
                                          }
                                          completion:^(BOOL finished) {
                                              [UIView animateWithDuration:0.15
                                                                    delay:0.0
                                                                  options:UIViewAnimationOptionCurveEaseIn
                                                               animations:^{
                                                                   self.transform = CGAffineTransformIdentity;
                                                               }
                                                               completion:^(BOOL finished) {
                                                               }];
                                          }];
                     }];
}

#pragma mark -
#pragma mark Gesture handlers

- (void)handleLongPress:(UILongPressGestureRecognizer *)aLongPresser
{
    if (aLongPresser.state == UIGestureRecognizerStateBegan)
    {
        CGRect targetFrame = CGRectMake(self.frame.size.width / 2.0, self.frame.size.height / 2.0, 0.0, 0.0);
        
        [self becomeFirstResponder];
        
        [self performBounceAnimation];
        
        UIMenuController *menu = [UIMenuController sharedMenuController];
        menu.arrowDirection = UIMenuControllerArrowUp;
        [menu setTargetRect:targetFrame inView:self];
        [menu setMenuVisible:YES animated:YES];
    }
}

#pragma mark -
#pragma mark TTTAttributedLabelDelegate methods

- (void)attributedLabel:(TTTAttributedLabel_LIO *)label didSelectLinkWithURL:(NSURL *)url
{
    [[UIApplication sharedApplication] openURL:url];
}

- (void)attributedLabel:(TTTAttributedLabel_LIO *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber
{
    NSURL *phoneUrl = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", phoneNumber]];
    [[UIApplication sharedApplication] openURL:phoneUrl];
}

@end