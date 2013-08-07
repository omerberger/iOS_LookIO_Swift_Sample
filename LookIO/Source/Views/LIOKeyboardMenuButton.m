//
//  LIOKeyboardMenuButton.m
//  LookIO
//
//  Created by Yaron Karasik on 8/7/13.
//
//

#import "LIOKeyboardMenuButton.h"

@implementation LIOKeyboardMenuButton;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        bottomLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        bottomLabel.textColor = [UIColor colorWithRed:182.0/255.0 green:178.0/255.0 blue:174.0/255.0 alpha:1.0];
        bottomLabel.font = [UIFont boldSystemFontOfSize:13.0];
        bottomLabel.backgroundColor = [UIColor clearColor];
        bottomLabel.textAlignment = UITextAlignmentCenter;
        bottomLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:bottomLabel];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect aFrame = self.imageView.frame;
    aFrame.origin.x = self.bounds.size.width/2 - aFrame.size.width/2;
    aFrame.origin.y = 0.22 * self.bounds.size.height;
    self.imageView.frame = aFrame;
    
    aFrame = bottomLabel.frame;
    aFrame.origin.x = 0;
    aFrame.origin.y = 0.65 * self.bounds.size.height;
    aFrame.size.width = self.bounds.size.width;
    aFrame.size.height = 18.0;
    bottomLabel.frame = aFrame;
    
}

-(void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (highlighted)
        bottomLabel.textColor = [UIColor grayColor];
    else
        bottomLabel.textColor = [UIColor colorWithRed:182.0/255.0 green:178.0/255.0 blue:174.0/255.0 alpha:1.0];
    
}

-(void)setBottomLabelText:(NSString*)text {
    bottomLabel.text = text;
}


@end
