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
@protocol GCDAsyncSocketDelegate_LIO;

@protocol LPSSEManagerDelegate <NSObject>
- (void)sseManagerDidConnect:(LPSSEManager *)aManager;
- (void)sseManagerDidDisconnect:(LPSSEManager *)aManager;
- (void)sseManager:(LPSSEManager *)aManager didReceivePacket:(NSString *)aPacket;
@end

@interface LPSSEManager : NSObject <GCDAsyncSocketDelegate_LIO>

- (id)initWithHost:(NSString *)aHost port:(int)aPort urlEndpoint:(NSString *)anEndpoint;
- (void)connect;
- (void)disconnect;

@property(nonatomic, retain) NSString *host;
@property(nonatomic, retain) NSString *urlEndpoint;
@property(nonatomic, assign) int port;
@property(nonatomic, assign) id <LPSSEManagerDelegate> delegate;

- (NSString *)sha1:(NSString *)input;

@end