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
    LIOChatBubbleViewFormattingModeLocal
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

@protocol LIOChatBubbleViewDelegate

- (void)chatBubbleViewWantsCopyMenu:(LIOChatBubbleView *)aView;
- (void)chatBubbleView:(LIOChatBubbleView *)aView didTapSupertypeLinkWithURL:(NSURL *)aURL link:(NSString*)aLink scheme:(NSString*)aScheme superType:(int)aSupertype;
- (void)chatBubbleView:(LIOChatBubbleView *)aView didTapIntraAppLinkWithURL:(NSURL *)aURL;
- (void)chatBubbleView:(LIOChatBubbleView *)aView didTapPhoneURL:(NSURL *)aURL link:(NSString *)aLink;
- (void)chatBubbleView:(LIOChatBubbleView *)aView didTapWebLinkWithURL:(NSURL *)aURL;

@end

@interface LIOChatBubbleView : UIView
{
    LIOChatBubbleViewFormattingMode formattingMode;
    LIOChatBubbleViewLinkMode linkMode;
    TTTAttributedLabel_LIO *mainMessageView;
    NSMutableArray *linkMessageViews, *links, *linkButtons, *linkTypes, *linkSupertypes, *intraAppLinkViews,
        *linkURLs, *linkSchemes;
    UIImageView *backgroundImage;
    NSString *senderName;
    LIOChatMessage *rawChatMessage;
    NSInteger index;
    id<LIOChatBubbleViewDelegate> delegate;
}

@property(nonatomic, assign) LIOChatBubbleViewFormattingMode formattingMode;
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