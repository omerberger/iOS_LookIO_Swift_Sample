//
//  LIOChatMessage.m
//  LookIO
//
//  Created by Joseph Toscano on 12/7/11.
//  Copyright (c) 2011 LivePerson, Inc. All rights reserved.
//

#import "LIOChatMessage.h"

// Managers
#import "LIOManager.h"

@interface LIOChatMessage ()

@end

@implementation LPChatBubbleLink

@end

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

- (void)detectLinks
{
    NSDataDetector *dataDetector = [[NSDataDetector alloc] initWithTypes:(NSTextCheckingTypeLink|NSTextCheckingTypePhoneNumber) error:nil];
    self.links = [[NSMutableArray alloc] init];
    self.textCheckingResults = [[NSMutableArray alloc] init];
    
    self.isShowingLinks = NO;

    // We should use the text with the sender name to fit the display that we will have later
    NSString *text = self.text;
    if (self.senderName != nil)
        text = [NSString stringWithFormat:@"%@: %@", self.senderName, self.text];
    
    NSRange fullRange = NSMakeRange(0, [text length]);
    [dataDetector enumerateMatchesInString:text options:0 range:fullRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        
        LPChatBubbleLink *currentLink = [[LPChatBubbleLink alloc] init];
        currentLink.string = [text substringWithRange:result.range];
        currentLink.originalRawString = [text substringWithRange:result.range];
        currentLink.URL = result.URL;
        
        if (NSTextCheckingTypeLink == result.resultType)
        {
            // Omit telephone numbers if this device can't even make a call.
            if ([[result.URL scheme] hasPrefix:@"tel"] && NO == [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://1112223333"]])
                return;
            
            currentLink.scheme = [result.URL scheme];
        }
        else if (NSTextCheckingTypePhoneNumber == result.resultType)
        {
            // Omit if this device can't call.
            if (NO == [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://1112223333"]])
                return;
            
            NSString *cleanedString = [[currentLink.string componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789-+()"] invertedSet]] componentsJoinedByString:@""];
            NSString *escapedPhoneNumber = [cleanedString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            currentLink.URL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", escapedPhoneNumber]];
        }
        
        // Trim the URL scheme out of the link text to be drawn to the screen.
        NSRange schemeRange = [currentLink.string rangeOfString:@"://"];
        if (schemeRange.location != NSNotFound)
            currentLink.string = [currentLink.string substringFromIndex:schemeRange.location + schemeRange.length];
        
        currentLink.checkingType = result.resultType;
        [self.links addObject:currentLink];
        [self.textCheckingResults addObject:result];
        self.isShowingLinks = YES;
        
        // Special handling for links; could be intra-app!
        if (NSTextCheckingTypeLink == result.resultType)
        {
            currentLink.isIntraAppLink = [[LIOManager sharedLookIOManager] performSelector:@selector(isIntraLink:) withObject:currentLink.URL];
        }
    }];    
}

@end