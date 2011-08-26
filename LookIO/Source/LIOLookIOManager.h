//
//  LIOLookIOManager.h
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GCDAsyncSocket_LIO, SBJsonParser_LIO, SBJsonWriter_LIO, LIOChatboxView;

@protocol LIOLookIOManagerDelegate
- (void)lookIOManagerFailedToConnectWithError:(NSError *)anError;
@end

@protocol LIOChatboxViewDelegate;

@interface LIOLookIOManager : NSObject <LIOChatboxViewDelegate, UITextFieldDelegate>
{
    NSTimer *screenCaptureTimer;
    UIImage *touchImage;
    GCDAsyncSocket_LIO *controlSocket;
    BOOL waitingForScreenshotAck, waitingForIntroAck, controlSocketConnecting, introduced;
    LIOChatboxView *chatbox;
    NSData *messageSeparatorData;
    NSData *lastScreenshotSent;
    SBJsonParser_LIO *jsonParser;
    SBJsonWriter_LIO *jsonWriter;
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

@end
