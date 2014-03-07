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
@property (nonatomic, strong) UIActivityIndicatorView *resendActivityIndicatorView;

@end

@implementation LIOChatTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        self.chatBubbleView = [[LPChatBubbleView alloc] initWithFrame:CGRectMake(8, 10, 100, 40)];
        [self.contentView addSubview:self.chatBubbleView];
        
        self.failedToSendButton = [[UIButton alloc] initWithFrame:CGRectMake(self.bounds.size.width - 313.0, 20, 22, 22)];
        self.failedToSendButton.accessibilityLabel = LIOLocalizedString(@"LIOAltChatViewController.ResendFailedMessageButton");
        UIImage* failedToSendButtonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOFailedMessageAlertIcon"];
        [self.failedToSendButton setImage:failedToSendButtonImage forState:UIControlStateNormal];
        [self.contentView addSubview:self.failedToSendButton];
        
        self.resendActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:self.failedToSendButton.frame];
        self.resendActivityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        [self.contentView addSubview:self.resendActivityIndicatorView];
    }
    return self;
}

+ (CGSize)expectedSizeForText:(NSString *)text withFont:(UIFont *)font forWidth:(CGFloat)width
{
    CGSize expectedTextSize;
    
    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        CGRect expectedTextRect = [text boundingRectWithSize:CGSizeMake(width, 9999)
                                                     options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                  attributes:@{NSFontAttributeName:font}
                                                     context:nil];
        expectedTextSize = expectedTextRect.size;
    }
    else
    {
        expectedTextSize = [text sizeWithFont:font constrainedToSize:CGSizeMake(width, 9999) lineBreakMode:UILineBreakModeWordWrap];
    }
    
    expectedTextSize = CGSizeMake(ceil(expectedTextSize.width) + 2.0, ceil(expectedTextSize.height) + 2.0);
    
    return expectedTextSize;
}

+ (CGSize)expectedSizeForAttributedString:(NSAttributedString *)attributedString withFont:(UIFont *)font forWidth:(CGFloat)width
{
    CGSize expectedTextSize;
    
    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        CGRect expectedTextRect = [attributedString boundingRectWithSize:CGSizeMake(width, 9999)
                                                     options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                     context:nil];
        expectedTextSize = expectedTextRect.size;
    }
    else
    {
        // TODO: Support iOS 5.0 here
        NSString *text = [attributedString string];
        expectedTextSize = [text sizeWithFont:font constrainedToSize:CGSizeMake(width, 9999) lineBreakMode:UILineBreakModeWordWrap];
    }
    
    expectedTextSize = CGSizeMake(ceil(expectedTextSize.width) + 2.0, ceil(expectedTextSize.height) + 2.0);
    
    return expectedTextSize;
}

+ (NSAttributedString *)attributedStringForChatMessage:(LIOChatMessage *)chatMessage
{
    
}

+ (CGSize)expectedSizeForChatMessage:(LIOChatMessage *)chatMessage constrainedToSize:(CGSize)size
{
    LIOBrandingElement brandingElement = LIOBrandingElementVisitorChatBubble;
    
    // Set up background color
    switch (chatMessage.kind) {
        case LIOChatMessageKindLocal:
            brandingElement = LIOBrandingElementVisitorChatBubble;
            break;
            
        case LIOChatMessageKindRemote:
            brandingElement = LIOBrandingElementAgentChatBubble;
            break;
            
        case LIOChatMessageKindSystemMessage:
            brandingElement = LIOBrandingElementSystemMessageChatBubble;
            
        default:
            break;
    }
    
    UIFont *boldFont = [[LIOBrandingManager brandingManager] boldFontForElement:brandingElement];
    UIFont *font = [[LIOBrandingManager brandingManager] fontForElement:brandingElement];
    CGFloat bubbleWidthFactor = [[LIOBrandingManager brandingManager] widthForElement:brandingElement];
    CGFloat maxSize = size.width * bubbleWidthFactor - 20;
    
    NSString *text = chatMessage.text;
    if (chatMessage.senderName != nil)
        text = [NSString stringWithFormat:@"%@: %@", chatMessage.senderName, chatMessage.text];
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:text];

    CTFontRef standardCTFont = CTFontCreateWithName((CFStringRef)font.fontName, font.pointSize, NULL);
    [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)CFBridgingRelease(standardCTFont) range:NSMakeRange(0, mutableAttributedString.length)];
    if ([chatMessage.senderName length])
    {
        NSAttributedString *nameCallout = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ", chatMessage.senderName]] ;
        NSRange boldRange = NSMakeRange(0, [nameCallout length]);
        
        CTFontRef boldNameCTFont = CTFontCreateWithName((CFStringRef)boldFont.fontName, boldFont.pointSize, NULL);
        
        if (boldRange.location != NSNotFound)
        {
            [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)CFBridgingRelease(boldNameCTFont) range:boldRange];
        }
    }
    
    CGSize expectedTextSize;
    
    if (chatMessage.isShowingLinks)
    {
        // TODO: Use attributeds tring for height with links

        LPChatBubbleView *chatBubbleView = [[LPChatBubbleView alloc] init];
        CGFloat bubbleHeight = [chatBubbleView populateLinksChatBubbleViewWithMessage:chatMessage forWidth:maxSize];
        
        expectedTextSize = CGSizeMake(maxSize, bubbleHeight);
    }
    else
    {
        expectedTextSize = [LIOChatTableViewCell expectedSizeForAttributedString:mutableAttributedString withFont:font forWidth:maxSize];
    }
    
    return CGSizeMake(expectedTextSize.width + 31.0, expectedTextSize.height + 35.0);
}

- (void)layoutSubviewsForChatMessage:(LIOChatMessage *)chatMessage
{
    [self.chatBubbleView prepareForReuse];
    
    LIOBrandingElement brandingElement = LIOBrandingElementVisitorChatBubble;
    
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
            
        case LIOChatMessageKindSystemMessage:
            brandingElement = LIOBrandingElementSystemMessageChatBubble;
            break;
            
        default:
            break;
    }
    
    self.chatBubbleView.backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:brandingElement];
    UIColor *textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:brandingElement];
    UIFont *boldNameFont = [[LIOBrandingManager brandingManager] boldFontForElement:brandingElement];
    UIFont *font = [[LIOBrandingManager brandingManager] fontForElement:brandingElement];
    self.chatBubbleView.messageLabel.textColor = textColor;
    self.chatBubbleView.messageLabel.font = [[LIOBrandingManager brandingManager] fontForElement:brandingElement];
    CGFloat bubbleWidthFactor = [[LIOBrandingManager brandingManager] widthForElement:brandingElement];
    CGFloat maxWidth = self.bounds.size.width * bubbleWidthFactor - 20;
    
    if (brandingElement == LIOBrandingElementSystemMessageChatBubble)
    {
        NSString *bubbleAlignment = [[LIOBrandingManager brandingManager] stringValueForField:@"bubble_alignment" forElement:LIOBrandingElementSystemMessageChatBubble];
        self.chatBubbleView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        if ([bubbleAlignment isEqualToString:@"right"])
            self.chatBubbleView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        if ([bubbleAlignment isEqualToString:@"left"])
            self.chatBubbleView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        if ([bubbleAlignment isEqualToString:@"center"])
            self.chatBubbleView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    }
    
    NSString *text = chatMessage.text;
    if (chatMessage.senderName != nil)
        text = [NSString stringWithFormat:@"%@: %@", chatMessage.senderName, chatMessage.text];
    
    if (chatMessage.isShowingLinks)
    {
        CGFloat expectedHeight = [self.chatBubbleView populateLinksChatBubbleViewWithMessage:chatMessage forWidth:maxWidth];
        CGSize expectedTextSize = CGSizeMake(maxWidth, expectedHeight);
        
        CGRect aFrame = self.chatBubbleView.frame;
        if (chatMessage.kind == LIOChatMessageKindSystemMessage)
        {
            NSString *bubbleAlignment = [[LIOBrandingManager brandingManager] stringValueForField:@"bubble_alignment" forElement:LIOBrandingElementSystemMessageChatBubble];
            if ([bubbleAlignment isEqualToString:@"right"])
                aFrame.origin.x = self.contentView.bounds.size.width - expectedTextSize.width - 30;
            if ([bubbleAlignment isEqualToString:@"left"])
                aFrame.origin.x = 8;
            if ([bubbleAlignment isEqualToString:@"center"])
                aFrame.origin.x = (self.contentView.bounds.size.width - expectedTextSize.width - 20)/2;
        }
        else
            aFrame.origin.x = chatMessage.kind == LIOChatMessageKindRemote ? 8 : self.contentView.bounds.size.width - expectedTextSize.width - 30;
        aFrame.origin.y = 10;
        aFrame.size.width = expectedTextSize.width + 20;
        aFrame.size.height = expectedTextSize.height + 16;
        self.chatBubbleView.frame = aFrame;
        
        for (int i=0; i<self.chatBubbleView.linkButtons.count; i++)
        {
            UIButton *linkButton = [self.chatBubbleView.linkButtons objectAtIndex:i];
            linkButton.tag = i;
            [linkButton addTarget:self action:@selector(didTapLinkButton:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    else
    {
        NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:text];
        
        CTFontRef standardCTFont = CTFontCreateWithName((CFStringRef)font.fontName, font.pointSize, NULL);
        [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)CFBridgingRelease(standardCTFont) range:NSMakeRange(0, mutableAttributedString.length)];
        if ([chatMessage.senderName length])
        {
            NSAttributedString *nameCallout = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ", chatMessage.senderName]] ;
            NSRange boldRange = NSMakeRange(0, [nameCallout length]);
            
            CTFontRef boldNameCTFont = CTFontCreateWithName((CFStringRef)boldNameFont.fontName, boldNameFont.pointSize, NULL);
            
            if (boldRange.location != NSNotFound)
            {
                [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)CFBridgingRelease(boldNameCTFont) range:boldRange];
            }
        }

        CGSize expectedTextSize = [LIOChatTableViewCell expectedSizeForAttributedString:mutableAttributedString withFont:font forWidth:maxWidth];
        
        CGRect aFrame = self.chatBubbleView.frame;
        if (chatMessage.kind == LIOChatMessageKindSystemMessage)
        {
            NSString *bubbleAlignment = [[LIOBrandingManager brandingManager] stringValueForField:@"bubble_alignment" forElement:LIOBrandingElementSystemMessageChatBubble];
            if ([bubbleAlignment isEqualToString:@"right"])
                aFrame.origin.x = self.contentView.bounds.size.width - expectedTextSize.width - 30;
            if ([bubbleAlignment isEqualToString:@"left"])
                aFrame.origin.x = 8;
            if ([bubbleAlignment isEqualToString:@"center"])
                aFrame.origin.x = (self.contentView.bounds.size.width - expectedTextSize.width - 20)/2;
        }
        else
            aFrame.origin.x = chatMessage.kind == LIOChatMessageKindRemote ? 8 : self.contentView.bounds.size.width - expectedTextSize.width - 30;
        aFrame.origin.y = 10;
        aFrame.size.width = expectedTextSize.width + 20;
        aFrame.size.height = expectedTextSize.height + 16;
        self.chatBubbleView.frame = aFrame;
        
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
    
    if (LIOIsUIKitFlatMode())
        for (UIView *subview in self.subviews)
            subview.clipsToBounds = NO;
    
    // If message sending failed, show the failed button
    if (LIOChatMessageKindLocal == chatMessage.kind && LIOChatMessageStatusFailed == chatMessage.status)
    {
        self.failedToSendButton.hidden = NO;
        CGRect aFrame = self.failedToSendButton.frame;
        aFrame.origin.x = self.chatBubbleView.frame.origin.x - self.failedToSendButton.frame.size.width - 10.0;
        aFrame.origin.y = self.chatBubbleView.frame.origin.y + (self.chatBubbleView.frame.size.height - self.failedToSendButton.frame.size.height)/2;
        self.failedToSendButton.frame = aFrame;
        
        self.failedToSendButton.tag = chatMessage.clientLineId;
        
        [self.resendActivityIndicatorView stopAnimating];
    }
    else
    {
        if (LIOChatMessageKindLocal == chatMessage.kind && LIOChatMessageStatusResending == chatMessage.status)
        {
            self.failedToSendButton.hidden = YES;
            CGRect aFrame = self.failedToSendButton.frame;
            aFrame.origin.x = self.chatBubbleView.frame.origin.x - self.failedToSendButton.frame.size.width - 10.0;
            aFrame.origin.y = self.chatBubbleView.frame.origin.y + (self.chatBubbleView.frame.size.height - self.failedToSendButton.frame.size.height)/2;
            self.failedToSendButton.frame = aFrame;

            self.resendActivityIndicatorView.frame = self.failedToSendButton.frame;
            [self.resendActivityIndicatorView startAnimating];
        }
        else
        {
            self.failedToSendButton.hidden = YES;
            [self.resendActivityIndicatorView stopAnimating];
        }
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)didTapLinkButton:(UIButton *)button
{
    [self.delegate chatTableViewCell:self didTapLinkButtonWithIndex:button.tag];
}

@end