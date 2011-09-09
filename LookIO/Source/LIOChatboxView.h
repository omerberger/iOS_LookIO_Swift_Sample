//
//  LIOChatboxView.h
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LIONiceTextField, LIOTextView;

/*
@protocol LIOChatboxViewDelegate
- (void)chatboxView:(LIOChatboxView *)aView didReturnWithText:(NSString *)aString;
- (void)chatboxViewDidTapSettingsButton:(LIOChatboxView *)aView;
@end
*/

@interface LIOChatboxView : UIView <UITextFieldDelegate>
{
    UIView *bubbleView;
    LIONiceTextField *inputField;
    UILabel *messageView;
    UIButton *sendButton;
    id settingsButton;
    id delegate;
}

@property(nonatomic, readonly) LIONiceTextField *inputField;
@property(nonatomic, readonly) UIButton *sendButton;
@property(nonatomic, readonly) id settingsButton;
@property(nonatomic, assign) id delegate;

- (void)populateMessageViewWithText:(NSString *)aString;

@end
