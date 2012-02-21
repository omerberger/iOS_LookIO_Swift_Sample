//
//  LIOChatBubbleView.h
//  LookIO
//
//  Created by Joseph Toscano on 12/5/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define LIOChatBubbleViewMaxTextWidth   267.0
#define LIOChatBubbleViewMinTextHeight  67.0

typedef enum
{
    LIOChatBubbleViewTailDirectionLeft,
    LIOChatBubbleViewTailDirectionRight
} LIOChatBubbleViewTailDirection;

typedef enum
{
    LIOChatBubbleViewFormattingModeRemote,
    LIOChatBubbleViewFormattingModeLocal
} LIOChatBubbleViewFormattingMode;

@interface LIOChatBubbleView : UIView
{
    LIOChatBubbleViewTailDirection tailDirection;
    LIOChatBubbleViewFormattingMode formattingMode;
    UILabel *messageView;
    UIImageView *backgroundImage;
}

@property(nonatomic, assign) LIOChatBubbleViewTailDirection tailDirection;
@property(nonatomic, assign) LIOChatBubbleViewFormattingMode formattingMode;

- (void)populateMessageViewWithText:(NSString *)aString;

@end