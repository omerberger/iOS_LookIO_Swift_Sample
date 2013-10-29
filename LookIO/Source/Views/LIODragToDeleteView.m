//
//  LIODragToDeleteView.m
//  LookIO
//
//  Created by Yaron Karasik on 10/29/13.
//
//

#import "LIODragToDeleteView.h"
#import "LIOAltChatViewController.h"

@implementation LIODragToDeleteView

@synthesize isZoomedIn;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CGColorRef darkColor = [UIColor colorWithWhite:0.1 alpha:0.7].CGColor;
        CGColorRef lightColor = [UIColor colorWithWhite:0.1 alpha:0.0].CGColor;

        LIOGradientLayer *vertGradient = [[LIOGradientLayer alloc] init];
        vertGradient.colors = [NSArray arrayWithObjects:(id)lightColor, (id)darkColor, nil];
        vertGradient.backgroundColor = [UIColor clearColor].CGColor;
        vertGradient.frame = self.bounds;
    
        [self.layer addSublayer:vertGradient];
        
        deleteLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.bounds.size.width/2 - self.bounds.size.height/4, self.bounds.size.height*3/16, self.bounds.size.height/2, self.bounds.size.height/2)];
        deleteLabel.backgroundColor = [UIColor whiteColor];
        deleteLabel.layer.cornerRadius = self.bounds.size.height/4;
        deleteLabel.textColor = [UIColor redColor];
        deleteLabel.text = @"X";
        deleteLabel.font = [UIFont systemFontOfSize:30.0];
        deleteLabel.textAlignment = UITextAlignmentCenter;
        [self addSubview:deleteLabel];
    }
    return self;
}

- (void)zoomInOnDeleteArea {
    self.isZoomedIn = YES;
    [UIView animateWithDuration:0.2 animations:^{
         deleteLabel.transform = CGAffineTransformMakeScale(1.3, 1.3);
    }];
}

- (void)zoomOutOfDeleteArea {
    self.isZoomedIn = NO;
    [UIView animateWithDuration:0.2 animations:^{
        deleteLabel.transform = CGAffineTransformIdentity;
    }];
}


@end
