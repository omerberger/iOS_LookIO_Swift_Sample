//
//  LIOLookIOManager.h
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GCDAsyncSocket, LIOChatboxView, SBJsonParser, SBJsonWriter;

@protocol LIOLookIOManagerDelegate
- (void)lookIOManagerFailedToConnectWithError:(NSError *)anError;
@end

@interface LIOLookIOManager : NSObject
{
    NSTimer *screenCaptureTimer;
    UIImage *touchImage;
    GCDAsyncSocket *controlSocket;
    BOOL waitingForScreenshotAck, controlSocketConnecting, introduced;
    LIOChatboxView *chatbox;
    NSData *messageSeparatorData;
    NSData *pendingScreenshotData;
    SBJsonParser *jsonParser;
    SBJsonWriter *jsonWriter;
    id<LIOLookIOManagerDelegate> delegate;
}

@property(nonatomic, retain) UIImage *touchImage;
@property(nonatomic, assign) id<LIOLookIOManagerDelegate> delegate;

+ (LIOLookIOManager *)sharedLookIOManager;
- (void)beginConnecting;

@end
