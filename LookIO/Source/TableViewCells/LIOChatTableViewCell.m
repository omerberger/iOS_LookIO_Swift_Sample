//
//  LIOChatTableViewCell.m
//  LookIO
//
//  Created by Yaron Karasik on 12/20/13.
//
//

#import "LIOChatTableViewCell.h"

#import "LIOBrandingManager.h"

#import "LPChatBubbleView.h"


@interface LIOChatTableViewCell ()

@property (nonatomic, strong) LPChatBubbleView *chatBubbleView;

@end

@implementation LIOChatTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        self.chatBubbleView = [[LPChatBubbleView alloc] initWithFrame:CGRectMake(8, 10, 100, 40)];
        [self.contentView addSubview:self.chatBubbleView];
    }
    return self;
}

+ (CGSize)expectedSizeForChatMessage:(LIOChatMessage *)chatMessage constrainedToSize:(CGSize)size
{
    LIOBrandingElement brandingElement;
    // Set up background color
    switch (chatMessage.kind) {
        case LIOChatMessageKindLocal:
            brandingElement = LIOBrandingElementVisitorChatBubble;
            break;
            
        case LIOChatMessageKindRemote:
            brandingElement = LIOBrandingElementAgentChatBubble;
            break;
            
        default:
            break;
    }
    
    UIFont *font = [[LIOBrandingManager brandingManager] fontForElement:brandingElement];
    CGFloat bubbleWidthFactor = [[LIOBrandingManager brandingManager] widthForElement:brandingElement];
    CGFloat maxSize = size.width * bubbleWidthFactor - 16;
    
    CGSize expectedTextSize = [chatMessage.text sizeWithFont:font constrainedToSize:CGSizeMake(maxSize, 9999) lineBreakMode:UILineBreakModeWordWrap];

    return CGSizeMake(expectedTextSize.width + 31.0, expectedTextSize.height + 35.0);
}

- (void)layoutSubviewsForChatMessage:(LIOChatMessage *)chatMessage
{
    LIOBrandingElement brandingElement;
    
    // Set up background color
    switch (chatMessage.kind) {
        case LIOChatMessageKindLocal:
            brandingElement = LIOBrandingElementVisitorChatBubble;
            self.chatBubbleView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            break;
            
        case LIOChatMessageKindRemote:
            brandingElement = LIOBrandingElementAgentChatBubble;
            self.chatBubbleView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
            break;
            
        default:
            break;
    }
    
    self.chatBubbleView.backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:brandingElement];
    self.chatBubbleView.messageLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:brandingElement];
    self.chatBubbleView.messageLabel.font = [[LIOBrandingManager brandingManager] fontForElement:brandingElement];
    CGFloat bubbleWidthFactor = [[LIOBrandingManager brandingManager] widthForElement:brandingElement];
    CGFloat maxSize = self.contentView.bounds.size.width * bubbleWidthFactor - 16;
    
    CGSize expectedTextSize = [chatMessage.text sizeWithFont:self.chatBubbleView.messageLabel.font constrainedToSize:CGSizeMake(maxSize, 9999) lineBreakMode:UILineBreakModeWordWrap];
    
    CGRect aFrame = self.chatBubbleView.frame;
    aFrame.origin.x = chatMessage.kind == LIOChatMessageKindRemote ? 8 : self.contentView.bounds.size.width - expectedTextSize.width - 30;
    aFrame.origin.y = 10;
    aFrame.size.width = expectedTextSize.width + 23;
    aFrame.size.height = expectedTextSize.height + 20;
    self.chatBubbleView.frame = aFrame;
    
    self.chatBubbleView.messageLabel.numberOfLines = 0;
    [self.chatBubbleView.messageLabel sizeToFit];
    
    self.chatBubbleView.messageLabel.text = chatMessage.text;
    
    aFrame = self.chatBubbleView.messageLabel.frame;
    aFrame.origin.x = 10;
    aFrame.origin.y = 10;
    aFrame.size = expectedTextSize;
    self.chatBubbleView.messageLabel.frame = aFrame;
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end