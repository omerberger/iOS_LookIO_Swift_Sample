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
}

@property(nonatomic, readonly) UITextView *messageView;

@end
