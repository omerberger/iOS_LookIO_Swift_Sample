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
    LIOChatMessageKindMapLocation,
    LIOChatMessageKindLink,
    LIOChatMessageKindPhoneNumber
} LIOChatMessageKind;

@interface LIOChatMessage : NSObject
{
    LIOChatMessageKind kind;
    NSString *text;
    NSDate *date;
    NSString *senderName;
    NSString *attachmentId;
    BOOL sendingFailed;
    NSString *lineId;
    NSString *clientLineId;
}

@property (nonatomic, assign) LIOChatMessageKind kind;
@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSString *senderName;
@property (nonatomic, retain) NSString *attachmentId;
@property (nonatomic, assign) BOOL sendingFailed;
@property (nonatomic, copy) NSString *lineId;
@property (nonatomic, copy) NSString *clientLineId;

+ (LIOChatMessage *)chatMessage;

@end