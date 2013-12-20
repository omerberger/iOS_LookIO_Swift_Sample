//
//  LPChatBubbleView.h
//  LookIO
//
//  Created by Yaron Karasik on 12/20/13.
//
//

#import <UIKit/UIKit.h>
#import "LIOChatMessage.h"

@interface LPChatBubbleView : UIView

- (void)layoutSubviewsForChatMessage:(LIOChatMessage *)chatMessage;

@end
