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
@property (nonatomic, assign) LIOFunnelState funnelState;
@property (nonatomic, copy) NSString *requiredSkill;
@property (nonatomic, copy) NSString *lastKnownPageViewValue;

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
        
        self.queuedLaunchReportDates = [[NSMutableArray alloc] init];
        self.multiskillMapping = nil;
        self.pendingEvents = [[NSMutableArray alloc] init];
        
        self.customButtonChatAvailable = NO;
        self.customButtonInvitationShown = NO;

    }
    return self;
}

//{"alternate_device_id":"928FA266-71CF-467B-88BF-AE28B128CFBC","device_type":"x86_64","locale":"en_US","app_id":"io.look.sample.yaron","limit_ad_tracking":false,"strings_hash":"93b814df622c7e4b95760b47d12be4ea","platform":"Apple iOS","skill":"mobile","sdk_version":"##UNKNOWN_VERSION##","device_id":"84E171F6-DCE0-4AA4-B28B-DE3F6BE69FAC","platform_version":"7.0.3","language":"he","app_foregrounded":true,"version":"1.1.0","extras":{"detected_settings":{"connection_type":"wifi","push":false,"jailbroken":false,"location_services":"enabled","distribution_type":"other","tz_offset":"-0500","app_bundle_version":"1.0"}}}//

//{"sdk_version":"##UNKNOWN_VERSION##","platform_version":"7.0.3","language":"he","version":"1.1.0","extras":{"detected_settings":{"connection_type":"wifi","push":false,"jailbroken":false,"location_services":"enabled","distribution_type":"other","tz_offset":"-0500","app_bundle_version":"1.0"}},"device_id":"D3B8DD7F-273A-4823-AFF0-44F17EF47897","device_type":"x86_64","platform":"Apple iOS","alternate_device_id":"4840B0D2-B303-47FC-AEAE-A7CE4A7C4D39","locale":"en_US","app_foregrounded":false} #ios #debug



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
        NSDictionary *statusDictionary = [self statusDictionaryIncludingExtras:YES includingType:NO includingEvents:NO];
        [[LPVisitAPIClient sharedClient] postPath:LIOLookIOManagerAppLaunchRequestURL parameters:statusDictionary success:^(LPHTTPRequestOperation *operation, id responseObject) {
            LIOLog(@"<LAUNCH> Request successful with response: %@", responseObject);
 
            NSDictionary *responseDict = (NSDictionary *)responseObject;
            [self parseAndSaveSettingsPayload:responseDict fromContinue:NO];
 
            LIOLog(@"<FUNNEL STATE> Visit");
            self.funnelState = LIOFunnelStateVisit;

        } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
            LIOLog(@"<LAUNCH> Request failed with response code %d and error: %d", operation.responseCode);

            if (404 == operation.responseCode)
            {
                [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"The server has reported that your app is not configured for use with LivePerson Mobile. Please contact mobile@liveperson.com for assistance."];
            }
 
            self.multiskillMapping = nil;
            [self.delegate visitSkillMappingDidChange:self];
        }];
    }
    else
    {
        [self.queuedLaunchReportDates addObject:[NSDate date]];
        self.multiskillMapping = nil;
        [self.delegate visitSkillMappingDidChange:self];
    }
}

#pragma mark Continue Methods

- (void)continuationTimerDidFire
{
    
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

}

@end
