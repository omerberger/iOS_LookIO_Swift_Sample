//
//  LIOEmailChatView.h
//  LookIO
//
//  Created by Yaron Karasik on 1/8/14.
//
//

#import <UIKit/UIKit.h>

@class LIOEmailChatView;

@protocol LIOEmailChatViewDelegate <NSObject>

- (void)emailChatViewDidCancel:(LIOEmailChatView *)emailChatView;
- (void)emailChatView:(LIOEmailChatView *)emailChatView didSubmitEmail:(NSString *)email;

@end

@interface LIOEmailChatView : UIView

@property (nonatomic, assign) id<LIOEmailChatViewDelegate> delegate;

@end
