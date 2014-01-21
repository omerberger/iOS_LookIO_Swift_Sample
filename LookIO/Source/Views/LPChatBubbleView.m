//
//  LPChatBubbleView.m
//  LookIO
//
//  Created by Yaron Karasik on 12/20/13.
//
//

#import "LPChatBubbleView.h"
#import "LIOBrandingManager.h"

@interface LPChatBubbleView () <UIGestureRecognizerDelegate>

@end

@implementation LPChatBubbleView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.layer.cornerRadius = 10.0;
        
        self.messageLabel = [[TTTAttributedLabel_LIO alloc] initWithFrame:CGRectMake(10, 0, self.bounds.size.width, self.bounds.size.height)];
        self.messageLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.messageLabel.textColor = [UIColor colorWithWhite:79.0/255.0 alpha:1.0];
        self.messageLabel.textAlignment = NSTextAlignmentLeft;
        self.messageLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:self.messageLabel];
        
        UILongPressGestureRecognizer *aLongPresser = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        aLongPresser.delegate = self;
        [self addGestureRecognizer:aLongPresser];
    }
    
    return self;
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
    [UIPasteboard generalPasteboard].string = self.messageLabel.text;
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

- (void)enterCopyModeAnimated:(BOOL)animated
{
    if (animated)
        [self performBounceAnimation];
    
    [self becomeFirstResponder];
    
    CGRect targetFrame = CGRectMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0, 0.0, 0.0);
    UIMenuController *menu = [UIMenuController sharedMenuController];
    menu.arrowDirection = UIMenuControllerArrowUp;
    [menu setTargetRect:targetFrame inView:self];
    [menu setMenuVisible:YES animated:YES];
}

#pragma mark -
#pragma mark Gesture handlers

- (void)handleLongPress:(UILongPressGestureRecognizer *)aLongPresser
{
    if (aLongPresser.state == UIGestureRecognizerStateBegan)
        [self enterCopyModeAnimated:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
