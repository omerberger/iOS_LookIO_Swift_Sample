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
@class GCDAsyncSocket_LIO;
@class LPSSEvent;
@protocol GCDAsyncSocketDelegate_LIO;

@protocol LPSSEManagerDelegate <NSObject>
- (void)sseManagerDidConnect:(LPSSEManager *)aManager;
- (void)sseManagerDidDisconnect:(LPSSEManager *)aManager;
- (void)sseManager:(LPSSEManager *)aManager didReceivePacket:(NSString *)aPacket;
- (void)sseManager:(LPSSEManager *)aManager didDispatchEvent:(LPSSEvent *)anEvent;
@end

typedef enum {
    LPSSEManagerReadyStateConnecting      = 0,
    LPSSEManagerReadyStateOpen            = 1,
    LPSSEManagerReadyStateClosed          = 2
} LPSSEManagerReadyState;

@interface LPSSEManager : NSObject <GCDAsyncSocketDelegate_LIO> {
    NSString* host;
    NSString* urlEndpoint;
    int port;
    id <LPSSEManagerDelegate> delegate;
}

- (id)initWithHost:(NSString *)aHost port:(int)aPort urlEndpoint:(NSString *)anEndpoint;
- (void)connect;
- (void)disconnect;
- (void)reset;

@property(nonatomic, retain) NSString *host;
@property(nonatomic, retain) NSString *urlEndpoint;
@property(nonatomic, assign) int port;
@property(nonatomic, assign) id <LPSSEManagerDelegate> delegate;

- (NSString *)sha1:(NSString *)input;

@end