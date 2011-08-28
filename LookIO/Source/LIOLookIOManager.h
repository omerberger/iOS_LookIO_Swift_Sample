//
//  LIOLookIOManager.h
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

@class GCDAsyncSocket_LIO, SBJsonParser_LIO, SBJsonWriter_LIO, LIOChatViewController;

@interface LIOLookIOManager : NSObject
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
    UIImageView *connectionLogo;
    CGRect controlButtonFrame;
    UIActivityIndicatorView *connectionSpinner;
    UILabel *connectionLabel;
    UIView *connectionBackground;
    NSMutableArray *chatHistory;
    LIOChatViewController *chatViewController;
    SystemSoundID soundYay, soundDing;
}

@property(nonatomic, retain) UIImage *touchImage;
@property(nonatomic, assign) CGRect controlButtonFrame;

+ (LIOLookIOManager *)sharedLookIOManager;
- (void)beginConnecting;

@end
