//
//  LIOChatTableViewCell.h
//  LookIO
//
//  Created by Yaron Karasik on 12/20/13.
//
//

#import <UIKit/UIKit.h>
#import "LIOChatMessage.h"

@interface LIOChatTableViewCell : UITableViewCell

- (void)layoutSubviewsForChatMessage:(LIOChatMessage *)chatMessage;
+ (CGSize)expectedSizeForChatMessage:(LIOChatMessage *)chatMessage constrainedToSize:(CGSize)size;

@end
