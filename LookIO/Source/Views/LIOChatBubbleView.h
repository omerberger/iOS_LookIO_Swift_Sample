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

typedef enum
{
    LIOChatBubbleViewFormattingModeRemote,
    LIOChatBubbleViewFormattingModeLocal
} LIOChatBubbleViewFormattingMode;

typedef enum
{
    LIOChatBubbleViewLinkModeDisabled,
    LIOChatBubbleViewLinkModeEnabled
} LIOChatBubbleViewLinkMode;

@interface LIOChatBubbleView : UIView
{
    LIOChatBubbleViewFormattingMode formattingMode;
    LIOChatBubbleViewLinkMode linkMode;
    TTTAttributedLabel_LIO *mainMessageView;
    NSMutableArray *linkMessageViews, *links, *linkButtons, *linkTypes;
    UIImageView *backgroundImage;
    NSString *senderName;
    NSDataDetector *dataDetector;
    
}

@property(nonatomic, assign) LIOChatBubbleViewFormattingMode formattingMode;
@property(nonatomic, readonly) LIOChatBubbleViewLinkMode linkMode;
@property(nonatomic, retain) NSString *senderName;

- (void)populateMessageViewWithText:(NSString *)aString;

@end