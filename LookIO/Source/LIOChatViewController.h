//
//  LIOChatViewController.h
//  LookIO
//
//  Created by Joe Toscano on 8/27/11.
//  Copyright 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LIOChatboxView, LIOChatViewController;

/*
@protocol LIOChatViewControllerDelegate
- (void)chatViewControllerWasDismissed:(LIOChatViewController *)aController;
- (void)chatViewController:(LIOChatViewController *)aController didChatWithText:(NSString *)aString;
- (void)chatViewControllerDidTapEndSessionButton:(LIOChatViewController *)aController;
@end

@protocol LIOChatViewControllerDataSource
- (NSArray *)chatViewControllerChatMessages:(LIOChatViewController *)aController;
@end
*/

@interface LIOChatViewController : UIViewController
{
    UIView *backgroundView;
    UIScrollView *scrollView;
    NSMutableArray *messageViews;
    UIButton *dismissalButton;
    id endSessionButton;
    id delegate;
    id dataSource;
}

@property(nonatomic, assign) id delegate, dataSource;

- (void)reloadMessages;
- (void)scrollToBottom;

@end
