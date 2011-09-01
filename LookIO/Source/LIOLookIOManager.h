//
//  LIOLookIOManager.h
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

@class GCDAsyncSocket_LIO, SBJsonParser_LIO, SBJsonWriter_LIO, LIOChatViewController, LIOConnectViewController;

@interface LIOLookIOManager : NSObject <UIAlertViewDelegate>
{
    NSTimer *screenCaptureTimer;
    UIImage *touchImage;
    GCDAsyncSocket_LIO *controlSocket;
    BOOL waitingForScreenshotAck, waitingForIntroAck, controlSocketConnecting, introduced, enqueued;
    NSData *messageSeparatorData;
    NSData *lastScreenshotSent;
    SBJsonParser_LIO *jsonParser;
    SBJsonWriter_LIO *jsonWriter;
    UIImageView *cursorView, *clickView;
    UIButton *controlButton;
    UIActivityIndicatorView *controlButtonSpinner;
    CGRect controlButtonFrame;
    NSMutableArray *chatHistory;
    LIOChatViewController *chatViewController;
    LIOConnectViewController *connectViewController;
    SystemSoundID soundYay, soundDing;
    BOOL unloadAfterDisconnect;
    BOOL minimized;
    NSNumber *lastKnownQueuePosition;
    BOOL screenshotsAllowed;
    UIBackgroundTaskIdentifier backgroundTaskId;
}

@property(nonatomic, retain) UIImage *touchImage;
@property(nonatomic, assign) CGRect controlButtonFrame;

+ (LIOLookIOManager *)sharedLookIOManager;
- (void)beginConnecting;
- (void)killConnection;

@end
