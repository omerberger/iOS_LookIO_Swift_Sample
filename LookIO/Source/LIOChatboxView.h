//
//  LIOChatboxView.h
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define LIOChatboxViewMaxTextLength         400
#define LIOChatboxViewMaxLinesPortrait      8
#define LIOChatboxViewMaxLinesLandscape     4

@class LIONiceTextField, LIOTextView;

/*
@protocol LIOChatboxViewDelegate
- (void)chatboxView:(LIOChatboxView *)aView didReturnWithText:(NSString *)aString;
- (void)chatboxViewDidTapSettingsButton:(LIOChatboxView *)aView;
@optional
- (void)chatboxViewDidTypeStuff:(LIOChatboxView *)aView;
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
    UILabel *messageView;
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
@property(nonatomic, assign) id delegate;

- (void)populateMessageViewWithText:(NSString *)aString;
- (void)switchToMode:(LIOChatboxViewMode)aMode;
- (void)rejiggerLayout;

@end
