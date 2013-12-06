//
//  LIOVisit.m
//  LookIO
//
//  Created by Yaron Karasik on 12/5/13.
//
//

#import "LIOVisit.h"

#import "LIOManager.h"
#import "LIOLogManager.h"
#import "LIOAnalyticsManager.h"
#import "LIOBundleManager.h"

#import "LPVisitAPIClient.h"
#import "LIOStatusManager.h"
#import "LPVisitAPIClient.h"

#import "LPHTTPRequestOperation.h"
#import "LIOTimerProxy.h"

#define LIOLookIOManagerVersion @"1.1.0"

#define HEXCOLOR(c) [UIColor colorWithRed:((c>>16)&0xFF)/255.0 \
                                    green:((c>>8)&0xFF)/255.0 \
                                     blue:((c)&0xFF)/255.0 \
                                    alpha:1.0]

#define LIOLookIOManagerDefaultContinuationReportInterval  60.0 // 1 minute
#define LIOLookIOManagerMaxContinueFailures                3

// User defaults keys
#define LIOLookIOManagerLastKnownButtonVisibilityKey    @"LIOLookIOManagerLastKnownButtonVisibilityKey"
#define LIOLookIOManagerLastKnownButtonTextKey          @"LIOLookIOManagerLastKnownButtonTextKey"
#define LIOLookIOManagerLastKnownButtonTintColorKey     @"LIOLookIOManagerLastKnownButtonTintColorKey"
#define LIOLookIOManagerLastKnownButtonTextColorKey     @"LIOLookIOManagerLastKnownButtonTextColorKey"
#define LIOLookIOManagerLastKnownWelcomeMessageKey      @"LIOLookIOManagerLastKnownWelcomeMessageKey"
#define LIOLookIOManagerLaunchReportQueueKey            @"LIOLookIOManagerLaunchReportQueueKey"
#define LIOLookIOManagerLastActivityDateKey             @"LIOLookIOManagerLastActivityDateKey"
#define LIOLookIOManagerLastKnownSessionIdKey           @"LIOLookIOManagerLastKnownSessionIdKey"
#define LIOLookIOManagerLastKnownVisitorIdKey           @"LIOLookIOManagerLastKnownVisitorIdKey"
#define LIOLookIOManagerPendingEventsKey                @"LIOLookIOManagerPendingEventsKey"
#define LIOLookIOManagerMultiskillMappingKey            @"LIOLookIOManagerMultiskillMappingKey"
#define LIOLookIOManagerLastKnownSurveysEnabled         @"LIOLookIOManagerLastKnownSurveysEnabled"

@interface LIOVisit ()

@property (nonatomic, copy) NSString *currentVisitId;
@property (nonatomic, assign) LIOVisitState visitState;

@property (nonatomic, copy) NSString *requiredSkill;
@property (nonatomic, copy) NSString *lastKnownPageViewValue;

@property (nonatomic, assign) LIOFunnelState funnelState;
@property (nonatomic, assign) BOOL introPacketWasSent;
@property (nonatomic, assign) BOOL funnelRequestIsActive;
@property (nonatomic, strong) NSMutableArray *funnelRequestQueue;

@property (nonatomic, assign) BOOL controlButtonHidden;
@property (nonatomic, strong) NSNumber *lastKnownButtonVisibility;
@property (nonatomic, assign) BOOL disableControlButtonOverride;
@property (nonatomic, assign) BOOL *previousControlButtonVisibilityValue;
@property (nonatomic, copy) NSString *lastKnownButtonText;
@property (nonatomic, copy) NSString *lastKnownButtonTintColor;
@property (nonatomic, copy) NSString *lastKnownButtonTextColor;

@property (nonatomic, copy) NSString *lastKnownWelcomeText;

@property (nonatomic, copy) NSString *lastKnownVisitURL;
@property (nonatomic, assign) NSTimeInterval nextTimeInterval;
@property (nonatomic, strong) LIOTimerProxy *continuationTimer;
@property (nonatomic, assign) BOOL continueCallInProgress;
@property (nonatomic, assign) NSInteger failedContinueCount;

@property (nonatomic, assign) BOOL lastKnownSurveysEnabled;
@property (nonatomic, assign) BOOL disableSurveysOverride;
@property (nonatomic, assign) BOOL previousSurveysEnabledValue;

@property (nonatomic, strong) NSMutableArray *queuedLaunchReportDates;
@property (nonatomic, strong) NSDictionary *multiskillMapping;
@property (nonatomic, strong) NSMutableArray *pendingEvents;
@property (nonatomic, strong) NSMutableDictionary *sessionExtras;

@property (nonatomic, assign) BOOL customButtonChatAvailable;
@property (nonatomic, assign) BOOL customButtonInvitationShown;

@end

@implementation LIOVisit

- (id)init
{
    self = [super init];
    if (self) {
        self.funnelState = LIOFunnelStateInitialized;
        LIOLog(@"<FUNNEL STATE> Initialized");
        
        self.visitState = LIOVisitStateInitialized;
        LIOLog(@"<VISIT STATE> Initiazlied");
        
        self.queuedLaunchReportDates = [[NSMutableArray alloc] init];
        self.multiskillMapping = nil;
        self.pendingEvents = [[NSMutableArray alloc] init];
        
        self.customButtonChatAvailable = NO;
        self.customButtonInvitationShown = NO;
        
        self.funnelRequestQueue = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark Status Dictionary Methods

- (NSDictionary *)statusDictionaryIncludingExtras:(BOOL)includeExtras includingType:(BOOL)includesType  includingEvents:(BOOL)includeEvents
{
    NSMutableDictionary *statusDictionary = [[NSMutableDictionary alloc] init];

    // Basic Device and App Parameters
    [statusDictionary setObject:[LIOStatusManager deviceType] forKey:@"device_type"];
    [statusDictionary setObject:[LIOStatusManager bundleId] forKey:@"app_id"];
    [statusDictionary setObject:@"Apple iOS" forKey:@"platform"];
    [statusDictionary setObject:[LIOStatusManager systemVersion] forKey:@"platform_version"];
    [statusDictionary setObject:LOOKIO_VERSION_STRING forKey:@"sdk_version"];

    // Device UDIDs
    [statusDictionary setObject:[LIOStatusManager udid] forKey:@"device_id"];
    NSNumber *limitAdTracking = [LIOStatusManager limitAdTracking];
    if (limitAdTracking)
        [statusDictionary setObject:limitAdTracking forKey:@"limit_ad_tracking"];
    NSString *alternateUdid = [LIOStatusManager alternateUdid];
    if (alternateUdid)
        [statusDictionary setObject:alternateUdid forKey:@"alternate_device_id"];
    
    // Pending Events
    if (includeEvents && [self.pendingEvents count])
        [statusDictionary setObject:self.pendingEvents forKey:@"events"];
    
    // Current Visit Id
    if ([self.currentVisitId length])
        [statusDictionary setObject:self.currentVisitId forKey:@"visit_id"];
    
    // TODO Find out if should send visitor_id here?
    
    if (includesType)
        [statusDictionary setObject:@"intro" forKey:@"type"];
    
    if ([LIOStatusManager statusManager].badInitialization)
        [statusDictionary setObject:[NSNumber numberWithBool:YES] forKey:@"bad_init"];
    
    if ([self.requiredSkill length])
        [statusDictionary setObject:self.requiredSkill forKey:@"skill"];
     
    [statusDictionary setObject:[NSNumber numberWithBool:[LIOStatusManager statusManager].appForegrounded] forKey:@"app_foregrounded"];

    /* TODO localizationTableHash
     NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
     NSString *localizationTableHash = [userDefaults objectForKey:LIOBundleManagerStringTableHashKey];
     if ([localizationTableHash length])
     [introDict setObject:localizationTableHash forKey:@"strings_hash"];
     */
    
    NSString *localeId = [LIOStatusManager localeId];
    if ([localeId length])
        [statusDictionary setObject:localeId forKey:@"locale"];
     
    NSString *languageId = [LIOStatusManager languageId];
    if ([languageId length])
        [statusDictionary setObject:languageId forKey:@"language"];

    if (includeExtras)
    {
        // TODO Do we need this?
        [statusDictionary setObject:LIOLookIOManagerVersion forKey:@"version"];
        
        // Detect some stuff about the client.
        NSMutableDictionary *detectedDict = [NSMutableDictionary dictionary];
        
        NSString *carrierName = [[LIOAnalyticsManager sharedAnalyticsManager] cellularCarrierName];
        if ([carrierName length])
            [detectedDict setObject:carrierName forKey:@"carrier_name"];
        
        NSString *bundleVersion = [[LIOAnalyticsManager sharedAnalyticsManager] hostAppBundleVersion];
        if ([bundleVersion length])
            [detectedDict setObject:bundleVersion forKey:@"app_bundle_version"];
        
        if ([[LIOAnalyticsManager sharedAnalyticsManager] locationServicesEnabled])
            [detectedDict setObject:@"enabled" forKey:@"location_services"];
        else
            [detectedDict setObject:@"disabled" forKey:@"location_services"];
        
        if ([[LIOAnalyticsManager sharedAnalyticsManager] cellularNetworkInUse])
            [detectedDict setObject:@"cellular" forKey:@"connection_type"];
        else
            [detectedDict setObject:@"wifi" forKey:@"connection_type"];
        
        NSArray *twitterHandles = [[LIOAnalyticsManager sharedAnalyticsManager] twitterHandles];
        if ([twitterHandles count])
            [detectedDict setObject:twitterHandles forKey:@"twitter"];
        
        NSString *tzOffset = [[LIOAnalyticsManager sharedAnalyticsManager] timezoneOffset];
        if ([tzOffset length])
            [detectedDict setObject:tzOffset forKey:@"tz_offset"];
        
        BOOL jailbroken = [[LIOAnalyticsManager sharedAnalyticsManager] jailbroken];
        [detectedDict setObject:[NSNumber numberWithBool:jailbroken] forKey:@"jailbroken"];
        
        BOOL pushEnabled = [[LIOAnalyticsManager sharedAnalyticsManager] pushEnabled];
        [detectedDict setObject:[NSNumber numberWithBool:pushEnabled] forKey:@"push"];
        
        [detectedDict setObject:[[LIOAnalyticsManager sharedAnalyticsManager] distributionType] forKey:@"distribution_type"];
        
        if ([LIOStatusManager statusManager].lastKnownLocation)
        {
            NSNumber *lat = [NSNumber numberWithDouble:[LIOStatusManager statusManager].lastKnownLocation.coordinate.latitude];
            NSNumber *lon = [NSNumber numberWithDouble:[LIOStatusManager statusManager].lastKnownLocation.coordinate.longitude];
            NSDictionary *location = [NSDictionary dictionaryWithObjectsAndKeys:lat, @"latitude", lon, @"longitude", nil];
            [detectedDict setObject:location forKey:@"location"];
        }
        
        NSMutableDictionary *extrasDict = [NSMutableDictionary dictionary];
        if ([self.sessionExtras count])
            [extrasDict setDictionary:self.sessionExtras];
        
        if ([detectedDict count])
            [extrasDict setObject:detectedDict forKey:@"detected_settings"];
        
        if ([self.lastKnownPageViewValue length])
            [extrasDict setObject:self.lastKnownPageViewValue forKey:@"view_name"];
        
        if ([extrasDict count])
        {
            [statusDictionary setObject:extrasDict forKey:@"extras"];
            
            NSString *emailAddress = [extrasDict objectForKey:@"email_address"];
            if ([emailAddress length])
            {
                // TODO What is this pendingEmailAddress?
//                [pendingEmailAddress release];
//                pendingEmailAddress = [emailAddress retain];
            }
        }
    }

    return statusDictionary;
}

- (NSDictionary *)resloveSettingsPayload:(NSDictionary *)settingsDict fromContinue:(BOOL)fromContinue
{
    
    NSMutableDictionary *resolvedSettings = [NSMutableDictionary dictionary];
    
    NSDictionary *skillsDict = [settingsDict objectForKey:@"skills"];
    if (skillsDict)
    {
        // Are these settings coming from a launch call? If so, replace current skill mapping wholesale.
        if (NO == fromContinue)
        {
            [resolvedSettings setObject:skillsDict forKey:@"skills"];
        }
        
        // Merge existing skill map with the new one.
        else
        {
            NSMutableDictionary *newMap = [self.multiskillMapping mutableCopy];
            if (nil == newMap)
                newMap = [NSMutableDictionary dictionary];
            
            if ([skillsDict count])
            {
                // Check for a "default=1" value.
                NSString *newDefault = nil;
                for (NSString *aSkillKey in skillsDict)
                {
                    NSDictionary *aSkillMap = [skillsDict objectForKey:aSkillKey];
                    NSNumber *defaultValue = [aSkillMap objectForKey:@"default"];
                    if (YES == [defaultValue boolValue])
                    {
                        newDefault = aSkillKey;
                        break;
                    }
                }
                
                // Merge.
                [newMap addEntriesFromDictionary:skillsDict];
                
                // Reset default values as needed.
                if (newDefault)
                {
                    NSMutableDictionary *defaultReplacementDict = [NSMutableDictionary dictionary];
                    for (NSString *aSkillKey in newMap)
                    {
                        NSDictionary *existingMap = [newMap objectForKey:aSkillKey];
                        NSNumber *defaultValue = [existingMap objectForKey:@"default"];
                        if (defaultValue)
                        {
                            if (YES == [defaultValue boolValue] && NO == [newDefault isEqualToString:aSkillKey])
                            {
                                NSMutableDictionary *newDict = [existingMap mutableCopy];
                                [newDict setObject:[NSNumber numberWithBool:NO] forKey:@"default"];
                                [defaultReplacementDict setObject:newDict forKey:aSkillKey];
                            }
                            else if (NO == [defaultValue boolValue] && YES == [newDefault isEqualToString:aSkillKey])
                            {
                                NSMutableDictionary *newDict = [existingMap mutableCopy];
                                [newDict setObject:[NSNumber numberWithBool:YES] forKey:@"default"];
                                [defaultReplacementDict setObject:newDict forKey:aSkillKey];
                            }
                        }
                    }
                    
                    [newMap addEntriesFromDictionary:defaultReplacementDict];
                }
            }
            
            // If the new skill map is an empty hash {}, do not merge; erase all entries.
            else
            {
                [newMap removeAllObjects];
            }
            
            [resolvedSettings setObject:newMap forKey:@"skills"];
        }
    }
    
    NSNumber *buttonVisibility = [settingsDict objectForKey:@"button_visibility"];
    if (buttonVisibility)
        [resolvedSettings setObject:buttonVisibility forKey:@"button_visibility"];
    
    NSString *buttonText = [settingsDict objectForKey:@"button_text"];
    if ([buttonText length])
        [resolvedSettings setObject:buttonText forKey:@"button_text"];
    
    NSString *welcomeText = [settingsDict objectForKey:@"welcome_text"];
    if ([welcomeText length])
        [resolvedSettings setObject:welcomeText forKey:@"welcome_text"];
    
    NSString *buttonTint = [settingsDict objectForKey:@"button_tint"];
    if ([buttonTint length])
        [resolvedSettings setObject:buttonTint forKey:@"button_tint"];
    
    NSString *buttonTextColor = [settingsDict objectForKey:@"button_text_color"];
    if ([buttonTextColor length])
        [resolvedSettings setObject:buttonTextColor forKey:@"button_text_color"];
    
    NSString *visitIdString = [settingsDict objectForKey:@"visit_id"];
    if ([visitIdString length])
        [resolvedSettings setObject:visitIdString forKey:@"visit_id"];
    
    NSDictionary *localizedStrings = [settingsDict objectForKey:@"localized_strings"];
    if ([localizedStrings count])
        [resolvedSettings setObject:localizedStrings forKey:@"localized_strings"];
    
    NSString *visitURLString = [settingsDict objectForKey:@"visit_url"];
    if ([visitURLString length])
        [resolvedSettings setObject:visitURLString forKey:@"visit_url"];
    
    NSNumber *nextIntervalNumber = [settingsDict objectForKey:@"next_interval"];
    if (nextIntervalNumber)
        [resolvedSettings setObject:nextIntervalNumber forKey:@"next_interval"];
    
    NSNumber *surveysEnabledNumber = [settingsDict objectForKey:@"surveys_enabled"];
    if (surveysEnabledNumber)
        [resolvedSettings setObject:surveysEnabledNumber forKey:@"surveys_enabled"];    
    
    return resolvedSettings;
}

- (void)parseAndSaveSettingsPayload:(NSDictionary *)settingsDict fromContinue:(BOOL)fromContinue
{
    LIOLog(@"Got settings payload: %@", settingsDict);
    
    NSDictionary *resolvedSettings = nil;
    @try
    {
        resolvedSettings = [self resloveSettingsPayload:settingsDict fromContinue:fromContinue];
    }
    @catch (NSException *exception)
    {
        [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"Invalid settings payload received from the server! Exception: %@", exception];
        
        // Delete multiskill mapping. This should force
        // the lib to report "disabled" back to the host app.
        self.multiskillMapping = nil;
        [self.delegate visitSkillMappingDidChange:self];
    }
    
    // Save.
    if ([resolvedSettings count])
    {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        NSDictionary *skillsMap = [resolvedSettings objectForKey:@"skills"];
        if (skillsMap)
        {
            self.multiskillMapping = skillsMap;
            [userDefaults setObject:self.multiskillMapping forKey:LIOLookIOManagerMultiskillMappingKey];
        }
        
        [self.delegate chatEnabledDidUpdate:self];
        
        NSNumber *buttonVisibility = [resolvedSettings objectForKey:@"button_visibility"];
        if (buttonVisibility)
        {
            self.lastKnownButtonVisibility = buttonVisibility;
            [userDefaults setObject:self.lastKnownButtonVisibility forKey:LIOLookIOManagerLastKnownButtonVisibilityKey];
            
            if (self.disableControlButtonOverride) {
                self.previousControlButtonVisibilityValue = [self.lastKnownButtonVisibility boolValue];
                self.lastKnownButtonVisibility = [NSNumber numberWithBool:NO];
            }
            
        }
        
        NSString *buttonText = [resolvedSettings objectForKey:@"button_text"];
        if ([buttonText length])
        {
            self.lastKnownButtonText = buttonText;
            [userDefaults setObject:self.lastKnownButtonText forKey:LIOLookIOManagerLastKnownButtonTextKey];
        }
        
        NSString *welcomeText = [resolvedSettings objectForKey:@"welcome_text"];
        if ([welcomeText length])
        {
            self.lastKnownWelcomeText = welcomeText;
            [userDefaults setObject:self.lastKnownWelcomeText forKey:LIOLookIOManagerLastKnownWelcomeMessageKey];
        }
        
        NSString *buttonTint = [resolvedSettings objectForKey:@"button_tint"];
        if ([buttonTint length])
        {
            [userDefaults setObject:buttonTint forKey:LIOLookIOManagerLastKnownButtonTintColorKey];
            
            unsigned int colorValue;
            [[NSScanner scannerWithString:buttonTint] scanHexInt:&colorValue];
            UIColor *color = HEXCOLOR(colorValue);
            
            self.lastKnownButtonTintColor = buttonTint;
        }
        
        NSString *buttonTextColor = [resolvedSettings objectForKey:@"button_text_color"];
        if ([buttonTextColor length])
        {
            [userDefaults setObject:buttonTextColor forKey:LIOLookIOManagerLastKnownButtonTextColorKey];
            
            unsigned int colorValue;
            [[NSScanner scannerWithString:buttonTextColor] scanHexInt:&colorValue];
            UIColor *color = HEXCOLOR(colorValue);
            self.lastKnownButtonTextColor = buttonTextColor;
        }
        
        NSString *visitIdString = [resolvedSettings objectForKey:@"visit_id"];
        if ([visitIdString length])
        {
            self.currentVisitId = visitIdString;
        }
        
        NSDictionary *localizedStrings = [resolvedSettings objectForKey:@"localized_strings"];
        if ([localizedStrings count])
        {
            [userDefaults setObject:localizedStrings forKey:LIOBundleManagerStringTableDictKey];
            
            NSDictionary *strings = [localizedStrings objectForKey:@"strings"];
            NSString *newHash = [[LIOBundleManager sharedBundleManager] hashForLocalizedStringTable:strings];
            [userDefaults setObject:newHash forKey:LIOBundleManagerStringTableHashKey];
            
            LIOLog(@"Got a localized string table for locale \"%@\", hash: \"%@\"", [localizedStrings objectForKey:@"langauge"], newHash);
        }
        
        NSString* visitURLString = [resolvedSettings objectForKey:@"visit_url"];
        if ([visitURLString length])
        {
            self.lastKnownVisitURL = visitURLString;

            LPVisitAPIClient* visitAPIClient = [LPVisitAPIClient sharedClient];
            visitAPIClient.baseURL = [NSURL URLWithString:self.lastKnownVisitURL];
        }
        
        NSNumber *nextIntervalNumber = [resolvedSettings objectForKey:@"next_interval"];
        if (nextIntervalNumber)
        {
            self.nextTimeInterval = [nextIntervalNumber doubleValue];
            
            [self.continuationTimer stopTimer];
            self.continuationTimer = nil;
            self.continuationTimer = [[LIOTimerProxy alloc] initWithTimeInterval:self.nextTimeInterval
                                                                     target:self
                                                                   selector:@selector(continuationTimerDidFire)];
        }
        
        NSNumber *surveysEnabled = [resolvedSettings objectForKey:@"surveys_enabled"];
        if (surveysEnabled)
        {
            [userDefaults setObject:surveysEnabled forKey:LIOLookIOManagerLastKnownSurveysEnabled];
            self.lastKnownSurveysEnabled = [surveysEnabled boolValue];
        }
        
        if (self.disableSurveysOverride) {
            self.previousSurveysEnabledValue = self.lastKnownSurveysEnabled;
            self.lastKnownSurveysEnabled = NO;
        }
        
        [self.delegate controlButtonVisibilityDidChange:self];
        [self.delegate controlButtonCharacteristsDidChange:self];
//      [self applicationDidChangeStatusBarOrientation:nil];
    }
}

#pragma mark Launch Visit Methods

- (void)launchVisit
{
    [[LIOAnalyticsManager sharedAnalyticsManager] pumpReachabilityStatus];
    if (LIOAnalyticsManagerReachabilityStatusConnected == [LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)
    {
        self.visitState = LIOVisitStateLaunching;
        LIOLog(@"<VISIT STATE> Launching");
        
        NSDictionary *statusDictionary = [self statusDictionaryIncludingExtras:YES includingType:NO includingEvents:NO];
        [[LPVisitAPIClient sharedClient] postPath:LIOLookIOManagerAppLaunchRequestURL parameters:statusDictionary success:^(LPHTTPRequestOperation *operation, id responseObject) {
            LIOLog(@"<LAUNCH> Request successful with response: %@", responseObject);
 
            NSDictionary *responseDict = (NSDictionary *)responseObject;
            [self parseAndSaveSettingsPayload:responseDict fromContinue:NO];
 
            self.funnelState = LIOFunnelStateVisit;
            LIOLog(@"<FUNNEL STATE> Visit");
            
            self.visitState = LIOVisitStateVisitInProgress;
            LIOLog(@"<VISIT STATE> In Progress");

        } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
            LIOLog(@"<LAUNCH> Request failed with response code %d and error: %d", operation.responseCode);

            if (404 == operation.responseCode)
            {
                [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"The server has reported that your app is not configured for use with LivePerson Mobile. Please contact mobile@liveperson.com for assistance."];
            }
            
            self.visitState = LIOVisitStateFailed;
            LIOLog(@"<VISIT STATE> Failed");
 
            self.multiskillMapping = nil;
            [self.delegate visitSkillMappingDidChange:self];
        }];
    }
    else
    {
        self.visitState = LIOVisitStateQueued;
        LIOLog(@"<VISIT STATE> Queued");
        
        [self.queuedLaunchReportDates addObject:[NSDate date]];
        self.multiskillMapping = nil;
        [self.delegate visitSkillMappingDidChange:self];
    }
}

#pragma mark Continue Methods

- (void)continuationTimerDidFire
{
    [self.continuationTimer stopTimer];
    self.continuationTimer = nil;

    if (0.0 == self.nextTimeInterval)
        self.nextTimeInterval = LIOLookIOManagerDefaultContinuationReportInterval;
    
    self.continuationTimer = [[LIOTimerProxy alloc] initWithTimeInterval:self.nextTimeInterval
                                                             target:self
                                                           selector:@selector(continuationTimerDidFire)];
    
    [self sendContinuationReport];
}

- (void)sendContinuationReport
{
    if (self.continueCallInProgress)
        return;
    
    if (0 == [self.lastKnownVisitURL length])
        return;
    
    self.continueCallInProgress = YES;
    
    NSDictionary *continueDict = [self statusDictionaryIncludingExtras:YES includingType:NO includingEvents:YES];
    
    [[LIOAnalyticsManager sharedAnalyticsManager] pumpReachabilityStatus];
    if (LIOAnalyticsManagerReachabilityStatusConnected == [LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)
    {
        [[LPVisitAPIClient sharedClient] postPath:LIOLookIOManagerAppContinueRequestURL parameters:continueDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
            self.continueCallInProgress = NO;
            self.failedContinueCount = 0;
            
            NSDictionary *responseDict = (NSDictionary *)responseObject;
            LIOLog(@"<CONTINUE> Success. HTTP code: %d. Response: %@", operation.responseCode, responseDict);
            
            [self parseAndSaveSettingsPayload:responseDict fromContinue:YES];
            
            // Continue call succeeded! Purge the event queue.
            [self.pendingEvents removeAllObjects];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:LIOLookIOManagerPendingEventsKey];
            
            [self updateAndReportFunnelState];
        } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
            self.continueCallInProgress = NO;
            
            LIOLog(@"<CONTINUE> Failed with response code: %d and error: %@", operation.responseCode, error);

            if (operation.responseCode == 404)
            {
                // New launch
                LIOLog(@"<CONTINUE> Failure. HTTP code: 404. The visit no longer exists. Starting a clean visit.");

                self.currentVisitId = nil;
                self.lastKnownVisitURL = nil;
                [self.continuationTimer stopTimer];
                self.continuationTimer = nil;
                
                [self launchVisit];
            }
            else
            {
                // Retry logic.
                
                if (self.failedContinueCount < LIOLookIOManagerMaxContinueFailures)
                {
                    self.failedContinueCount += 1;
                    LIOLog(@"<CONTINUE> Retry attempt %u of %u...", self.failedContinueCount, LIOLookIOManagerMaxContinueFailures);
                    
                    // The timer should automatically trigger the next continue call.
                }
                else
                {
                    LIOLog(@"<CONTINUE> Retries exhausted. Stopping future continue calls.");
                    
                    [self.continuationTimer stopTimer];
                    self.continuationTimer = nil;
                    
                    // TODO Check why the visitor id is here..
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:LIOLookIOManagerLastKnownVisitorIdKey];
                    self.lastKnownVisitURL = nil;
                    
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:LIOLookIOManagerMultiskillMappingKey];
                    self.multiskillMapping = nil;
                }
            }
            
            if ([self.pendingEvents count])
            {
                // Oh crap, the continue call failed!
                // Save all queued events to the user defaults store.
                [[NSUserDefaults standardUserDefaults] setObject:self.pendingEvents forKey:LIOLookIOManagerPendingEventsKey];
            }
        }];
    }
    
    [self updateAndReportFunnelState];
}

#pragma mark Chat Status Methods

- (BOOL)chatEnabled
{
    // nil or empty
    if (0 == [self.multiskillMapping count])
        return NO;
    
    // See if the current skill has a mapping.
    NSDictionary *aMap = [self.multiskillMapping objectForKey:self.requiredSkill];
    if ([aMap count])
    {
        NSNumber *enabledValue = [aMap objectForKey:@"enabled"];
        return [enabledValue boolValue];
    }
    
    // Nope. No current skill set. Try to find the default.
    if (0 == [self.requiredSkill length])
    {
        for (NSString *aSkillKey in self.multiskillMapping)
        {
            NSDictionary *aMap = [self.multiskillMapping objectForKey:aSkillKey];
            NSNumber *defaultValue = [aMap objectForKey:@"default"];
            if (defaultValue && YES == [defaultValue boolValue])
            {
                NSNumber *enabledValue = [aMap objectForKey:@"enabled"];
                return [enabledValue boolValue];
            }
        }
        
        // No default? o_O
    }
    
    // Oh well.
    return NO;
}

#pragma mark Custom Chat Button Methods

- (void)setChatAvailable
{
    self.customButtonChatAvailable = YES;
    [self updateAndReportFunnelState];
}

- (void)setChatUnavailable
{
    self.customButtonChatAvailable = NO;
    [self updateAndReportFunnelState];
}

- (void)setInvitationShown
{
    self.customButtonInvitationShown = YES;
    [self updateAndReportFunnelState];
}

- (void)setInvitationNotShown
{
    self.customButtonInvitationShown = NO;
    [self updateAndReportFunnelState];
}

#pragma mark Funnel Reporting Methods

- (void)updateAndReportFunnelState
{
    // For visit state, let's see if we can upgrade to hotlead
    if (self.funnelState == LIOFunnelStateVisit)
    {
        // If the tab visibility is not always, let's first check that the devloper has set the chat to available.
        // If not, it should stay a visit
        if (LIOButtonVisibilityAlways != [self.lastKnownButtonVisibility integerValue])
        {
            if (self.customButtonChatAvailable)
            {
                // If the tab visibility is not always, but chat is available, this is a hotlead
                self.funnelState = LIOFunnelStateHotlead;
                LIOLog(@"<FUNNEL STATE> Hotlead");
                [self sendFunnelPacketForState:self.funnelState];
            }
        }
        else
        {
            // Or, if the tab is supposed to be shown, whether or not it is actually shown, it's a hotlead
            self.funnelState = LIOFunnelStateHotlead;
            LIOLog(@"<FUNNEL STATE> Hotlead");
            [self sendFunnelPacketForState:self.funnelState];
        }
    }
    
    // If we're at the hot lead state, let's check if we can upgrade to invitation, or downgrade to visit
    if (self.funnelState == LIOFunnelStateHotlead)
    {
        // If the tab visibility is not always, let's first check that the developer has reported that the invitation has been shown
        // If not, it should stay a hotlead
        // If chat has been disabled, downgrade to a visit
        if (LIOButtonVisibilityAlways != [self.lastKnownButtonVisibility integerValue])
        {
            if (!self.customButtonChatAvailable)
            {
                self.funnelState = LIOFunnelStateVisit;
                LIOLog(@"<FUNNEL STATE> Visit");
                [self sendFunnelPacketForState:self.funnelState];
            }
            else
            {
                if (self.customButtonInvitationShown)
                {
                    self.funnelState = LIOFunnelStateInvitation;
                    LIOLog(@"<FUNNEL STATE> Invitation");
                    [self sendFunnelPacketForState:self.funnelState];
                }
            }
        }
        else
        {
            if (!self.controlButtonHidden)
            {
                self.funnelState = LIOFunnelStateInvitation;
                LIOLog(@"<FUNNEL STATE> Invitation");
                [self sendFunnelPacketForState:self.funnelState];
            }
        }
    }
    
    // If we're at the invitation state, let's make sure we can maintain it
    if (self.funnelState == LIOFunnelStateInvitation)
    {
        // If a chat started before invitation state was reached, it will be reported here.
        // We can return from the call because it is the topmost state
        if (self.introPacketWasSent)
        {
            self.funnelState = LIOFunnelStateClicked;
            LIOLog(@"<FUNNEL STATE> Clicked");
            [self sendFunnelPacketForState:self.funnelState];
            return;
        }
        
        // If the tab visibility is not always, let's check if the developer:
        // Set chat to unavailable, making it a visit
        // Set invitation to not shown, making it a hotlead
        if (LIOButtonVisibilityAlways != [self.lastKnownButtonVisibility intValue])
        {
            // If chat unavailable, it's a visit
            if (!self.customButtonChatAvailable)
            {
                self.funnelState = LIOFunnelStateVisit;
                LIOLog(@"<FUNNEL STATE> Visit");
                [self sendFunnelPacketForState:self.funnelState];
            }
            else
            {
                // If chat available, but invitation not shown, it's a hotlead
                // Otherwise, it stays an invitation
                if (!self.customButtonInvitationShown)
                {
                    self.funnelState = LIOFunnelStateHotlead;
                    LIOLog(@"<FUNNEL STATE> Hotlead");
                    [self sendFunnelPacketForState:self.funnelState];
                }
            }
        }
        else
        {
            // If tab availability is always, let's check if the tab is visible, otherwise downgrade to hotlead
            if (self.controlButtonHidden)
            {
                self.funnelState = LIOFunnelStateHotlead;
                LIOLog(@"<FUNNEL STATE> Hotlead");
                [self sendFunnelPacketForState:self.funnelState];
            }
        }
    }
    
    // If we're at the clicked lead state, and the chat has ended, let's downgrade it
    // We can return from each condition because there the final state is set here
    if (self.funnelState == LIOFunnelStateClicked)
    {
        if (!self.introPacketWasSent)
        {
            // Case one - Tab is not visible, and the button is not being displayed, downgrade to a visit
            if (LIOButtonVisibilityAlways != [self.lastKnownButtonVisibility intValue])
            {
                // If chat unavailable, it's a visit
                if (!self.customButtonChatAvailable)
                {
                    self.funnelState = LIOFunnelStateVisit;
                    LIOLog(@"<FUNNEL STATE> Visit");
                    [self sendFunnelPacketForState:self.funnelState];
                    return;
                }
                
                // If chat available, but invitation not shown, it's a hotlead
                if (!self.customButtonInvitationShown)
                {
                    self.funnelState = LIOFunnelStateHotlead;
                    LIOLog(@"<FUNNEL STATE> Hotlead");
                    [self sendFunnelPacketForState:self.funnelState];
                    return;
                }
                
                // Otherwise it's an invitation
                self.funnelState = LIOFunnelStateInvitation;
                LIOLog(@"<FUNNEL STATE> Invitation");
                [self sendFunnelPacketForState:self.funnelState];
                return;
                
            } else {
                // If tab is visible, it's an invitation, otherwise a hotlead
                if (!self.controlButtonHidden)
                {
                    self.funnelState = LIOFunnelStateInvitation;
                    LIOLog(@"<FUNNEL STATE> Invitation");
                }
                else
                {
                    self.funnelState = LIOFunnelStateHotlead;
                    LIOLog(@"<FUNNEL STATE> Hotlead");
                }
                
                [self sendFunnelPacketForState:self.funnelState];
                return;
            }
        }
    }
}

- (void)sendFunnelPacketForState:(LIOFunnelState)funnelState
{
    [[LIOAnalyticsManager sharedAnalyticsManager] pumpReachabilityStatus];
    
    // Let's check if we are in the middle of a request, or disconnected,
    // otherwise queue this request until network returns or a new state is updated
    
    if (self.funnelRequestIsActive || (LIOAnalyticsManagerReachabilityStatusConnected != [LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)) {
        NSNumber* nextFunnelRequest = [NSNumber numberWithInt:funnelState];
        [self.funnelRequestQueue addObject:nextFunnelRequest];
        return;
    }
    
    self.funnelRequestIsActive = YES;
    
    NSString *currentStateString = @"";
    
    switch (funnelState) {
        case LIOFunnelStateVisit:
            currentStateString = @"visit";
            break;
            
        case LIOFunnelStateHotlead:
            currentStateString = @"hotlead";
            break;
            
        case LIOFunnelStateInvitation:
            currentStateString = @"invitation";
            break;
            
        case LIOFunnelStateClicked:
            currentStateString = @"clicked";
            break;
            
        default:
            break;
    }
    
    // If not one these four value, nothing to report
    if ([currentStateString isEqualToString:@""])
        return;
    
    NSDictionary* buttonFunnelDict = [NSDictionary dictionaryWithObject:currentStateString forKey:@"current_state"];
    NSDictionary *funnelDict = [NSDictionary dictionaryWithObject:buttonFunnelDict forKey:@"button_funnel"];
    
    [[LPVisitAPIClient sharedClient] postPath:LIOLookIOManagerVisitFunnelRequestURL parameters:funnelDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
        if (responseObject)
            LIOLog(@"<FUNNEL> with data:%@ response: %@", funnelDict, responseObject);
        else
            LIOLog(@"<FUNNEL> with data:%@ success", funnelDict);
        
        self.funnelRequestIsActive = NO;
        if (self.funnelRequestQueue.count > 0) {
            NSNumber* nextFunnelState = [self.funnelRequestQueue objectAtIndex:0];
            [self sendFunnelPacketForState:[nextFunnelState intValue]];
            [self.funnelRequestQueue removeObjectAtIndex:0];
        }
    } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
        // TODO Rereport a failed funnel request?
        LIOLog(@"<FUNNEL> with data:%@ failure: %@", funnelDict, error);
        
        self.funnelRequestIsActive = NO;
        if (self.funnelRequestQueue.count > 0) {
            NSNumber* nextFunnelState = [self.funnelRequestQueue objectAtIndex:0];
            [self sendFunnelPacketForState:[nextFunnelState intValue]];
            [self.funnelRequestQueue removeObjectAtIndex:0];
        }
    }];
}

@end
