//
//  LIOChatTableViewCell.m
//  LookIO
//
//  Created by Yaron Karasik on 12/20/13.
//
//

#import "LIOChatTableViewCell.h"

#import "LIOBrandingManager.h"
#import "LIOBundleManager.h"

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
    
    UIFont *font = [[LIOBrandingManager brandingManager] boldFontForElement:brandingElement];
    CGFloat bubbleWidthFactor = [[LIOBrandingManager brandingManager] widthForElement:brandingElement];
    CGFloat maxSize = size.width * bubbleWidthFactor - 20;
    
    NSString *text = chatMessage.text;
    if (chatMessage.senderName != nil)
        text = [NSString stringWithFormat:@"%@: %@", chatMessage.senderName, chatMessage.text];
    
    CGSize expectedTextSize;
    
    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        CGRect expectedTextRect = [text boundingRectWithSize:CGSizeMake(maxSize, 9999)
                                                     options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                  attributes:@{NSFontAttributeName:font}
                                                     context:nil];
        expectedTextSize = expectedTextRect.size;
    }
    else
    {
        expectedTextSize = [text sizeWithFont:font constrainedToSize:CGSizeMake(maxSize, 9999) lineBreakMode:UILineBreakModeWordWrap];
    }
    expectedTextSize = CGSizeMake(ceil(expectedTextSize.width), ceil(expectedTextSize.height));
    
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
    UIColor *textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:brandingElement];
    UIFont *boldNameFont = [[LIOBrandingManager brandingManager] boldFontForElement:brandingElement];
    self.chatBubbleView.messageLabel.textColor = textColor;
    self.chatBubbleView.messageLabel.font = [[LIOBrandingManager brandingManager] fontForElement:brandingElement];
    CGFloat bubbleWidthFactor = [[LIOBrandingManager brandingManager] widthForElement:brandingElement];
    CGFloat maxSize = self.contentView.bounds.size.width * bubbleWidthFactor - 20;
    
    NSString *text = chatMessage.text;
    if (chatMessage.senderName != nil)
        text = [NSString stringWithFormat:@"%@: %@", chatMessage.senderName, chatMessage.text];
    
    CGSize expectedTextSize;
    
    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        CGRect expectedTextRect = [text boundingRectWithSize:CGSizeMake(maxSize, 9999)
                                                                 options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                              attributes:@{NSFontAttributeName:boldNameFont}
                                                                 context:nil];
        expectedTextSize = expectedTextRect.size;
    }
    else
    {
        expectedTextSize = [text sizeWithFont:boldNameFont constrainedToSize:CGSizeMake(maxSize, 9999) lineBreakMode:UILineBreakModeWordWrap];
    }
    expectedTextSize = CGSizeMake(ceil(expectedTextSize.width), ceil(expectedTextSize.height));
    
    CGRect aFrame = self.chatBubbleView.frame;
    aFrame.origin.x = chatMessage.kind == LIOChatMessageKindRemote ? 8 : self.contentView.bounds.size.width - expectedTextSize.width - 30;
    aFrame.origin.y = 10;
    aFrame.size.width = expectedTextSize.width + 20;
    aFrame.size.height = expectedTextSize.height + 16;
    self.chatBubbleView.frame = aFrame;
    
    self.chatBubbleView.messageLabel.numberOfLines = 0;
    [self.chatBubbleView.messageLabel sizeToFit];
    
    [self.chatBubbleView.messageLabel setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:^ NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        
        if ([chatMessage.senderName length])
        {
            NSAttributedString *nameCallout = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ", chatMessage.senderName]] ;
            NSRange boldRange = NSMakeRange(0, [nameCallout length]);
            
            CTFontRef boldNameCTFont = CTFontCreateWithName((CFStringRef)boldNameFont.fontName, boldNameFont.pointSize, NULL);
            
            if (boldRange.location != NSNotFound)
            {
                [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)CFBridgingRelease(boldNameCTFont) range:boldRange];
                [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)textColor.CGColor range:boldRange];
            }
        }
        return mutableAttributedString;
    }];
    
    aFrame = self.chatBubbleView.messageLabel.frame;
    aFrame.origin.x = 10;
    aFrame.origin.y = 8;
    aFrame.size = expectedTextSize;
    self.chatBubbleView.messageLabel.frame = aFrame;
    self.chatBubbleView.messageLabel.numberOfLines = 0;
    [self.chatBubbleView.messageLabel sizeThatFits:expectedTextSize];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end