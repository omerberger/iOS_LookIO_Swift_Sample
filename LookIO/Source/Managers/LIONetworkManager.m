//
//  LIONetworkManager.m
//  LookIO
//
//  Created by Yaron Karasik on 12/5/13.
//
//

#import "LIONetworkManager.h"

#import "LPVisitAPIClient.h"
#import "LPChatAPIClient.h"
#import "LPMediaAPIClient.h"

#define LIOLookIOManagerDefaultControlEndpoint      @"dispatch.look.io"
#define LIOLookIOManagerDefaultControlEndpoint_Dev  @"dispatch.staging.look.io"
#define LIOLookIOManagerDefaultControlEndpoint_QA   @"dispatch.qa.look.io"

@implementation LIONetworkManager

static LIONetworkManager *networkManager = nil;

#pragma mark Initialization Methods

+ (LIONetworkManager *)networkManager
{
    if (nil == networkManager)
        networkManager = [[LIONetworkManager alloc] init];
    
    return networkManager;
}

- (id)init {
    self = [super init];
    if (self) {
        self.serverMode = LIOServerProduction;
        self.controlEndpoint = LIOLookIOManagerDefaultControlEndpoint;
        self.usesTLS = YES;
        
        [[NSHTTPCookieStorage sharedHTTPCookieStorage]setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    }
    return self;
}

#pragma mark Control Endpoint Setup

- (void)setProductionMode
{
    self.serverMode = LIOServerProduction;
    self.controlEndpoint = LIOLookIOManagerDefaultControlEndpoint;
    
    // Init the ChatAPIClient
    LPChatAPIClient* chatClient = [LPChatAPIClient sharedClient];
    chatClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/api/v2/chat/", LIOLookIOManagerDefaultControlEndpoint]];
    
    LPMediaAPIClient* mediaClient = [LPMediaAPIClient sharedClient];
    mediaClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/api/v2/media/", LIOLookIOManagerDefaultControlEndpoint]];
    
    LPVisitAPIClient* visitClient = [LPVisitAPIClient sharedClient];
    visitClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", LIOLookIOManagerDefaultControlEndpoint]];
}

- (void)setStagingMode
{
    self.serverMode = LIOServerStaging;
    self.controlEndpoint = LIOLookIOManagerDefaultControlEndpoint_Dev;
    
    // Init the ChatAPIClient
    LPChatAPIClient* chatClient = [LPChatAPIClient sharedClient];
    chatClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/api/v2/chat/", LIOLookIOManagerDefaultControlEndpoint_Dev]];
    
    LPMediaAPIClient* mediaClient = [LPMediaAPIClient sharedClient];
    mediaClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/api/v2/media/", LIOLookIOManagerDefaultControlEndpoint_Dev]];
    
    LPVisitAPIClient* visitClient = [LPVisitAPIClient sharedClient];
    visitClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", LIOLookIOManagerDefaultControlEndpoint_Dev]];
}

- (void)setQAMode
{
    self.serverMode = LIOServerQA;
    self.controlEndpoint = LIOLookIOManagerDefaultControlEndpoint_QA;
    
    // Init the ChatAPIClient
    LPChatAPIClient* chatClient = [LPChatAPIClient sharedClient];
    chatClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/api/v2/chat/", LIOLookIOManagerDefaultControlEndpoint_QA]];
    
    LPMediaAPIClient* mediaClient = [LPMediaAPIClient sharedClient];
    mediaClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/api/v2/media/", LIOLookIOManagerDefaultControlEndpoint_QA]];
    
    LPVisitAPIClient* visitClient = [LPVisitAPIClient sharedClient];
    visitClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", LIOLookIOManagerDefaultControlEndpoint_QA]];
}




@end
