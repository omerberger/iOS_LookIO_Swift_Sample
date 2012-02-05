//
//  LIOChatboxView.h
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define LIOChatboxViewMaxTextLength         200
#define LIOChatboxViewMaxLinesPortrait      8
#define LIOChatboxViewMaxLinesLandscape     4

#define LIOChatboxViewAdTextTrigger         @"🈁♨✝ADVERTISEMENT!✝♨🈁"
#define LIOChatboxViewNotificationTrigger   @"🈁♨✝"

@class LIONiceTextField, LIOTextView, JTextView;

/*
@protocol LIOChatboxViewDelegate
- (void)chatboxView:(LIOChatboxView *)aView didReturnWithText:(NSString *)aString;
- (void)chatboxViewDidTapSettingsButton:(LIOChatboxView *)aView;
@optional
- (void)chatboxViewDidTypeStuff:(LIOChatboxView *)aView;
- (void)chatboxViewWasTapped:(LIOChatboxView *)aView;
@end
*/

typedef enum
{
    LIOChatboxViewModeMinimal,
    LIOChatboxViewModeFull
} LIOChatboxViewMode;

@interface LIOChatboxView : UIView <UITextViewDelegate>
{
    UIView *bubbleView;
    UITextView *inputField;
    UILabel *inputFieldPlaceholder, *agentTypingLabel;
    JTextView *messageView;
    UIButton *sendButton;
    UIImageView *inputFieldBackground;
    id settingsButton;
    
    CGFloat singleLineHeight;
    LIOChatboxViewMode currentMode;
    id delegate;
}

@property(nonatomic, readonly) UITextView *inputField;
@property(nonatomic, readonly) UIButton *sendButton;
@property(nonatomic, readonly) id settingsButton;
@property(nonatomic, readonly) UILabel *agentTypingLabel;
@property(nonatomic, assign) id delegate;

- (id)initWithFrame:(CGRect)frame initialMode:(LIOChatboxViewMode)initialMode;
- (void)populateMessageViewWithText:(NSString *)aString;
- (void)switchToMode:(LIOChatboxViewMode)aMode;
- (void)rejiggerLayout;

@end
