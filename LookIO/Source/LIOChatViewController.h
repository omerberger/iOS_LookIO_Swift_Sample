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
@end
 */

@interface LIOChatViewController : UIViewController
{
    UIView *backgroundView;
    UIScrollView *scrollView;
    NSMutableArray *messageViews;
    UIButton *dismissalButton;
    id delegate;
}

@property(nonatomic, assign) id delegate;

- (void)reloadMessages;
- (void)addMessage:(NSString *)aMessage animated:(BOOL)animated;
- (void)addMessages:(NSArray *)messages;
- (void)scrollToBottom;

@end
