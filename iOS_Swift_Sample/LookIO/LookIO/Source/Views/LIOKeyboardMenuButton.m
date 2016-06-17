//
//  LIOKeyboardMenuButton.m
//  LookIO
//
//  Created by Yaron Karasik on 8/7/13.
//
//

#import "LIOKeyboardMenuButton.h"
#import "LIOBrandingManager.h"

@interface LIOKeyboardMenuButton ()

@property (nonatomic, strong) UILabel *bottomLabel;

@end

@implementation LIOKeyboardMenuButton;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.bottomLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.bottomLabel.font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementKeyboardMenu];
        self.bottomLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementKeyboardMenu];
        self.bottomLabel.backgroundColor = [UIColor clearColor];
        self.bottomLabel.textAlignment = UITextAlignmentCenter;
        self.bottomLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:self.bottomLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect aFrame = self.imageView.frame;
    aFrame.origin.x = self.bounds.size.width/2 - aFrame.size.width/2;
    aFrame.origin.y = 0.22 * self.bounds.size.height;
    self.imageView.frame = aFrame;
    
    CGSize expectedSize = [self.bottomLabel.text sizeWithFont:self.bottomLabel.font constrainedToSize:CGSizeMake(self.bounds.size.width - 6.0, 40.0) lineBreakMode:UILineBreakModeWordWrap];
    
    self.bottomLabel.numberOfLines = 0;
    aFrame = self.bottomLabel.frame;
    aFrame.origin.x = 3.0;
    aFrame.origin.y = 0.64 * self.bounds.size.height;
    aFrame.size.width = self.bounds.size.width - 6.0;
    aFrame.size.height = expectedSize.height;
    self.bottomLabel.frame = aFrame;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (highlighted)
        self.bottomLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1.0];
    else
        self.bottomLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementKeyboardMenu];
}

- (void)setBottomLabelText:(NSString*)text {
    self.bottomLabel.text = text;
}

@end