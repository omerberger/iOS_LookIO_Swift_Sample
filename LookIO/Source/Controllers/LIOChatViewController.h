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
    LIOKeyboardStateMenu
} LIOKeyboardState;

@class LIOChatViewController;

@protocol LIOChatViewControllerDelegate <NSObject>

- (void)chatViewControllerDidDismissChat:(LIOChatViewController *)chatViewController;

@end

@interface LIOChatViewController : UIViewController

@property (nonatomic, assign) id <LIOChatViewControllerDelegate> delegate;

- (void)setEngagement:(LIOEngagement *)engagement;

@end
