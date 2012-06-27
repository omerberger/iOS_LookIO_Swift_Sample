//
//  LIOChatMessage.m
//  LookIO
//
//  Created by Joseph Toscano on 12/7/11.
//  Copyright (c) 2011 LivePerson, Inc. All rights reserved.
//

#import "LIOChatMessage.h"

@implementation LIOChatMessage

@synthesize kind, text, date, senderName, sequence;

+ (LIOChatMessage *)chatMessage
{
    return [[[LIOChatMessage alloc] init] autorelease];
}

- (void)dealloc
{
    [text release];
    [date release];
    [senderName release];
    
    [super dealloc];
}

@end