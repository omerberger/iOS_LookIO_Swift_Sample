//
//  LIOEngagement.m
//  LookIO
//
//  Created by Yaron Karasik on 12/5/13.
//
//

#import "LIOEngagement.h"

#import "LIOAnalyticsManager.h"
#import "LPChatAPIClient.h"
#import "LIOLogManager.h"

#define LIOLookIOManagerLastKnownChatCookiesKey @"LIOLookIOManagerLastKnownChatCookiesKey"

@interface LIOEngagement ()

@property (nonatomic, strong) NSMutableArray *chatCookies;

@property (nonatomic, copy) NSString *engagementId;
@property (nonatomic, copy) NSString *chatSSEUrlString;
@property (nonatomic, copy) NSString *chatPostUrlString;
@property (nonatomic, copy) NSString *chatMediaUrlString;

@end

@implementation LIOEngagement

- (id)init {
    self = [super init];
    if (self) {
        self.messages = [[NSMutableArray alloc] init];
        self.lastClientLineId = 0;

        self.chatCookies = [[NSMutableArray alloc] init];
    }
}

#pragma mark Engagement Lifecycle Methods

- (void)startEngagementWithIntroDictionary:(NSDictionary *)introDictionary;
{
    [self sendIntroPacketWithIntroDictionary:introDictionary];
}

#pragma Parsing methods

- (void)saveChatCookies {
    [self.chatCookies removeAllObjects];
    
    NSArray *all = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[LPChatAPIClient sharedClient].baseURL];
    for (NSHTTPCookie *cookie in all) {
        [self.chatCookies addObject:cookie];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *cookieData = [NSKeyedArchiver archivedDataWithRootObject:self.chatCookies];

    [userDefaults setObject:cookieData forKey:LIOLookIOManagerLastKnownChatCookiesKey];
    [userDefaults synchronize];
}

- (void)parseAndSaveEngagementInfoPayload:(NSDictionary*)params
{
    LIOLog(@"Got engagement payload: %@", params);
    
    // Parse.
    NSDictionary *resolvedPayload = nil;
    @try
    {
        resolvedPayload = [self resolveEngagementPayload:params];
    }
    @catch (NSException *exception)
    {
        [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"Invalid engagement payload received from the server! Exception: %@", exception];
    }
    
    // Save.
    if ([resolvedPayload count])
    {
        self.engagementId = [resolvedPayload objectForKey:@"engagement_id"];
        self.chatSSEUrlString = [resolvedPayload objectForKey:@"sse_url"];
        self.chatPostUrlString = [resolvedPayload objectForKey:@"post_url"];
        self.chatMediaUrlString = [resolvedPayload objectForKey:@"media_url"];
        
        [self setupAPIClientBaseURL];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:self.engagementId forKey:LIOLookIOManagerLastKnownEngagementIdKey];
        [userDefaults setObject:self.chatSSEUrlString forKey:LIOLookIOManagerLastKnownChatSSEUrlStringKey];
        [userDefaults setObject:self.chatPostUrlString forKey:LIOLookIOManagerLastKnownChatPostUrlString];
        [userDefaults setObject:self.chatMediaUrlString forKey:LIOLookIOManagerLastKnownChatMediaUrlString];
        
        [userDefaults synchronize];
        
        [self connectSSESocket];
    }
}

#pragma mark Intro Methods

- (void)sendIntroPacketWithIntroDictionary:(NSDictionary *)introDictionary;
{
    [[LIOAnalyticsManager sharedAnalyticsManager] pumpReachabilityStatus];
    if (LIOAnalyticsManagerReachabilityStatusConnected == [LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)
    {
        // Clear any existing cookies
        [[LPChatAPIClient sharedClient] clearCookies];
        
        [[LPChatAPIClient sharedClient] postPath:LIOLookIOManagerChatIntroRequestURL parameters:introDictionary success:^(LPHTTPRequestOperation *operation, id responseObject) {
            
            if (responseObject)
                LIOLog(@"<INTRO> response: %@", responseObject);
            else
                LIOLog(@"<INTRO> success");
            
            NSDictionary* responseDict = (NSDictionary*)responseObject;

            [self saveChatCookies];
            [self parseAndSaveEngagementInfoPayload:responseDict];
            
            [self.delegate engagementDidStart:self];
            
        } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
            LIOLog(@"<INTRO> failure: %@", error);
            
        }];
    }
}

@end
