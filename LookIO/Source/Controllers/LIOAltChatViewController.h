//
//  LIOAltChatViewController.h
//  LookIO
//
//  Created by Joseph Toscano on 12/5/11.
//  Copyright (c) 2011 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LIOSurveyManager.h"

@class LIOAltChatViewController, LIOInputBarView, LIOHeaderBarView, LIODismissalBarView, LIOGradientLayer, LIOToasterView, LIOSurveyView;
@class LIOTimerProxy, LIOChatMessage, LIOSurveyManager, LIOWebView, LIOKeyboardMenu;

@protocol LIOInputBarViewDelegate;
@protocol LIOHeaderBarViewDelegate;
@protocol LIODismissalBarViewDelegate;
@protocol LIOEmailHistoryViewControllerDelegate;
@protocol LIOLeaveMessageViewControllerDelegate;
@protocol LIOChatBubbleViewDelegate;
@protocol LIOToasterViewDelegate;
@protocol LIOSurveyViewDelegate;
@protocol LIOKeyboardMenuDelegate;

// LIOGradientLayer gets rid of implicit layer animations.
@interface LIOGradientLayer : CAGradientLayer
@end

@protocol LIOAltChatViewControllerDelegate
- (void)altChatViewController:(LIOAltChatViewController *)aController wasDismissedWithPendingChatText:(NSString *)aString;
- (void)altChatViewController:(LIOAltChatViewController *)aController didChatWithText:(NSString *)aString;
- (void)altChatViewController:(LIOAltChatViewController *)aController didChatWithAttachmentId:(NSString *)aString;
- (void)altChatViewControllerDidTapEndSessionButton:(LIOAltChatViewController *)aController;
- (void)altChatViewControllerDidTapEndScreenshotsButton:(LIOAltChatViewController *)aController;
- (BOOL)altChatViewController:(LIOAltChatViewController *)aController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation;
- (BOOL)altChatViewControllerShouldAutorotate:(LIOAltChatViewController *)aController;
- (NSInteger)altChatViewControllerSupportedInterfaceOrientations:(LIOAltChatViewController *)aController;
- (void)altChatViewController:(LIOAltChatViewController *)aController didEnterTranscriptEmail:(NSString *)anEmail;
- (void)altChatViewController:(LIOAltChatViewController *)aController didEnterLeaveMessageEmail:(NSString *)anEmail withMessage:(NSString *)aMessage;
- (void)altChatViewControllerWantsSessionTermination:(LIOAltChatViewController *)aController;
- (void)altChatViewControllerWantsToLeaveSurvey:(LIOAltChatViewController *)aController;
- (void)altChatViewController:(LIOAltChatViewController *)aController didResendChatMessage:(LIOChatMessage*)aMessage;
- (void)altChatViewController:(LIOAltChatViewController *)aController didFinishPreSurveyWithResponses:(NSDictionary *)aResponseDict;
- (void)altChatViewController:(LIOAltChatViewController *)aController didFinishOfflineSurveyWithResponses:(NSDictionary*)aResponseDict;
- (void)altChatViewController:(LIOAltChatViewController *)aController didFinishPostSurveyWithResponses:(NSDictionary*)aResponseDict;
- (BOOL)altChatViewControllerShouldHideEmailChat:(LIOAltChatViewController *)aController;

@optional
- (void)altChatViewControllerDidStartDismissalAnimation:(LIOAltChatViewController *)aController;
- (void)altChatViewControllerDidFinishDismissalAnimation:(LIOAltChatViewController *)aController;
- (void)altChatViewControllerTypingDidStart:(LIOAltChatViewController *)aController;
- (void)altChatViewControllerTypingDidStop:(LIOAltChatViewController *)aController;
- (void)altChatViewControllerWillPresentImagePicker:(LIOAltChatViewController *)aController;
- (void)altChatViewControllerWillDismissImagePicker:(LIOAltChatViewController *)aController;

@end

@protocol LIOAltChatViewControllerDataSource
- (NSArray *)altChatViewControllerChatMessages:(LIOAltChatViewController *)aController;
@end

@interface LIOAltChatViewController : UIViewController
    <UIActionSheetDelegate, UITableViewDataSource, UITableViewDelegate, LIOInputBarViewDelegate, UIScrollViewDelegate,
     LIOHeaderBarViewDelegate, LIODismissalBarViewDelegate, LIOEmailHistoryViewControllerDelegate,
     LIOLeaveMessageViewControllerDelegate, LIOChatBubbleViewDelegate, LIOToasterViewDelegate, UIPopoverControllerDelegate,
    UIAlertViewDelegate, UIImagePickerControllerDelegate, LIOSurveyViewDelegate, LIOKeyboardMenuDelegate>
{
    CGFloat previousScrollHeight;
    UIView *background;
    UIView *reconnectionOverlay;
    UITableView *tableView;
    NSArray *chatMessages;
    NSUInteger previousTextLength;
    NSString *pendingChatText, *initialChatText;
    BOOL agentTyping, keyboardShowing, leavingMessage;
    LIOInputBarView *inputBar;
    LIOHeaderBarView *headerBar;
    UITableViewCell *functionHeaderChat;
    UIButton *emailConvoButton, *dismissButton;
    LIODismissalBarView *dismissalBar;
    CGFloat keyboardHeight;
    LIOGradientLayer *vertGradient, *horizGradient;
    UIPopoverController *popover;
    NSUInteger currentScrollId;
    NSMutableArray *chatBubbleHeights;
    UIView *tappableDismissalAreaForPadUI;
    LIOToasterView *toasterView;
    NSString *pendingNotificationString;
    BOOL pendingNotificationStringIsTypingNotification;
    BOOL surveyWasCanceled;
    id pendingSurveyResponse;
    int numPreviousMessagesToShowInScrollback;
    NSMutableArray *messagesSentBeforeAvailabilityKnown;
    UIAlertView *alertView;
    UIActionSheet *actionSheet;
    NSString *lastSentMessageText;
    UIImage *pendingImageAttachment;
    id<LIOAltChatViewControllerDelegate> delegate;
    id<LIOAltChatViewControllerDataSource> dataSource;
    
    LIOSurveyView* surveyView;
    BOOL surveyInProgress, waitingForSurvey, waitingForEngagementToStart;

    int currentPopoverType;

    LIOChatMessage *clickedFailedMessage;
    NSInteger clickedFailedMessageIndex;
    
    BOOL isAnimatingDismissal;
    BOOL isAnimatingReveal;
    
    BOOL shouldHideStatusBarAfterImagePicker;
    BOOL viewWereUpdatedForPreferedStatusBar;
    
    NSURL *urlBeingLaunched;

    LIOWebView* webView;

    NSMutableArray* chatModules;
    int activeChatModuleIndex;
    UIView* topButtonsView;
    UIView* moduleView;
    BOOL isModuleViewVisible;

    LIOKeyboardMenu *keyboardMenu;
    BOOL keyboardMenuIsVisible;
}

@property(nonatomic, assign) id<LIOAltChatViewControllerDelegate> delegate;
@property(nonatomic, assign) id<LIOAltChatViewControllerDataSource> dataSource;
@property(nonatomic, retain) NSString *initialChatText;
@property(nonatomic, assign, getter=isAgentTyping) BOOL agentTyping;

- (void)reloadMessages;
- (void)scrollToBottomDelayed:(BOOL)delayed;
- (void)performRevealAnimationWithFadeIn:(BOOL)fadeIn;
- (void)performDismissalAnimation;
- (void)showReconnectionOverlay;
- (void)hideReconnectionOverlay;
- (NSString *)currentChatText;
- (NSString*)lastSentMessageText;
- (void)revealNotificationString:(NSString *)aString withAnimatedKeyboard:(BOOL)animated;
- (void)forceLeaveMessageScreen;
- (void)bailOnSecondaryViews;
- (void)showSurveyViewForType:(LIOSurveyManagerSurveyType)surveyType;
- (void)dismissSurveyView;
- (void)noSurveyRecieved;
- (void)engagementDidStart;
- (void)hideChatUIForSurvey:(BOOL)animated;
- (void)dismissExistingAlertView;

@end
