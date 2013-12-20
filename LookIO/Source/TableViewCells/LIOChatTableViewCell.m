//
//  LIOChatTableViewCell.m
//  LookIO
//
//  Created by Yaron Karasik on 12/20/13.
//
//

#import "LIOChatTableViewCell.h"
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
        [self addSubview:self.chatBubbleView];
    }
    return self;
}

- (void)layoutSubviewsForChatMessage:(LIOChatMessage *)chatMessage
{
    [self.chatBubbleView layoutSubviewsForChatMessage:chatMessage];
    /*
    CGFloat maxSize = self.contentView.bounds.size.width * 0.625;
    
    CGRect expectedTextSize = [chatMessage.text boundingRectWithSize:CGSizeMake(maxSize, 9999)
                                                             options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                          attributes:@{NSFontAttributeName:self.messageLabel.font}
                                                             context:nil];
    
    CGRect aFrame = self.backgroundImageView.frame;
    aFrame.origin.x = chatMessage.messageType == HKBChatMessageTypeVisitorMessage ? 8 : self.contentView.bounds.size.width - expectedTextSize.size.width - 30;
    aFrame.origin.y = 10;
    aFrame.size.width = expectedTextSize.size.width + 23;
    aFrame.size.height = expectedTextSize.size.height + 20;
    self.backgroundImageView.frame = aFrame;
    
    if (chatMessage.messageType == HKBChatMessageTypeVisitorMessage)
        self.backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    else
        self.backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    
    self.messageLabel.numberOfLines = 0;
    [self.messageLabel sizeToFit];
    
    self.messageLabel.text = chatMessage.text;
    
    aFrame = self.messageLabel.frame;
    aFrame.origin.x = 10;
    aFrame.origin.y = 10;
    aFrame.size = expectedTextSize.size;
    self.messageLabel.frame = aFrame;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"hh:mm a"];
    
    self.nameAndDateLabel.text = [NSString stringWithFormat:@"%@ %@", (chatMessage.messageType == HKBChatMessageTypeAgentMessage ? @"Me" :  chatMessage.senderName), [[dateFormatter stringFromDate:chatMessage.date] lowercaseString]];
    
    expectedTextSize = [self.nameAndDateLabel.text boundingRectWithSize:CGSizeMake(maxSize, 9999)
                                                                options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                             attributes:@{NSFontAttributeName:self.nameAndDateLabel.font}
                                                                context:nil];
    
    self.nameAndDateLabel.numberOfLines = 1;
    [self.nameAndDateLabel sizeToFit];
    
    aFrame = self.nameAndDateLabel.frame;
    aFrame.origin.x = chatMessage.messageType ? 9 : self.bounds.size.width - expectedTextSize.size.width - 9;
    aFrame.origin.y = self.backgroundImageView.frame.origin.y + self.backgroundImageView.frame.size.height + 5;
    self.nameAndDateLabel.frame = aFrame;
    
    if (chatMessage.messageType == HKBChatMessageTypeVisitorMessage) {
        self.nameAndDateLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        
        self.backgroundImageView.backgroundColor = [UIColor colorWithRed:225.0/255.0 green:225.0/255.0 blue:231.0/255.0 alpha:1.0];
        self.messageLabel.textColor = [UIColor darkGrayColor];
    }
    else {
        self.nameAndDateLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        
        self.backgroundImageView.backgroundColor = [UIColor colorWithRed:71.0/255.0 green:161.0/255.0 blue:1.0 alpha:1.0];
        self.messageLabel.textColor = [UIColor whiteColor];
    }
     */
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end