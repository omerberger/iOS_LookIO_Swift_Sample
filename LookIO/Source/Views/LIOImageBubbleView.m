//
//  LIOImageBubbleView.m
//  LookIO
//
//  Created by Yaron Karasik on 7/19/13.
//
//

#import "LIOImageBubbleView.h"
#import "LIOMediaManager.h"

@implementation LIOImageBubbleView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code        
        UILongPressGestureRecognizer *aLongPresser = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)] autorelease];
        [self addGestureRecognizer:aLongPresser];
        
        self.userInteractionEnabled = YES;
        isBouncing = NO;
    }
    return self;
}

- (void)performBounceAnimation {
    
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
                                                                   isBouncing = NO;
                                                               }];
                                          }];
                     }];
}

- (void)enterCopyModeAnimated:(BOOL)animated
{
    [self becomeFirstResponder];
    
    CGRect targetFrame = CGRectMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0, 0.0, 0.0);
    UIMenuController *menu = [UIMenuController sharedMenuController];
    UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:@"Save Image" action:@selector(saveImage:)];
    [menu setMenuItems:[NSArray arrayWithObject:menuItem]];
    [menuItem release];
    menu.arrowDirection = UIMenuControllerArrowUp;
    [menu setTargetRect:targetFrame inView:self];
    [menu setMenuVisible:YES animated:YES];
    
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(saveImage:)) {
        return YES;
    }
    return NO;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)saveImage:(id)sender {
    UIImageWriteToSavedPhotosAlbum(self.image, nil, nil, nil);
}

- (void)handleLongPress:(id)sender
{
    if (isBouncing)
        return;
    isBouncing = YES;
    [self performBounceAnimation];
    
    [self enterCopyModeAnimated:YES];

}

@end
