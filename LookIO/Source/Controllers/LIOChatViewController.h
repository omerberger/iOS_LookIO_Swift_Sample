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
    LIOKeyboardstateCompletelyHidden
} LIOKeyboardState;

typedef enum {
    LIOChatStateChat = 0,
    LIOChatStateEmailChat,
    LIOChatStateImagePicker,
    LIOChatStateWeb,
    LIOChatStateImageApprove
} LIOChatState;

@class LIOChatViewController;

@protocol LIOChatViewControllerDelegate <NSObject>

- (void)chatViewControllerDidDismissChat:(LIOChatViewController *)chatViewController;
- (void)chatViewControllerDidEndChat:(LIOChatViewController *)chatViewController;
- (void)chatViewControllerDidTapIntraAppLink:(NSURL *)url;
- (void)chatViewControllerDidTapWebLink:(NSURL *)url;
- (void)chatViewControllerLandscapeWantsHeaderBarHidden:(BOOL)hidden;

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

- (BOOL)shouldHideHeaderBarForLandscape;

- (void)dismissExistingAlertView;

@end
