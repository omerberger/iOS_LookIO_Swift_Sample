//
//  LIOChatBubbleView.h
//  LookIO
//
//  Created by Joseph Toscano on 12/5/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define LIOChatBubbleViewMaxTextWidth   250.0
#define LIOChatBubbleViewMinTextHeight  67.0

@class TTTAttributedLabel_LIO;

@protocol TTTAttributedLabelDelegate;

typedef enum
{
    LIOChatBubbleViewFormattingModeRemote,
    LIOChatBubbleViewFormattingModeLocal
} LIOChatBubbleViewFormattingMode;

@interface LIOChatBubbleView : UIView <TTTAttributedLabelDelegate>
{
    LIOChatBubbleViewFormattingMode formattingMode;
    TTTAttributedLabel_LIO *messageView;
    UIImageView *backgroundImage;
    NSString *senderName;
}

@property(nonatomic, assign) LIOChatBubbleViewFormattingMode formattingMode;
@property(nonatomic, retain) NSString *senderName;

- (void)populateMessageViewWithText:(NSString *)aString;

@end