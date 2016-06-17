//
//  LIODragToDeleteView.m
//  LookIO
//
//  Created by Yaron Karasik on 10/29/13.
//
//

#import "LIODragToDeleteView.h"

@implementation LIODragToDeleteView

@synthesize isZoomedIn, deleteLabel;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.alpha = 0.0;
        
        CGColorRef darkColor = [UIColor colorWithWhite:0.1 alpha:0.5].CGColor;
        CGColorRef lightColor = [UIColor colorWithWhite:0.1 alpha:0.0].CGColor;

        vertGradient = [[LIOGradientLayer alloc] init];
        vertGradient.colors = [NSArray arrayWithObjects:(id)lightColor, (id)darkColor, nil];
        vertGradient.backgroundColor = [UIColor clearColor].CGColor;
        vertGradient.frame = self.bounds;
    
        [self.layer addSublayer:vertGradient];
        
        deleteLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.bounds.size.width/2 - self.bounds.size.height/4, self.bounds.size.height*5/32, self.bounds.size.height/2, self.bounds.size.height/2)];
        deleteLabel.backgroundColor = [UIColor whiteColor];
        deleteLabel.layer.cornerRadius = self.bounds.size.height/4;
        deleteLabel.textColor = [UIColor redColor];
        deleteLabel.text = @"X";
        deleteLabel.font = [UIFont systemFontOfSize:25.0];
        deleteLabel.textAlignment = UITextAlignmentCenter;
        deleteLabel.alpha = 0.7;
        deleteLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:deleteLabel];
        
        dragHereLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.bounds.size.width/2 - 75, self.bounds.size.height*23/32, 150, 13.0)];
        dragHereLabel.text = @"Drag here to hide";
        dragHereLabel.textAlignment = UITextAlignmentCenter;
        dragHereLabel.alpha = 0.0;
        dragHereLabel.backgroundColor = [UIColor clearColor];
        dragHereLabel.font = [UIFont boldSystemFontOfSize:12.0];
        dragHereLabel.textColor = [UIColor whiteColor];
        dragHereLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        [self addSubview:dragHereLabel];
    }
    return self;
}

- (void)layoutSubviews {
    vertGradient.frame = self.bounds;
}

- (void)presentDeleteArea {
    UIInterfaceOrientation actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect frame = self.frame;
        if (UIInterfaceOrientationLandscapeLeft == actualInterfaceOrientation)
            frame.origin.x -= 110;
        if (UIInterfaceOrientationLandscapeRight == actualInterfaceOrientation)
            frame.origin.x += 110;
        if (UIInterfaceOrientationPortrait == actualInterfaceOrientation)
            frame.origin.y -= 110;
        if (UIInterfaceOrientationPortraitUpsideDown == actualInterfaceOrientation)
            frame.origin.y += 110;
        self.frame = frame;
        
        self.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            CGRect frame = self.frame;
            if (UIInterfaceOrientationLandscapeLeft == actualInterfaceOrientation)
                frame.origin.x += 10;
            if (UIInterfaceOrientationLandscapeRight == actualInterfaceOrientation)
                frame.origin.x -= 10;
            if (UIInterfaceOrientationPortrait == actualInterfaceOrientation)
                frame.origin.y += 10;
            if (UIInterfaceOrientationPortraitUpsideDown == actualInterfaceOrientation)
                frame.origin.y -= 10;
            self.frame = frame;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 delay:0.2 options:UIViewAnimationOptionCurveLinear animations:^{
                dragHereLabel.alpha = 1.0;
            } completion:nil];
        }];
    }];
}

- (void)dismissDeleteArea {
    UIInterfaceOrientation actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];

    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect frame = self.frame;

        if (UIInterfaceOrientationLandscapeLeft == actualInterfaceOrientation)
            frame.origin.x += 100;
        if (UIInterfaceOrientationLandscapeRight == actualInterfaceOrientation)
            frame.origin.x -= 100;
        if (UIInterfaceOrientationPortrait == actualInterfaceOrientation)
            frame.origin.y += 100;
        if (UIInterfaceOrientationPortraitUpsideDown == actualInterfaceOrientation)
            frame.origin.y -= 100;

        self.frame = frame;
        
        self.alpha = 0.0;
        dragHereLabel.alpha = 0.0;
    } completion:nil];
}

- (void)zoomInOnDeleteArea {
    self.isZoomedIn = YES;
    [UIView animateWithDuration:0.2 animations:^{
        deleteLabel.transform = CGAffineTransformMakeScale(1.4, 1.4);
        dragHereLabel.transform = CGAffineTransformMakeTranslation(0.0, 7.0);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            deleteLabel.transform = CGAffineTransformMakeScale(1.2, 1.2);
            dragHereLabel.transform = CGAffineTransformMakeTranslation(0.0, 5.0);
        }];
    }];
}

- (void)zoomOutOfDeleteArea {
    self.isZoomedIn = NO;
    [UIView animateWithDuration:0.2 animations:^{
        deleteLabel.transform = CGAffineTransformMakeScale(0.9, 0.9);
        dragHereLabel.transform = CGAffineTransformMakeTranslation(0.0, -2.0);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            dragHereLabel.transform = CGAffineTransformIdentity;
            deleteLabel.transform = CGAffineTransformIdentity;
        }];
    }];
}


@end
