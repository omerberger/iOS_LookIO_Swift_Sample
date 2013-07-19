//
//  LPMediaAPIClient.m
//  LookIO
//
//  Created by Yaron Karasik on 7/19/13.
//
//

#import "LPMediaAPIClient.h"

static LPMediaAPIClient *sharedClient = nil;

@implementation LPMediaAPIClient

+ (LPMediaAPIClient *) sharedClient
{
    if (nil == sharedClient)
        sharedClient = [[LPMediaAPIClient alloc] init];
    
    return sharedClient;
}

@end
