//
//  LIOLookIOManager.h
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 Joseph Toscano. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GCDAsyncSocket, SBJsonParser, SBJsonWriter, LIOChatboxView;

@protocol LIOChatboxViewDelegate;

@protocol LIOLookIOManagerDelegate
- (void)lookIOManagerFailedToConnectWithError:(NSError *)anError;
@end

@interface LIOLookIOManager : NSObject <LIOChatboxViewDelegate, UITextFieldDelegate>
{
    NSTimer *screenCaptureTimer;
    UIImage *touchImage;
    GCDAsyncSocket *controlSocket;
    BOOL waitingForScreenshotAck, waitingForIntroAck, controlSocketConnecting, introduced;
    LIOChatboxView *chatbox;
    NSData *messageSeparatorData;
    NSData *lastScreenshotSent;
    SBJsonParser *jsonParser;
    SBJsonWriter *jsonWriter;
    UIImageView *cursorView, *connectionLogo, *clickView;
    UITextField *chatField;
    NSTimer *chatboxTimer;
    BOOL chatting;
    id<LIOLookIOManagerDelegate> delegate;
}

@property(nonatomic, retain) UIImage *touchImage;
@property(nonatomic, assign) id<LIOLookIOManagerDelegate> delegate;

+ (LIOLookIOManager *)sharedLookIOManager;
- (void)beginConnecting;
- (void)callTwilio;

@end
