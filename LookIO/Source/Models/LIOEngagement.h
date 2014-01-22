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

@class LIOEngagement;

@protocol LIOEngagementDelegate <NSObject>

- (void)engagementDidStart:(LIOEngagement *)engagement;
- (void)engagementDidConnect:(LIOEngagement *)engagement;
- (void)engagementAgentIsReady:(LIOEngagement *)engagement;
- (void)engagementDidFailToStart:(LIOEngagement *)engagement;
- (void)engagementDidCancel:(LIOEngagement *)engagement;
- (void)engagementDidEnd:(LIOEngagement *)engagement;
- (void)engagementDidDisconnect:(LIOEngagement *)engagement withAlert:(BOOL)withAlert;
- (void)engagement:(LIOEngagement *)engagement didSendMessage:(LIOChatMessage *)message;
- (void)engagement:(LIOEngagement *)engagement didReceiveMessage:(LIOChatMessage *)message;
- (void)engagement:(LIOEngagement *)engagement didReceiveNotification:(NSString *)notification;
- (void)engagementDidReceivePrechatSurvey:(LIOEngagement *)engagement;
- (void)engagementDidReceiveOfflineSurvey:(LIOEngagement *)engagement;
- (void)engagementDidSubmitPrechatSurvey:(LIOEngagement *)engagement;
- (void)engagement:(LIOEngagement *)engagement agentDidUpdateTypingStatus:(BOOL)isTyping;
- (BOOL)engagementShouldShowSendPhotoKeyboardItem:(LIOEngagement *)engagement;
- (void)engagementWantsReconnectionPrompt:(LIOEngagement *)engagement;
- (void)engagementDidReconnect:(LIOEngagement *)engagement;
- (void)engagementDidFailToReconnect:(LIOEngagement *)engagement;

@end

@interface LIOEngagement : NSObject

@property (nonatomic, assign) id <LIOEngagementDelegate> delegate;

@property (nonatomic, assign) NSInteger lastClientLineId;
@property (nonatomic, strong) NSMutableArray *messages;

@property (nonatomic, strong) LIOSurvey *prechatSurvey;
@property (nonatomic, strong) LIOSurvey *postchatSurvey;
@property (nonatomic, strong) LIOSurvey *offlineSurvey;

- (id)initWithVisit:(LIOVisit *)aVisit;

- (void)startEngagement;
- (void)cancelEngagement;
- (void)endEngagement;
- (void)declineEngagementReconnect;
- (void)acceptEngagementReconnect;
- (void)cancelReconnect;
- (void)cleanUpEngagement;

- (void)sendVisitorLineWithText:(NSString *)text;
- (void)sendVisitorLineWithAttachmentId:(NSString *)attachmentId;

- (void)submitSurvey:(LIOSurvey *)survey;
- (void)sendChatHistoryPacketWithEmail:(NSString *)email;
- (BOOL)shouldPresentPostChatSurvey;

- (void)sendAdvisoryPacketWithDict:(NSDictionary *)advisoryDict;

- (BOOL)shouldShowEmailChatButtonItem;
- (BOOL)shouldShowSendPhotoButtonItem;

@end
