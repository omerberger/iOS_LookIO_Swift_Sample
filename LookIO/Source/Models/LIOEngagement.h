//
//  LIOEngagement.h
//  LookIO
//
//  Created by Yaron Karasik on 12/5/13.
//
//

#import <Foundation/Foundation.h>
#import "LIOVisit.h"

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
- (void)engagementDidFailToStart:(LIOEngagement *)engagement;
- (void)engagementDidCancel:(LIOEngagement *)engagement;

@end

@interface LIOEngagement : NSObject

@property (nonatomic, assign) id <LIOEngagementDelegate> delegate;

@property (nonatomic, assign) NSInteger lastClientLineId;
@property (nonatomic, strong) NSMutableArray *messages;

- (id)initWithVisit:(LIOVisit *)aVisit;

- (void)startEngagement;
- (void)cancelEngagement;
- (void)endEngagement;

@end
