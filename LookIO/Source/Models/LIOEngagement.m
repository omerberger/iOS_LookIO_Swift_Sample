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
#import "LPMediaAPIClient.h"
#import "LIOLogManager.h"
#import "LPSSEManager.h"

#import "LIOChatMessage.h"

#define LIOLookIOManagerLastKnownChatCookiesKey  @"LIOLookIOManagerLastKnownChatCookiesKey"
#define LIOLookIOManagerLastKnownEngagementIdKey @"LIOLookIOManagerLastKnownEngagementIdKey"
#define LIOLookIOManagerLastKnownSSEUrlStringKey @"LIOLookIOManagerLastKnownSSEUrlStringKey"
#define LIOLookIOManagerLastKnownPostUrlString   @"LIOLookIOManagerLastKnownPostUrlString"
#define LIOLookIOManagerLastKnownMediaUrlString  @"LIOLookIOManagerLastKnownMediaUrlString"
#define LIOLookIOManagerLastSSEventIdString      @"LIOLookIOManagerLastSSEventIdString"


@interface LIOEngagement () <LPSSEManagerDelegate>

@property (nonatomic, strong) NSMutableArray *chatCookies;

@property (nonatomic, strong) LIOVisit *visit;

@property (nonatomic, strong) LPSSEManager *sseManager;
@property (nonatomic, assign) LIOSSEChannelState sseChannelState;

@property (nonatomic, copy) NSString *engagementId;
@property (nonatomic, copy) NSString *SSEUrlString;
@property (nonatomic, copy) NSString *postUrlString;
@property (nonatomic, copy) NSString *mediaUrlString;
@property (nonatomic, copy) NSString *lastSSEventId;

@end

@implementation LIOEngagement

- (id)initWithVisit:(LIOVisit *)aVisit {
    self = [super init];
    if (self) {
        self.visit = aVisit;
        
        self.messages = [[NSMutableArray alloc] init];
        [self populateFirstChatMessage];
        
        self.lastClientLineId = 0;

        self.chatCookies = [[NSMutableArray alloc] init];
        
        self.sseChannelState = LIOSSEChannelStateInitialized;
    }
    return self;
}

- (void)populateFirstChatMessage
{
    if (self.messages.count == 0)
    {
        LIOChatMessage *firstMessage = [LIOChatMessage chatMessage];
        firstMessage.kind = LIOChatMessageKindRemote;
        firstMessage.date = [NSDate date];
        firstMessage.lineId = nil;
        firstMessage.text = [self.visit welcomeText];
        [self.messages addObject:firstMessage];
    }
}

#pragma mark Engagement Lifecycle Methods

- (void)startEngagement
{
    [self sendIntroPacket];
}

- (void)cancelEngagement
{
    [self.sseManager disconnect];
}

#pragma Engagement Payload methods

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

- (NSDictionary *)resolveEngagementPayload:(NSDictionary *)params
{
    NSMutableDictionary *resolvedPayload = [NSMutableDictionary dictionary];
    
    NSString* engagementId = [params objectForKey:@"engagement_id"];
    if ([engagementId length])
        [resolvedPayload setObject:engagementId forKey:@"engagement_id"];
    
    NSString* sseUrl = [params objectForKey:@"sse_url"];
    if ([engagementId length])
        [resolvedPayload setObject:sseUrl forKey:@"sse_url"];
    
    NSString* postUrl = [params objectForKey:@"post_url"];
    if ([engagementId length])
        [resolvedPayload setObject:postUrl forKey:@"post_url"];
    
    NSString* mediaUrl = [params objectForKey:@"media_url"];
    if ([engagementId length])
        [resolvedPayload setObject:mediaUrl forKey:@"media_url"];
    
    return resolvedPayload;
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
        self.SSEUrlString = [resolvedPayload objectForKey:@"sse_url"];
        self.postUrlString = [resolvedPayload objectForKey:@"post_url"];
        self.mediaUrlString = [resolvedPayload objectForKey:@"media_url"];
        
        [self setupAPIClientBaseURL];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:self.engagementId forKey:LIOLookIOManagerLastKnownEngagementIdKey];
        [userDefaults setObject:self.SSEUrlString forKey:LIOLookIOManagerLastKnownSSEUrlStringKey];
        [userDefaults setObject:self.postUrlString forKey:LIOLookIOManagerLastKnownPostUrlString];
        [userDefaults setObject:self.mediaUrlString forKey:LIOLookIOManagerLastKnownMediaUrlString];
        
        [userDefaults synchronize];
        
        [self connectSSESocket];
    }
}

- (void)setupAPIClientBaseURL {
    LPChatAPIClient *chatAPIClient = [LPChatAPIClient sharedClient];
    chatAPIClient.baseURL = [NSURL URLWithString:self.postUrlString];
    
    LPMediaAPIClient *mediaAPIClient = [LPMediaAPIClient sharedClient];
    mediaAPIClient.baseURL = [NSURL URLWithString:self.mediaUrlString];
    
    // Let's remove any cookies from previous sessions
    [chatAPIClient clearCookies];
    [mediaAPIClient clearCookies];
    
    for (NSHTTPCookie *cookie in self.chatCookies) {
        NSMutableDictionary *chatCookieProperties = [NSMutableDictionary dictionary];
        [chatCookieProperties setObject:cookie.name forKey:NSHTTPCookieName];
        [chatCookieProperties setObject:cookie.value forKey:NSHTTPCookieValue];
        [chatCookieProperties setObject:chatAPIClient.baseURL.host forKey:NSHTTPCookieDomain];
        [chatCookieProperties setObject:chatAPIClient.baseURL.path forKey:NSHTTPCookiePath];
        [chatCookieProperties setObject:[NSString stringWithFormat:@"%lu", (unsigned long)cookie.version] forKey:NSHTTPCookieVersion];
        
        NSHTTPCookie *chatCookie = [NSHTTPCookie cookieWithProperties:chatCookieProperties];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:chatCookie];
        
        NSMutableDictionary *mediaCookieProperties = [NSMutableDictionary dictionary];
        [mediaCookieProperties setObject:cookie.name forKey:NSHTTPCookieName];
        [mediaCookieProperties setObject:cookie.value forKey:NSHTTPCookieValue];
        [mediaCookieProperties setObject:mediaAPIClient.baseURL.host forKey:NSHTTPCookieDomain];
        [mediaCookieProperties setObject:mediaAPIClient.baseURL.path forKey:NSHTTPCookiePath];
        [mediaCookieProperties setObject:[NSString stringWithFormat:@"%lu", (unsigned long)cookie.version] forKey:NSHTTPCookieVersion];
        
        NSHTTPCookie *mediaCookie = [NSHTTPCookie cookieWithProperties:mediaCookieProperties];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:mediaCookie];
    }
}

#pragma mark Intro Methods

- (void)sendIntroPacket
{
    [[LIOAnalyticsManager sharedAnalyticsManager] pumpReachabilityStatus];
    if (LIOAnalyticsManagerReachabilityStatusConnected == [LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)
    {
        // Clear any existing cookies
        [[LPChatAPIClient sharedClient] clearCookies];
        
        [[LPChatAPIClient sharedClient] postPath:LIOLookIOManagerChatIntroRequestURL parameters:[self.visit introDictionary] success:^(LPHTTPRequestOperation *operation, id responseObject) {
            
            if (responseObject)
                LIOLog(@"<INTRO> response: %@", responseObject);
            else
                LIOLog(@"<INTRO> success");
            
            NSDictionary* responseDict = (NSDictionary*)responseObject;

            [self saveChatCookies];
            [self parseAndSaveEngagementInfoPayload:responseDict];
            
            
        } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
            LIOLog(@"<INTRO> failure: %@", error);
            
            [self.delegate engagementDidFailToStart:self];
            
        }];
    }
}

#pragma mark SSE Channel Methods

- (void)connectSSESocket
{
    self.sseChannelState = LIOSSEChannelStateConnecting;
    
    if (self.sseManager)
    {
        [self.sseManager reset];
        self.sseManager = nil;
    }
    
    NSNumber *portToUse = [NSNumber numberWithInteger:443];
    NSURL* url = [NSURL URLWithString:self.SSEUrlString];
    if (url.port != 0)
        portToUse = url.port;
    
    BOOL sseSocketUsesTLS = YES;
    if ([url.scheme isEqualToString:@"http"])
        sseSocketUsesTLS = NO;
    
    self.sseManager = [[LPSSEManager alloc] initWithHost:url.host port:portToUse urlEndpoint:[NSString stringWithFormat:@"%@/%@", url.path, self.engagementId] usesTLS:sseSocketUsesTLS lastEventId:self.lastSSEventId cookies:[NSArray arrayWithArray:self.chatCookies]];
    
    self.sseManager.delegate = self;
    [self.sseManager connect];
}

- (void)sseManagerDidConnect:(LPSSEManager *)aManager
{
    self.sseChannelState = LIOSSEChannelStateConnected;
    
    if (LIOVisitStateChatRequested)
    {
        [self.delegate engagementDidStart:self];
    }
}

- (void)sseManagerDidDisconnect:(LPSSEManager *)aManager
{
    if (LIOVisitStateChatRequested == self.visit.visitState && LIOSSEChannelStateConnecting == self.sseChannelState)
    {
        [self.delegate engagementDidFailToStart:self];
    }
    
    if (LIOSSEChannelStateCancelling == self.sseChannelState)
    {
        [self.delegate engagementDidCancel:self];
    }
    
}

- (void)sseManagerWillDisconnect:(LPSSEManager *)aManager withError:(NSError *)err
{
}

- (void)sseManager:(LPSSEManager *)aManager didDispatchEvent:(LPSSEvent *)anEvent
{
    
}

@end
