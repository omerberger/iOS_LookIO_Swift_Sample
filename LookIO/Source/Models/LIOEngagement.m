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
#import "LIOMediaManager.h"
#import "LIOStatusManager.h"
#import "LPHTTPRequestOperation.h"
#import "NSData+Base64.h"

#import "LIOLogManager.h"

#import "LPSSEManager.h"
#import "LPSSEvent.h"

#import "LIOTimerProxy.h"

#define LIOLookIOManagerLastKnownChatCookiesKey         @"LIOLookIOManagerLastKnownChatCookiesKey"
#define LIOLookIOManagerLastKnownEngagementIdKey        @"LIOLookIOManagerLastKnownEngagementIdKey"
#define LIOLookIOManagerLastKnownSSEUrlStringKey        @"LIOLookIOManagerLastKnownSSEUrlStringKey"
#define LIOLookIOManagerLastKnownPostUrlString          @"LIOLookIOManagerLastKnownPostUrlString"
#define LIOLookIOManagerLastKnownMediaUrlString         @"LIOLookIOManagerLastKnownMediaUrlString"
#define LIOLookIOManagerLastSSEventIdString             @"LIOLookIOManagerLastSSEventIdString"
#define LIOLookIOManagerLastKnownChatLastEventIdString  @"LIOLookIOManagerLastKnownChatLastEventIdString"
#define LIOLookIOManagerLastActivityDateKey             @"LIOLookIOManagerLastActivityDateKey"
#define LIOLookIOManagerLastKnownChatHistoryKey         @"LIOLookIOManagerLastKnownChatHistoryKey"


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

@property (nonatomic, strong) LIOTimerProxy *reconnectTimer;
@property (nonatomic, assign) LIOSSEChannelState retryAfterPreviousSSEChannelState;

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
        LIOChatMessage *firstMessage = [[LIOChatMessage alloc] init];
        firstMessage.status = LIOChatMessageStatusCreatedLocally;
        firstMessage.kind = LIOChatMessageKindRemote;
        firstMessage.date = [NSDate date];
        firstMessage.lineId = nil;
        firstMessage.text = [self.visit welcomeText];
        [self.messages addObject:firstMessage];
    }
}

#pragma mark Engagement Lifecycle Methods

- (void)cleanUpEngagement
{
    self.sseManager.delegate = nil;
}


- (void)startEngagement
{
    [self sendIntroPacket];
    [self.visit updateAndReportFunnelState];
}

- (void)cancelEngagement
{
    self.sseChannelState = LIOSSEChannelStateCancelling;
    [self.sseManager disconnect];
    
    if (self.reconnectTimer)
    {
        [self.reconnectTimer stopTimer];
        self.reconnectTimer = nil;
    }
}

- (void)endEngagement
{
    self.sseChannelState = LIOSSEChannelStateEnding;
    [self sendOutroPacket];
}

- (void)declineEngagementReconnect
{
    self.sseChannelState = LIOSSEChannelStateInitialized;
}

- (void)acceptEngagementReconnect
{
    [self connectSSESocket];
}

- (void)cancelReconnect
{
    if (LIOSSEChannelStateReconnectRetryAfter == self.sseChannelState)
    {
        if (self.reconnectTimer)
        {
            [self.reconnectTimer stopTimer];
            self.reconnectTimer = nil;
        }

        self.sseChannelState = LIOSSEChannelStateInitialized;
        [self.delegate engagementDidEnd:self];
    }
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
        
        self.sseChannelState = LIOSSEChannelStateConnecting;
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
    else
    {
        [self.delegate engagementDidFailToStart:self];
    }
}

#pragma mark -
#pragma mark Reconnect Methods

- (void)reconnectRetryAfter:(NSInteger)retryAfterSeconds
{
    // Retry after can occur for different types of channel state. We remember the previos state so we can return to it later if the reconnect fails
    self.retryAfterPreviousSSEChannelState = self.sseChannelState;
    
    self.sseChannelState = LIOSSEChannelStateReconnectRetryAfter;
    self.reconnectTimer = [[LIOTimerProxy alloc] initWithTimeInterval:retryAfterSeconds target:self selector:@selector(reconnectTimerDidFire)];
}

- (void)reconnectTimerDidFire
{
    self.sseChannelState = self.retryAfterPreviousSSEChannelState;

    if (self.reconnectTimer)
    {
        [self.reconnectTimer stopTimer];
        self.reconnectTimer = nil;
    }
    
    [self connectSSESocket];
}

#pragma mark SSE Channel Methods

- (void)connectSSESocket
{
    
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

}

- (void)sseManagerDidDisconnect:(LPSSEManager *)aManager
{
    switch (self.sseChannelState) {

            // If are not expecting a disconnect, we should try to reconnect
        case LIOSSEChannelStateConnected:
            self.sseChannelState = LIOSSEChannelStateReconnecting;
            [self connectSSESocket];
            break;
            
        // If we are trying to reconnect and failed, display an alert to the user
        case LIOSSEChannelStateReconnecting:
            [self handleSSEConnectionFailed];
            break;
            
        case LIOSSEChannelStateReconnectPrompt:
            [self handleSSEConnectionFailed];
            break;

        // If we are attempting to connect initially, this means we failed to start
        case LIOSSEChannelStateConnecting:
            [self handleSSEConnectionFailed];
            break;

        // If we're cancelling, this means cancelling succeeded
        case LIOSSEChannelStateCancelling:
            self.sseChannelState = LIOSSEChannelStateInitialized;
            [self.delegate engagementDidCancel:self];
            break;
           
        // If we're ending, this means ending succeeded
        case LIOSSEChannelStateEnding:
            self.sseChannelState = LIOSSEChannelStateInitialized;
            [self.delegate engagementDidEnd:self];
            break;
            
        // If we recieved an outro earlier, we are expecting this disconnect
        case LIOSSEChannelStateDisconnecting:
            self.sseChannelState = LIOSSEChannelStateInitialized;
            [self.delegate engagementDidDisconnect:self withAlert:YES];
            break;
            
        case LIOSSEChannelStateReconnectRetryAfter:
            break;
            
        case LIOSSEChannelStateInitialized:
            // If we are disconnected in this state, it means we already handled the disconnection through "reintroed" or "dispatch_error", and we can ignore this
            break;
            
        default:
            break;
    }
}

- (void)sseManagerWillDisconnect:(LPSSEManager *)aManager withError:(NSError *)err
{
}

- (void)handleSSEConnectionFailed
{
    switch (self.sseChannelState) {
        case LIOSSEChannelStateConnecting:
            self.sseChannelState = LIOSSEChannelStateInitialized;
            if (LIOVisitStateChatRequested == self.visit.visitState)
                [self.delegate engagementDidFailToStart:self];
            break;
            
        case LIOSSEChannelStateReconnecting:
            self.sseChannelState = LIOSSEChannelStateReconnectPrompt;
            [self.delegate engagementWantsReconnectionPrompt:self];
            break;
            
        case LIOSSEChannelStateReconnectPrompt:
            self.sseChannelState = LIOSSEChannelStateInitialized;
            [self.delegate engagementDidFailToReconnect:self];
            break;
            
            
            
        default:
            break;
    }
}


- (void)sseManager:(LPSSEManager *)aManager didDispatchEvent:(LPSSEvent *)anEvent
{
    NSError *error = nil;
    NSDictionary *aPacket = [NSJSONSerialization JSONObjectWithData:[anEvent.data dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];

    if (error || nil == aPacket)
    {
        [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"Invalid JSON received from server: \"%@\"", anEvent.data];
        return;
    }
    
    if (anEvent.eventId)
        if (![anEvent.eventId isEqualToString:@""])
            self.lastSSEventId = anEvent.eventId;
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.lastSSEventId forKey:LIOLookIOManagerLastKnownChatLastEventIdString];
    [userDefaults synchronize];
    
    LIOLog(@"<LPSSEManager> Dispatch event with data:\n%@\n", aPacket);
    
    NSString *type = [aPacket objectForKey:@"type"];

    // Reintroed
    if ([type isEqualToString:@"reintroed"])
    {
        NSNumber *success = [aPacket objectForKey:@"success"];
        if (success)
        {
            if (LIOSSEChannelStateReconnectPrompt == self.sseChannelState)
            {
                [self.delegate engagementDidReconnect:self];
            }
        
            self.sseChannelState = LIOSSEChannelStateConnected;
        
            if (LIOVisitStateChatRequested == self.visit.visitState)
            {
                [self sendCapabilitiesPacket];
                [self.delegate engagementDidConnect:self];
            }
        }
        else
        {
            if ([aPacket objectForKey:@"retry_after"]) {
                NSNumber *retryAfterObjects = [aPacket objectForKey:@"retry_after"];
                NSInteger retryAfterSeconds = [retryAfterObjects integerValue];
                
                if (retryAfterSeconds != -1) {
                    [self reconnectRetryAfter:retryAfterSeconds];
                    LIOLog(@"<LPSSEManager> Attempting reconnection in %d seconds..", retryAfterSeconds);
                }
                else
                {
                    [self handleSSEConnectionFailed];
                }
            }
            else
                [self handleSSEConnectionFailed];
        }
    }
    
    // Dispatch Error
    
    if ([type isEqualToString:@"dispatch_error"])
    {
        if ([aPacket objectForKey:@"retry_after"]) {
            NSNumber *retryAfterObjects = [aPacket objectForKey:@"retry_after"];
            NSInteger retryAfterSeconds = [retryAfterObjects integerValue];

            BOOL retryAfter = arc4random() % 2;
            if (retryAfter)
                retryAfterSeconds = 5;

            if (retryAfterSeconds != -1) {
                [self reconnectRetryAfter:retryAfterSeconds];
                LIOLog(@"<LPSSEManager> Attempting reconnection in %d seconds..", retryAfterSeconds);
            }
            else
            {
                [self handleSSEConnectionFailed];
            }
        }
        else
        {
            [self handleSSEConnectionFailed];
        }
    }
    
    // Received line
    if ([type isEqualToString:@"line"])
    {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:[NSDate date] forKey:LIOLookIOManagerLastActivityDateKey];
        [userDefaults synchronize];
            
        NSString *text = [aPacket objectForKey:@"text"];
        NSString *senderName = [aPacket objectForKey:@"sender_name"];
        NSString *lineId = [aPacket objectForKey:@"line_id"];
        NSString *clientLineId = nil;
        if ([aPacket objectForKey:@"client_line_id"])
            clientLineId = [aPacket objectForKey:@"client_line_id"];
            
        LIOChatMessage *newMessage = [[LIOChatMessage alloc] init];
        newMessage.text = text;
        newMessage.senderName = senderName;
        newMessage.kind = LIOChatMessageKindRemote;
        newMessage.status = LIOChatMessageStatusReceived;
        newMessage.date = [NSDate date];
        newMessage.lineId = lineId;
        newMessage.clientLineId = clientLineId;
            
        BOOL shouldAddMessage = YES;
        // Don't add messages which originated from the visitor and are echoed back to the client
        // but add their line_id by matching their client_line_id
        if ([aPacket objectForKey:@"source"]) {
            NSString *source = [aPacket objectForKey:@"source"];
            if ([source isEqualToString:@"visitor"])
            {
                shouldAddMessage = NO;
                    
                NSPredicate *clientLineIdPredicate = [NSPredicate predicateWithFormat:@"clientLineId = %@", newMessage.clientLineId];
                NSArray *messagesWithClientLineId = [self.messages filteredArrayUsingPredicate:clientLineIdPredicate];
                if (messagesWithClientLineId.count > 0)
                {
                    LIOChatMessage *matchedClientLineIdMessage = [messagesWithClientLineId objectAtIndex:0];
                    if (matchedClientLineIdMessage.lineId == nil)
                        matchedClientLineIdMessage.lineId = newMessage.lineId;
                }
            }
        
            // Don't add messages if the lineId is identical to one we already have
            if (newMessage.lineId)
            {
                NSPredicate *lineIdPredicate = [NSPredicate predicateWithFormat:@"lineId = %@", newMessage.lineId];
                NSArray *messagesWithLineId = [self.messages filteredArrayUsingPredicate:lineIdPredicate];
                if (messagesWithLineId.count > 0)
                    shouldAddMessage = NO;
            }
            
            if (shouldAddMessage)
            {
                [self.messages addObject:newMessage];

                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                NSData *chatHistoryData = [NSKeyedArchiver archivedDataWithRootObject:self.messages];
                [userDefaults setObject:chatHistoryData forKey:LIOLookIOManagerLastKnownChatHistoryKey];
                [userDefaults synchronize];

                [self.delegate engagement:self didReceiveMessage:newMessage];
            }
        }
    }
    
    // Received Survey
    if ([type isEqualToString:@"survey"]) {

        // Check if this is an offline survey
        if ([aPacket objectForKey:@"offline"]) {
            // By default, we're not calling the custom chat not answered method.
            // If the developer has implemented both relevant methods, and shouldUseCustomactionForNotChatAnswered returns YES,
            // we do want to use this method
            
            // TODO Handle shouldUseCustomactionForNotChatAnswered
            
            NSDictionary *offlineSurveyDict = [aPacket objectForKey:@"offline"];
            if (offlineSurveyDict && [offlineSurveyDict isKindOfClass:[NSDictionary class]])
            {
                self.offlineSurvey = [[LIOSurvey alloc] initWithSurveyDictionary:offlineSurveyDict surveyType:LIOSurveyTypeOffline];
            } else {
                NSString *lastSentMessageText = nil;
                
                if (self.messages.count > 0)
                {
                    LIOChatMessage *chatMessage = [self.messages objectAtIndex:self.messages.count - 1];
                    lastSentMessageText = chatMessage.text;
                }
                
                self.offlineSurvey = [[LIOSurvey alloc] initWithDefaultOfflineSurveyWithResponse:lastSentMessageText];
            }
            
            [self.delegate engagementDidReceiveOfflineSurvey:self];
        }
        
        // Check if this is a postchat survey
        if ([aPacket objectForKey:@"postchat"]) {
            NSDictionary *postSurveyDict = [aPacket objectForKey:@"postchat"];
            if (postSurveyDict && [postSurveyDict isKindOfClass:[NSDictionary class]])
            {
                self.postchatSurvey = [[LIOSurvey alloc] initWithSurveyDictionary:postSurveyDict surveyType:LIOSurveyTypePostchat];
            }
        }
        
        if ([aPacket objectForKey:@"prechat"]) {
            NSDictionary *preSurveyDict = [aPacket objectForKey:@"prechat"];
            if (preSurveyDict && [preSurveyDict isKindOfClass:[NSDictionary class]])
            {
                // If the dictionary is empty, just start the engagement
                if ([preSurveyDict.allKeys count] == 0)
                {
                    [self.delegate engagementDidStart:self];
                }
                else
                {
                    self.prechatSurvey = [[LIOSurvey alloc] initWithSurveyDictionary:preSurveyDict surveyType:LIOSurveyTypePrechat];
                    [self.delegate engagementDidReceivePrechatSurvey:self];
                }
            }
        }
    }
    
    // Received Advisory
    if ([type isEqualToString:@"advisory"])
    {
        NSString *action = [aPacket objectForKey:@"action"];
    
        if ([action isEqualToString:@"notification"])
        {
            NSDictionary *data = [aPacket objectForKey:@"data"];
            NSString *notification = [data objectForKey:@"message"];
            
            [self.delegate engagement:self didReceiveNotification:notification];
        }
        if ([action isEqualToString:@"send_logs"])
        {
            // TODO Send Longs
            // [[LIOLogManager sharedLogManager] uploadLog];
        }
        if ([action isEqualToString:@"typing_start"])
        {
            [self.delegate engagement:self agentDidUpdateTypingStatus:YES];
        }
        if ([action isEqualToString:@"typing_stop"])
        {
            [self.delegate engagement:self agentDidUpdateTypingStatus:NO];
        }
        if ([action isEqualToString:@"connected"])
        {
            LIOLog(@"We're live!");            
            [self.delegate engagementAgentIsReady:self];
        }
        if ([action isEqualToString:@"unprovisioned"])
        {
            // TODO Handle unprovisioed
            /*
            unprovisioned = YES;
        
            [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
        
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.UnprovisionedAlertTitle")
                                                        message:LIOLocalizedString(@"LIOLookIOManager.UnprovisionedAlertBody")
                                                        delegate:self
                                                cancelButtonTitle:nil
                                                otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.UnprovisionedAlertButton"), nil];
            alertView.tag = LIOLookIOManagerUnprovisionedAlertViewTag;
            [alertView show];
            [alertView autorelease];
             */
        }
        if ([action isEqualToString:@"leave_message"])
        {
            // By default, we're not calling the custom chat not answered method.
            // If the developer has implemented both relevant methods, and shouldUseCustomactionForNotChatAnswered returns YES,
            // we do want to use this method
        
            // TODO Handle leave message
            /*
             callChatNotAnsweredAfterDismissal = NO;
        
                if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManagerShouldUseCustomActionForChatNotAnswered:)])
                    if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManagerCustomActionForChatNotAnswered:)])
                        callChatNotAnsweredAfterDismissal = [delegate lookIOManagerShouldUseCustomActionForChatNotAnswered:self];
        
                if (callChatNotAnsweredAfterDismissal) {
                    [self altChatViewControllerWantsSessionTermination:altChatViewController];
                } else {
                    LIOSurveyManager* surveyManager = [LIOSurveyManager sharedSurveyManager];
                    surveyManager.offlineSurveyIsDefault = YES;
            
                    NSString *lastSentMessageText = nil;
                    if (altChatViewController)
                        lastSentMessageText = altChatViewController.lastSentMessageText;
            
                    [[LIOSurveyManager sharedSurveyManager] populateDefaultOfflineSurveyWithResponse:lastSentMessageText];
            
                    [altChatViewController forceLeaveMessageScreen];
                 }
                 */
        }
        if ([action isEqualToString:@"engagement_started"])
        {
            [self.delegate engagementDidStart:self];
        }
    }
    
    if ([type isEqualToString:@"outro"])
    {
        self.sseChannelState = LIOSSEChannelStateDisconnecting;
    }

}

#pragma mark -
#pragma mark Chat API Methods

- (void)sendLineWithMessage:(LIOChatMessage *)message
{
    // TO DO - Check that engagement is active
    NSDictionary *lineDict = [NSDictionary dictionaryWithObjectsAndKeys:@"line", @"type", message.text, @"text", message.clientLineId, @"client_line_id", nil];
    NSString* lineRequestUrl = [NSString stringWithFormat:@"%@/%@", LIOLookIOManagerChatLineRequestURL, self.engagementId];
    
    [[LPChatAPIClient sharedClient] postPath:lineRequestUrl parameters:lineDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
        if (responseObject)
            LIOLog(@"<LINE> response: %@", responseObject);
        else
            LIOLog(@"<LINE> success");
        
        message.status = LIOChatMessageStatusSent;
        
        // Report message success to refresh table view if needed
        
    } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
        LIOLog(@"<LINE> failure: %@", error);
        
        // TODO - failed message with alert signal
        
        // If we get a 404, let's terminate the engagement
        if (operation.responseCode == 404) {
            // TO DO - End engagement and alert
        } else {
            message.status = LIOChatMessageStatusFailed;
            // TO DO - Refresh table view and notify user if needed
        }
    }];
}

- (void)sendMediaPacketWithMessage:(LIOChatMessage *)message
{
    // TODO: No engagement ID
    
    NSData *attachmentData = [[LIOMediaManager sharedInstance] mediaDataWithId:message.attachmentId];
    
    if (attachmentData)
    {
        NSString *mimeType = [[LIOMediaManager sharedInstance] mimeTypeFromId:message.attachmentId];
        NSString *sessionId = self.engagementId;
        NSString *bundleId = [LIOStatusManager bundleId];
        NSString *boundary = @"0xKhTmLbOuNdArY";
        NSString *dataBase64 = base64EncodedStringFromData(attachmentData);
        
        NSMutableData *body = [NSMutableData data];
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Disposition: form-data; name=\"file\"; filename=\"lpmobile_ios_upload\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimeType] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[dataBase64 dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Disposition: form-data; name=\"engagement_key\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[sessionId dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Disposition: form-data; name=\"bundle\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[bundleId dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [[LPMediaAPIClient sharedClient] postMultipartDataToPath:LIOLookIOManagerMediaUploadRequestURL data:body success:^(LPHTTPRequestOperation *operation, id responseObject) {

            message.status = LIOChatMessageStatusSent;

            // TODO - If message had failed before, update it here

            if (responseObject)
                LIOLog(@"<PHOTO UPLOAD> with response: %@", responseObject);
            else
                LIOLog(@"<PHOTO UPLOAD> success");
            
        } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
            message.status = LIOChatMessageStatusFailed;
            
            if (operation.responseCode == 413) {
                // TODO - If message is too big, has special notification for the user
                /*
                UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOAltChatViewController.AttachFailureLargeFileTitle")
                                                                    message:LIOLocalizedString(@"LIOAltChatViewController.AttachFailureLargeFileBody") delegate:nil
                                                              cancelButtonTitle:LIOLocalizedString(@"LIOAltChatViewController.AttachFailureLargeFileButton")
                                                              otherButtonTitles:nil];
                    
                [alertView show];
                [alertView release];
                 */
            }
            else
            {
                // TODO - Regular failure notification
                /*
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.FailedAttachmentSendTitle")
                                                                    message:LIOLocalizedString(@"LIOLookIOManager.FailedAttachmentSendBody")
                                                                   delegate:nil
                                                          cancelButtonTitle:@"LIOLookIOManager.FailedAttachmentSendButton"
                                                          otherButtonTitles:nil];
                [alertView show];
                [alertView autorelease];
                 */
            }
            
            LIOLog(@"<PHOTO UPLOAD> with failure: %@", error);
        }];
    }
}

- (void)sendOutroPacket
{
    // TODO Check if engagement id exists

    NSDictionary *outroDict = [NSDictionary dictionaryWithObjectsAndKeys:@"outro", @"type", nil];
    NSString* outroRequestUrl = [NSString stringWithFormat:@"%@/%@", LIOLookIOManagerChatOutroRequestURL, self.engagementId];
    
    [[LPChatAPIClient sharedClient] postPath:outroRequestUrl parameters:outroDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
        if (responseObject)
            LIOLog(@"<OUTRO> response: %@", responseObject);
        else
            LIOLog(@"<OUTRO> success");
        
        if (self.sseManager)
            [self.sseManager disconnect];
        
        [self.delegate engagementDidEnd:self];
        
    } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
        LIOLog(@"<OUTRO> failure: %@", error);
        if (self.sseManager)
            [self.sseManager disconnect];
        
        [self.delegate engagementDidEnd:self];

    }];
}

- (void)sendCapabilitiesPacket {
    // TODO Check if engagement id exists
    
    NSArray *capsArray = [NSArray arrayWithObjects:@"show_leavemessage", @"show_infomessage", nil];
    NSDictionary *capsDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              capsArray, @"capabilities",
                              nil];
    NSString* capsRequestUrl = [NSString stringWithFormat:@"%@/%@", LIOLookIOManagerChatCapabilitiesRequestURL, self.engagementId];
    
    [[LPChatAPIClient sharedClient] postPath:capsRequestUrl parameters:capsDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
        if (responseObject)
            LIOLog(@"<CAPABILITIES> response: %@", responseObject);
        else
            LIOLog(@"<CAPABILITIES> success");
        
    } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
        LIOLog(@"<CAPABILITIES> failure: %@", error);
        
        // TODO Retry failed capabilities call
    }];
}

- (void)sendAdvisoryPacketWithDict:(NSDictionary*)advisoryDict
{
    // TODO Check if engagement id exists

    NSString* advisoryRequestUrl = [NSString stringWithFormat:@"%@/%@", LIOLookIOManagerChatAdvisoryRequestURL, self.engagementId];
    
    [[LPChatAPIClient sharedClient] postPath:advisoryRequestUrl parameters:advisoryDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
        if (responseObject)
            LIOLog(@"<ADVISORY> with data %@ response: %@", advisoryDict, responseObject);
        else
            LIOLog(@"<ADVISORY> with data %@ success", advisoryDict);
    } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
        LIOLog(@"<ADVISORY> with data %@ failure: %@", advisoryDict, error);
    }];
}

- (void)sendChatHistoryPacketWithEmail:(NSString *)email
{
    // TODO Check if engagement id exists

    NSDictionary *emailDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:email], @"email_addresses", nil];

    NSString* chatHistoryRequestUrl = [NSString stringWithFormat:@"%@/%@", LIOLookIOManagerChatHistoryRequestURL, self.engagementId];
    
    [[LPChatAPIClient sharedClient] postPath:chatHistoryRequestUrl parameters:emailDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
        if (responseObject)
            LIOLog(@"<CHAT_HISTORY> response: %@", responseObject);
        else
            LIOLog(@"<CHAT_HISTORY> success");
    } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
        LIOLog(@"<CHAT_HISTORY> failure: %@", error);
    }];
}

#pragma mark -
#pragma mark Action Methods

- (void)sendVisitorLineWithText:(NSString *)text
{
    LIOChatMessage *newMessage = [[LIOChatMessage alloc] init];
    newMessage.status = LIOChatMessageStatusInitialized;
    newMessage.kind = LIOChatMessageKindLocal;
    newMessage.date = [NSDate date];
    newMessage.lineId = nil;
    newMessage.senderName = @"Me";
    newMessage.text = text;
    newMessage.clientLineId = [NSString stringWithFormat:@"%ld", (long)self.lastClientLineId];
    self.lastClientLineId += 1;
    [self.messages addObject:newMessage];
    
    [self sendLineWithMessage:newMessage];
    [self.delegate engagement:self didSendMessage:newMessage];
}

- (void)sendVisitorLineWithAttachmentId:(NSString *)attachmentId
{
    LIOChatMessage *newMessage = [[LIOChatMessage alloc] init];
    newMessage.status = LIOChatMessageStatusInitialized;
    newMessage.kind = LIOChatMessageKindLocalImage;
    newMessage.date = [NSDate date];
    newMessage.attachmentId = attachmentId;
    [self.messages addObject:newMessage];
    
    [self sendMediaPacketWithMessage:newMessage];
    [self.delegate engagement:self didSendMessage:newMessage];
}

- (void)submitSurvey:(LIOSurvey *)survey
{
    // TODO Check if engagement id exists

    NSString *surveyTypeString;
    switch (survey.surveyType) {
        case LIOSurveyTypePrechat:
            surveyTypeString = @"prechat";
            [self.delegate engagementDidSubmitPrechatSurvey:self];
            
            break;
            
        case LIOSurveyTypeOffline:
            surveyTypeString = @"offline";
            break;
            
        case LIOSurveyTypePostchat:
            surveyTypeString = @"postchat";
            break;
            
        default:
            break;
    }
    
    
    NSString* surveyRequestUrl = [NSString stringWithFormat:@"%@/%@", LIOLookIOManagerChatSurveyRequestURL, self.engagementId];
    NSDictionary *params = [NSDictionary dictionaryWithObject:[survey responseDict] forKey:surveyTypeString];
    
    [[LPChatAPIClient sharedClient] postPath:surveyRequestUrl parameters:params success:^(LPHTTPRequestOperation *operation, id responseObject) {
        if (responseObject)
            LIOLog(@"<SURVEY> with data:%@ response: %@", params, responseObject);
        else
            LIOLog(@"<SURVEY> success");
        
    } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
        LIOLog(@"<SURVEY> failure: %@", error);
        
        // If submitting the survey fails, and it's a pre chat survey, it's better to start the chat without the survey than ending the session
        // TODO
    }];
}

#pragma mark -
#pragma mark Helper Methods

- (BOOL)shouldPresentPostChatSurvey
{
    BOOL shouldPresentPostChatSurvey = NO;
    if (self.visit.surveysEnabled && self.postchatSurvey)
        shouldPresentPostChatSurvey = YES;
    
    return shouldPresentPostChatSurvey;
}

- (BOOL)shouldShowEmailChatButtonItem
{
    return !self.visit.hideEmailChat;
}

- (BOOL)shouldShowSendPhotoButtonItem
{
    return [self.delegate engagementShouldShowSendPhotoKeyboardItem:self];
}



@end
