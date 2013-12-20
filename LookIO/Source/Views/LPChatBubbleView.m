//
//  LPChatBubbleView.m
//  LookIO
//
//  Created by Yaron Karasik on 12/20/13.
//
//

#import "LPChatBubbleView.h"
#import "LIOBrandingManager.h"

@implementation LPChatBubbleView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.layer.cornerRadius = 5.0;
        
        self.messageLabel = [[TTTAttributedLabel_LIO alloc] initWithFrame:CGRectMake(10, 0, self.bounds.size.width, self.bounds.size.height)];
        self.messageLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.messageLabel.font = [UIFont systemFontOfSize:16.0];
        self.messageLabel.textColor = [UIColor colorWithWhite:79.0/255.0 alpha:1.0];
        self.messageLabel.textAlignment = NSTextAlignmentLeft;
        self.messageLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:self.messageLabel];
    }
    
    return self;
}

@end
