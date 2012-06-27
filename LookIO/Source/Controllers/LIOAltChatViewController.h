//
//  LIOAltChatViewController.h
//  LookIO
//
//  Created by Joseph Toscano on 12/5/11.
//  Copyright (c) 2011 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LIOSurveyManager.h" // for LIOSurveyManagerSurveyType

typedef enum
{
    LIOAltChatViewControllerModeChat,
    LIOAltChatViewControllerModeSurvey
} LIOAltChatViewControllerMode;

@class LIOAltChatViewController, LIOInputBarView, LIOHeaderBarView, LIODismissalBarView, LIOGradientLayer, LIOToasterView;
@class LIOSurveyPickerView, LIOSurveyValidationView;

@protocol LIOInputBarViewDelegate;
@protocol LIOHeaderBarViewDelegate;
@protocol LIOAboutViewControllerDelegate;
@protocol LIODismissalBarViewDelegate;
@protocol LIOEmailHistoryViewControllerDelegate;
@protocol LIOLeaveMessageViewControllerDelegate;
@protocol LIOChatBubbleViewDelegate;
@protocol LIOToasterViewDelegate;
@protocol LIOSurveyPickerViewDelegate;

@protocol LIOAltChatViewControllerDelegate
- (void)altChatViewController:(LIOAltChatViewController *)aController wasDismissedWithPendingChatText:(NSString *)aString;
- (void)altChatViewController:(LIOAltChatViewController *)aController didChatWithText:(NSString *)aString;
- (void)altChatViewControllerDidTapEndSessionButton:(LIOAltChatViewController *)aController;
- (void)altChatViewControllerDidTapEndScreenshotsButton:(LIOAltChatViewController *)aController;
- (BOOL)altChatViewController:(LIOAltChatViewController *)aController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation;
- (void)altChatViewController:(LIOAltChatViewController *)aController didEnterBetaEmail:(NSString *)anEmail;
- (void)altChatViewController:(LIOAltChatViewController *)aController didEnterTranscriptEmail:(NSString *)anEmail;
- (void)altChatViewController:(LIOAltChatViewController *)aController didEnterLeaveMessageEmail:(NSString *)anEmail withMessage:(NSString *)aMessage;
- (void)altChatViewControllerWantsSessionTermination:(LIOAltChatViewController *)aController;
- (void)altChatViewControllerWantsToLeaveSurvey:(LIOAltChatViewController *)aController;
- (void)altChatViewController:(LIOAltChatViewController *)aController didFinishSurveyWithResponses:(NSDictionary *)aResponseDict;
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
     LIOHeaderBarViewDelegate, LIOAboutViewControllerDelegate, LIODismissalBarViewDelegate,
     LIOEmailHistoryViewControllerDelegate, LIOLeaveMessageViewControllerDelegate, LIOChatBubbleViewDelegate,
     LIOToasterViewDelegate, UIPopoverControllerDelegate, LIOSurveyPickerViewDelegate, UIAlertViewDelegate>
{
    CGFloat previousScrollHeight;
    UIView *background;
    UIView *reconnectionOverlay;
    UITableView *tableView;
    NSArray *currentMessages, *chatMessages;
    NSMutableArray *surveyMessages;
    NSUInteger previousTextLength;
    NSString *pendingChatText, *initialChatText;
    BOOL agentTyping, keyboardShowing, leavingMessage;
    LIOInputBarView *inputBar;
    LIOHeaderBarView *headerBar;
    UITableViewCell *functionHeaderChat, *functionHeaderSurvey;
    UIButton *aboutButton, *emailConvoButton, *dismissButton, *leaveSurveyButton;
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
    BOOL aboutScreenWasPresentedViaInputBarAdArea;
    LIOAltChatViewControllerMode currentMode;
    int currentSurveyQuestionIndex;
    LIOSurveyManagerSurveyType currentSurveyType;
    NSString *currentSurveyValidationErrorString;
    LIOSurveyPickerView *surveyPicker;
    LIOSurveyValidationView *validationView;
    id pendingSurveyResponse;
    int numPreviousMessagesToShowInScrollback;
    int previousSurveyQuestionBubbleGenerated;
    BOOL pickerIsBeingUsed;
    id<LIOAltChatViewControllerDelegate> delegate;
    id<LIOAltChatViewControllerDataSource> dataSource;
}

@property(nonatomic, assign) id<LIOAltChatViewControllerDelegate> delegate;
@property(nonatomic, assign) id<LIOAltChatViewControllerDataSource> dataSource;
@property(nonatomic, retain) NSString *initialChatText;
@property(nonatomic, assign, getter=isAgentTyping) BOOL agentTyping;
@property(nonatomic, assign) LIOAltChatViewControllerMode currentMode;
@property(nonatomic, assign) LIOSurveyManagerSurveyType currentSurveyType;
@property(nonatomic, assign) int currentSurveyQuestionIndex;

- (void)reloadMessages;
- (void)scrollToBottomDelayed:(BOOL)delayed;
- (void)performRevealAnimation;
- (void)performDismissalAnimation;
- (void)showReconnectionOverlay;
- (void)hideReconnectionOverlay;
- (NSString *)currentChatText;
- (void)revealNotificationString:(NSString *)aString withAnimatedKeyboard:(BOOL)animated;

@end
