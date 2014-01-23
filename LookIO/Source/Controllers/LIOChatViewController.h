//
//  LIOChatViewController.h
//  LookIO
//
//  Created by Yaron Karasik on 12/5/13.
//
//

#import <UIKit/UIKit.h>

#import "LIOEngagement.h"

typedef enum {
    LIOKeyboardStateKeyboard = 0,
    LIOKeyboardStateHidden,
    LIOKeyboardStateMenu,
    LIOKeyboardStateMenuDragging,
    LIOKeyboardStateIntroAnimation,
    LIOKeyboardStateEmailChatIntroAnimation,
    LIOKeyboardStateEmailChatOutroAnimation
} LIOKeyboardState;

typedef enum {
    LIOChatStateChat = 0,
    LIOChatStateEmailChat,
    LIOChatStateImagePicker,
    LIOChatStateImageApprove
} LIOChatState;

@class LIOChatViewController;

@protocol LIOChatViewControllerDelegate <NSObject>

- (void)chatViewControllerDidDismissChat:(LIOChatViewController *)chatViewController;
- (void)chatViewControllerVisitorDidSendLine:(NSString *)line;
- (void)chatViewControllerDidEndChat:(LIOChatViewController *)chatViewController;

@end

@interface LIOChatViewController : UIViewController

@property (nonatomic, assign) id <LIOChatViewControllerDelegate> delegate;

- (void)setEngagement:(LIOEngagement *)engagement;
- (void)engagement:(LIOEngagement *)engagement didReceiveMessage:(LIOChatMessage *)message;
- (void)engagementChatMessageStatusDidChange:(LIOEngagement *)engagement;
- (void)dismissChat:(id)sender;

- (void)headerBarViewPlusButtonWasTapped;

- (void)displayToasterNotification:(NSString *)notification;
- (void)displayToasterAgentIsTyping:(BOOL)isTyping;

@end
