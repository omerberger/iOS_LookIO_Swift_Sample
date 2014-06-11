//
//  LIOVisit.m
//  LookIO
//
//  Created by Yaron Karasik on 12/5/13.
//
//

#import "LIOVisit.h"

// Managers
#import "LIOLogManager.h"
#import "LIOAnalyticsManager.h"
#import "LIOBundleManager.h"
#import "LIOBrandingManager.h"
#import "LIOStatusManager.h"
#import "LIOLookIOManager.h"

// Networking
#import "LPVisitAPIClient.h"
#import "LPVisitAPIClient.h"
#import "LPHTTPRequestOperation.h"

// Helpers
#import "LIOTimerProxy.h"

// Apple Frameworks
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCallCenter.h>

#define LIOLookIOManagerVersion @"1.1.0"

#define LIOLookIOManagerDefaultContinuationReportInterval  60.0 // 1 minute
#define LIOLookIOManagerMaxContinueFailures                3
#define LIOLookIOMAnagerMaxEventQueueSize                  100

#define LIOVisitMaxRelaunches                              50
#define LIOVisitMaxRelaunchTimePeriod                      60

#define LIOPendingEventsTimerInterval                      2.0

// User defaults keys
#define LIOLookIOManagerLaunchReportQueueKey            @"LIOLookIOManagerLaunchReportQueueKey"
#define LIOLookIOManagerVisitorIdKey                    @"LIOLookIOManagerVisitorIdKey"

#define LIOVisitUnknownAccountName                      @"LIOVisitUnknownAccountName"

@interface LIOVisit ()

@property (nonatomic, copy) NSString *currentVisitId;
@property (nonatomic, copy) NSString *visitorId;

@property (nonatomic, copy) NSString *requiredSkill;
@property (nonatomic, copy) NSString *lastKnownPageViewValue;

@property (nonatomic, strong) NSMutableDictionary *lastReportedSettingsDictionary;
@property (nonatomic, strong) NSMutableDictionary *lastReportedEventsDictionary;

@property (nonatomic, assign) LIOFunnelState funnelState;
@property (nonatomic, assign) BOOL funnelRequestIsActive;
@property (nonatomic, strong) NSMutableArray *funnelRequestQueue;
@property (nonatomic, assign) NSInteger failedFunnelCount;

@property (nonatomic, assign) BOOL disableControlButtonOverride;
@property (nonatomic, assign) NSNumber *previousControlButtonVisibilityValue;

@property (nonatomic, copy) NSString *lastKnownWelcomeText;

@property (nonatomic, copy) NSString *lastKnownVisitURL;
@property (nonatomic, assign) NSTimeInterval nextTimeInterval;
@property (nonatomic, strong) LIOTimerProxy *continuationTimer;
@property (nonatomic, strong) LIOTimerProxy *pendingEventsTimer;
@property (nonatomic, assign) BOOL continueCallInProgress;
@property (nonatomic, assign) NSInteger failedContinueCount;

@property (nonatomic, assign) BOOL disableSurveysOverride;

@property (nonatomic, assign) BOOL overrideButtonType;
@property (nonatomic, strong) NSNumber *previousButtonType;

@property (nonatomic, assign) BOOL lastKnownHideEmailChat;

@property (nonatomic, strong) NSMutableArray *queuedLaunchReportDates;
@property (nonatomic, strong) NSDictionary *multiskillMapping;
@property (nonatomic, strong) NSMutableArray *pendingEvents;
@property (nonatomic, strong) NSMutableDictionary *visitUDEs;

@property (nonatomic, assign) BOOL customButtonChatAvailable;
@property (nonatomic, assign) BOOL customButtonInvitationShown;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (nonatomic, strong) CTCallCenter *callCenter;
@property (nonatomic, strong) NSDate *callConnectionTime;
@property (nonatomic, assign) BOOL didReportFirstCall;
@property (nonatomic, assign) BOOL isCurrentCallOutgoingAndFirst;
@property (nonatomic, copy) NSString *callVisitId;

@property (nonatomic, assign) BOOL lastKnownCreditCardMaskingEnabled;

@property (nonatomic, copy) NSString *lastKnownLoggingURL;
@property (nonatomic, assign) BOOL loggingEnabled;
@property (nonatomic, strong) NSTimer *loggingTimer;

// IAR
@property (nonatomic, assign) BOOL isIAREnabled;
@property (nonatomic, strong) NSMutableArray *accountSkills;
@property (nonatomic, assign) BOOL shouldNextContinueCallIncludeAllUDEs;

// Timer and counter used to backoff from visit relaunching loop
@property (nonatomic, assign) NSInteger relaunchCount;
@property (nonatomic, strong) NSTimer *relaunchCountTimer;

// To support the coldLead event
@property (nonatomic, assign) BOOL didReportInitialColdLead;

@end

@implementation LIOVisit

- (id)init
{
    self = [super init];
    if (self) {
        self.funnelState = LIOFunnelStateInitialized;
        self.failedFunnelCount = 0;
        
        self.visitState = LIOVisitStateInitialized;
        
        self.developerDisabledChat = NO;
        
        self.multiskillMapping = nil;
        self.visitUDEs = [[NSMutableDictionary alloc] init];

        self.customButtonChatAvailable = NO;
        self.customButtonInvitationShown = NO;
        
        self.controlButtonHidden = YES;
        
        self.funnelRequestQueue = [[NSMutableArray alloc] init];
        
        self.dateFormatter = [[NSDateFormatter alloc] init];
        self.dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
        self.dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        
        self.overrideButtonType = NO;
        self.disableSurveysOverride = NO;
        
        self.lastKnownCreditCardMaskingEnabled = NO;
        self.loggingEnabled = NO;
        
        self.isIAREnabled = YES;
        self.shouldNextContinueCallIncludeAllUDEs = NO;
        self.accountSkills = [NSMutableArray array];
        self.defaultAccountSkill = nil;
        self.requiredAccountSkill = nil;
        
        self.didReportInitialColdLead = NO;
        
        self.relaunchCount = 0;
        
        // Start monitoring analytics.
        [LIOAnalyticsManager sharedAnalyticsManager];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityDidChange:)
                                                     name:LIOAnalyticsManagerReachabilityDidChangeNotification
                                                   object:[LIOAnalyticsManager sharedAnalyticsManager]];
                
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        // Hash the existing langauge file to prepare for visit launching
        if (![userDefaults objectForKey:LIOBundleManagerStringTableHashKey])
        {
            LIOBundleManager *bundleManager = [LIOBundleManager sharedBundleManager];
            NSString *languageId = [[NSLocale preferredLanguages] objectAtIndex:0];
            NSDictionary *builtInTable = [bundleManager localizedStringTableForLanguage:languageId];
            if ([builtInTable count])
            {
                
                NSDictionary *localizedStrings = [NSDictionary dictionaryWithObject:builtInTable forKey:@"strings"];
                [userDefaults setObject:localizedStrings forKey:LIOBundleManagerStringTableDictKey];
                
                NSString *newHash = [bundleManager hashForLocalizedStringTable:builtInTable];
                [userDefaults setObject:newHash forKey:LIOBundleManagerStringTableHashKey];
                
                LIOLog(@"Hashing the bundled localization table (\"%@\") succeeded: %@", languageId, newHash);
            }
            else
            {
                LIOLog(@"Couldn't hash the bundled localization table (\"%@\"). Table might not exist for that language.", languageId);
            }
        }
        
        // Hash the existing branding file to prepare for visit launching
        if (![userDefaults objectForKey:LIOBrandingManagerBrandingDictHashKey])
        {
            NSString *brandingMd5 = [[LIOBundleManager sharedBundleManager] hashForLocalBrandingFile];
            [userDefaults setObject:brandingMd5 forKey:LIOBrandingManagerBrandingDictHashKey];
        }
        
        // Set up the pending events queue
        self.pendingEvents = [[NSMutableArray alloc] init];
        self.lastReportedEventsDictionary = [[NSMutableDictionary alloc] init];
        
        // Set up the queued launch report queue
        self.queuedLaunchReportDates = [[userDefaults objectForKey:LIOLookIOManagerLaunchReportQueueKey] mutableCopy];
        if (nil == self.queuedLaunchReportDates)
            self.queuedLaunchReportDates = [[NSMutableArray alloc] init];
        
        // Set up the visitor id, if it exists
        if ([userDefaults objectForKey:LIOLookIOManagerVisitorIdKey])
            self.visitorId = [userDefaults objectForKey:LIOLookIOManagerVisitorIdKey];
        else
            self.visitorId = nil;
        
        // Default visibility is no - until recieving a different visibility setting
        self.lastKnownButtonVisibility = [[NSNumber alloc] initWithBool:NO];
        
        self.relaunchCountTimer = [NSTimer scheduledTimerWithTimeInterval:LIOVisitMaxRelaunchTimePeriod target:self selector:@selector(visitMaxRelaunchTimerDidFire:) userInfo:nil repeats:YES];
        
        // Setup the call center object to monitor phone calls
        [self setupCallCenter];
    }
    return self;
}

- (void)disableControlButton
{
    if (self.disableControlButtonOverride)
        return;
    
    self.disableControlButtonOverride = YES;
    self.previousControlButtonVisibilityValue = self.lastKnownButtonVisibility;
    self.lastKnownButtonVisibility = [NSNumber numberWithInteger:0];
    
    [self refreshControlButtonVisibility];
}

- (void)undisableControlButton {
    if (!self.disableControlButtonOverride)
        return;
    
    self.disableControlButtonOverride = NO;
    self.lastKnownButtonVisibility = self.previousControlButtonVisibilityValue;
    
    [self refreshControlButtonVisibility];
}

- (void)disableSurveys {
    self.disableSurveysOverride = YES;
}

- (void)undisableSurveys {
    self.disableSurveysOverride = NO;
}

- (BOOL)surveysDisabled
{
    return self.disableSurveysOverride;
}

- (void)useIconButton
{
    if (!self.overrideButtonType)
    {
        self.overrideButtonType = YES;
        self.previousButtonType = self.lastKnownButtonType;
    }
    
    self.lastKnownButtonType = [NSNumber numberWithInteger:1];
}

- (void)useTextButton
{
    if (!self.overrideButtonType)
    {
        self.overrideButtonType = YES;
        self.previousButtonType = self.lastKnownButtonType;
    }

    self.lastKnownButtonType = [NSNumber numberWithInteger:0];
}

- (void)useDefaultButton
{
    self.overrideButtonType = NO;
    self.lastKnownButtonType = self.previousButtonType;
    self.previousButtonType = nil;
}

#pragma mark -
#pragma mark Status Dictionary Methods

- (NSDictionary *)statusDictionaryIncludingExtras:(BOOL)includeExtras includingType:(BOOL)includesType  includingEvents:(BOOL)includeEvents resendAllUDEs:(BOOL)resendAllUDEs
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
    
    // Pending Events
    if (resendAllUDEs)
    {
        NSArray *lastReportedEvents = [self.lastReportedEventsDictionary allValues];
        if ([lastReportedEvents count])
        {
            [statusDictionary setObject:lastReportedEvents forKey:@"events"];
        }
    }
    else
    {
        if (includeEvents && [self.pendingEvents count])
            [statusDictionary setObject:self.pendingEvents forKey:@"events"];
    }
    
    // Current Visit Id
    if ([self.currentVisitId length])
    {
        [statusDictionary setObject:self.currentVisitId forKey:@"visit_id"];
    }
    
    // Send visitor ID, if we have it. Otherwise request it.
    if ([self.visitorId length])
    {
        [statusDictionary setObject:self.visitorId forKey:@"visitor_id"];
    }
    else
    {
        [statusDictionary setObject:[NSNumber numberWithBool:YES] forKey:@"request_visitor_id"];
    }
    
    if (includesType)
        [statusDictionary setObject:@"intro" forKey:@"type"];
    
    if ([LIOStatusManager statusManager].badInitialization)
        [statusDictionary setObject:[NSNumber numberWithBool:YES] forKey:@"bad_init"];

    if (self.isIAREnabled)
    {
        if (self.requiredAccountSkill)
        {
            [statusDictionary setObject:self.requiredAccountSkill.skill forKey:@"skill"];
            if (![self.requiredAccountSkill.account isEqualToString:LIOVisitUnknownAccountName])
                [statusDictionary setObject:self.requiredAccountSkill.account forKey:@"site_id"];
        }
    }
    else
    {
        if ([self.requiredSkill length])
            [statusDictionary setObject:self.requiredSkill forKey:@"skill"];
    }
    
    
    [statusDictionary setObject:[NSNumber numberWithBool:[LIOStatusManager statusManager].appForegrounded] forKey:@"app_foregrounded"];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *localizationTableHash = [userDefaults objectForKey:LIOBundleManagerStringTableHashKey];
    if ([localizationTableHash length])
        [statusDictionary setObject:localizationTableHash forKey:@"strings_hash"];
    
    NSString* brandingDictHash = [userDefaults objectForKey:LIOBrandingManagerBrandingDictHashKey];
    if (brandingDictHash)
        [statusDictionary setObject:brandingDictHash forKey:@"branding_md5"];
    
    NSString *localeId = [LIOStatusManager localeId];
    if ([localeId length])
        [statusDictionary setObject:localeId forKey:@"locale"];
    
    NSString *languageId = [LIOStatusManager languageId];
    if ([languageId length])
        [statusDictionary setObject:languageId forKey:@"language"];

    if (includeExtras)
    {
        // TODO: Do we need this?
        [statusDictionary setObject:LIOLookIOManagerVersion forKey:@"version"];
        
        // Detect some stuff about the client.
        if (self.lastReportedSettingsDictionary == nil)
            self.lastReportedSettingsDictionary = [NSMutableDictionary dictionary];
        
        NSMutableDictionary *detectedDict = [NSMutableDictionary dictionary];
        
        NSString *carrierName = [[LIOAnalyticsManager sharedAnalyticsManager] cellularCarrierName];
        if ([carrierName length])
        {
            // Let's check if this has already been reported
            NSString *reportedCarrierName = [self.lastReportedSettingsDictionary objectForKey:@"carrier_name"];
            if (![reportedCarrierName isEqualToString:carrierName])
            {
                [detectedDict setObject:carrierName forKey:@"carrier_name"];
                [self.lastReportedSettingsDictionary setObject:carrierName forKey:@"carrier_name"];
            }
        }
        
        NSString *bundleVersion = [[LIOAnalyticsManager sharedAnalyticsManager] hostAppBundleVersion];
        if ([bundleVersion length])
        {
            NSString *reportedBundleVersion = [self.lastReportedSettingsDictionary objectForKey:@"app_bundle_version"];
            if (![reportedBundleVersion isEqualToString:reportedBundleVersion])
            {
                [detectedDict setObject:bundleVersion forKey:@"app_bundle_version"];
                [self.lastReportedSettingsDictionary setObject:bundleVersion forKey:@"app_bundle_version"];
            }
        }
        
        NSString *locationServicesEnabled = [[LIOAnalyticsManager sharedAnalyticsManager] locationServicesEnabled] ? @"enabled" : @"disabled";
        NSString *reportedLocationServicesEnabled = [self.lastReportedSettingsDictionary objectForKey:@"location_services"];
        if (![reportedLocationServicesEnabled isEqualToString:locationServicesEnabled])
        {
            [detectedDict setObject:locationServicesEnabled forKey:@"location_services"];
            [self.lastReportedSettingsDictionary setObject:locationServicesEnabled forKey:@"location_services"];
        }

        NSString *connectionType = [[LIOAnalyticsManager sharedAnalyticsManager] cellularNetworkInUse] ? @"cellular" : @"wifi";
        NSString *reportedConnectionType = [self.lastReportedSettingsDictionary objectForKey:@"connection_type"];
        if (![reportedConnectionType isEqualToString:connectionType])
        {
            [detectedDict setObject:connectionType forKey:@"connection_type"];
            [self.lastReportedSettingsDictionary setObject:connectionType forKey:@"connection_type"];
        }
        
        NSArray *twitterHandles = [[LIOAnalyticsManager sharedAnalyticsManager] twitterHandles];
        if ([twitterHandles count])
        {
            NSArray *reportedTwitterHandles = [self.lastReportedSettingsDictionary objectForKey:@"twitter"];
            if (reportedTwitterHandles == nil)
            {
                [detectedDict setObject:twitterHandles forKey:@"twitter"];
                [self.lastReportedSettingsDictionary setObject:twitterHandles forKey:@"twitter"];
            }
            else
            {
                // Let's see if we have any new ones
                NSSet *currentSet = [NSSet setWithArray:twitterHandles];
                NSSet *reportedSet = [NSSet setWithArray:reportedTwitterHandles];
                if (![currentSet isEqualToSet:reportedSet])
                {
                    [detectedDict setObject:twitterHandles forKey:@"twitter"];
                    [self.lastReportedSettingsDictionary setObject:twitterHandles forKey:@"twitter"];
                }
            }
        }
        
        NSString *tzOffset = [[LIOAnalyticsManager sharedAnalyticsManager] timezoneOffset];
        if ([tzOffset length])
        {
            NSString *reportedTzOffset = [self.lastReportedSettingsDictionary objectForKey:@"tz_offset"];
            if (![reportedTzOffset isEqualToString:tzOffset])
            {
                [detectedDict setObject:tzOffset forKey:@"tz_offset"];
                [self.lastReportedSettingsDictionary setObject:tzOffset forKey:@"tz_offset"];
            }
        }
        
        BOOL jailbroken = [[LIOAnalyticsManager sharedAnalyticsManager] jailbroken];
        NSNumber *reportedJailbroken = [self.lastReportedSettingsDictionary objectForKey:@"jailbroken"];
        if (reportedJailbroken == nil || reportedJailbroken.boolValue != jailbroken)
        {
            [detectedDict setObject:[NSNumber numberWithBool:jailbroken] forKey:@"jailbroken"];
            [self.lastReportedSettingsDictionary setObject:[NSNumber numberWithBool:jailbroken] forKey:@"jailbroken"];
        }
        
        BOOL pushEnabled = [[LIOAnalyticsManager sharedAnalyticsManager] pushEnabled];
        NSNumber *reportedPushEnabled = [self.lastReportedSettingsDictionary objectForKey:@"push"];
        if (reportedPushEnabled == nil || reportedPushEnabled.boolValue != pushEnabled)
        {
            [detectedDict setObject:[NSNumber numberWithBool:pushEnabled] forKey:@"push"];
            [self.lastReportedSettingsDictionary setObject:[NSNumber numberWithBool:pushEnabled] forKey:@"push"];
        }
        
        NSString *distributionType = [[LIOAnalyticsManager sharedAnalyticsManager] distributionType];
        NSString *reportedDistributionType = [self.lastReportedSettingsDictionary objectForKey:@"distribution_type"];
        if (![reportedDistributionType isEqualToString:distributionType])
        {
            [detectedDict setObject:distributionType forKey:@"distribution_type"];
            [self.lastReportedSettingsDictionary setObject:distributionType forKey:@"distribution_type"];
        }
        
        if ([LIOAnalyticsManager sharedAnalyticsManager].lastKnownLocation)
        {
            NSNumber *lat = [NSNumber numberWithDouble:[LIOAnalyticsManager sharedAnalyticsManager].lastKnownLocation.coordinate.latitude];
            NSNumber *lon = [NSNumber numberWithDouble:[LIOAnalyticsManager sharedAnalyticsManager].lastKnownLocation.coordinate.longitude];
            NSNumber *lastReportedLatitute = [self.lastReportedSettingsDictionary objectForKey:@"latitude"];
            NSNumber *lastReportedLongitude = [self.lastReportedSettingsDictionary objectForKey:@"longitude"];

            NSMutableDictionary *location = [NSMutableDictionary dictionary];
            if (lastReportedLatitute == nil || lastReportedLatitute.floatValue != lat.floatValue)
            {
                [location setObject:lat forKey:@"latitude"];
                [self.lastReportedSettingsDictionary setObject:lat forKey:@"latitude"];
            }
            if (lastReportedLongitude == nil || lastReportedLongitude.floatValue != lon.floatValue)
            {
                [location setObject:lon forKey:@"longitude"];
                [self.lastReportedSettingsDictionary setObject:lon forKey:@"longitude"];
            }
            
            if ([location count])
                [detectedDict setObject:location forKey:@"location"];
        }
        
        if (UIAccessibilityIsVoiceOverRunning())
        {
            NSNumber *reportedVoiceoverEnabled = [self.lastReportedSettingsDictionary objectForKey:@"voiceover_enabled"];
            if (reportedVoiceoverEnabled == nil || reportedVoiceoverEnabled.boolValue != YES)
            {
                [detectedDict setObject:[NSNumber numberWithBool:YES] forKey:@"voiceover_enabled"];
                [self.lastReportedSettingsDictionary setObject:[NSNumber numberWithBool:YES] forKey:@"voiceover_enabled"];
            }
        }
        else
        {
            NSNumber *reportedVoiceoverEnabled = [self.lastReportedSettingsDictionary objectForKey:@"voiceover_enabled"];
            if (reportedVoiceoverEnabled.boolValue == YES)
            {
                [detectedDict setObject:[NSNumber numberWithBool:NO] forKey:@"voiceover_enabled"];
                [self.lastReportedSettingsDictionary setObject:[NSNumber numberWithBool:NO] forKey:@"voiceover_enabled"];
            }
            
        }
        
        NSMutableDictionary *extrasDict = [NSMutableDictionary dictionary];
        if ([self.visitUDEs count])
            [extrasDict setDictionary:self.visitUDEs];
        
        // If we are resending all UDEs, we should report the last reported settings as it incldues everything.
        if (resendAllUDEs)
        {
            [extrasDict setObject:self.lastReportedSettingsDictionary forKey:@"detected_settings"];
        }
        else
        {
            if ([detectedDict count])
                [extrasDict setObject:detectedDict forKey:@"detected_settings"];
        }
        
        if ([self.lastKnownPageViewValue length])
            [extrasDict setObject:self.lastKnownPageViewValue forKey:@"view_name"];
        
        if ([extrasDict count])
        {
            [statusDictionary setObject:extrasDict forKey:@"extras"];
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
        id accountsObject = [skillsDict objectForKey:@"accounts"];
        // This is an IAR enabled account
        if (accountsObject)
        {
            NSArray *accountsArray = nil;
            if ([accountsObject isKindOfClass:[NSDictionary class]])
            {
                NSDictionary *singleAccountDictionary = (NSDictionary *)accountsObject;
                accountsArray = [NSArray arrayWithObject:singleAccountDictionary];
            }
            if ([accountsObject isKindOfClass:[NSArray class]])
            {
                accountsArray = (NSArray *)accountsObject;
            }
            
            NSMutableArray *accountSkills = [NSMutableArray array];

            for (NSDictionary *accountsDictionary in accountsArray)
            {
                for (NSString *accountName in accountsDictionary.allKeys)
                {
                    NSDictionary *skillDictionary = [accountsDictionary objectForKey:accountName];
                    for (NSString *skillName in skillDictionary)
                    {
                        NSDictionary *skillStatus = [skillDictionary objectForKey:skillName];
                        if (skillStatus == nil) continue;
                        
                        LIOAccountSkillStatus *accountSkillStatus = [[LIOAccountSkillStatus alloc] init];
                        accountSkillStatus.account = accountName;
                        accountSkillStatus.skill = skillName;
                        
                        NSNumber *defaultValue = [skillStatus objectForKey:@"default"];
                        if (defaultValue) accountSkillStatus.isDefault = [defaultValue boolValue];
                        
                        NSNumber *enabledValue = [skillStatus objectForKey:@"enabled"];
                        if (enabledValue) accountSkillStatus.isEnabledOnServer = [enabledValue boolValue];
                        
                        [accountSkills addObject:accountSkillStatus];
                    }
                }
            }

            NSDictionary *skillsDict = [NSDictionary dictionaryWithObject:accountSkills forKey:@"accounts"];
            [resolvedSettings setObject:skillsDict forKey:@"skills"];
        }
        else
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
    }
    
    NSDictionary *buttonDictionary = [settingsDict objectForKey:@"button"];
    if (buttonDictionary)
    {
        NSMutableDictionary *resolvedButtonDictionary = [[NSMutableDictionary alloc] init];
        
        NSNumber *buttonType = [buttonDictionary objectForKey:@"button_type"];
        if (buttonType)
            [resolvedButtonDictionary setObject:buttonType forKey:@"button_type"];
        
        NSNumber *popupChat = [buttonDictionary objectForKey:@"popup_chat"];
        if (popupChat)
            [resolvedButtonDictionary setObject:popupChat forKey:@"popup_chat"];
        
        if (resolvedButtonDictionary.allKeys.count > 0)
            [resolvedSettings setObject:resolvedButtonDictionary forKey:@"button"];
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
    
    NSString *visitorIdString = [settingsDict objectForKey:@"visitor_id"];
    if ([visitorIdString length])
        [resolvedSettings setObject:visitorIdString forKey:@"visitor_id"];
    
    NSDictionary *localizedStrings = [settingsDict objectForKey:@"localized_strings"];
    if ([localizedStrings count])
        [resolvedSettings setObject:localizedStrings forKey:@"localized_strings"];
    
    NSString *visitURLString = [settingsDict objectForKey:@"visit_url"];
    if ([visitURLString length])
        [resolvedSettings setObject:visitURLString forKey:@"visit_url"];
    
    NSNumber *nextIntervalNumber = [settingsDict objectForKey:@"next_interval"];
    if (nextIntervalNumber)
        [resolvedSettings setObject:nextIntervalNumber forKey:@"next_interval"];
    
    NSNumber *hideEmailChatNumber = [settingsDict objectForKey:@"hide_email_chat"];
    if (hideEmailChatNumber)
        [resolvedSettings setObject:hideEmailChatNumber forKey:@"hide_email_chat"];
    
    NSDictionary *brandingDictionary = [settingsDict objectForKey:@"branding"];
    if (brandingDictionary)
        [resolvedSettings setObject:brandingDictionary forKey:@"branding"];
        
    NSString *brandingMd5String = [settingsDict objectForKey:@"branding_md5"];
    if (brandingMd5String)
        [resolvedSettings setObject:brandingMd5String forKey:@"branding_md5"];
    
    NSString *loggingUrl = [settingsDict objectForKey:@"logging_url"];
    if (loggingUrl)
        [resolvedSettings setObject:loggingUrl forKey:@"logging_url"];
    
    NSNumber *creditCardMaskingEnabledNumber = [settingsDict objectForKey:@"mask_cc"];
    if (creditCardMaskingEnabledNumber)
        [resolvedSettings setObject:creditCardMaskingEnabledNumber forKey:@"mask_cc"];
    
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
        if (self.isIAREnabled)
            [self removeAllIARAccountSkills];
        [self refreshControlButtonVisibility];
        
        if (!self.chatInProgress)
            self.visitState = LIOVisitStateFailed;
    }
    
    // Save.
    if ([resolvedSettings count])
    {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        NSDictionary *skillsMap = [resolvedSettings objectForKey:@"skills"];
        if (skillsMap)
        {
            // If an accounts array exists, use IAR
            NSArray *accountSkillMap = [skillsMap objectForKey:@"accounts"];
            if (accountSkillMap)
            {
                // Main another array of existing account-skills, so we can delete any account-skill that has been deleted since
                NSMutableArray *accountSkillsToDelete = [[NSMutableArray alloc] initWithArray:self.accountSkills];
                
                self.isIAREnabled = YES;
                for (LIOAccountSkillStatus *newAccountSkill in accountSkillMap)
                {
                    // Check if this account-skill pair exists
                    NSPredicate *accountSkillPredicate = [NSPredicate predicateWithFormat:@"account = %@ AND skill = %@", newAccountSkill.account, newAccountSkill.skill];
                    NSArray *predicateArray = [self.accountSkills filteredArrayUsingPredicate:accountSkillPredicate];

                    // If exists
                    if (predicateArray.count > 0)
                    {
                        LIOAccountSkillStatus *existingAccountSkill = [predicateArray objectAtIndex:0];
                        
                        // No need to delete this account-skill
                        [accountSkillsToDelete removeObject:existingAccountSkill];

                        // This will take into consideration if a chat is in progress or if developer disabled chat
                        BOOL previousEnabledValue = existingAccountSkill.isEnabledLastReported;

                        existingAccountSkill.isDefault = newAccountSkill.isDefault;
                        existingAccountSkill.isEnabledOnServer = newAccountSkill.isEnabledOnServer;

                        // This will take into consideration if a chat is in progress or if developer disabled chat
                        BOOL newEnabledValue = [self isChatEnabledForSkill:existingAccountSkill.skill forAccount:existingAccountSkill.account];
                        
                        // If changed, update the delegate
                        if (previousEnabledValue != newEnabledValue)
                        {
                            existingAccountSkill.isEnabledLastReported = newEnabledValue;
                            [self.delegate visit:self didChangeEnabled:newEnabledValue forSkill:newAccountSkill.skill forAccount:newAccountSkill.account];
                        }
                        
                        if (existingAccountSkill.isDefault)
                            self.defaultAccountSkill = existingAccountSkill;
                    }
                    else
                    {
                        [self.accountSkills addObject:newAccountSkill];
                        newAccountSkill.isEnabledLastReported = [self isChatEnabledForSkill:newAccountSkill.skill forAccount:newAccountSkill.account];
                        [self.delegate visit:self didChangeEnabled:newAccountSkill.isEnabledLastReported forSkill:newAccountSkill.skill forAccount:newAccountSkill.account];
                        
                        if (newAccountSkill.isDefault)
                            self.defaultAccountSkill = newAccountSkill;
                    }
                }
                
                if (accountSkillsToDelete.count > 0)
                {
                    // Don't delete a skill set by the developer, but set it to disabled if it was enabled
                    if (self.requiredAccountSkill)
                    {
                        if ([accountSkillsToDelete containsObject:self.requiredAccountSkill])
                        {
                            self.requiredAccountSkill.isEnabledOnServer = NO;
                            if (self.requiredAccountSkill.isEnabledLastReported == YES)
                                [self.delegate visit:self didChangeEnabled:NO forSkill:self.requiredAccountSkill.skill forAccount:self.requiredAccountSkill.account];
                            [accountSkillsToDelete removeObject:self.requiredAccountSkill];
                        }
                    }
                    
                    for (LIOAccountSkillStatus *accountSkill in accountSkillsToDelete)
                    {
                        if (accountSkill.isEnabledLastReported == YES)
                            [self.delegate visit:self didChangeEnabled:NO forSkill:accountSkill.skill forAccount:accountSkill.account];
                    }
                    
                    [self.accountSkills removeObjectsInArray:accountSkillsToDelete];
                }
                
                // Check that this isn't a skill that developer set before first continue call arrived
                if (self.requiredAccountSkill && self.defaultAccountSkill)
                {
                    if ([self.requiredAccountSkill.account isEqualToString:LIOVisitUnknownAccountName])
                    {
                        self.requiredAccountSkill.account = self.defaultAccountSkill.account;
                            
                        // Check if this is duplicate to an existing skill, and if so, use the existing skill
                        NSPredicate *accountSkillPredicate = [NSPredicate predicateWithFormat:@"account = %@ AND skill = %@", self.requiredAccountSkill.account, self.requiredAccountSkill.skill];
                        NSArray *predicateArray = [self.accountSkills filteredArrayUsingPredicate:accountSkillPredicate];
                            
                        // If exists
                        if (predicateArray.count > 0)
                        {
                            LIOAccountSkillStatus *actualRequiredAccountSkill = [predicateArray objectAtIndex:0];
                            self.requiredAccountSkill = actualRequiredAccountSkill;
                        }
                    }
                }
            }
            else
            {
                self.isIAREnabled = NO;
                self.multiskillMapping = skillsMap;
            }
        }
        
        [self.delegate visitChatEnabledDidUpdate:self];
        
        NSNumber *buttonVisibility = [resolvedSettings objectForKey:@"button_visibility"];
        if (buttonVisibility)
        {
            self.lastKnownButtonVisibility = buttonVisibility;
            
            if (self.disableControlButtonOverride)
            {
                self.previousControlButtonVisibilityValue = self.lastKnownButtonVisibility;
                self.lastKnownButtonVisibility = [NSNumber numberWithBool:0];
            }
        }
        
        NSDictionary *buttonDictionary = [resolvedSettings objectForKey:@"button"];
        if (buttonDictionary)
        {
            NSNumber *buttonType = [buttonDictionary objectForKey:@"button_type"];
            if (buttonType)
            {
                self.lastKnownButtonType = buttonType;
            }
            
            NSNumber *popupChat = [buttonDictionary objectForKey:@"popup_chat"];
            if (popupChat)
            {
                self.lastKnownButtonPopupChat = [popupChat boolValue];
            }            
        }
        
        NSString *buttonText = [resolvedSettings objectForKey:@"button_text"];
        if ([buttonText length])
        {
            self.lastKnownButtonText = buttonText;
        }
        
        NSString *welcomeText = [resolvedSettings objectForKey:@"welcome_text"];
        if ([welcomeText length])
        {
            self.lastKnownWelcomeText = welcomeText;
        }
        
        NSString *buttonTint = [resolvedSettings objectForKey:@"button_tint"];
        if ([buttonTint length])
        {
            unsigned int colorValue;
            [[NSScanner scannerWithString:buttonTint] scanHexInt:&colorValue];
            self.lastKnownButtonTintColor = buttonTint;
        }
        
        NSString *buttonTextColor = [resolvedSettings objectForKey:@"button_text_color"];
        if ([buttonTextColor length])
        {
            unsigned int colorValue;
            [[NSScanner scannerWithString:buttonTextColor] scanHexInt:&colorValue];
            self.lastKnownButtonTextColor = buttonTextColor;
        }
        
        NSString *visitIdString = [resolvedSettings objectForKey:@"visit_id"];
        if ([visitIdString length])
        {
            self.currentVisitId = visitIdString;
        }
        
        NSString *visitorIdString = [resolvedSettings objectForKey:@"visitor_id"];
        if ([visitorIdString length])
        {
            self.visitorId = visitorIdString;
            [userDefaults setObject:visitorIdString forKey:LIOLookIOManagerVisitorIdKey];
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
            
            [self.pendingEventsTimer stopTimer];
            self.pendingEventsTimer = nil;
            
            if (self.visitState != LIOVisitStateEnding)
            {
                self.continuationTimer = [[LIOTimerProxy alloc] initWithTimeInterval:self.nextTimeInterval
                                                                              target:self
                                                                            selector:@selector(continuationTimerDidFire)];
                self.pendingEventsTimer = [[LIOTimerProxy alloc] initWithTimeInterval:LIOPendingEventsTimerInterval
                                                                               target:self
                                                                             selector:@selector(pendingEventsTimerDidFire)];
            }
        }
        
        NSNumber *hideEmailChat = [resolvedSettings objectForKey:@"hide_email_chat"];
        if (hideEmailChat)
        {
            self.lastKnownHideEmailChat = [hideEmailChat boolValue];
        }
        
        NSDictionary *brandingDictionary = [resolvedSettings objectForKey:@"branding"];
        if (brandingDictionary)
        {
            // Ignore empty branding dictionaries
            if ([brandingDictionary count])
            {
                [userDefaults setObject:brandingDictionary forKey:LIOBrandingManagerBrandingDictKey];
                [LIOBrandingManager brandingManager].lastKnownBrandingDictionary = brandingDictionary;
                [[LIOBrandingManager brandingManager] preloadCustomBrandingImages];
        
                NSString *brandingMd5 = [resolvedSettings objectForKey:@"branding_md5"];
                if (brandingMd5)
                {
                    [userDefaults setObject:brandingMd5 forKey:LIOBrandingManagerBrandingDictHashKey];
                }
            }
        }
        
        NSString* loggingURLString = [resolvedSettings objectForKey:@"logging_url"];
        if ([loggingURLString length])
        {
            // Logging should start either if this is the first logging_url received
            // of if it's different than the last logging url recieved
            if (self.lastKnownLoggingURL == nil || ![self.lastKnownLoggingURL isEqualToString:loggingURLString])
            {
                [self startLogUploadingWithURL:loggingURLString];
            }
        }
        
        NSNumber *creditCardMaskingEnabledNumber = [resolvedSettings objectForKey:@"mask_cc"];
        if (creditCardMaskingEnabledNumber)
        {
            self.lastKnownCreditCardMaskingEnabled = [creditCardMaskingEnabledNumber boolValue];
        }
        
        [userDefaults synchronize];
        [self refreshControlButtonVisibility];
        [self.delegate controlButtonCharacteristsDidChange:self];
    }
}

- (NSDictionary *)introDictionary
{
    NSDictionary *introDictionary = [self statusDictionaryIncludingExtras:YES includingType:YES includingEvents:YES resendAllUDEs:NO];
    
    return introDictionary;
}

#pragma mark -
#pragma mark Launch Visit Methods

// Launch a new visit because of a 404 response
// If chat is in progress, we need to maintain the previous visit state

- (void)visitMaxRelaunchTimerDidFire:(NSTimer *)timer
{
    self.relaunchCount = 0;
}

- (void)relaunchVisit
{
    self.relaunchCount += 1;
    if (self.relaunchCount > 50)
    {
        LIOLog(@"<VISIT> Attempted to relaunch more than %d times in %d seconds, stopping all future visits.", LIOVisitMaxRelaunches, LIOVisitMaxRelaunchTimePeriod);
        
        if (!self.chatInProgress)
            self.visitState = LIOVisitStateFailed;
        
        self.multiskillMapping = nil;
        if (self.isIAREnabled)
            [self removeAllIARAccountSkills];
        [self refreshControlButtonVisibility];

        return;
    }
    
    [self.delegate visitWillRelaunch:self];

    // If this is a relaunch during chat, don't change visit state
    if (!self.chatInProgress)
        self.visitState = LIOVisitStateInitialized;
    
    self.currentVisitId = nil;
    self.lastReportedSettingsDictionary = nil;

    [self.continuationTimer stopTimer];
    self.continuationTimer = nil;
    
    [self.pendingEventsTimer stopTimer];
    self.pendingEventsTimer = nil;

    if (self.isIAREnabled)
        [self removeAllIARAccountSkills];
    [self refreshControlButtonVisibility];
    [self.delegate visitChatEnabledDidUpdate:self];

    self.isIAREnabled = YES;
    self.didReportInitialColdLead = NO;
    
    [self setupCallCenter];
    
    [self launchVisit];
}

- (void)launchVisit
{
    [[LIOAnalyticsManager sharedAnalyticsManager] pumpReachabilityStatus];
    if (LIOAnalyticsManagerReachabilityStatusConnected == [LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)
    {
        // If this is a relaunch during chat, don't change visit state
        if (!self.chatInProgress)
            self.visitState = LIOVisitStateLaunching;
        
        NSDictionary *statusDictionary = [self statusDictionaryIncludingExtras:YES includingType:NO includingEvents:NO resendAllUDEs:NO];
        NSDictionary *headersDictionary = [NSDictionary dictionaryWithObject:@"account-skills" forKey:@"X-LivepersonMobile-Capabilities"];
        [[LPVisitAPIClient sharedClient] postPath:LIOLookIOManagerAppLaunchRequestURL parameters:statusDictionary headers:headersDictionary success:^(LPHTTPRequestOperation *operation, id responseObject) {
            LIOLog(@"<LAUNCH> Request successful with response: %@", responseObject);
            
            [self.delegate visitReportDidLaunch:self];
 
            NSDictionary *responseDict = (NSDictionary *)responseObject;
            [self parseAndSaveSettingsPayload:responseDict fromContinue:NO];
 
            // If this is a relaunch during chat, don't change visit state
            if (!self.chatInProgress)
            {
                self.visitState = LIOVisitStateVisitInProgress;
            }
            
            self.funnelState = LIOFunnelStateVisit;
            LIOLog(@"<FUNNEL STATE> Visit");
            
            [self updateAndReportFunnelState];
            [self.delegate visitDidLaunch:self];
            
            if (![self chatInProgress])
            {
                [self.delegate visit:self wantsToShowMessage:LIOLocalizedString(@"LIOControlButtonView.ChatInvitePopupMessage")];
            }
        } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
            LIOLog(@"<LAUNCH> Request failed with response code %d and error: %d", operation.responseCode);

            if (404 == operation.responseCode)
            {
                [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"The server has reported that your app is not configured for use with LivePerson Mobile. Please contact mobile@liveperson.com for assistance."];
            }
            
            if (!self.chatInProgress)
                self.visitState = LIOVisitStateFailed;
 
            self.multiskillMapping = nil;
            [self.delegate visitSkillMappingDidChange:self];
            
            if (self.isIAREnabled)
                [self removeAllIARAccountSkills];
            [self refreshControlButtonVisibility];
        }];
    }
    else
    {
        self.visitState = LIOVisitStateQueued;
        
        [self.queuedLaunchReportDates addObject:[NSDate date]];
        [[NSUserDefaults standardUserDefaults] setObject:self.queuedLaunchReportDates forKey:LIOLookIOManagerLaunchReportQueueKey];
        
        // Delete multiskill mapping. This should force
        // the lib to report "disabled" back to the host app.
        self.multiskillMapping = nil;
        [self.delegate visitSkillMappingDidChange:self];
        
        if (self.isIAREnabled)
            [self removeAllIARAccountSkills];
        [self refreshControlButtonVisibility];
    }
}

- (void)stopVisit
{
    self.visitState = LIOVisitStateEnding;
    
    [self refreshControlButtonVisibility];
    
    [self.continuationTimer stopTimer];
    self.continuationTimer = nil;
    
    [self.pendingEventsTimer stopTimer];
    self.pendingEventsTimer = nil;
}

#pragma mark -
#pragma mark Reachability Methods

- (void)reachabilityDidChange:(NSNotification *)notification
{
    // Update button and enabled status
    [self refreshControlButtonVisibility];
    [self.delegate visitChatEnabledDidUpdate:self];
    [self updateEnabledForAllAccountsAndSkills];
    [self.delegate visitReachabilityDidChange:self];

    switch ([LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)
    {
        case LIOAnalyticsManagerReachabilityStatusConnected:
            if (LIOVisitStateQueued == self.visitState)
            {
                [self launchVisit];
            }
            
            // Send any funnel requests that were queued while disconnected
            [self handleFunnelQueueIfNeeded];
            
            break;
            
        default:
            break;
    }
}

#pragma mark -
#pragma mark Continue Methods

- (void)continuationTimerDidFire
{
    [self.continuationTimer stopTimer];
    self.continuationTimer = nil;
    
    if (0.0 == self.nextTimeInterval)
        self.nextTimeInterval = LIOLookIOManagerDefaultContinuationReportInterval;
    
    // Don't create a new timer if the visit state is ending
    if (self.visitState != LIOVisitStateEnding)
    {
        self.continuationTimer = [[LIOTimerProxy alloc] initWithTimeInterval:self.nextTimeInterval
                                                             target:self
                                                           selector:@selector(continuationTimerDidFire)];
        [self sendContinuationReport];
    }
}

- (void)pendingEventsTimerDidFire
{
    if (self.pendingEvents.count > 0)
        [self sendContinuationReport];
}

// Used as a response to "send_udes" packet which is used in IAR to send all previous UDEs to an IAR chat
- (void)sendContinuationReportAndResendAllUDEs
{
    self.shouldNextContinueCallIncludeAllUDEs = YES;
    [self sendContinuationReport];
}

- (void)sendContinuationReport
{
    if (self.continueCallInProgress)
        return;
    
    if (0 == [self.lastKnownVisitURL length])
        return;
    
    self.continueCallInProgress = YES;
    
    BOOL continueCallIncludesResendAllUDEs = self.shouldNextContinueCallIncludeAllUDEs;
    
    NSDictionary *continueDict = [self statusDictionaryIncludingExtras:YES includingType:NO includingEvents:YES resendAllUDEs:continueCallIncludesResendAllUDEs];
    NSArray *reportedEvents = [NSArray arrayWithArray:self.pendingEvents];
    NSDictionary *headersDictionary = [NSDictionary dictionaryWithObject:@"account-skills" forKey:@"X-LivepersonMobile-Capabilities"];

    NSString *currentVisitId = [NSString stringWithFormat:@"%@", self.currentVisitId];
    [[LIOAnalyticsManager sharedAnalyticsManager] pumpReachabilityStatus];
    if (LIOAnalyticsManagerReachabilityStatusConnected == [LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)
    {
        [[LPVisitAPIClient sharedClient] postPath:LIOLookIOManagerAppContinueRequestURL parameters:continueDict headers:headersDictionary success:^(LPHTTPRequestOperation *operation, id responseObject) {
            
            if (continueCallIncludesResendAllUDEs)
                self.shouldNextContinueCallIncludeAllUDEs = NO;

            self.continueCallInProgress = NO;
            self.failedContinueCount = 0;
                        
            NSDictionary *responseDict = (NSDictionary *)responseObject;
            LIOLog(@"<CONTINUE> Success. HTTP code: %d. Response: %@", operation.responseCode, responseDict);
            
            [self parseAndSaveSettingsPayload:responseDict fromContinue:YES];
            
            // Continue call succeeded! Purge the event queue.
            [self.pendingEvents removeObjectsInArray:reportedEvents];
            
            [self updateAndReportFunnelState];
            
            if (![self chatInProgress])
            {
                [self.delegate visit:self wantsToShowMessage:LIOLocalizedString(@"LIOControlButtonView.ChatInvitePopupMessage")];
            }
            
        } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
            self.continueCallInProgress = NO;
            
            LIOLog(@"<CONTINUE> Failed with response code: %d and error: %@", operation.responseCode, error);

            if (operation.responseCode == 404)
            {
                if (self.currentVisitId)
                {
                    if ([self.currentVisitId isEqualToString:currentVisitId])
                    {
                        LIOLog(@"<CONTINUE> Failure. HTTP code: 404. The visit no longer exists. Starting a clean visit.");

                        // New launch
                        [self relaunchVisit];
                    }
                    else
                    {
                        LIOLog(@"<CONTINUE> Failure. HTTP code: 404, but for a previous visit; Ignoring.");
                    }
                }
                else
                {
                    LIOLog(@"<CONTINUE> Failure. HTTP code: 404, but for a previous visit; Ignoring.");
                }
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
                    
                    [self.pendingEventsTimer stopTimer];
                    self.pendingEventsTimer = nil;
                    
                    self.lastKnownVisitURL = nil;
                    
                    self.multiskillMapping = nil;
                    if (self.isIAREnabled)
                        [self removeAllIARAccountSkills];
                    [self refreshControlButtonVisibility];

                    if (!self.chatInProgress)
                        self.visitState = LIOVisitStateFailed;
                }
            }
        }];
    }
}

- (void)refreshControlButtonVisibility
{
    if (self.visitState == LIOVisitStateEnding)
    {
        self.controlButtonHidden = YES;

        LIOLog(@"<<CONTROL>> Hiding. Reason: Visit ending.");
        [self.delegate visit:self controlButtonIsHiddenDidUpdate:self.controlButtonHidden notifyDelegate:NO];
        
        return;
    }
    
    // Trump card #0: If we have no visibility information, button is hidden.
    if (self.isIAREnabled)
    {
        if (nil == self.lastKnownButtonVisibility || self.accountSkills.count == 0)
        {
            self.controlButtonHidden = YES;
            LIOLog(@"<<CONTROL>> Hiding. Reason: never got any visibility or enabled-status settings from the server.");
            [self.delegate visit:self controlButtonIsHiddenDidUpdate:self.controlButtonHidden notifyDelegate:NO];
            
            return;
        }
    }
    else
    {
        if (nil == self.lastKnownButtonVisibility || nil == self.multiskillMapping)
        {
            self.controlButtonHidden = YES;
            LIOLog(@"<<CONTROL>> Hiding. Reason: never got any visibility or enabled-status settings from the server.");
            [self.delegate visit:self controlButtonIsHiddenDidUpdate:self.controlButtonHidden notifyDelegate:NO];
            
            return;
        }
    }
    
    // Trump card #1: Not in a session, and not "enabled" from server-side settings.

    if (!self.chatEnabled && !self.chatInProgress)
    {
        self.controlButtonHidden = YES;
        LIOLog(@"<<CONTROL>> Hiding. Reason: [self enabled] == NO.");
        [self.delegate visit:self controlButtonIsHiddenDidUpdate:self.controlButtonHidden notifyDelegate:YES];
        return;
    }
    
    BOOL willHide = NO, willShow = NO;
    NSString *aReason;
    
    if (self.lastKnownButtonVisibility)
    {
        NSInteger buttonVisibilityValue = [self.lastKnownButtonVisibility integerValue];
        if (LIOButtonVisibilityNever == buttonVisibilityValue) // Never
        {
            // Want to hide.
            willHide = NO == self.controlButtonHidden;
            aReason = @"lastKnownButtonVisibility == 0 (never)";
        }
        else if (LIOButtonVisibilityAlways == buttonVisibilityValue) // Always
        {
            // Want to show.
            willShow = self.controlButtonHidden;
            aReason = @"lastKnownButtonVisibility == 1 (always)";
        }
        else if (LIOButtonVisibilityInSession == buttonVisibilityValue) // In session
        {
            if (self.visitState == LIOVisitStateChatActive || self.visitState == LIOVisitStatePreChatSurvey || self.visitState == LIOVisitStateChatStarted)
            {
                // Want to show.
                willShow = self.controlButtonHidden;
                aReason = @"lastKnownButtonVisibility == 3 (in-session only) && (LIOVisitStateChatInProgress)";
            }
            else
            {
                // Want to hide.
                willHide = NO == self.controlButtonHidden;
                aReason = @"lastKnownButtonVisibility == 3 (in-session only)";
            }
        }
    }
    else
    {
        willShow = self.controlButtonHidden;
        aReason = @"no visibility setting";
    }
    
    if (willHide)
    {
        LIOLog(@"<<CONTROL>> Hiding. Reason: %@", aReason);
        
        self.controlButtonHidden = YES;
        [self.delegate visit:self controlButtonIsHiddenDidUpdate:self.controlButtonHidden notifyDelegate:YES];
        
    }
    else if (willShow)
    {
        LIOLog(@"<<CONTROL>> Showing. Reason: %@", aReason);
        
        self.controlButtonHidden = NO;
        [self.delegate visit:self controlButtonIsHiddenDidUpdate:self.controlButtonHidden notifyDelegate:YES];
    }
}

#pragma mark -
#pragma mark Visit Status Methods

- (BOOL)hideEmailChat
{
    return self.lastKnownHideEmailChat;
}

- (BOOL)maskCreditCards
{
    return self.lastKnownCreditCardMaskingEnabled;
}

- (void)setVisitState:(LIOVisitState)visitState
{
    _visitState = visitState;
    
    NSArray *stateNames = @[@"Initialized", @"Failed", @"Queued", @"Launching", @"VisitInProgress", @"ChatRequested", @"ChatOpened", @"PreChatSurvey",  @"ChatStarted", @"OfflineSurvey", @"ChatActive", @"PostChatSurvey", @"Ending"];
    
    LIOLog(@"<VISIT STATE> %@", [stateNames objectAtIndex:self.visitState]);
}

- (void)setSkill:(NSString *)skill
{
    if (self.isIAREnabled)
    {
        if (skill == nil)
        {
            self.requiredAccountSkill = nil;
        }
        else
        {
            // Since only a skill has been specified, we will use the default account here
            if (self.defaultAccountSkill)
            {
                NSString *defaultAccount = self.defaultAccountSkill.account;
                NSPredicate *accountSkillPredicate = [NSPredicate predicateWithFormat:@"account = %@ AND skill = %@", defaultAccount, skill];
                NSArray *predicateArray = [self.accountSkills filteredArrayUsingPredicate:accountSkillPredicate];
                
                // If this skill exists for the default account, let's set it as the required account-skill
                if (predicateArray.count > 0)
                {
                    LIOAccountSkillStatus *accountSkillStatus = [predicateArray objectAtIndex:0];
                    self.requiredAccountSkill = accountSkillStatus;
                }
                // If not, let's create it
                else
                {
                    LIOAccountSkillStatus *newAccountSkillStatus = [[LIOAccountSkillStatus alloc] init];
                    newAccountSkillStatus.skill = skill;
                    newAccountSkillStatus.account = defaultAccount;
                    newAccountSkillStatus.isEnabledOnServer = NO;
                    newAccountSkillStatus.isEnabledLastReported = NO;
                    newAccountSkillStatus.isDefault = NO;
                    
                    self.requiredAccountSkill = newAccountSkillStatus;
                    [self.accountSkills addObject:newAccountSkillStatus];
                }
            }
            // If there is no default, we haven't received it from server yet. Let's use a general key for that account name and update it later.
            else
            {
                LIOAccountSkillStatus *newAccountSkillStatus = [[LIOAccountSkillStatus alloc] init];
                newAccountSkillStatus.skill = skill;
                newAccountSkillStatus.account = LIOVisitUnknownAccountName;
                newAccountSkillStatus.isEnabledOnServer = NO;
                newAccountSkillStatus.isEnabledLastReported = NO;
                newAccountSkillStatus.isDefault = NO;
                
                // This one is not added to AccountSkills because it's only relevant as a required account skill
                self.requiredAccountSkill = newAccountSkillStatus;
            }
        }
    }
    else
    {
        self.requiredSkill = skill;
    }
    
    [self sendContinuationReport];
    [self refreshControlButtonVisibility];
    
    [self.delegate visitChatEnabledDidUpdate:self];
}

- (void)setSkill:(NSString *)skill withAccount:(NSString *)account
{
    if (self.isIAREnabled) {
        if (skill == nil || account == nil)
        {
            self.requiredAccountSkill = nil;
        }
        else
        {
            // Let's check if this skill was received from the server
            NSPredicate *accountSkillPredicate = [NSPredicate predicateWithFormat:@"account = %@ AND skill = %@", account, skill];
            NSArray *predicateArray = [self.accountSkills filteredArrayUsingPredicate:accountSkillPredicate];
            
            // If exists
            if (predicateArray.count > 0)
            {
                LIOAccountSkillStatus *accountSkillStatus = [predicateArray objectAtIndex:0];
                self.requiredAccountSkill = accountSkillStatus;
            }
            else
            {
                LIOAccountSkillStatus *accountSkillStatus = [[LIOAccountSkillStatus alloc] init];
                accountSkillStatus.skill = skill;
                accountSkillStatus.account = account;
                accountSkillStatus.isDefault = NO;
                accountSkillStatus.isEnabledOnServer = NO;
                accountSkillStatus.isEnabledLastReported = NO;
                
                [self.accountSkills addObject:accountSkillStatus];
                self.requiredAccountSkill = accountSkillStatus;
            }
        }
    }
    else {
        self.requiredSkill = skill;
    }
    
    [self sendContinuationReport];
    [self refreshControlButtonVisibility];
    [self.delegate visitChatEnabledDidUpdate:self];
}

#pragma mark -
#pragma mark Chat Status Methods

- (void)removeAllIARAccountSkills
{
    // There is no more default account-skill
    self.defaultAccountSkill = nil;

    // Disable all account skills, and report their new status
    for (LIOAccountSkillStatus *accountSkillStatus in self.accountSkills)
    {
        accountSkillStatus.isEnabledOnServer = NO;
    }
    [self updateEnabledForAllAccountsAndSkills];

    // Remove all skills, except the one set as required, which
    NSMutableArray *accountSkillsToRemove = [NSMutableArray arrayWithArray:self.accountSkills];
    if (self.requiredAccountSkill)
    {
        if ([accountSkillsToRemove containsObject:self.requiredAccountSkill])
        {
            [accountSkillsToRemove removeObject:self.requiredAccountSkill];
        }
    }
    [self.accountSkills removeObjectsInArray:accountSkillsToRemove];
}

- (void)updateEnabledForAllAccountsAndSkills
{
    for (LIOAccountSkillStatus *accountSkillStatus in self.accountSkills)
    {
        BOOL previousEnabledValue = accountSkillStatus.isEnabledLastReported;
        accountSkillStatus.isEnabledLastReported = [self isChatEnabledForSkill:accountSkillStatus.skill forAccount:accountSkillStatus.account];
        if (previousEnabledValue != accountSkillStatus.isEnabledLastReported)
            [self.delegate visit:self didChangeEnabled:accountSkillStatus.isEnabledLastReported forSkill:accountSkillStatus.skill forAccount:accountSkillStatus.account];
    }
}

- (BOOL)chatEnabled
{
    // If no network, chat is not enabled
    [[LIOAnalyticsManager sharedAnalyticsManager] pumpReachabilityStatus];
    if (LIOAnalyticsManagerReachabilityStatusDisconnected == [LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)
        return NO;
    
    // If chat is in progress, chat should always be enabled
    if (self.chatInProgress)
        return YES;
    
    // If developer explictly disabled chat, chat should be disabled
    if (self.developerDisabledChat)
        return NO;
    
    // IAR skill structure
    if (self.isIAREnabled)
    {
        // If no account-skills, return NO
        if (self.accountSkills.count == 0)
            return NO;
        
        // If developer has set a required skill/account, return its status
        if (self.requiredAccountSkill)
        {
            return self.requiredAccountSkill.isEnabledOnServer;
        }
        
        // If not, use the default skill
        if (self.defaultAccountSkill)
        {
            return self.defaultAccountSkill.isEnabledOnServer;
        }
        
        // If no skill-account set and no default, return NO
        return NO;
    }
    // Classic skill structure
    else
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
    
    return NO;
}

- (BOOL)isChatEnabledForSkill:(NSString *)skill
{
    // If no network, chat is not enabled
    [[LIOAnalyticsManager sharedAnalyticsManager] pumpReachabilityStatus];
    if (LIOAnalyticsManagerReachabilityStatusDisconnected == [LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)
        return NO;
    
    // If chat is in progress, chat should always be enabled
    if (self.chatInProgress)
        return YES;
    
    // If developer explictly disabled chat, chat should be disabled
    if (self.developerDisabledChat)
        return NO;
    
    if (self.isIAREnabled)
    {
        
        // If a default account exists, look for this skill within this account, and use that value.
        if (self.defaultAccountSkill)
        {
            NSString *defaultAccount = self.defaultAccountSkill.account;
            NSPredicate *accountSkillPredicate = [NSPredicate predicateWithFormat:@"account = %@ AND skill = %@", defaultAccount, skill];
            NSArray *accountSkillArray = [self.accountSkills filteredArrayUsingPredicate:accountSkillPredicate];
            if (accountSkillArray.count > 0)
            {
                LIOAccountSkillStatus *accountSkill = [accountSkillArray objectAtIndex:0];
                return accountSkill.isEnabledOnServer;
            }
            
            return NO;
        }
        
        return NO;
    } else {
        // nil or empty
        if (0 == [self.multiskillMapping count])
            return NO;
        
        // See if the selected skill has a mapping.
        NSDictionary *aMap = [self.multiskillMapping objectForKey:skill];
        if ([aMap count])
        {
            NSNumber *enabledValue = [aMap objectForKey:@"enabled"];
            return [enabledValue boolValue];
        }
        
        // Oh well.
        return NO;

    }
    
    return NO;    
}

- (BOOL)isChatEnabledForSkill:(NSString *)skill forAccount:(NSString *)account
{
    // If no network, chat is not enabled
    [[LIOAnalyticsManager sharedAnalyticsManager] pumpReachabilityStatus];
    if (LIOAnalyticsManagerReachabilityStatusDisconnected == [LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)
        return NO;
    
    // If chat is in progress, chat should be enabled for all skills in the account
    if (self.chatInProgress)
    {
        NSString *engagementSkill = [self.delegate visitCurrentEngagementSkill:self];
        NSString *engagementAccount = [self.delegate visitCurrentEngagementAccount:self];
        if (engagementAccount == nil || engagementSkill == nil) return YES;
        
        if ([engagementAccount isEqualToString:account] && [engagementSkill isEqualToString:skill])
            return YES;

        // Otherwise, let's pass through and return the actual enabled status    
    }
    
    // If developer explictly disabled chat, chat should be disabled
    if (self.developerDisabledChat)
        return NO;
    
    if (self.isIAREnabled)
    {
        NSPredicate *accountSkillPredicate = [NSPredicate predicateWithFormat:@"account = %@ AND skill = %@", account, skill];
        NSArray *accountSkillArray = [self.accountSkills filteredArrayUsingPredicate:accountSkillPredicate];
        if (accountSkillArray.count > 0)
        {
            LIOAccountSkillStatus *accountSkill = [accountSkillArray objectAtIndex:0];
            return accountSkill.isEnabledOnServer;
        }
        
        return NO;
    }
    
    // Without IAR, this isn't defined, because there is no account record to access
    return NO;
}

- (BOOL)chatInProgress
{
    switch (self.visitState)
    {
        case LIOVisitStateInitialized:
            return NO;
            break;
            
        case LIOVisitStateFailed:
            return NO;
            break;
            
        case LIOVisitStateQueued:
            return NO;
            break;
            
        case LIOVisitStateLaunching:
            return NO;
            break;
            
        case LIOVisitStateVisitInProgress:
            return NO;
            break;
            
        case LIOVisitStateChatRequested:
            return YES;
            break;

        case LIOVisitStateChatOpened:
            return YES;
            break;
            
        case LIOVisitStatePreChatSurvey:
            return YES;
            break;
            
        case LIOVisitStateChatStarted:
            return YES;
            break;
            
        case LIOVisitStateOfflineSurvey:
            return YES;
            break;
            
        case LIOVisitStateChatActive:
            return YES;
            break;
            
        case LIOVisitStatePostChatSurvey:
            return YES;
            break;
            
        case LIOVisitStateEnding:
            return NO;
            break;
            
        default:
            return NO;
            break;
    }
}

- (BOOL)visitActive
{
    switch (self.visitState)
    {
        case LIOVisitStateInitialized:
            return YES;
            break;
            
        case LIOVisitStateFailed:
            return NO;
            break;
            
        case LIOVisitStateQueued:
            return NO;
            break;
            
        case LIOVisitStateLaunching:
            return YES;
            break;
            
        case LIOVisitStateVisitInProgress:
            return YES;
            break;
            
        case LIOVisitStateChatRequested:
            return YES;
            break;
            
        case LIOVisitStateChatOpened:
            return YES;
            break;
            
        case LIOVisitStatePreChatSurvey:
            return YES;
            break;
            
        case LIOVisitStateChatStarted:
            return YES;
            break;
            
        case LIOVisitStateOfflineSurvey:
            return YES;
            break;
            
        case LIOVisitStateChatActive:
            return YES;
            break;
            
        case LIOVisitStatePostChatSurvey:
            return YES;
            break;
            
        case LIOVisitStateEnding:
            return YES;
            break;
            
        default:
            return NO;
            break;
    }
}

#pragma mark -
#pragma mark Custom Chat Button Methods

- (void)setChatAvailable
{
    BOOL previousValue = self.customButtonChatAvailable;
    self.customButtonChatAvailable = YES;
    
    if (previousValue == NO)
        [self updateAndReportFunnelState];
}

- (void)setChatUnavailable
{
    BOOL previousValue = self.customButtonChatAvailable;
    self.customButtonChatAvailable = NO;
    
    if (previousValue == YES)
        [self updateAndReportFunnelState];
}

- (void)setInvitationShown
{
    BOOL previousValue = self.customButtonInvitationShown;
    self.customButtonInvitationShown = YES;

    if (previousValue == NO)
        [self updateAndReportFunnelState];
}

- (void)setInvitationNotShown
{
    BOOL previousValue = self.customButtonInvitationShown;
    self.customButtonInvitationShown = NO;
    
    if (previousValue == YES)
        [self updateAndReportFunnelState];
}

#pragma mark -
#pragma mark Funnel Reporting Methods

- (void)updateAndReportFunnelState
{
    // Don't update and report funnel state if visit is not active. This will be called when a new visit is launched
    if (LIOVisitStateInitialized == self.visitState || LIOVisitStateLaunching == self.visitState || LIOVisitStateQueued == self.visitState || LIOVisitStateEnding == self.visitState || LIOVisitStateFailed == self.visitState)
    {
        return;
    }
    
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
                [self.delegate visit:self didChangeFunnelState:self.funnelState];
                
                self.didReportInitialColdLead = YES;
            }
        }
        else
        {
            // Or, if the tab is supposed to be shown, whether or not it is actually shown, it's a hotlead
            self.funnelState = LIOFunnelStateHotlead;
            LIOLog(@"<FUNNEL STATE> Hotlead");
            [self sendFunnelPacketForState:self.funnelState];
            [self.delegate visit:self didChangeFunnelState:self.funnelState];

            self.didReportInitialColdLead = YES;
        }
    }
    
    // If we haven't reported the initial coldLead yet, and we didn't just report a hotLead, we should report a coldLead
    if (!self.didReportInitialColdLead && LIOFunnelStateVisit == self.funnelState)
    {
        self.didReportInitialColdLead = YES;
        [self.delegate visit:self didChangeFunnelState:self.funnelState];
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
                [self.delegate visit:self didChangeFunnelState:self.funnelState];
            }
            else
            {
                if (self.customButtonInvitationShown)
                {
                    self.funnelState = LIOFunnelStateInvitation;
                    LIOLog(@"<FUNNEL STATE> Invitation");
                    [self sendFunnelPacketForState:self.funnelState];
                    [self.delegate visit:self didChangeFunnelState:self.funnelState];
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
                [self.delegate visit:self didChangeFunnelState:self.funnelState];
            }
        }
    }
    
    // If we're at the invitation state, let's make sure we can maintain it
    if (self.funnelState == LIOFunnelStateInvitation)
    {
        // If a chat started before invitation state was reached, it will be reported here.
        // We can return from the call because it is the topmost state
        if ([self chatInProgress])
        {
            self.funnelState = LIOFunnelStateClicked;
            LIOLog(@"<FUNNEL STATE> Clicked");
            [self sendFunnelPacketForState:self.funnelState];
            [self.delegate visit:self didChangeFunnelState:self.funnelState];
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
                [self.delegate visit:self didChangeFunnelState:self.funnelState];
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
                    [self.delegate visit:self didChangeFunnelState:self.funnelState];
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
                [self.delegate visit:self didChangeFunnelState:self.funnelState];
            }
        }
    }
    
    // If we're at the clicked lead state, and the chat has ended, let's downgrade it
    // We can return from each condition because there the final state is set here
    if (self.funnelState == LIOFunnelStateClicked)
    {
        if (![self chatInProgress])
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
                    [self.delegate visit:self didChangeFunnelState:self.funnelState];
                    return;
                }
                
                // If chat available, but invitation not shown, it's a hotlead
                if (!self.customButtonInvitationShown)
                {
                    self.funnelState = LIOFunnelStateHotlead;
                    LIOLog(@"<FUNNEL STATE> Hotlead");
                    [self sendFunnelPacketForState:self.funnelState];
                    [self.delegate visit:self didChangeFunnelState:self.funnelState];
                    return;
                }
                
                // Otherwise it's an invitation
                self.funnelState = LIOFunnelStateInvitation;
                LIOLog(@"<FUNNEL STATE> Invitation");
                [self sendFunnelPacketForState:self.funnelState];
                [self.delegate visit:self didChangeFunnelState:self.funnelState];
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
                [self.delegate visit:self didChangeFunnelState:self.funnelState];
                return;
            }
        }
    }
}

- (void)handleFunnelQueueIfNeeded
{
    if (self.funnelRequestQueue.count > 0) {
        NSNumber* nextFunnelState = [self.funnelRequestQueue objectAtIndex:0];
        [self.funnelRequestQueue removeObjectAtIndex:0];
        [self sendFunnelPacketForState:[nextFunnelState intValue]];
    }
}

- (void)sendFunnelPacketForState:(LIOFunnelState)funnelState
{
    [[LIOAnalyticsManager sharedAnalyticsManager] pumpReachabilityStatus];
    
    // Let's check if we are in the middle of a request, or disconnected, or the visit is not yet active
    // otherwise queue this request until network returns or a new state is updated
    
    if (self.funnelRequestIsActive || (LIOAnalyticsManagerReachabilityStatusConnected != [LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus || ![self visitActive])) {
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
    
    NSString *currentVisitId = [NSString stringWithFormat:@"%@", self.currentVisitId];
    NSDictionary* buttonFunnelDict = [NSDictionary dictionaryWithObject:currentStateString forKey:@"current_state"];
    NSDictionary *funnelDict = [NSDictionary dictionaryWithObject:buttonFunnelDict forKey:@"button_funnel"];
    
    [[LPVisitAPIClient sharedClient] postPath:LIOLookIOManagerVisitFunnelRequestURL parameters:funnelDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
        if (responseObject)
            LIOLog(@"<FUNNEL> with data:%@ response: %@", funnelDict, responseObject);
        else
            LIOLog(@"<FUNNEL> with data:%@ success", funnelDict);
        
        self.funnelRequestIsActive = NO;
        self.failedFunnelCount = 0;
        
        [self handleFunnelQueueIfNeeded];
    } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
        if (operation.responseCode == 404)
        {
            self.funnelRequestIsActive = NO;
            self.failedFunnelCount = 0;

            if (self.currentVisitId)
            {
                if ([self.currentVisitId isEqualToString:currentVisitId])
                {
                    LIOLog(@"<FUNNEL> Failure. HTTP code: 404. The visit no longer exists. Starting a clean visit.");
                    [self relaunchVisit];
                }
                else
                {
                    LIOLog(@"<CONTINUE> Failure. HTTP code: 404, but for a previous visit; Ignoring.");
                    [self handleFunnelQueueIfNeeded];
                }
            }
            else
            {
                LIOLog(@"<CONTINUE> Failure. HTTP code: 404, but for a previous visit; Ignoring.");
                [self handleFunnelQueueIfNeeded];
            }
        }
        else
        {
            LIOLog(@"<FUNNEL> with data:%@ failure: %@ code: %d", funnelDict, error, operation.responseCode);

            self.funnelRequestIsActive = NO;
            self.failedFunnelCount += 1;
            if (self.failedFunnelCount < 10)
            {
                NSNumber* failedFunnelRequest = [NSNumber numberWithInt:funnelState];
                [self.funnelRequestQueue insertObject:failedFunnelRequest atIndex:0];
            }
            else
            {
                self.failedFunnelCount = 0;
            }
        
            [self handleFunnelQueueIfNeeded];
        }
    }];
}

#pragma mark -
#pragma mark Access Methods to Visit Properties

- (NSString *)welcomeText
{
    NSString *welcomeText = @"";
    
    if (self.lastKnownWelcomeText)
        welcomeText = self.lastKnownWelcomeText;
    else
        welcomeText = LIOLocalizedString(@"LIOLookIOManager.DefaultWelcomeMessage");
    
    return welcomeText;
}

#pragma mark -
#pragma mark UDE Methods

- (void)setUDE:(id)anObject forKey:(NSString *)aKey
{
    if (anObject)
    {
        
        NSError *writeError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[NSArray arrayWithObject:anObject] options:nil error:&writeError];

        if (!writeError && jsonData)
        {
            [self.visitUDEs setObject:anObject forKey:aKey];
            [self sendContinuationReport];
        }
        else
            [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"Can't add object of class \"%@\" to session extras! Use simple classes like NSString, NSArray, NSDictionary, NSNumber, NSDate, etc.", NSStringFromClass([anObject class])];
    }
    else
    {
        [self.visitUDEs removeObjectForKey:aKey];
        [self sendContinuationReport];
    }
}

- (id)UDEForKey:(NSString *)aKey
{
    return [self.visitUDEs objectForKey:aKey];
}

- (void)addUDEs:(NSDictionary *)aDictionary
{
    // We only allow JSONable objects.
    NSError *writeError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:aDictionary options:nil error:&writeError];
    
    if (!writeError && jsonData)
    {
        [self.visitUDEs addEntriesFromDictionary:aDictionary];
        [self sendContinuationReport];
    }
    else
        [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"Can't add dictionary of objects to session extras! Use classes like NSString, NSArray, NSDictionary, NSNumber, NSDate, etc."];
}

- (void)clearUDEs
{
    [self.visitUDEs removeAllObjects];
    [self sendContinuationReport];
}

// FIXME: Handle case where continue call is in progress and this is called.
// Need an overflow hash.
- (void)reportEvent:(NSString *)anEvent withData:(id<NSObject>)someData
{
    id<NSObject> dataPayload = someData;
    if (nil == dataPayload)
        dataPayload = [NSNumber numberWithInt:1];
    
    NSMutableDictionary *newEvent = [NSMutableDictionary dictionary];
    [newEvent setObject:anEvent forKey:@"name"];
    [newEvent setObject:dataPayload forKey:@"data"];
    [newEvent setObject:[self.dateFormatter stringFromDate:[NSDate date]] forKey:@"timestamp"];
    
    [self.pendingEvents addObject:newEvent];
    [self.lastReportedEventsDictionary setObject:newEvent forKey:anEvent];
    
    // Queue is capped. Remove oldest entry on overflow.
    if ([self.pendingEvents count] > LIOLookIOMAnagerMaxEventQueueSize)
        [self.pendingEvents removeObjectAtIndex:0];
    
    // For PageView event, also record the last known page view
    if (YES == [anEvent isEqualToString:kLPEventPageView])
    {
        if ([someData isKindOfClass:[NSString class]])
        {
            // Okay, this IS a pageview event. Record it as the last known.
            self.lastKnownPageViewValue = (NSString *)someData;
        }
    }
}

#pragma mark Call Center Methods

- (void)setupCallCenter
{
    self.didReportFirstCall = NO;
    self.callConnectionTime = nil;
    self.isCurrentCallOutgoingAndFirst = NO;
    [self.visitUDEs removeObjectForKey:@"CALL_LP_STATE"];
    [self.visitUDEs removeObjectForKey:@"CALL_DURATION"];
    
    LIOVisit *currentVisit = self;
    
    self.callCenter = [[CTCallCenter alloc] init];
    self.callCenter.callEventHandler = ^(CTCall* call)
    {
        // If we've already reported call data for this visit, do nothing
        if (call.callState == CTCallStateIncoming)
        {
            currentVisit.isCurrentCallOutgoingAndFirst = NO;
            [currentVisit.delegate visitHasIncomingCall:currentVisit];
        
        }
        if (call.callState == CTCallStateDialing)
        {
            if (currentVisit.didReportFirstCall)
                return;

            currentVisit.isCurrentCallOutgoingAndFirst = YES;
            currentVisit.callVisitId = currentVisit.currentVisitId;
            
            // If the funnel state is clicked, we should check the engagement through the delegate to see if we are actually in funnel state 5 or 6
            LIOFunnelState callFunnelState = (LIOFunnelStateClicked == currentVisit.funnelState) ? [currentVisit.delegate visit:currentVisit engagementFunnelStateForFunnelState:LIOFunnelStateClicked] : currentVisit.funnelState;
            
            [currentVisit setUDE:[NSNumber numberWithInteger:callFunnelState] forKey:@"CALL_LP_STATE"];
            currentVisit.didReportFirstCall = YES;
            
            currentVisit.callConnectionTime = nil;
        }
        if (call.callState == CTCallStateConnected)
        {
            // We only want to monitor data if the current call is outgoing
            if (currentVisit.isCurrentCallOutgoingAndFirst)
            {
                currentVisit.callConnectionTime = [NSDate date];
            }
        }
        if (call.callState == CTCallStateDisconnected)
        {
            // We only want to monitor data if the current call is outgoing
            if (currentVisit.isCurrentCallOutgoingAndFirst)
            {
                // Calculate the call time, or report 0 if call was never connected
                NSInteger callTimeInSeconds = 0;
                if (currentVisit.callConnectionTime != nil)
                {
                    callTimeInSeconds = (NSInteger)(-[currentVisit.callConnectionTime timeIntervalSinceNow]);
                }
                
                // Make sure we the call time only if we're still at the same visit
                if ([currentVisit.currentVisitId isEqualToString:currentVisit.callVisitId])
                {
                    [currentVisit setUDE:[NSNumber numberWithInteger:callTimeInSeconds] forKey:@"CALL_DURATION"];

                    currentVisit.callConnectionTime = nil;
                    currentVisit.isCurrentCallOutgoingAndFirst = NO;
                }
            }
        }
    };
}

#pragma mark -
#pragma mark Logging Methods

- (void)startLogUploadingWithURL:(NSString *)loggingURLString
{
    self.loggingEnabled = YES;
    self.lastKnownLoggingURL = loggingURLString;
    [LIOLogManager sharedLogManager].lastKnownLoggingUrl = loggingURLString;
    self.loggingTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(loggingUploadTimerDidFire:) userInfo:nil repeats:YES];
    [[LIOLogManager sharedLogManager] uploadLogForVisit:self];
}

- (void)stopLogUploading
{
    self.loggingEnabled = NO;
    [self.loggingTimer invalidate];
    self.loggingTimer = nil;
}

- (void)loggingUploadTimerDidFire:(NSTimer *)timer
{
    [[LIOLogManager sharedLogManager] uploadLogForVisit:self];
}

@end