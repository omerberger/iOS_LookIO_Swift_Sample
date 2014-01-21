//
//  LPChatImageView.m
//  LookIO
//
//  Created by Yaron Karasik on 1/13/14.
//
//

#import "LPChatImageView.h"

#import "LIOBundleManager.h"

@interface LPChatImageView () <UIGestureRecognizerDelegate>

@property (nonatomic, assign) BOOL isBouncing;

@end

@implementation LPChatImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 10.0;
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.layer.masksToBounds = YES;
        self.imageView.layer.cornerRadius = 10.0;
        
        [self addSubview:self.imageView];

        UIImage *stretchableShadow = stretchableShadow = [[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchablePhotoShadow"] stretchableImageWithLeftCapWidth:42 topCapHeight:62];
        self.foregroundImageView = [[UIImageView alloc] initWithImage:stretchableShadow];
        self.foregroundImageView.frame = self.bounds;
        self.foregroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;        
//        [self addSubview:self.foregroundImageView];

        UILongPressGestureRecognizer *aLongPresser = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)] autorelease];
        aLongPresser.delegate = self;
        [self addGestureRecognizer:aLongPresser];
        
        self.userInteractionEnabled = YES;
        self.isBouncing = NO;
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
                                                                   self.isBouncing = NO;
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

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(saveImage:)) {
        return YES;
    }
    return NO;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)saveImage:(id)sender
{
    UIImageWriteToSavedPhotosAlbum(self.imageView.image, nil, nil, nil);
}

#pragma mark -
#pragma mark Gesture handlers

- (void)handleLongPress:(id)sender
{
    if (self.isBouncing)
        return;
    self.isBouncing = YES;
    [self performBounceAnimation];
    
    [self enterCopyModeAnimated:YES];
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}


@end

