//
//  LIOChatTableViewImageCell.h
//  LookIO
//
//  Created by Yaron Karasik on 1/10/14.
//
//

#import <UIKit/UIKit.h>
#import "LIOChatMessage.h"

@interface LIOChatTableViewImageCell : UITableViewCell

@property (nonatomic, strong) UIButton *failedToSendButton;

- (void)layoutSubviewsForChatMessage:(LIOChatMessage *)chatMessage;
+ (CGSize)expectedSizeForChatMessage:(LIOChatMessage *)chatMessage constrainedToSize:(CGSize)size;

@end
