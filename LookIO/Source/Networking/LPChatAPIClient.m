//
//  LPChatAPIClient.m
//  LookIO
//
//  Created by Yaron Karasik on 7/16/13.
//
//

#import "LPChatAPIClient.h"

static LPChatAPIClient *sharedClient = nil;

@implementation LPChatAPIClient

+ (LPChatAPIClient *) sharedClient
{
    if (nil == sharedClient)
        sharedClient = [[LPChatAPIClient alloc] init];
    
    return sharedClient;
}

@end
