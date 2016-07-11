//
//  LPPCIFormAPIClient.m
//  LookIO
//
//  Created by Gil Goldenberg on 12/15/14.
//
//

#import "LPPCIFormAPIClient.h"

static LPPCIFormAPIClient *sharedClient = nil;

@implementation LPPCIFormAPIClient

+ (LPPCIFormAPIClient *) sharedClient
{
    if (nil == sharedClient)
        sharedClient = [[LPPCIFormAPIClient alloc] init];
    
    return sharedClient;
}

@end
