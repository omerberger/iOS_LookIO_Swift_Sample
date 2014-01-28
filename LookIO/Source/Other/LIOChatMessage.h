//
//  LIOChatMessage.h
//  LookIO
//
//  Created by Joseph Toscano on 12/7/11.
//  Copyright (c) 2011 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
    LIOChatMessageKindRemote,
    LIOChatMessageKindLocal,
    LIOChatMessageKindLocalImage,
    LIOChatMessageKindMapLocation,
    LIOChatMessageKindLink,
    LIOChatMessageKindPhoneNumber
} LIOChatMessageKind;

typedef enum
{
    LIOChatMessageStatusInitialized,
    LIOChatMessageStatusSending,
    LIOChatMessageStatusResending,
    LIOChatMessageStatusSent,
    LIOChatMessageStatusFailed,
    LIOChatMessageStatusReceived,
    LIOChatMessageStatusCreatedLocally
} LIOChatMessageStatus;

@interface LPChatBubbleLink : NSObject

@property (nonatomic, copy) NSString *string;
@property (nonatomic, copy) NSString *originalRawString;
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, copy) NSString *scheme;
@property (nonatomic, assign) NSTextCheckingType* checkingType;
@property (nonatomic, assign) BOOL isIntraAppLink;

@end

@interface LIOChatMessage : NSObject

@property (nonatomic, assign) LIOChatMessageKind kind;
@property (nonatomic, assign) LIOChatMessageStatus status;

@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSString *senderName;
@property (nonatomic, retain) NSString *attachmentId;
@property (nonatomic, assign) BOOL sendingFailed;
@property (nonatomic, copy) NSString *lineId;
@property (nonatomic, copy) NSString *clientLineId;

@property (nonatomic, assign) BOOL isShowingLinks;
@property (nonatomic, strong) NSMutableArray *links;
@property (nonatomic, strong) NSMutableArray *textCheckingResults;

- (void)detectLinks;

@end