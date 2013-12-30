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

typedef enum
{
    LIOSSEChannelStateInitialized = 0,
    LIOSSEChannelStateConnecting,
    LIOSSEChannelStateConnected,
    LIOSSEChannelStateCancelling
} LIOSSEChannelState;

@class LIOEngagement;

@protocol LIOEngagementDelegate <NSObject>

- (void)engagementDidStart:(LIOEngagement *)engagement;
- (void)engagementDidConnect:(LIOEngagement *)engagement;
- (void)engagementDidFailToStart:(LIOEngagement *)engagement;
- (void)engagementDidCancel:(LIOEngagement *)engagement;
- (void)engagementDidEnd:(LIOEngagement *)engagement;
- (void)engagement:(LIOEngagement *)engagement didSendMessage:(LIOChatMessage *)message;
- (void)engagement:(LIOEngagement *)engagement didReceiveMessage:(LIOChatMessage *)message;
- (void)engagement:(LIOEngagement *)engagement didReceiveNotification:(NSString *)notification;

@end

@interface LIOEngagement : NSObject

@property (nonatomic, assign) id <LIOEngagementDelegate> delegate;

@property (nonatomic, assign) NSInteger lastClientLineId;
@property (nonatomic, strong) NSMutableArray *messages;

- (id)initWithVisit:(LIOVisit *)aVisit;

- (void)startEngagement;
- (void)cancelEngagement;
- (void)endEngagement;

- (void)sendVisitorLineWithText:(NSString *)text;

@end
