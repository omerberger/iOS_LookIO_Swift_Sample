//
//  LPChatBubbleView.h
//  LookIO
//
//  Created by Yaron Karasik on 12/20/13.
//
//

#import <UIKit/UIKit.h>
#import "LIOChatMessage.h"
#import "TTTAttributedLabel.h"

@interface LPChatBubbleView : UIView

@property (nonatomic, strong) TTTAttributedLabel_LIO *messageLabel;

@end
