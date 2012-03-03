//
//  LIOAltChatViewController.h
//  LookIO
//
//  Created by Joseph Toscano on 12/5/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LIOAltChatViewController, LIOInputBarView, LIOHeaderBarView;

@protocol LIOInputBarViewDelegate;

@protocol LIOHeaderBarViewDelegate;

@protocol LIOAboutViewControllerDelegate;

@protocol LIOAltChatViewControllerDelegate
- (void)altChatViewController:(LIOAltChatViewController *)aController wasDismissedWithPendingChatText:(NSString *)aString;
- (void)altChatViewController:(LIOAltChatViewController *)aController didChatWithText:(NSString *)aString;
- (void)altChatViewControllerDidTapEndSessionButton:(LIOAltChatViewController *)aController;
- (void)altChatViewControllerDidTapEndScreenshotsButton:(LIOAltChatViewController *)aController;
- (void)altChatViewControllerDidTapEmailButton:(LIOAltChatViewController *)aController;
- (BOOL)altChatViewController:(LIOAltChatViewController *)aController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation;
- (void)altChatViewController:(LIOAltChatViewController *)aController didEnterBetaEmail:(NSString *)anEmail;
@optional
- (void)altChatViewControllerDidStartDismissalAnimation:(LIOAltChatViewController *)aController;
- (void)altChatViewControllerDidFinishDismissalAnimation:(LIOAltChatViewController *)aController;
- (void)altChatViewControllerTypingDidStart:(LIOAltChatViewController *)aController;
- (void)altChatViewControllerTypingDidStop:(LIOAltChatViewController *)aController;
@end

@protocol LIOAltChatViewControllerDataSource
- (NSArray *)altChatViewControllerChatMessages:(LIOAltChatViewController *)aController;
@end

@interface LIOAltChatViewController : UIViewController
    <UIActionSheetDelegate, UITableViewDataSource, UITableViewDelegate, LIOInputBarViewDelegate, UIScrollViewDelegate,
     LIOHeaderBarViewDelegate, LIOAboutViewControllerDelegate>
{
    UIImageView *background;
    UITableView *tableView;
    NSArray *messages;
    UIActionSheet *settingsActionSheet;
    NSUInteger endSessionIndex, endSharingIndex, emailIndex;
    NSUInteger previousTextLength;
    NSString *pendingChatText, *initialChatText;
    BOOL agentTyping;
    LIOInputBarView *inputBar;
    LIOHeaderBarView *headerBar;
    UITableViewCell *functionHeader;
    id<LIOAltChatViewControllerDelegate> delegate;
    id<LIOAltChatViewControllerDataSource> dataSource;
}

@property(nonatomic, assign) id<LIOAltChatViewControllerDelegate> delegate;
@property(nonatomic, assign) id<LIOAltChatViewControllerDataSource> dataSource;
@property(nonatomic, retain) NSString *initialChatText;
@property(nonatomic, assign) BOOL agentTyping;

- (void)reloadMessages;

@end
