//
//  LIOChatBubbleView.h
//  LookIO
//
//  Created by Joseph Toscano on 12/5/11.
//  Copyright (c) 2011 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define LIOChatBubbleViewMaxTextWidth   250.0
#define LIOChatBubbleViewMinTextHeight  67.0

@class TTTAttributedLabel_LIO, LIOChatMessage, LIOChatBubbleView;

typedef enum
{
    LIOChatBubbleViewFormattingModeRemote,
    LIOChatBubbleViewFormattingModeLocal,
    LIOChatBubbleViewFormattingModeHeader
} LIOChatBubbleViewFormattingMode;

typedef enum
{
    LIOChatBubbleViewLinkModeDisabled,
    LIOChatBubbleViewLinkModeEnabled
} LIOChatBubbleViewLinkMode;

typedef enum
{
    LIOChatBubbleViewLinkSupertypeExtra,
    LIOChatBubbleViewLinkSupertypeIntra
} LIOChatBubbleViewLinkSupertype;

typedef enum
{
    LIOChatBubbleViewBubbleStyleChat,
    LIOChatBubbleViewBubbleStyleSurvey
} LIOChatBubbleViewBubbleStyle;

@protocol LIOChatBubbleViewDelegate
- (void)chatBubbleViewWantsCopyMenu:(LIOChatBubbleView *)aView;
- (void)chatBubbleView:(LIOChatBubbleView *)aView didTapIntraAppLinkWithURL:(NSURL *)aURL;
@end

@interface LIOChatBubbleView : UIView <UIAlertViewDelegate>
{
    LIOChatBubbleViewFormattingMode formattingMode;
    LIOChatBubbleViewLinkMode linkMode;
    LIOChatBubbleViewBubbleStyle bubbleStyle;
    TTTAttributedLabel_LIO *mainMessageView;
    NSMutableArray *linkMessageViews, *links, *linkButtons, *linkTypes, *linkSupertypes, *intraAppLinkViews;
    UIImageView *backgroundImage;
    NSString *senderName;
    NSURL *urlBeingLaunched;
    LIOChatMessage *rawChatMessage;
    NSInteger index;
    id<LIOChatBubbleViewDelegate> delegate;
}

@property(nonatomic, assign) LIOChatBubbleViewFormattingMode formattingMode;
@property(nonatomic, assign) LIOChatBubbleViewBubbleStyle bubbleStyle;
@property(nonatomic, readonly) LIOChatBubbleViewLinkMode linkMode;
@property(nonatomic, readonly) NSMutableArray *linkMessageViews, *linkButtons, *links;
@property(nonatomic, retain) NSString *senderName;
@property(nonatomic, readonly) TTTAttributedLabel_LIO *mainMessageView;
@property(nonatomic, retain) LIOChatMessage *rawChatMessage;
@property(nonatomic, assign) NSInteger index;
@property(nonatomic, assign) id<LIOChatBubbleViewDelegate> delegate;

- (void)populateMessageViewWithText:(NSString *)aString;
- (void)enterCopyModeAnimated:(BOOL)animated;

@end