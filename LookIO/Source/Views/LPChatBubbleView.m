//
//  LPChatBubbleView.m
//  LookIO
//
//  Created by Yaron Karasik on 12/20/13.
//
//

#import "LPChatBubbleView.h"
#import "TTTAttributedLabel.h"
#import "LIOChatMessage.h"

@interface LPChatBubbleView ()

@property (nonatomic, strong) TTTAttributedLabel_LIO *messageLabel;

@end

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
        [self addSubview:self.messageLabel];
    }
    return self;
}

- (void)layoutSubviewsForChatMessage:(LIOChatMessage *)chatMessage
{
    self.messageLabel.text = chatMessage.text;
}

@end
