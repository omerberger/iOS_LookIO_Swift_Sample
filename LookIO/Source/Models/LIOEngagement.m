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
#import "LPHTTPRequestOperation.h"

#import "LIOLogManager.h"

#import "LPSSEManager.h"
#import "LPSSEvent.h"

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

- (void)startEngagement
{
    [self sendIntroPacket];
}

- (void)cancelEngagement
{
    [self.sseManager disconnect];
}

- (void)endEngagement
{
    [self sendOutroPacket];
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
        [self.delegate engagementDidConnect:self];
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
    
    // Received Advisory
    if ([type isEqualToString:@"advisory"])
    {
        NSString *action = [aPacket objectForKey:@"action"];
    
        if ([action isEqualToString:@"notification"])
        {
            NSDictionary *data = [aPacket objectForKey:@"data"];
            NSString *message = [data objectForKey:@"message"];

            // TODO Send Notification
        }
        if ([action isEqualToString:@"send_logs"])
        {
            // TODO Send Longs
            // [[LIOLogManager sharedLogManager] uploadLog];
        }
        if ([action isEqualToString:@"typing_start"])
        {
            // TODO Set agent typing
        }
        if ([action isEqualToString:@"typing_stop"])
        {
            // TODO Set agent not typing
        }
        if ([action isEqualToString:@"connected"])
        {
            // TODO Notify "agent is ready to chat with you"
            LIOLog(@"We're live!");
        
            /*
            if (UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
            {
                UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                localNotification.soundName = @"LookIODing.caf";
                localNotification.alertBody = LIOLocalizedString(@"LIOLookIOManager.LocalNotificationReadyBody");
                localNotification.alertAction = LIOLocalizedString(@"LIOLookIOManager.LocalNotificationReadyButton");
                [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
            
                [self showChatAnimated:NO];
            }
            */
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
}

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
        
        // If we get a 404, let's terminate the engagement
        if (operation.responseCode == 404) {
            // TO DO - End engagement and alert
        } else {
            message.status = LIOChatMessageStatusFailed;
            // TO DO - Refresh table view and notify user if needed
        }
    }];
}

-(void)sendOutroPacket
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

#pragma mark Action Methods

- (void)sendVisitorLineWithText:(NSString *)text
{
    LIOChatMessage *newMessage = [[LIOChatMessage alloc] init];
    newMessage.status = LIOChatMessageStatusInitialized;
    newMessage.kind = LIOChatMessageKindLocal;
    newMessage.date = [NSDate date];
    newMessage.lineId = nil;
    newMessage.text = text;
    newMessage.clientLineId = [NSString stringWithFormat:@"%ld", (long)self.lastClientLineId];
    self.lastClientLineId += 1;
    [self.messages addObject:newMessage];
    
    [self sendLineWithMessage:newMessage];
    [self.delegate engagement:self didSendMessage:newMessage];
}


@end
