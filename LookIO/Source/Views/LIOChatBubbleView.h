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

typedef enum
{
    LIOChatBubbleViewFormattingModeRemote,
    LIOChatBubbleViewFormattingModeLocal
} LIOChatBubbleViewFormattingMode;

@interface LIOChatBubbleView : UIView
{
    LIOChatBubbleViewFormattingMode formattingMode;
    UILabel *messageView;
    UIImageView *backgroundImage;
}

@property(nonatomic, assign) LIOChatBubbleViewFormattingMode formattingMode;
@property(nonatomic, readonly) UILabel *messageView;

- (void)populateMessageViewWithText:(NSString *)aString;

@end