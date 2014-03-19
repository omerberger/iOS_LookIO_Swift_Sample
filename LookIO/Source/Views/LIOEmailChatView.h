//
//  LIOEmailChatView.h
//  LookIO
//
//  Created by Yaron Karasik on 1/8/14.
//
//

#import <UIKit/UIKit.h>

typedef enum
{
    LIOEmailChatViewResultNone,
    LIOEmailChatViewResultCancel,
    LIOEmailChatViewResultSubmit
} LIOEmailChatViewResult;

@class LIOEmailChatView;

@protocol LIOEmailChatViewDelegate <NSObject>

- (void)emailChatViewDidCancel:(LIOEmailChatView *)emailChatView;
- (void)emailChatView:(LIOEmailChatView *)emailChatView didSubmitEmail:(NSString *)email;
- (void)emailChatViewDidForceDismiss:(LIOEmailChatView *)emailChatView;
- (void)emailChatViewDidFinishDismissAnimation:(LIOEmailChatView *)emailChatView;

@end

@interface LIOEmailChatView : UIView

@property (nonatomic, assign) id<LIOEmailChatViewDelegate> delegate;
@property (nonatomic, assign) LIOEmailChatViewResult emailChatViewResult;

- (void)present;
- (void)dismiss;
- (void)forceDismiss;
- (void)dismissExistingAlertView;
- (void)cleanup;

@end
