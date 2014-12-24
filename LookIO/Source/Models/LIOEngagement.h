//
//  LIOEngagement.h
//  LookIO
//
//  Created by Yaron Karasik on 12/5/13.
//
//

#import <Foundation/Foundation.h>

#import "LIOVisit.h"
#import "LIOChatMessage.h"
#import "LIOSurvey.h"

typedef enum
{
    LIOSSEChannelStateInitialized = 0,
    LIOSSEChannelStateConnecting,
    LIOSSEChannelStateConnected,
    LIOSSEChannelStateCancelling,
    LIOSSEChannelStateEnding,
    LIOSSEChannelStateDisconnecting,
    LIOSSEChannelStateReconnecting,
    LIOSSEChannelStateReconnectPrompt,
    LIOSSEChannelStateReconnectRetryAfter
} LIOSSEChannelState;

typedef enum
{
    LIOQueuedRequestTypeCapabilities,
    LIOQueuedRequestTypeSurvey,
    LIOQueuedRequestTypeAdvisory,
    LIOQueuedRequestTypeChatHistory,
    LIOQueuedRequestTypePermission
} LIOQueuedRequestType;

@class LIOEngagement, LIOSecuredFormInfo;

@protocol LIOEngagementDelegate <NSObject>

// Engagement Lifecycle
- (void)engagementDidQueue:(LIOEngagement *)engagement;
- (void)engagementDidStart:(LIOEngagement *)engagement;
- (void)engagementDidConnect:(LIOEngagement *)engagement;
- (void)engagementAgentIsReady:(LIOEngagement *)engagement;
- (void)engagementDidFailToStart:(LIOEngagement *)engagement;
- (void)engagementDidCancel:(LIOEngagement *)engagement;
- (void)engagementDidEnd:(LIOEngagement *)engagement;
- (void)engagementDidDisconnect:(LIOEngagement *)engagement withAlert:(BOOL)withAlert;
- (void)engagementDidDisconnectWhileInPostOrOfflineSurvey:(LIOEngagement *)engagement;

// Messages and Notifications
- (void)engagement:(LIOEngagement *)engagement didSendMessage:(LIOChatMessage *)message;
- (void)engagement:(LIOEngagement *)engagement didReceiveMessage:(LIOChatMessage *)message;
- (void)engagement:(LIOEngagement *)engagement didReceiveNotification:(NSString *)notification;
- (void)engagement:(LIOEngagement *)engagement agentDidUpdateTypingStatus:(BOOL)isTyping;
- (void)engagementChatMessageStatusDidChange:(LIOEngagement *)engagement;

// Surveys
- (void)engagementDidReceivePrechatSurvey:(LIOEngagement *)engagement;
- (void)engagementDidReceiveOfflineSurvey:(LIOEngagement *)engagement;
- (void)engagementDidSubmitPrechatSurvey:(LIOEngagement *)engagement;
- (void)engagementDidSubmitPostchatSurvey:(LIOEngagement *)engagement;
- (void)engagementDidSubmitOfflineSurvey:(LIOEngagement *)engagement;
- (void)engagementHasNoPrechatSurvey:(LIOEngagement *)engagement;

// Others
- (BOOL)engagementShouldShowSendPhotoKeyboardItem:(LIOEngagement *)engagement;
- (void)engagementRequestedToResendAllUDEs:(LIOEngagement *)engagement;
- (BOOL)engagementShouldCacheChatMessages:(LIOEngagement *)engagement;

// Reconnectiongs
- (void)engagementWantsReconnectionPrompt:(LIOEngagement *)engagement;
- (void)engagementDidReconnect:(LIOEngagement *)engagement;
- (void)engagementDidFailToReconnect:(LIOEngagement *)engagement;

// Screensharing
- (void)engagementWantsScreenshare:(LIOEngagement *)engagement;
- (UIImage *)engagementWantsScreenshot:(LIOEngagement *)engagement;
- (void)engagement:(LIOEngagement *)engagement wantsCursor:(BOOL)cursor;
- (void)engagement:(LIOEngagement *)engagement screenshareCursorMoveToPoint:(CGPoint)point;
- (void)engagement:(LIOEngagement *)engagement screenshareDidClickAtPoint:(CGPoint)point;

// SSO
- (BOOL)engagementShouldUseSSO:(LIOEngagement *)engagement;
- (NSURL *)engagementSSOKeyGenURL:(LIOEngagement *)engagement;

@end

@interface LIOEngagement : NSObject

@property (nonatomic, assign) id <LIOEngagementDelegate> delegate;

@property (nonatomic, assign) BOOL isConnected;
@property (nonatomic, assign) BOOL isAgentTyping;
@property (nonatomic, assign) BOOL didReportChatInteractive;

@property (nonatomic, assign) NSInteger lastClientLineId;
@property (nonatomic, strong) NSMutableArray *messages;

@property (nonatomic, strong) LIOSurvey *prechatSurvey;
@property (nonatomic, strong) LIOSurvey *postchatSurvey;
@property (nonatomic, strong) LIOSurvey *offlineSurvey;

@property (nonatomic, copy) NSString *engagementSkill;
@property (nonatomic, copy) NSString *engagementAccount;

- (id)initWithVisit:(LIOVisit *)aVisit skill:(NSString *)skill account:(NSString *)account;

- (void)startEngagement;
- (void)attemptReconnectionWithVisit:(LIOVisit *)aVisit;
- (void)cancelEngagement;
- (void)endEngagement;
- (void)declineEngagementReconnect;
- (void)acceptEngagementReconnect;
- (void)cancelReconnect;
- (void)cleanUpEngagement;
- (void)engagementNotFound;

- (void)sendVisitorLineWithText:(NSString *)text;
- (void)sendVisitorLineWithAttachmentId:(NSString *)attachmentId;
- (void)sendLineWithMessage:(LIOChatMessage *)message;
- (void)sendMediaPacketWithMessage:(LIOChatMessage *)message;
- (void)sendSubmitPacketWithSecuredFormInfo:(LIOSecuredFormInfo *)securedFormInfo Success:(void(^)())success Failure:(void(^)())failure;

- (void)submitSurvey:(LIOSurvey *)survey retries:(NSInteger)retries;
- (void)sendChatHistoryPacketWithEmail:(NSString *)email retries:(NSInteger)retries;
- (void)sendAdvisoryPacketWithDict:(NSDictionary *)advisoryDict retries:(NSInteger)retries;
- (void)sendPermissionPacketWithDict:(NSDictionary *)permissionDict retries:(NSInteger)retries;

- (BOOL)shouldPresentPostChatSurvey;

- (BOOL)shouldShowEmailChatButtonItem;
- (BOOL)shouldShowSendPhotoButtonItem;

- (void)reachabilityDidChange;

+ (LIOEngagement *)loadExistingEngagement;

- (void)startScreenshare;
- (void)stopScreenshare;


@end
