//
//  LIOChatMessage.h
//  LookIO
//
//  Created by Joseph Toscano on 12/7/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
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
}

@property(nonatomic, assign) LIOChatMessageKind kind;
@property(nonatomic, retain) NSString *text;
@property(nonatomic, retain) NSDate *date;
@property(nonatomic, retain) NSString *senderName;

+ (LIOChatMessage *)chatMessage;

@end