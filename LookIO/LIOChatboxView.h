//
//  LIOChatboxView.h
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 Joseph Toscano. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LIOChatboxView;

@protocol LIOChatboxViewDelegate
- (void)chatboxViewWasTapped:(LIOChatboxView *)aView;
@end

@interface LIOChatboxView : UIView <UITextFieldDelegate>
{
    UITextView *historyView;
    UITextField *inputField;
    id<LIOChatboxViewDelegate> delegate;
}

@property(nonatomic, assign) id<LIOChatboxViewDelegate> delegate;

- (void)addText:(NSString *)someText;

@end
