//
//  LIOChatboxView.h
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LIOChatboxView : UIView <UITextFieldDelegate>
{
    UIView *bubbleView;
    UITextField *inputField;
    UITextView *messageView;
    BOOL canTakeInput;
    id delegate;
}

@property(nonatomic, readonly) UITextView *messageView;
@property(nonatomic, readonly) UITextField *inputField;
@property(nonatomic, assign) BOOL canTakeInput;
@property(nonatomic, assign) id delegate;

- (void)takeInput;

@end
