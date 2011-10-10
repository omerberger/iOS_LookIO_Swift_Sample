//
//  LIOChatViewController.h
//  LookIO
//
//  Created by Joe Toscano on 8/27/11.
//  Copyright 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LIOTimerProxy.h"

@class LIOChatboxView, LIOChatViewController;

/*
@protocol LIOChatViewControllerDelegate
- (void)chatViewControllerWasDismissed:(LIOChatViewController *)aController;
- (void)chatViewController:(LIOChatViewController *)aController didChatWithText:(NSString *)aString;
- (void)chatViewControllerDidTapEndSessionButton:(LIOChatViewController *)aController;
- (void)chatViewControllerDidTapEndScreenshotsButton:(LIOChatViewController *)aController;
- (void)chatViewControllerDidTapEmailButton:(LIOChatViewController *)aController;
@optional
- (void)chatViewControllerDidFinishDismissalAnimation:(LIOChatViewController *)aController;
- (void)chatViewControllerTypingDidStart:(LIOChatViewController *)aController;
- (void)chatViewControllerTypingDidStop:(LIOChatViewController *)aController;
@end

@protocol LIOChatViewControllerDataSource
- (NSArray *)chatViewControllerChatMessages:(LIOChatViewController *)aController;
@end
*/

@interface LIOChatViewController : UIViewController <UIActionSheetDelegate>
{
    UIView *backgroundView;
    UIScrollView *scrollView;
    NSMutableArray *messageViews;
    UIButton *dismissalButton;
    NSUInteger endSessionIndex, endSharingIndex, emailIndex;
    NSUInteger previousTextLength;
    id delegate;
    id dataSource;
}

@property(nonatomic, assign) id delegate, dataSource;

- (void)reloadMessages;
- (void)scrollToBottom;
- (void)performDismissalAnimation;
- (void)performRevealAnimation;

@end
