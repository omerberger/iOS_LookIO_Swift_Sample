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

#define LIOChatTableViewImageCellAttachmentRowHeight           135.0
#define LIOChatTableViewImageCellAttachmentDisplayHeight       120.0
#define LIOChatTableViewImageCellMaximumAttachmentDisplayWidth 150.0

@interface LIOChatTableViewImageCell ()

@property (nonatomic, strong) LPChatImageView *chatImageView;

@end

@implementation LIOChatTableViewImageCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        self.chatImageView = [[LPChatImageView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:self.chatImageView];
    }
    
    return self;
}

+ (CGSize)expectedSizeForChatMessage:(LIOChatMessage *)chatMessage constrainedToSize:(CGSize)size
{
    return CGSizeMake(LIOChatTableViewImageCellAttachmentRowHeight, LIOChatTableViewImageCellAttachmentRowHeight);
}

- (void)layoutSubviewsForChatMessage:(LIOChatMessage *)chatMessage
{
    NSLog(@"Attachment id is %@", chatMessage.attachmentId);
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
                                        
                    // TODO Failed message view
                    /*
                    if (LIOChatMessageKindLocal == aMessage.kind && aMessage.sendingFailed) {
                        UIButton* failedMessageButton = [[UIButton alloc] initWithFrame:CGRectMake(foregroundImage.frame.origin.x - 32.0, foregroundImage.frame.size.height/2 - 11.0 , 22, 22)];
                        UIImage* failedMessageButtonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOFailedMessageAlertIcon"];
                        [failedMessageButton setImage:failedMessageButtonImage forState:UIControlStateNormal];
                        [failedMessageButton addTarget:self action:@selector(failedMessageButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
                        failedMessageButton.tag = LIOAltChatViewControllerTableViewCellFailedMessageButtonTag;
                        [aCell.contentView addSubview:failedMessageButton];
                    }
                    */
                }
            }
        }
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end
