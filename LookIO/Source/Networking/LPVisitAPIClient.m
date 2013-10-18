//
//  LPVisitAPIClient.m
//  LookIO
//
//  Created by Yaron Karasik on 7/16/13.
//
//

#import "LPVisitAPIClient.h"

static LPVisitAPIClient *sharedClient = nil;

@implementation LPVisitAPIClient

+ (LPVisitAPIClient *) sharedClient
{
    if (nil == sharedClient)
        sharedClient = [[LPVisitAPIClient alloc] init];
    
    return sharedClient;
}

@end