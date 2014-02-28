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
#import <zlib.h>

#import "LIOLogManager.h"

#import "LPSSEManager.h"
#import "LPSSEvent.h"

#import "LIOTimerProxy.h"

#define LIOLookIOManagerLastKnownEngagementKey            @"LIOLookIOManagerLastKnownEngagementKey"
#define LIOLookIOManagerLastKnownEngagementMessagesKey    @"LIOLookIOManagerLastKnownEngagementMessagesKey"
#define LIOLookIOManagerLastKnownEngagementActivityDate   @"LIOLookIOManagerLastKnownEngagementActivityDate"

#define LIOChatAPIRequestRetries                        3
#define LIOEngagementReconnectionAfterCrashTimeLimit    60.0 // 1 minutes
#define LIOLookIOManagerMessageSeparator                @"!look.io!"
#define LIOLookIOManagerScreenCaptureInterval           0.5

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

@property (nonatomic, strong) NSMutableArray *failedRequestQueue;

@property (nonatomic, assign) BOOL isScreenShareActive;
@property (nonatomic, strong) NSTimer *screenshareTimer;
@property (nonatomic, assign) BOOL isScreenShareRequestInProgress;
@property (nonatomic, assign) unsigned long previousScreenshotHash;
@property (nonatomic, strong) NSDate *screenSharingStartedDate;

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
        
        self.failedRequestQueue = [[NSMutableArray alloc] init];
        
        self.isConnected = NO;
        self.isAgentTyping = NO;
    }
    return self;
}

- (void)attemptReconnectionWithVisit:(LIOVisit *)aVisit
{
    self.visit = aVisit;
    
    [self setupAPIClientBaseURL];
    
    self.sseChannelState = LIOSSEChannelStateReconnectPrompt;
    [self connectSSESocket];
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
        [firstMessage detectLinks];
        [self.messages addObject:firstMessage];
    }
}

#pragma mark -
#pragma mark Engagement Lifecycle Methods

- (void)cleanUpEngagement
{
    self.sseManager.delegate = nil;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults removeObjectForKey:LIOLookIOManagerLastKnownEngagementKey];
    [userDefaults removeObjectForKey:LIOLookIOManagerLastKnownEngagementActivityDate];
    [userDefaults removeObjectForKey:LIOLookIOManagerLastKnownEngagementMessagesKey];
    
    [userDefaults synchronize];
    
    if (self.isScreenShareActive)
        [self stopScreenshare];
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

- (void)engagementNotFound
{
    self.sseChannelState = LIOSSEChannelStateDisconnecting;
    [self.sseManager disconnect];
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
        self.isAgentTyping = NO;
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

#pragma mark -
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
            self.isAgentTyping = NO;
            [self.delegate engagementDidEnd:self];
            break;
            
        // If we recieved an outro earlier, we are expecting this disconnect
        case LIOSSEChannelStateDisconnecting:
            self.sseChannelState = LIOSSEChannelStateInitialized;
            self.isAgentTyping = NO;
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
            if (LIOVisitStatePostChatSurvey == self.visit.visitState || LIOVisitStateOfflineSurvey == self.visit.visitState)
            {
                self.sseChannelState = LIOSSEChannelStateInitialized;
                self.isAgentTyping = NO;
                [self.delegate engagementDidDisconnectWhileInPostOrOfflineSurvey:self];
            }
            else
            {
                self.sseChannelState = LIOSSEChannelStateReconnectPrompt;
                [self.delegate engagementWantsReconnectionPrompt:self];
            }
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
                [self sendCapabilitiesPacketRetries:0];
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
        // Just in case we didn't receive a "connected" packet, if we receive a line we are connected
        self.isConnected = YES;
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
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
        [newMessage detectLinks];
        
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
                [self saveEngagementMessages];
                
                [self.delegate engagement:self didReceiveMessage:newMessage];
            }
        }
    }
    
    // Received Survey
    if ([type isEqualToString:@"survey"]) {

        // Check if this is an offline survey
        if ([aPacket objectForKey:@"offline"]) {
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
            [self saveEngagement];
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
                
                [self saveEngagement];
                [self saveEngagementMessages];
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
            // TODO: Send Logs
            // [[LIOLogManager sharedLogManager] uploadLog];
        }
        if ([action isEqualToString:@"typing_start"])
        {
            self.isAgentTyping = YES;
            [self.delegate engagement:self agentDidUpdateTypingStatus:YES];
        }
        if ([action isEqualToString:@"typing_stop"])
        {
            self.isAgentTyping = NO;
            [self.delegate engagement:self agentDidUpdateTypingStatus:NO];
        }
        if ([action isEqualToString:@"connected"])
        {
            LIOLog(@"We're live!");
            
            self.isConnected = YES;
            [self.delegate engagementAgentIsReady:self];
        }
        if ([action isEqualToString:@"unprovisioned"])
        {
            // TODO: Handle unprovisioned?
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
        
            // TODO: Handle leave message?
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
            [self saveEngagement];
            [self saveEngagementMessages];
        }
    }
    
    if ([type isEqualToString:@"outro"])
    {
        // If we are already ending the session, and received an outro,
        // this is still and ending session, not a disconnect session
        if (LIOSSEChannelStateEnding != self.sseChannelState)
            self.sseChannelState = LIOSSEChannelStateDisconnecting;
    }
    
    if ([type isEqualToString:@"permission"])
    {
        NSString *asset = [aPacket objectForKey:@"asset"];
        if ([asset isEqualToString:@"screenshare"])
            [self.delegate engagementWantsScreenshare:self];
    }
    
    if ([type isEqualToString:@"screen_cursor"])
    {
        if (self.isScreenShareActive)
        {
            NSNumber *xObject = [aPacket objectForKey:@"x"];
            NSNumber *yObject = [aPacket objectForKey:@"y"];

            [self.delegate engagement:self screenshareCursorMoveToPoint:CGPointMake([xObject floatValue], [yObject floatValue])];
        }
    }
    if ([type isEqualToString:@"screen_cursor_start"])
    {
        [self.delegate engagement:self wantsCursor:YES];
    }
    if ([type isEqualToString:@"screen_cursor_stop"])
    {
        [self.delegate engagement:self wantsCursor:NO];
    }
    if ([type isEqualToString:@"screen_click"])
    {
        NSNumber *xObject = [aPacket objectForKey:@"x"];
        NSNumber *yObject = [aPacket objectForKey:@"y"];

        [self.delegate engagement:self screenshareDidClickAtPoint:CGPointMake([xObject floatValue], [yObject floatValue])];
    }

}

#pragma mark -
#pragma mark Chat API Methods

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

- (void)sendLineWithMessage:(LIOChatMessage *)message
{
    if (LIOChatMessageStatusFailed == message.status)
    {
        message.status = LIOChatMessageStatusResending;
        [self.delegate engagementChatMessageStatusDidChange:self];
    }
    else
    {
        message.status = LIOChatMessageStatusSending;
    }
    
    NSDictionary *lineDict = [NSDictionary dictionaryWithObjectsAndKeys:@"line", @"type", message.text, @"text", message.clientLineId, @"client_line_id", nil];
    NSString* lineRequestUrl = [NSString stringWithFormat:@"%@/%@", LIOLookIOManagerChatLineRequestURL, self.engagementId];
    
    [[LPChatAPIClient sharedClient] postPath:lineRequestUrl parameters:lineDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
        if (responseObject)
            LIOLog(@"<LINE> response: %@", responseObject);
        else
            LIOLog(@"<LINE> success");
        
        // If this is a resend, we need to update the message view
        if (LIOChatMessageStatusResending == message.status)
        {
            [self.delegate engagementChatMessageStatusDidChange:self];
            message.status = LIOChatMessageStatusSent;
        }
        else
        {
            message.status = LIOChatMessageStatusSent;
        }
        
    } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
        LIOLog(@"<LINE> failure: %@", error);
        
        // If we get a 404, let's terminate the engagement
        if (operation.responseCode == 404) {
            [self engagementNotFound];
        }
        // For other errors, we should display an alert for the failed message
        else
        {
            message.status = LIOChatMessageStatusFailed;
            [self.delegate engagementChatMessageStatusDidChange:self];
        }
    }];
}

- (void)sendMediaPacketWithMessage:(LIOChatMessage *)message
{
    if (LIOChatMessageStatusFailed == message.status)
    {
        message.status = LIOChatMessageStatusResending;
        [self.delegate engagementChatMessageStatusDidChange:self];
    }
    else
    {
        message.status = LIOChatMessageStatusSending;
    }
    
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

            if (responseObject)
                LIOLog(@"<PHOTO UPLOAD> with response: %@", responseObject);
            else
                LIOLog(@"<PHOTO UPLOAD> success");
            
            // If this is a resend, we need to update the message view
            if (LIOChatMessageStatusResending == message.status)
            {
                [self.delegate engagementChatMessageStatusDidChange:self];
                message.status = LIOChatMessageStatusSent;
            }
            else
            {
                message.status = LIOChatMessageStatusSent;
            }
            
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
                // If we get a 404, let's terminate the engagement
                if (operation.responseCode == 404) {
                    [self engagementNotFound];
                }
                // For other errors, we should display an alert for the failed message
                else
                {
                    message.status = LIOChatMessageStatusFailed;
                    [self.delegate engagementChatMessageStatusDidChange:self];
                }
            }
            
            LIOLog(@"<PHOTO UPLOAD> with failure: %@", error);
        }];
    }
}

- (void)sendOutroPacket
{
    NSDictionary *outroDict = [NSDictionary dictionaryWithObjectsAndKeys:@"outro", @"type", nil];
    NSString* outroRequestUrl = [NSString stringWithFormat:@"%@/%@", LIOLookIOManagerChatOutroRequestURL, self.engagementId];
    
    [[LPChatAPIClient sharedClient] postPath:outroRequestUrl parameters:outroDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
        if (responseObject)
            LIOLog(@"<OUTRO> response: %@", responseObject);
        else
            LIOLog(@"<OUTRO> success");
        
        if (self.sseManager)
            [self.sseManager disconnect];
        
        self.isAgentTyping = NO;
        [self.delegate engagementDidEnd:self];
        
    } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
        LIOLog(@"<OUTRO> failure: %@", error);
        if (self.sseManager)
            [self.sseManager disconnect];
        
        self.isAgentTyping = NO;
        [self.delegate engagementDidEnd:self];
    }];
}

- (void)sendCapabilitiesPacketRetries:(NSInteger)retries
{
    // Submit the request if network is available, otherwise, queue it
    
    [[LIOAnalyticsManager sharedAnalyticsManager] pumpReachabilityStatus];
    if (LIOAnalyticsManagerReachabilityStatusConnected == [LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)
    {
        
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
            
            // If we get a 404, let's terminate the engagement
            if (operation.responseCode == 404) {
                [self engagementNotFound];
            }
            else
            {
                [self addQueuedRequestWithType:LIOQueuedRequestTypeCapabilities payload:nil retries:retries+1];
            }
        }];
    }
    else
    {
        [self addQueuedRequestWithType:LIOQueuedRequestTypeCapabilities payload:nil retries:retries];
    }
}

- (void)sendAdvisoryPacketWithDict:(NSDictionary*)advisoryDict retries:(NSInteger)retries
{
    // Don't report advisories if the session is ending
    if (LIOSSEChannelStateEnding == self.sseChannelState)
        return;
    
    [[LIOAnalyticsManager sharedAnalyticsManager] pumpReachabilityStatus];
    if (LIOAnalyticsManagerReachabilityStatusConnected == [LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)
    {
        
        NSString* advisoryRequestUrl = [NSString stringWithFormat:@"%@/%@", LIOLookIOManagerChatAdvisoryRequestURL, self.engagementId];
        
        [[LPChatAPIClient sharedClient] postPath:advisoryRequestUrl parameters:advisoryDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
            if (responseObject)
                LIOLog(@"<ADVISORY> with data %@ response: %@", advisoryDict, responseObject);
            else
                LIOLog(@"<ADVISORY> with data %@ success", advisoryDict);
        } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
            LIOLog(@"<ADVISORY> with data %@ failure: %@", advisoryDict, error);
            
            if (operation.responseCode == 404)
            {
                [self engagementNotFound];
            }
            else
            {
                [self addQueuedRequestWithType:LIOQueuedRequestTypeAdvisory payload:advisoryDict retries:retries + 1];
                [self handleRequestQueueIfNeeded];
            }
        }];
    }
    else
    {
        [self addQueuedRequestWithType:LIOQueuedRequestTypeAdvisory payload:advisoryDict retries:retries];
    }
}

- (void)sendChatHistoryPacketWithEmail:(NSString *)email retries:(NSInteger)retries
{
    // Submit the request if network is available, otherwise, queue it
    
    [[LIOAnalyticsManager sharedAnalyticsManager] pumpReachabilityStatus];
    if (LIOAnalyticsManagerReachabilityStatusConnected == [LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)
    {
        NSDictionary *emailDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:email], @"email_addresses", nil];
        
        NSString* chatHistoryRequestUrl = [NSString stringWithFormat:@"%@/%@", LIOLookIOManagerChatHistoryRequestURL, self.engagementId];
        
        [[LPChatAPIClient sharedClient] postPath:chatHistoryRequestUrl parameters:emailDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
            if (responseObject)
                LIOLog(@"<CHAT_HISTORY> response: %@", responseObject);
            else
                LIOLog(@"<CHAT_HISTORY> success");
        } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
            LIOLog(@"<CHAT_HISTORY> failure: %@", error);
            
            if (operation.responseCode == 404)
            {
                // For a 404, end the engagement
                [self engagementNotFound];
            }
            else
            {
                [self addQueuedRequestWithType:LIOQueuedRequestTypeChatHistory payload:email retries:retries+1];
                [self handleRequestQueueIfNeeded];
            }
        }];
    }
    else
    {
        [self addQueuedRequestWithType:LIOQueuedRequestTypeChatHistory payload:email retries:retries];
    }
}

- (void)sendPermissionPacketWithDict:(NSDictionary *)permissionDict retries:(NSInteger)retries
{
    [[LIOAnalyticsManager sharedAnalyticsManager] pumpReachabilityStatus];
    if (LIOAnalyticsManagerReachabilityStatusConnected == [LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)
    {
        
        NSString* permissionRequestUrl = [NSString stringWithFormat:@"%@/%@", LIOLookIOManagerChatPermissionRequestURL, self.engagementId];
        
        [[LPChatAPIClient sharedClient] postPath:permissionRequestUrl parameters:permissionDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
            if (responseObject)
                LIOLog(@"<PERMISSION> with data %@ response: %@", permissionDict, responseObject);
            else
                LIOLog(@"<PERMISSION> with data %@ success", permissionDict);
        } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
            LIOLog(@"<PERMISSION> with data %@ failure: %@", permissionDict, error);
            
            if (operation.responseCode == 404)
            {
                [self engagementNotFound];
            }
            else
            {
                [self addQueuedRequestWithType:LIOQueuedRequestTypePermission payload:permissionDict retries:retries + 1];
                [self handleRequestQueueIfNeeded];
            }
        }];
    }
    else
    {
        [self addQueuedRequestWithType:LIOQueuedRequestTypePermission payload:permissionDict retries:retries];
    }
}

- (void)submitSurvey:(LIOSurvey *)survey retries:(NSInteger)retries
{
    // Submit the request if network is available, otherwise, queue it
    
    [[LIOAnalyticsManager sharedAnalyticsManager] pumpReachabilityStatus];
    if (LIOAnalyticsManagerReachabilityStatusConnected == [LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)
    {
        NSString *surveyTypeString;
        switch (survey.surveyType) {
            case LIOSurveyTypePrechat:
                surveyTypeString = @"prechat";
                [self.delegate engagementDidSubmitPrechatSurvey:self];
                
                break;
                
            // In case of offline or postchat, we are expecting the session to end afterwards
                
            case LIOSurveyTypeOffline:
                surveyTypeString = @"offline";
                self.sseChannelState = LIOSSEChannelStateEnding;
                break;
                
            case LIOSurveyTypePostchat:
                surveyTypeString = @"postchat";
                self.sseChannelState = LIOSSEChannelStateEnding;
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
            
            if (operation.responseCode == 404)
            {
                // For a 404, we only need to end the engagement if it's a pre chat survey, otherwise it is already ended
                if (LIOSurveyTypePrechat == survey.surveyType)
                {
                    [self engagementNotFound];
                }
            }
            else
            {
                // For all other failures, queue the request, and retry
                [self addQueuedRequestWithType:LIOQueuedRequestTypeSurvey payload:survey retries:retries+1];
                [self handleRequestQueueIfNeeded];
            }
        }];
    }
    else
    {
        [self addQueuedRequestWithType:LIOQueuedRequestTypeSurvey payload:survey retries:retries];
    }
}

#pragma mark -
#pragma mark Chat API Queue

- (void)addQueuedRequestWithType:(LIOQueuedRequestType)type payload:(id)payload retries:(NSInteger)retries
{
    // Queue the request until the retries have reached the defined level
    if (retries < LIOChatAPIRequestRetries)
    {
        NSDictionary *queuedRequest;
        if (payload)
        {
            queuedRequest = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:type], @"type", payload, @"payload", [NSNumber numberWithInteger:retries], @"retries", nil];
        }
        else
        {
            queuedRequest = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:type], @"type", [NSNumber numberWithInteger:retries], @"retries", nil];
        }
        
        [self.failedRequestQueue addObject:queuedRequest];
    }
}

- (void)handleRequestQueueIfNeeded
{
    if (self.failedRequestQueue.count > 0)
    {
        NSDictionary *nextQueuedRequest = [self.failedRequestQueue objectAtIndex:0];
        [self.failedRequestQueue removeObjectAtIndex:0];
        
        id payload = [nextQueuedRequest objectForKey:@"payload"];
        
        NSNumber *requestTypeObject = [nextQueuedRequest objectForKey:@"type"];
        LIOQueuedRequestType requestType = [requestTypeObject intValue];
        
        NSNumber *retriesObject = [nextQueuedRequest objectForKey:@"retries"];
        NSInteger retries = [retriesObject integerValue];
        
        switch (requestType) {
            case LIOQueuedRequestTypeAdvisory:
                if ([payload isKindOfClass:[NSDictionary class]])
                {
                    NSDictionary *payloadDictionary = (NSDictionary *)payload;
                    [self sendAdvisoryPacketWithDict:payloadDictionary retries:retries];
                }
                break;
                
            case LIOQueuedRequestTypeCapabilities:
                [self sendCapabilitiesPacketRetries:retries];
                break;
                
            case LIOQueuedRequestTypeChatHistory:
                if ([payload isKindOfClass:[NSString class]])
                {
                    NSString *payloadString = (NSString *)payload;
                    [self sendChatHistoryPacketWithEmail:payloadString retries:retries];
                }
                break;
                
            case LIOQueuedRequestTypeSurvey:
                if ([payload isKindOfClass:[LIOSurvey class]])
                {
                    LIOSurvey *payloadSurvey = (LIOSurvey *)payload;
                    [self submitSurvey:payloadSurvey retries:retries];
                }
                break;
                
            case LIOQueuedRequestTypePermission:
                if ([payload isKindOfClass:[NSDictionary class]])
                {
                    NSDictionary *payloadDictionary = (NSDictionary *)payload;
                    [self sendPermissionPacketWithDict:payloadDictionary retries:retries];
                }
                
            default:
                break;
        }
    }
}

- (void)reachabilityDidChange
{
    [[LIOAnalyticsManager sharedAnalyticsManager] pumpReachabilityStatus];
    if (LIOAnalyticsManagerReachabilityStatusConnected == [LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)
    {
        [self handleRequestQueueIfNeeded];
    }
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
    [newMessage detectLinks];
    newMessage.clientLineId = [NSString stringWithFormat:@"%ld", (long)self.lastClientLineId];
    self.lastClientLineId += 1;
    [self.messages addObject:newMessage];
    
    [self sendLineWithMessage:newMessage];
    [self.delegate engagement:self didSendMessage:newMessage];
    
    [self saveEngagementMessages];
}

- (void)sendVisitorLineWithAttachmentId:(NSString *)attachmentId
{
    LIOChatMessage *newMessage = [[LIOChatMessage alloc] init];
    newMessage.status = LIOChatMessageStatusInitialized;
    newMessage.kind = LIOChatMessageKindLocalImage;
    newMessage.date = [NSDate date];
    newMessage.attachmentId = attachmentId;
    newMessage.clientLineId = [NSString stringWithFormat:@"%ld", (long)self.lastClientLineId];
    self.lastClientLineId += 1;
    [self.messages addObject:newMessage];
    
    [self sendMediaPacketWithMessage:newMessage];
    [self.delegate engagement:self didSendMessage:newMessage];
    
    [self saveEngagementMessages];
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

#pragma mark - 
#pragma mark Save Methods

+ (LIOEngagement *)loadExistingEngagement
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults objectForKey:LIOLookIOManagerLastKnownEngagementKey] || ![userDefaults objectForKey:LIOLookIOManagerLastKnownEngagementActivityDate])
        return nil;
    
    NSDate *lastActivityDate = [userDefaults objectForKey:LIOLookIOManagerLastKnownEngagementActivityDate];
    NSTimeInterval timeSinceLastActivity = [lastActivityDate timeIntervalSinceNow];
    if (timeSinceLastActivity < -LIOEngagementReconnectionAfterCrashTimeLimit)
    {
        // Too much time has passed.
        LIOLog(@"Found a saved engagement id, but it's old. Discarding...");

        [userDefaults removeObjectForKey:LIOLookIOManagerLastKnownEngagementKey];
        [userDefaults removeObjectForKey:LIOLookIOManagerLastKnownEngagementActivityDate];
        [userDefaults removeObjectForKey:LIOLookIOManagerLastKnownEngagementMessagesKey];
        
        [userDefaults synchronize];
        
        return nil;
    }

    LIOEngagement *engagement = [NSKeyedUnarchiver unarchiveObjectWithData:[userDefaults objectForKey:LIOLookIOManagerLastKnownEngagementKey]];
    
    [engagement loadEngagementMessages];
    
    return engagement;
}

- (void)saveEngagement
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:self] forKey:LIOLookIOManagerLastKnownEngagementKey];
    [userDefaults synchronize];
}

- (void)saveEngagementMessages
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:self.messages] forKey:LIOLookIOManagerLastKnownEngagementMessagesKey];
    [userDefaults setObject:[NSDate date] forKey:LIOLookIOManagerLastKnownEngagementActivityDate];
    [userDefaults synchronize];
}

- (void)loadEngagementMessages
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:LIOLookIOManagerLastKnownEngagementMessagesKey])
    {
        self.messages = [NSKeyedUnarchiver unarchiveObjectWithData:[userDefaults objectForKey:LIOLookIOManagerLastKnownEngagementMessagesKey]];
    }
}

#pragma mark -
#pragma mark NSCopying Methods

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.lastClientLineId = [decoder decodeIntegerForKey:@"lastClientLineId"];
        
        self.prechatSurvey = [decoder decodeObjectForKey:@"prechatSurvey"];
        self.postchatSurvey = [decoder decodeObjectForKey:@"postchatSurvey"];
        self.offlineSurvey = [decoder decodeObjectForKey:@"offlineSurvey"];
        
        self.chatCookies = [decoder decodeObjectForKey:@"chatCookies"];
        
        self.engagementId = [decoder decodeObjectForKey:@"engagementId"];
        self.SSEUrlString = [decoder decodeObjectForKey:@"SSEUrlString"];
        self.postUrlString = [decoder decodeObjectForKey:@"postUrlString"];
        self.mediaUrlString = [decoder decodeObjectForKey:@"mediaUrlString"];
        self.lastSSEventId = [decoder decodeObjectForKey:@"lastSSEventId"];
        
        self.isConnected = [decoder decodeBoolForKey:@"isConnected"];
        
        self.sseChannelState = LIOSSEChannelStateInitialized;
        self.failedRequestQueue = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    
    [encoder encodeInteger:self.lastClientLineId forKey:@"lastClientLineId"];

    [encoder encodeObject:self.prechatSurvey forKey:@"prechatSurvey"];
    [encoder encodeObject:self.postchatSurvey forKey:@"postchatSurvey"];
    [encoder encodeObject:self.offlineSurvey forKey:@"offlineSurvey"];
    
    [encoder encodeObject:self.chatCookies forKey:@"chatCookies"];
    
    [encoder encodeObject:self.engagementId forKey:@"engagementId"];
    [encoder encodeObject:self.SSEUrlString forKey:@"SSEUrlString"];
    [encoder encodeObject:self.postUrlString forKey:@"postUrlString"];
    [encoder encodeObject:self.mediaUrlString forKey:@"mediaUrlString"];
    [encoder encodeObject:self.lastSSEventId forKey:@"lastSSEventId"];
    
    [encoder encodeBool:self.isConnected forKey:@"isConnected"];
}

#pragma mark -
#pragma mark Screensharing Methods

- (void)startScreenshare
{
    self.isScreenShareActive = YES;
    self.screenSharingStartedDate = [NSDate date];
    self.screenshareTimer = [NSTimer scheduledTimerWithTimeInterval:LIOLookIOManagerScreenCaptureInterval
                                                          target:self
                                                        selector:@selector(screenCaptureTimerDidFire:)
                                                        userInfo:nil
                                                         repeats:YES];
}

- (void)stopScreenshare
{
    self.isScreenShareActive = NO;
    if (self.screenshareTimer)
    {
        [self.screenshareTimer invalidate];
        self.screenshareTimer = nil;
    }
    [self.delegate engagement:self wantsCursor:NO];        
}

- (void)screenCaptureTimerDidFire:(NSTimer *)aTimer
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *screenshotImage = [self.delegate engagementWantsScreenshot:self];
        if (screenshotImage != nil)
        {
            NSData *screenshotData = UIImageJPEGRepresentation(screenshotImage, 0.0);

            unsigned long currentHash = crc32(0L, Z_NULL, 0);
            currentHash = crc32(currentHash, [screenshotData bytes], [screenshotData length]);
            
            if (0 == self.previousScreenshotHash || currentHash != self.previousScreenshotHash)
            {
                self.previousScreenshotHash = currentHash;
                
                UIInterfaceOrientation actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
                NSString *orientationString = @"???";
                if (UIInterfaceOrientationPortrait == actualInterfaceOrientation)
                    orientationString = @"portrait";
                else if (UIInterfaceOrientationPortraitUpsideDown == actualInterfaceOrientation)
                    orientationString = @"portrait_upsidedown";
                else if (UIInterfaceOrientationLandscapeRight == actualInterfaceOrientation)
                    orientationString = @"landscape";
                else
                    orientationString = @"landscape_upsidedown";
                
                NSTimeInterval timeSinceSharingStarted = [[NSDate date] timeIntervalSinceDate:self.screenSharingStartedDate];
                
                // screenshot:ver:time:orientation:w:h:datalen:[blarghle]
                NSString *header = [NSString stringWithFormat:@"screenshot:2:%f:%@:%d:%d:%lu:", timeSinceSharingStarted, orientationString, (int)screenshotImage.size.width, (int)screenshotImage.size.height, (unsigned long)[screenshotData length]];
                NSData *headerData = [header dataUsingEncoding:NSUTF8StringEncoding];
                
                NSMutableData *dataToSend = [NSMutableData data];
                [dataToSend appendData:headerData];
                [dataToSend appendData:screenshotData];
                [dataToSend appendData:[LIOLookIOManagerMessageSeparator dataUsingEncoding:NSUTF8StringEncoding]];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self sendScreenshotPacketWithData:dataToSend];
                    LIOLog(@"\n\n[SCREENSHOT] Sent %dx%d %@ screenshot (%u bytes).\nHeader: %@\n\n", (int)screenshotImage.size.width, (int)screenshotImage.size.height, orientationString, [dataToSend length], header);
                });
            }
        }
    });
}

- (void)sendScreenshotPacketWithData:(NSData*)screenshotData {
    // Don't send screenshot while previous screenshot is being sent
    if (self.isScreenShareRequestInProgress)
        return;
    
    NSString* screenshotRequestUrl = [NSString stringWithFormat:@"%@/%@", LIOLookIOManagerChatScreenshotRequestURL, self.engagementId];
    [[LPChatAPIClient sharedClient] postPath:screenshotRequestUrl data:screenshotData success:^(LPHTTPRequestOperation *operation, id responseObject) {
        self.isScreenShareRequestInProgress = NO;
        if (responseObject)
            LIOLog(@"<SCREENSHOT> with response: %@", responseObject);
        else
            LIOLog(@"<SCREENSHOT> success");
    } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
        self.isScreenShareRequestInProgress = NO;
        
        LIOLog(@"<SCREENSHOT> with data %@ failure: %@", screenshotData, error);
    }];
}


@end
