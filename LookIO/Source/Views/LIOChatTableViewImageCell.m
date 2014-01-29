//
//  LIOChatTableViewImageCell.m
//  LookIO
//
//  Created by Yaron Karasik on 1/10/14.
//
//

#import "LIOChatTableViewImageCell.h"
#import "LPChatImageView.h"

#import "LIOMediaManager.h"
#import "LIOBundleManager.h"

#define LIOChatTableViewImageCellAttachmentRowHeight           135.0
#define LIOChatTableViewImageCellAttachmentDisplayHeight       120.0
#define LIOChatTableViewImageCellMaximumAttachmentDisplayWidth 150.0

@interface LIOChatTableViewImageCell ()

@property (nonatomic, strong) LPChatImageView *chatImageView;
@property (nonatomic, strong) UIActivityIndicatorView *resendActivityIndicatorView;

@end

@implementation LIOChatTableViewImageCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        self.chatImageView = [[LPChatImageView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:self.chatImageView];
        
        self.failedToSendButton = [[UIButton alloc] initWithFrame:CGRectMake(self.bounds.size.width - 313.0, 20, 22, 22)];
        UIImage* failedToSendButtonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOFailedMessageAlertIcon"];
        [self.failedToSendButton setImage:failedToSendButtonImage forState:UIControlStateNormal];
        [self.contentView addSubview:self.failedToSendButton];
        
        self.resendActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:self.failedToSendButton.frame];
        self.resendActivityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        [self.contentView addSubview:self.resendActivityIndicatorView];
    }
    
    return self;
}

+ (CGSize)expectedSizeForChatMessage:(LIOChatMessage *)chatMessage constrainedToSize:(CGSize)size
{
    return CGSizeMake(LIOChatTableViewImageCellAttachmentRowHeight, LIOChatTableViewImageCellAttachmentRowHeight);
}

- (void)layoutSubviewsForChatMessage:(LIOChatMessage *)chatMessage
{
    if ([chatMessage.attachmentId length])
    {
        NSString *mimeType = [[LIOMediaManager sharedInstance] mimeTypeFromId:chatMessage.attachmentId];
        if ([mimeType hasPrefix:@"image"])
        {
            NSData *imageData = [[LIOMediaManager sharedInstance] mediaDataWithId:chatMessage.attachmentId];
            if (imageData)
            {
                UIImage *attachmentImage = [[UIImage alloc] initWithData:imageData];
                if (attachmentImage)
                {
                    self.chatImageView.imageView.image = attachmentImage;
                    
                    CGRect frame;
                    if (attachmentImage.size.height > 0) {
                        frame.size.width = LIOChatTableViewImageCellAttachmentDisplayHeight*(attachmentImage.size.width/attachmentImage.size.height);
                        if (frame.size.width > LIOChatTableViewImageCellMaximumAttachmentDisplayWidth)
                            frame.size.width = LIOChatTableViewImageCellMaximumAttachmentDisplayWidth;
                    }
                    else
                        frame.size.width = LIOChatTableViewImageCellAttachmentDisplayHeight;
                    frame.size.height = LIOChatTableViewImageCellAttachmentDisplayHeight;
                    frame.origin.x = 3;
                    frame.origin.y = 3;
                    self.chatImageView.imageView.frame = frame;
                    
                    frame.origin.x = self.bounds.size.width - frame.size.width - 13.0;
                    frame.origin.y = 5;
                    frame.size.width = frame.size.width + 6.0;
                    frame.size.height = frame.size.height + 8.0;
                    self.chatImageView.frame = frame;
                }
            }
        }
    }
    
    if (LIOIsUIKitFlatMode())
        for (UIView *subview in self.subviews)
            subview.clipsToBounds = NO;

    // If message sending failed, show the failed button
    if (LIOChatMessageKindLocalImage == chatMessage.kind && LIOChatMessageStatusFailed == chatMessage.status)
    {
        self.failedToSendButton.hidden = NO;
        CGRect aFrame = self.failedToSendButton.frame;
        aFrame.origin.x = self.chatImageView.frame.origin.x - self.failedToSendButton.frame.size.width - 10.0;
        aFrame.origin.y = self.chatImageView.frame.origin.y + (self.chatImageView.frame.size.height - self.failedToSendButton.frame.size.height)/2;
        self.failedToSendButton.frame = aFrame;
        
        self.failedToSendButton.tag = chatMessage.clientLineId;
        
        [self.resendActivityIndicatorView stopAnimating];
    }
    else
    {
        if (LIOChatMessageKindLocalImage == chatMessage.kind && LIOChatMessageStatusResending == chatMessage.status)
        {
            self.failedToSendButton.hidden = YES;
            CGRect aFrame = self.failedToSendButton.frame;
            aFrame.origin.x = self.chatImageView.frame.origin.x - self.failedToSendButton.frame.size.width - 10.0;
            aFrame.origin.y = self.chatImageView.frame.origin.y + (self.chatImageView.frame.size.height - self.failedToSendButton.frame.size.height)/2;
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

@end
