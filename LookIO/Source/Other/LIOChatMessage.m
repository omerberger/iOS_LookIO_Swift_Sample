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
#define LIOChatMessageStatusKey         @"LIOChatMessageStatusKey"
#define LIOChatMessageTextKey           @"LIOChatMessageTextKey"
#define LIOChatMessageDateKey           @"LIOChatMessageDateKey"
#define LIOChatMessageSenderNameKey     @"LIOChatMessageSenderNameKey"
#define LIOChatMessageAttachmentIdKey   @"LIOChatMessageAttachmentIdKey"
#define LIOChatMessageSendingFailedKey  @"LIOChatMessageSendingFailedKey"
#define LIOChatMessageLineIdKey         @"LIOChatMessageLineIdKey"
#define LIOChatMessageClientLineIdKey   @"LIOChatMessageClientLineIdKey"

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:[NSNumber numberWithInteger:self.kind] forKey:LIOChatMessageKindKey];
    [encoder encodeObject:[NSNumber numberWithInteger:self.status] forKey:LIOChatMessageStatusKey];
    [encoder encodeObject:self.text forKey:LIOChatMessageTextKey];
    [encoder encodeObject:self.date forKey:LIOChatMessageDateKey];
    [encoder encodeObject:self.senderName forKey:LIOChatMessageSenderNameKey];
    [encoder encodeObject:self.attachmentId forKey:LIOChatMessageAttachmentIdKey];
    [encoder encodeObject:[NSNumber numberWithBool:self.sendingFailed] forKey:LIOChatMessageSendingFailedKey];
    [encoder encodeObject:self.lineId forKey:LIOChatMessageLineIdKey];
    [encoder encodeObject:self.clientLineId forKey:LIOChatMessageClientLineIdKey];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    
    if (self) {
        NSNumber *kindNumber = [decoder decodeObjectForKey:LIOChatMessageKindKey];
        self.kind = [kindNumber integerValue];
        NSNumber *statusNumber = [decoder decodeObjectForKey:LIOChatMessageStatusKey];
        self.status = [statusNumber integerValue];
        self.text = [decoder decodeObjectForKey:LIOChatMessageTextKey];
        self.date = [decoder decodeObjectForKey:LIOChatMessageDateKey];
        self.senderName = [decoder decodeObjectForKey:LIOChatMessageSenderNameKey];
        self.attachmentId = [decoder decodeObjectForKey:LIOChatMessageAttachmentIdKey];
        NSNumber *sendingFailedNumber = [decoder decodeObjectForKey:LIOChatMessageSendingFailedKey];
        self.sendingFailed = [sendingFailedNumber boolValue];
        self.lineId = [decoder decodeObjectForKey:LIOChatMessageLineIdKey];
        self.clientLineId = [decoder decodeObjectForKey:LIOChatMessageClientLineIdKey];
    }
    
    return self;
}

@end