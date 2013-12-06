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

#import "LPVisitAPIClient.h"
#import "LIOStatusManager.h"
#import "LPVisitAPIClient.h"

#define LIOLookIOManagerVersion @"1.1.0"

@interface LIOVisit ()

@property (nonatomic, copy) NSString *currentVisitId;
@property (nonatomic, assign) LIOFunnelState funnelState;
@property (nonatomic, copy) NSString *requiredSkill;
@property (nonatomic, copy) NSString *lastKnownPageViewValue;

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

#pragma mark Launch Visit Methods

- (void)launchVisit
{
    [[LIOAnalyticsManager sharedAnalyticsManager] pumpReachabilityStatus];
    if (LIOAnalyticsManagerReachabilityStatusConnected == [LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)
    {
        NSDictionary *statusDictionary = [self statusDictionaryIncludingExtras:YES includingType:NO includingEvents:NO];
        [[LPVisitAPIClient sharedClient] postPath:LIOLookIOManagerAppLaunchRequestURL parameters:statusDictionary success:^(LPHTTPRequestOperation *operation, id responseObject) {
            LIOLog(@"<LAUNCH> Request successful with response: %@", responseObject);
        
        } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
            LIOLog(@"<LAUNCH> Request failed with error: %@", error);

        }];
    }
    else
    {
        [self.queuedLaunchReportDates addObject:[NSDate date]];
        self.multiskillMapping = nil;
        [self.delegate skillMappingDidChange:self];
    }
    
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
