//
//  LPSSEManager.h
//  Barracuda
//
//  Created by Joe Toscano on 1/7/13.
//  Copyright (c) 2013 LivePerson, Inc. All rights reserved.
//

/*
 ¡¡ N.B. !!
 This class only supports SSE-encoded keys called "data".
 */

#import <UIKit/UIKit.h>

@class LPSSEManager;
@class AsyncSocket_LIO;
@class LPSSEvent;
@protocol AsyncSocketDelegate_LIO;

@protocol LPSSEManagerDelegate <NSObject>
- (void)sseManagerDidConnect:(LPSSEManager *)aManager;
- (void)sseManagerWillDisconnect:(LPSSEManager *)aManager withError:(NSError*)err;
- (void)sseManagerDidDisconnect:(LPSSEManager *)aManager;
- (void)sseManager:(LPSSEManager *)aManager didDispatchEvent:(LPSSEvent *)anEvent;
@end

typedef enum {
    LPSSEManagerReadyStateConnecting      = 0,
    LPSSEManagerReadyStateOpen            = 1,
    LPSSEManagerReadyStateClosed          = 2
} LPSSEManagerReadyState;

@interface LPSSEManager : NSObject <AsyncSocketDelegate_LIO> {
    NSString* host;
    NSString* urlEndpoint;
    int port;
    id <LPSSEManagerDelegate> delegate;
    BOOL usesTLS;
    BOOL usesSecretToken;
    NSString* secretToken;
}

- (id)initWithHost:(NSString *)aHost port:(NSNumber*)aPort urlEndpoint:(NSString *)anEndpoint usesTLS:(BOOL)usesTLS lastEventId:(NSString *)anEventId useSecretToken:(BOOL)shouldUseSecretToken secretToken:(NSString*)aSecretToken;
- (void)connect;
- (void)disconnect;
- (void)reset;

@property(nonatomic, retain) NSString *host;
@property(nonatomic, retain) NSString *urlEndpoint;
@property(nonatomic, assign) int port;
@property(nonatomic, assign) id <LPSSEManagerDelegate> delegate;
@property(nonatomic, assign) BOOL usesTLS;
@property(nonatomic, assign) BOOL usesSecretToken;
@property(nonatomic, retain) NSString* secretToken;

@end