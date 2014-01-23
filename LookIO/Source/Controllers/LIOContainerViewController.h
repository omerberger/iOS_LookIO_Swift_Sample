//
//  LIOContainerViewController.h
//  LookIO
//
//  Created by Yaron Karasik on 12/9/13.
//
//

#import <UIKit/UIKit.h>
#import "LIOEngagement.h"
#import "LPSurveyViewController.h"
#import "LIOChatViewController.h"

typedef enum {
    LIOHeaderBarStateHidden = 0,
    LIOHeaderBarStateVisible,
    LIOHeaderBarStateLandscapeHidden
} LIOHeaderBarState;

typedef enum {
    LIOContainerViewStateLoading = 0,
    LIOContainerViewStateChat,
    LIOContainerViewStateSurvey
} LIOContainerViewState;

@class LIOContainerViewController;

@protocol LIOContainerViewControllerDelegate <NSObject>

- (void)containerViewControllerDidDismiss:(LIOContainerViewController *)containerViewController;
- (void)containerViewControllerDidPresentPostChatSurvey:(LIOContainerViewController *)containerViewController;

@end

@interface LIOContainerViewController : UIViewController

@property (nonatomic, assign) id <LIOContainerViewControllerDelegate> delegate;

- (void)setBlurImage:(UIImage *)image;
- (void)updateBlurImage:(UIImage *)image;

- (void)presentChatForEngagement:(LIOEngagement *)anEngagement;
- (void)presentPrechatSurveyForEngagement:(LIOEngagement *)anEngagement;
- (void)presentOfflineSurveyForEngagement:(LIOEngagement *)anEngagement;
- (void)presentPostchatSurveyForEngagement:(LIOEngagement *)anEngagement;

- (void)engagement:(LIOEngagement *)engagement didReceiveMessage:(LIOChatMessage *)message;
- (void)engagement:(LIOEngagement *)engagement didReceiveNotification:(NSString *)notification;
- (void)engagement:(LIOEngagement *)engagement agentIsTyping:(BOOL)isTyping;
- (void)engagementChatMessageStatusDidChange:(LIOEngagement *)engagement;

- (void)presentLoadingViewController;
- (void)dismissCurrentViewController;


@end
