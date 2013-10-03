//
//  LIOChatMessage.m
//  LookIO
//
//  Created by Joseph Toscano on 12/7/11.
//  Copyright (c) 2011 LivePerson, Inc. All rights reserved.
//

#import "LIOChatMessage.h"

@implementation LIOChatMessage

#define LIOChatMessageKindKey           @"LIOChatMessageKindKey"
#define LIOChatMessageTextKey           @"LIOChatMessageTextKey"
#define LIOChatMessageDateKey           @"LIOChatMessageDateKey"
#define LIOChatMessageSenderNameKey     @"LIOChatMessageSenderNameKey"
#define LIOChatMessageAttachmentIdKey   @"LIOChatMessageAttachmentIdKey"
#define LIOChatMessageSendingFailedKey  @"LIOChatMessageSendingFailedKey"
#define LIOChatMessageLineIdKey         @"LIOChatMessageLineIdKey"

@synthesize kind, text, date, senderName, attachmentId, sendingFailed, lineId ,clientLineId;

+ (LIOChatMessage *)chatMessage
{
    return [[[LIOChatMessage alloc] init] autorelease];
}

- (void)dealloc
{
    [attachmentId release];
    [text release];
    [date release];
    [senderName release];
    
    [super dealloc];
}

- (void) encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:[NSNumber numberWithInteger:kind] forKey:LIOChatMessageKindKey];
    [encoder encodeObject:text forKey:LIOChatMessageTextKey];
    [encoder encodeObject:date forKey:LIOChatMessageDateKey];
    [encoder encodeObject:senderName forKey:LIOChatMessageSenderNameKey];
    [encoder encodeObject:attachmentId forKey:LIOChatMessageAttachmentIdKey];
    [encoder encodeObject:[NSNumber numberWithBool:sendingFailed] forKey:LIOChatMessageSendingFailedKey];
    [encoder encodeObject:lineId forKey:LIOChatMessageLineIdKey];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        NSNumber *kindNumber = [decoder decodeObjectForKey:LIOChatMessageKindKey];
        self.kind = [kindNumber integerValue];
        self.text = [decoder decodeObjectForKey:LIOChatMessageTextKey];
        self.date = [decoder decodeObjectForKey:LIOChatMessageDateKey];
        self.senderName = [decoder decodeObjectForKey:LIOChatMessageSenderNameKey];
        self.attachmentId = [decoder decodeObjectForKey:LIOChatMessageAttachmentIdKey];
        NSNumber *sendingFailedNumber = [decoder decodeObjectForKey:LIOChatMessageSendingFailedKey];
        self.sendingFailed = [sendingFailedNumber boolValue];
        self.lineId = [decoder decodeObjectForKey:lineId];
    }
    
    return self;
}

@end