//
//  LIOLookIOManager.m
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 LivePerson, Inc. All rights reserved.
//

#import "AsyncSocket.h"
#import <CommonCrypto/CommonDigest.h>
#import <QuartzCore/QuartzCore.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreLocation/CoreLocation.h>
#import <zlib.h>
#import <sys/socket.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <sys/sysctl.h>
#import <netinet/in.h>
#import "LIOLookIOManager.h"
#import "SBJSON.h"
#import "NSData+Base64.h"
#import "LIOAltChatViewController.h"
#import "LIOControlButtonView.h"
#import "LIOSquareControlButtonView.h"
#import "LIOAnalyticsManager.h"
#import "LIOChatMessage.h"
#import "LIOBundleManager.h"
#import "LIOInterstitialViewController.h"
#import "LIOLogManager.h"
#import "LIOTimerProxy.h"
#import "LIOSurveyManager.h"
#import "LIOSurveyTemplate.h"
#import "LIOSurveyQuestion.h"
#import "LIOPlugin.h"
#import "LIOMediaManager.h"

#import "LPSSEManager.h"
#import "LPChatAPIClient.h"
#import "LPVisitAPIClient.h"
#import "LPMediaAPIClient.h"
#import "LPSSEvent.h"
#import "LPHTTPRequestOperation.h"

#import <AdSupport/AdSupport.h>
#import "DRNRealTimeBlurView.h"
#import "LIOBlurImageView.h"
#import "LIODragToDeleteView.h"

#define HEXCOLOR(c) [UIColor colorWithRed:((c>>16)&0xFF)/255.0 \
                                    green:((c>>8)&0xFF)/255.0 \
                                     blue:((c)&0xFF)/255.0 \
                                    alpha:1.0]

// Misc. constants
#define LIOLookIOManagerVersion @"1.1.0"

#define LIOLookIOManagerScreenCaptureInterval       0.5
#define LIOLookIOManagerDefaultContinuationReportInterval  60.0 // 1 minute
#define LIOLookIOManagerMaxContinueFailures 3
#define LIOLookIOMAnagerMaxEventQueueSize   100

#define LIOLookIOManagerWriteTimeout            5.0

#define LIOLookIOManagerRealtimeExtrasTimeInterval 5.0
#define LIOLookIOManagerRealtimeExtrasLocationChangeThreshhold 0.0001 // Sort of like walking to a new room...?

#define LIOLookIOManagerReconnectionTimeLimit           120.0 // 2 minutes
#define LIOLookIOManagerReconnectionAfterCrashTimeLimit 60.0 // 1 minutes

#define LIOLookIOManagerDefaultControlEndpoint      @"dispatch.look.io"
#define LIOLookIOManagerDefaultControlEndpoint_Dev  @"dispatch.staging.look.io"
#define LIOLookIOManagerDefaultControlEndpoint_QA   @"dispatch.qa.look.io"
#define LIOLookIOManagerControlEndpointPort         8100
#define LIOLookIOManagerControlEndpointPortTLS      9000

#define LIOLookIOManagerAppLaunchRequestURL         @"api/v1/visit/launch"
#define LIOLookIOManagerAppContinueRequestURL       @"/continue"
#define LIOLookIOManagerVisitFunnelRequestURL       @"/funnel"
#define LIOLookIOManagerLogUploadRequestURL         @"api/v1/app/log"

#define LIOLookIOManagerChatIntroRequestURL         @"intro"
#define LIOLookIOManagerChatOutroRequestURL         @"outro"
#define LIOLookIOManagerChatLineRequestURL          @"line"
#define LIOLookIOManagerChatFeedbackRequestURL      @"feedback"
#define LIOLookIOManagerChatSurveyRequestURL        @"survey"
#define LIOLookIOManagerChatCapabilitiesRequestURL  @"capabilities"
#define LIOLookIOManagerChatHistoryRequestURL       @"chat_history"
#define LIOLookIOManagerChatAdvisoryRequestURL      @"advisory"
#define LIOLookIOManagerCustomVarsRequestURL        @"custom_vars"
#define LIOLookIOManagerChatPermissionRequestURL    @"permission"
#define LIOLookIOManagerChatScreenshotRequestURL    @"screenshot"
#define LIOLookIOManagerMediaUploadRequestURL       @"upload"

#define LIOLookIOManagerMessageSeparator        @"!look.io!"

#define LIOLookIOManagerDisconnectConfirmAlertViewTag       1
#define LIOLookIOManagerScreenshotPermissionAlertViewTag    2
#define LIOLookIOManagerDisconnectErrorAlertViewTag         3
#define LIOLookIOManagerNoAgentsOnlineAlertViewTag          4
#define LIOLookIOManagerUnprovisionedAlertViewTag           5
#define LIOLookIOManagerAgentEndedSessionAlertViewTag       6
#define LIOLookIOManagerReconnectionModeAlertViewTag        7
#define LIOLookIOManagerReconnectionCancelAlertViewTag      8
#define LIOLookIOManagerReconnectionSucceededAlertViewTag   9
#define LIOLookIOManagerReconnectionFailedAlertViewTag      10
#define LIOLookIOManagerDisconnectOutroAlertViewTag         11
#define LIOLookIOManagerSSEConnectionFailedAlertViewTag     12
#define LIOLookIOManagerDisconnectedByDeveloperAlertViewTag 13

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
#define LIOLookIOManagerLastKnownHideEmailChat          @"LIOLookIOManagerLastKnownHideEmailChat"

#define LIOLookIOManagerLastKnownEngagementIdKey        @"LIOLookIOManagerLastKnownEngagementIdKey"
#define LIOLookIOManagerLastKnownChatSSEUrlStringKey    @"LIOLookIOManagerLastKnownChatSSEUrlStringKey"
#define LIOLookIOManagerLastKnownChatPostUrlString      @"LIOLookIOManagerLastKnownChatPostUrlString"
#define LIOLookIOManagerLastKnownChatMediaUrlString     @"LIOLookIOManagerLastKnownChatMediaUrlString"
#define LIOLookIOManagerLastKnownChatLastEventIdString  @"LIOLookIOManagerLastKnownChatLastEventIdString"
#define LIOLookIOManagerLastKnownChatCookiesKey         @"LIOLookIOManagerLastKnownChatCookiesKey"
#define LIOLookIOManagerLastKnownChatHistoryKey         @"LIOLookIOManagerLastKnownChatHistoryKey"

#define LIOLookIOManagerControlButtonMinHeight 110.0
#define LIOLookIOManagerControlButtonMinWidth  35.0
#define LIOLookIOManagerSquareControlButtonSize 50.0;

// Event constants.
NSString *const kLPEventConversion  = @"LPEventConversion";
NSString *const kLPEventPageView    = @"LPEventPageView";
NSString *const kLPEventSignUp      = @"LPEventSignUp";
NSString *const kLPEventSignIn      = @"LPEventSignIn";
NSString *const kLPEventAddedToCart = @"LPEventAddedToCart";

typedef enum
{
    LIOFunnelStateInitialized = 0,
    LIOFunnelStateVisit,
    LIOFunnelStateHotlead,
    LIOFunnelStateInvitation,
    LIOFunnelStateClicked,
} LIOFunnelState;

typedef enum
{
    LIOServerProduction = 0,
    LIOServerStaging,
    LIOServerQA
} LIOServerMode;

@interface LIOLookIOManager ()
    <LIOControlButtonViewDelegate, LIOAltChatViewControllerDataSource, LIOAltChatViewControllerDelegate, LIOInterstitialViewControllerDelegate, AsyncSocketDelegate_LIO, LPSSEManagerDelegate, LIOSquareControlButtonViewDelegate>
{
    NSTimer *screenCaptureTimer;
    UIImage *touchImage;
    BOOL waitingForScreenshotAck, waitingForIntroAck, controlSocketConnecting, introduced, enqueued, resetAfterDisconnect, killConnectionAfterChatViewDismissal, resetAfterChatViewDismissal, sessionEnding, outroReceived, screenshotsAllowed, usesTLS, userWantsSessionTermination, appLaunchRequestIgnoringLocationHeader, firstChatMessageSent, resumeMode, unprovisioned, socketConnected, willAskUserToReconnect, realtimeExtrasWaitingForLocation, realtimeExtrasLastKnownCellNetworkInUse, cursorEnded, resetAfterNextForegrounding, controlButtonHidden, controlButtonVisibilityAnimating, rotationIsActuallyHappening, badInitialization, chatReceivedWhileAppBackgrounded, appForegrounded;
    LIOServerMode serverMode;
    NSData *messageSeparatorData;
    unsigned long previousScreenshotHash;
    SBJsonParser_LIO *jsonParser;
    SBJsonWriter_LIO *jsonWriter;
    UIImageView *cursorView, *clickView;
    LIOControlButtonView *controlButton;
    LIOSquareControlButtonView *squareControlButton;
    LIODragToDeleteView *dragToDeleteView;
    UInt32 controlButtonType;
    NSMutableArray *chatHistory;
    NSNumber *lastKnownQueuePosition;
    UIBackgroundTaskIdentifier backgroundTaskId;
    UIWindow *lookioWindow, *previousKeyWindow, *mainWindow;
    NSMutableURLRequest *appLaunchRequest, *appContinueRequest, *appIntroRequest, *appLineRequest;
    NSURLConnection *appLaunchRequestConnection, *appContinueRequestConnection, *appIntroRequestConnection, *appLineRequestConnection;
    NSMutableData *appLaunchRequestData, *appContinueRequestData, *appIntroRequestData, *appLineRequestData;
    NSInteger appLaunchRequestResponseCode, appContinueRequestResponseCode, appIntroRequestResponseCode, appLineRequestResponseCode;
    LIOAltChatViewController *altChatViewController;
    LIOInterstitialViewController *interstitialViewController;
    NSString *pendingEmailAddress;
    NSString *friendlyName;
    NSMutableDictionary *sessionExtras;
    NSDictionary *realtimeExtrasPreviousSessionExtras;
    NSMutableDictionary *proactiveChatRules;
    UIInterfaceOrientation actualInterfaceOrientation;
    NSNumber *lastKnownButtonVisibility;
    NSString *lastKnownButtonText;
    UIColor *lastKnownButtonTintColor, *lastKnownButtonTextColor;
    NSString *lastKnownWelcomeMessage;
    BOOL lastKnownSurveysEnabled;
    BOOL lastKnownHideEmailChat;
    NSArray *supportedOrientations;
    NSString *pendingChatText;
    NSDate *screenSharingStartedDate;
    NSMutableArray *queuedLaunchReportDates;
    NSDateFormatter *dateFormatter;
    NSDate *backgroundedTime;
    CLLocation *lastKnownLocation, *realtimeExtrasChangedLocation;
    NSString *overriddenEndpoint;
    LIOTimerProxy *reconnectionTimer, *reintroTimeoutTimer, *continuationTimer, *realtimeExtrasTimer;
    NSUInteger previousReconnectionTimerStep;
    NSString *controlEndpoint;
    UIStatusBarStyle originalStatusBarStyle;
    UIView *statusBarUnderlay, *statusBarUnderlayBlackout;
    NSMutableArray *urlSchemes;
    NSURL *pendingIntraAppLinkURL;
    NSString *currentVisitId;
    NSString *currentRequiredSkill;
    NSTimeInterval nextTimeInterval;
    NSDictionary *surveyResponsesToBeSent;
    NSString *partialPacketString;
    CGRect controlButtonShownFrame, controlButtonHiddenFrame;
    NSMutableDictionary *registeredPlugins;
    NSMutableArray *pendingEvents;
    int failedContinueCount;
    NSDictionary *multiskillMapping;
    NSString *lastKnownPageViewValue;
    id<LIOLookIOManagerDelegate> delegate;
    
    BOOL shouldLockOrientation;

    NSString* chatEngagementId;
    NSString* chatSSEUrlString;
    NSString* chatPostUrlString;
    NSString* chatMediaUrlString;
    NSString* chatLastEventId;
    NSMutableArray *chatCookies;
    
    LPSSEManager* sseManager;
    BOOL sseSocketAttemptingReconnect;
    BOOL sseConnectionDidFail;
    int sseConnectionRetryAfter;
    LIOTimerProxy *sseReconnectTimer;
    
    BOOL chatClosingAsPartOfReset;
    
    BOOL customButtonChatAvailable;
    BOOL customButtonInvitationShown;
    LIOFunnelState currentFunnelState;
    NSString *lastKnownVisitURL;
    BOOL introPacketWasSent;
    NSMutableArray* funnelRequestQueue;
    BOOL funnelRequestIsActive;
    BOOL callChatNotAnsweredAfterDismissal;

    BOOL shouldSendCapabilitiesPacket;
    int failedCapabilitiesCount;
    
    BOOL shouldSendChatHistoryPacket;
    NSDictionary *failedChatHistoryDict;
    int failedChatHistoryCount;
    
    int lastClientLineId;
    
    UIAlertView *dismissibleAlertView;
    LIOBlurImageView *blurImageView;

    UInt32 selectedChatTheme;
    
    BOOL disableSurveysOverride;
    BOOL previousSurveysEnabledValue;
    
    BOOL disableControlButtonOverride;
    BOOL previousControlButtonValue;
    
    CGFloat controlButtonPanX;
    CGFloat controlButtonPanY;
}

@property(nonatomic, readonly) BOOL screenshotsAllowed;
@property(nonatomic, readonly) NSString *pendingEmailAddress;
@property(nonatomic, assign) BOOL resetAfterNextForegrounding;
@property(nonatomic, readonly) NSDictionary *registeredPlugins;

- (void)rejiggerWindows;
- (void)refreshControlButtonVisibility;
- (NSDictionary *)buildIntroDictionaryIncludingExtras:(BOOL)includeExtras includingType:(BOOL)includesType includingSurveyResponses:(BOOL)includesSurveyResponses includingEvents:(BOOL)includeEvents;
- (NSString *)wwwFormEncodedDictionary:(NSDictionary *)aDictionary withName:(NSString *)aName;
- (void)configureReconnectionTimer;
- (BOOL)beginConnectingWithError:(NSError **)anError;
- (void)killReconnectionTimer;
- (NSString *)dateToStandardizedString:(NSDate *)aDate;
- (void)showReconnectionQuery;
- (void)populateChatWithFirstMessage;
- (BOOL)agentsAvailable;

@end

NSString *uniqueIdentifier()
{
    int mib[6];
    size_t len;
    char *buf;
    unsigned char *ptr;
    struct if_msghdr *ifm;
    struct sockaddr_dl *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0)
    {
        printf("Error: if_nametoindex error\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0)
    {
        printf("Error: sysctl, take 1\n");
        return NULL;
    }
    
    if ((buf = malloc(len)) == NULL)
    {
        printf("Could not allocate memory. error!\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0)
    {
        printf("Error: sysctl, take 2");
        return NULL;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    NSString *outstring = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X", 
                           *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    free(buf);
    
    const char *value = [outstring UTF8String];
    
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, strlen(value), outputBuffer);
    
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++)
        [outputString appendFormat:@"%02x",outputBuffer[count]];
    
    return [outputString autorelease];
}

@implementation LIOLookIOManager

@synthesize screenshotsAllowed, mainWindow, delegate, pendingEmailAddress;
@synthesize resetAfterNextForegrounding, registeredPlugins, selectedChatTheme;
@dynamic enabled, chatInProgress;

static LIOLookIOManager *sharedLookIOManager = nil;

+ (LIOLookIOManager *)sharedLookIOManager
{
    if (nil == sharedLookIOManager)
        sharedLookIOManager = [[LIOLookIOManager alloc] init];
    
    return sharedLookIOManager;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        lastClientLineId = 0;
        
        customButtonChatAvailable = NO;
        customButtonInvitationShown = NO;
        LIOLog(@"<FUNNEL STATE> Initialized");
        currentFunnelState = LIOFunnelStateInitialized;
        introPacketWasSent = NO;
        funnelRequestQueue = [[[NSMutableArray alloc] init] retain];
        funnelRequestIsActive = NO;
        callChatNotAnsweredAfterDismissal = NO;
        serverMode = LIOServerProduction;

        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

        if (0 == [[userDefaults objectForKey:LIOBundleManagerStringTableHashKey] length])
        {
            LIOBundleManager *bundleManager = [LIOBundleManager sharedBundleManager];
            NSString *languageId = [[NSLocale preferredLanguages] objectAtIndex:0];
            NSDictionary *builtInTable = [bundleManager localizedStringTableForLanguage:languageId];
            if ([builtInTable count])
            {
                NSString *newHash = [bundleManager hashForLocalizedStringTable:builtInTable];
                [userDefaults setObject:newHash forKey:LIOBundleManagerStringTableHashKey];
                
                LIOLog(@"Hashing the bundled localization table (\"%@\") succeeded: %@", languageId, newHash);
            }
            else
            {
                LIOLog(@"Couldn't hash the bundled localization table (\"%@\"). Table might not exist for that language.", languageId);
            }
        }
        
        touchImage = [[[LIOBundleManager sharedBundleManager] imageNamed:@"LIODefaultTouch"] retain];
        cursorView = [[UIImageView alloc] initWithImage:touchImage];
        cursorView.frame = CGRectMake(-cursorView.frame.size.width, -cursorView.frame.size.height, cursorView.frame.size.width, cursorView.frame.size.height);
        [keyWindow addSubview:cursorView];
        clickView = [[UIImageView alloc] initWithImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOClickIndicator"]];
        clickView.frame = CGRectMake(-clickView.frame.size.width, -clickView.frame.size.height, clickView.frame.size.width, clickView.frame.size.height);
        [keyWindow addSubview:clickView];
        cursorView.hidden = YES;
        clickView.hidden = YES;
        cursorEnded = YES;
        
        originalStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
        
        nextTimeInterval = 0.0;
        
        controlEndpoint = LIOLookIOManagerDefaultControlEndpoint;
        usesTLS = YES;
        
        sessionExtras = [[NSMutableDictionary alloc] init];
        proactiveChatRules = [[NSMutableDictionary alloc] init];
        registeredPlugins = [[NSMutableDictionary alloc] init];
        pendingEvents = [[NSMutableArray alloc] init];
        
        // Restore saved pending events.
        NSArray *savedPendingEvents = [userDefaults objectForKey:LIOLookIOManagerPendingEventsKey];
        if ([savedPendingEvents count])
            [pendingEvents addObjectsFromArray:savedPendingEvents];
        
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
        dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        
        queuedLaunchReportDates = [[userDefaults objectForKey:LIOLookIOManagerLaunchReportQueueKey] mutableCopy];
        if (nil == queuedLaunchReportDates)
            queuedLaunchReportDates = [[NSMutableArray alloc] init];
        
        jsonParser = [[SBJsonParser_LIO alloc] init];
        jsonWriter = [[SBJsonWriter_LIO alloc] init];
        
        urlSchemes = [[NSMutableArray alloc] init];
        NSArray *cfBundleURLTypes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
        if ([cfBundleURLTypes isKindOfClass:[NSArray class]])
        {
            for (NSDictionary *aURLType in cfBundleURLTypes)
            {
                if ([aURLType isKindOfClass:[NSDictionary class]])
                {
                    NSArray *cfBundleURLSchemes = [aURLType objectForKey:@"CFBundleURLSchemes"];
                    if ([cfBundleURLSchemes isKindOfClass:[NSArray class]])
                    {
                        for (NSString *aScheme in cfBundleURLSchemes)
                        {
                            if (NO == [urlSchemes containsObject:aScheme])
                                [urlSchemes addObject:aScheme];
                        }
                    }
                }
            }
        }
        
        // Start monitoring analytics.
        [LIOAnalyticsManager sharedAnalyticsManager];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityDidChange:)
                                                     name:LIOAnalyticsManagerReachabilityDidChangeNotification
                                                   object:[LIOAnalyticsManager sharedAnalyticsManager]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(locationWasDetermined:)
                                                     name:LIOAnalyticsManagerLocationWasDeterminedNotification
                                                   object:[LIOAnalyticsManager sharedAnalyticsManager]];
        
        // Init the ChatAPIClient
        LPChatAPIClient* chatClient = [LPChatAPIClient sharedClient];
        chatClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/api/v2/chat/", LIOLookIOManagerDefaultControlEndpoint]];
        
        LPMediaAPIClient* mediaClient = [LPMediaAPIClient sharedClient];
        mediaClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/api/v2/media/", LIOLookIOManagerDefaultControlEndpoint]];
        
        LPVisitAPIClient* visitClient = [LPVisitAPIClient sharedClient];
        visitClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", LIOLookIOManagerDefaultControlEndpoint]];
    }
    
    return self;
}

-(void)setChatAvailable {
    customButtonChatAvailable = YES;
    [self updateAndReportFunnelState];
}

-(void)setChatUnavailable {
    customButtonChatAvailable = NO;
    [self updateAndReportFunnelState];
}

-(void)setInvitationShown {
    customButtonInvitationShown = YES;
    [self updateAndReportFunnelState];
}

-(void)setInvitationNotShown {
    customButtonInvitationShown = NO;
    [self updateAndReportFunnelState];
}

- (void)setStagingMode
{
    serverMode = LIOServerStaging;
    controlEndpoint = LIOLookIOManagerDefaultControlEndpoint_Dev;

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
    serverMode = LIOServerQA;
    controlEndpoint = LIOLookIOManagerDefaultControlEndpoint_QA;
    
    // Init the ChatAPIClient
    LPChatAPIClient* chatClient = [LPChatAPIClient sharedClient];
    chatClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/api/v2/chat/", LIOLookIOManagerDefaultControlEndpoint_QA]];
    
    LPMediaAPIClient* mediaClient = [LPMediaAPIClient sharedClient];
    mediaClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/api/v2/media/", LIOLookIOManagerDefaultControlEndpoint_QA]];
    
    LPVisitAPIClient* visitClient = [LPVisitAPIClient sharedClient];
    visitClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", LIOLookIOManagerDefaultControlEndpoint_QA]];
}

- (void)setProductionMode
{
    serverMode = LIOServerProduction;
    controlEndpoint = LIOLookIOManagerDefaultControlEndpoint;
    
    // Init the ChatAPIClient
    LPChatAPIClient* chatClient = [LPChatAPIClient sharedClient];
    chatClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/api/v2/chat/", LIOLookIOManagerDefaultControlEndpoint]];
    
    LPMediaAPIClient* mediaClient = [LPMediaAPIClient sharedClient];
    mediaClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/api/v2/media/", LIOLookIOManagerDefaultControlEndpoint]];
    
    LPVisitAPIClient* visitClient = [LPVisitAPIClient sharedClient];
    visitClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", LIOLookIOManagerDefaultControlEndpoint]];
}

- (void)disableSurveys {
    disableSurveysOverride = YES;
    previousSurveysEnabledValue = [LIOSurveyManager sharedSurveyManager];
    [LIOSurveyManager sharedSurveyManager].surveysEnabled = NO;
}

- (void)undisableSurveys {
    disableSurveysOverride = NO;
    [LIOSurveyManager sharedSurveyManager].surveysEnabled = previousSurveysEnabledValue;
}

- (void)disableControlButton {
    disableControlButtonOverride = YES;
    previousControlButtonValue = [lastKnownButtonVisibility boolValue];
    lastKnownButtonVisibility = [NSNumber numberWithBool:NO];
    
    [self refreshControlButtonVisibility];
}

- (void)undisableControlButton {
    disableControlButtonOverride = NO;
    lastKnownButtonVisibility = [NSNumber numberWithBool:previousControlButtonValue];
    
    [self refreshControlButtonVisibility];
}

- (void)uploadLog:(NSString *)logBody
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http%@://%@/%@", usesTLS ? @"s" : @"", controlEndpoint, LIOLookIOManagerLogUploadRequestURL]];
    NSString *udid = @"";

    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
        udid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    } else {
        udid = uniqueIdentifier();
    }
    
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    
    NSMutableURLRequest *uploadLogRequest = [NSMutableURLRequest requestWithURL:url
                                                                    cachePolicy:NSURLCacheStorageNotAllowed
                                                                timeoutInterval:10.0];
    [uploadLogRequest addValue:bundleId forHTTPHeaderField:@"X-Lookio-AppID"];
    [uploadLogRequest addValue:@"Apple iOS" forHTTPHeaderField:@"X-Lookio-Platform"];
    [uploadLogRequest addValue:udid forHTTPHeaderField:@"X-Lookio-DeviceID"];
    [uploadLogRequest addValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
    [uploadLogRequest setHTTPBody:[logBody dataUsingEncoding:NSUTF8StringEncoding]];
    [uploadLogRequest setHTTPMethod:@"POST"];
    
    [NSURLConnection connectionWithRequest:uploadLogRequest delegate:nil];
    
    LIOLog(@"Uploading LookIO log to %@ ...", [url absoluteString]);
}

- (void)sendLaunchReport
{
    // First time setup.
    if (nil == appLaunchRequest)
    {
        appLaunchRequest = [[NSMutableURLRequest alloc] initWithURL:nil
                                                        cachePolicy:NSURLCacheStorageNotAllowed
                                                    timeoutInterval:10.0];
        [appLaunchRequest setHTTPMethod:@"POST"];
        [appLaunchRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        appLaunchRequestData = [[NSMutableData alloc] init];
        appLaunchRequestResponseCode = -1;
    }
    
    if ([overriddenEndpoint length])
    {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http%@://%@/%@", usesTLS ? @"s" : @"", overriddenEndpoint, LIOLookIOManagerAppLaunchRequestURL]];
        [appLaunchRequest setURL:url];
    }
    else
    {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http%@://%@/%@", usesTLS ? @"s" : @"", controlEndpoint, LIOLookIOManagerAppLaunchRequestURL]];
        [appLaunchRequest setURL:url];
    }
    
    // Send off the app launch packet, if connected.
    [[LIOAnalyticsManager sharedAnalyticsManager] pumpReachabilityStatus];
    if (LIOAnalyticsManagerReachabilityStatusConnected == [LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)
    {
        NSDictionary *introDict = [self buildIntroDictionaryIncludingExtras:YES includingType:NO includingSurveyResponses:NO includingEvents:NO];
        NSString *introDictJSONEncoded = [jsonWriter stringWithObject:introDict];
        [appLaunchRequest setHTTPBody:[introDictJSONEncoded dataUsingEncoding:NSUTF8StringEncoding]];
        LIOLog(@"<LAUNCH> Endpoint: \"%@\"\n    Request: %@", [appLaunchRequest.URL absoluteString], introDictJSONEncoded);
        appLaunchRequestConnection = [[NSURLConnection alloc] initWithRequest:appLaunchRequest delegate:self];
    }
    else
    {
        // Queue this launch packet.
        [queuedLaunchReportDates addObject:[NSDate date]];
        [[NSUserDefaults standardUserDefaults] setObject:queuedLaunchReportDates forKey:LIOLookIOManagerLaunchReportQueueKey];
        
        // Delete multiskill mapping. This should force
        // the lib to report "disabled" back to the host app.
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:LIOLookIOManagerMultiskillMappingKey];
        [multiskillMapping release];
        multiskillMapping = nil;
        
        [self refreshControlButtonVisibility];
    }
}

- (void)sendContinuationReport
{
    if (appContinueRequestConnection)
        return;
    
    if (0 == [lastKnownVisitURL length])
        return;
    
    // First time setup.
    if (nil == appContinueRequest)
    {
        appContinueRequest = [[NSMutableURLRequest alloc] initWithURL:nil
                                                          cachePolicy:NSURLCacheStorageNotAllowed
                                                      timeoutInterval:10.0];
        [appContinueRequest setHTTPMethod:@"POST"];
        [appContinueRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        appContinueRequestData = [[NSMutableData alloc] init];
        appContinueRequestResponseCode = -1;
    }
    
    // Send it! ... if we have Internets, that is.
    [[LIOAnalyticsManager sharedAnalyticsManager] pumpReachabilityStatus];
    if (LIOAnalyticsManagerReachabilityStatusConnected == [LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)
    {
        NSDictionary *introDict = [self buildIntroDictionaryIncludingExtras:YES includingType:NO includingSurveyResponses:NO includingEvents:YES];
        NSString *introDictJSONEncoded = [jsonWriter stringWithObject:introDict];
        [appContinueRequest setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", lastKnownVisitURL, LIOLookIOManagerAppContinueRequestURL]]];
        [appContinueRequest setHTTPBody:[introDictJSONEncoded dataUsingEncoding:NSUTF8StringEncoding]];
        LIOLog(@"<CONTINUE> Endpoint: \"%@\"\n    Request: %@", [appContinueRequest.URL absoluteString], introDictJSONEncoded);
        appContinueRequestConnection = [[NSURLConnection alloc] initWithRequest:appContinueRequest delegate:self];
    }
    
    [self updateAndReportFunnelState];
}

- (void)performSetupWithDelegate:(id<LIOLookIOManagerDelegate>)aDelegate
{
    NSAssert([NSThread currentThread] == [NSThread mainThread], @"LookIO can only be used on the main thread!");
    
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    
    appForegrounded = YES;
    controlButtonHidden = YES;
    
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    badInitialization = nil == keyWindow;
    
    delegate = aDelegate;
    
    // - (NSString *)lookIOManagerControlEndpointOverride:(LIOLookIOManager *)aManager;
    if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManagerControlEndpointOverride:)])
    {
        [controlEndpoint release];
        controlEndpoint = [[delegate lookIOManagerControlEndpointOverride:self] retain];
    }
    
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    // Try to get supported orientation information from plist.
    NSArray *plistOrientations = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedInterfaceOrientations"];
    if (plistOrientations)
    {
        NSMutableArray *orientationNumbers = [NSMutableArray array];
        
        if ([plistOrientations containsObject:@"UIInterfaceOrientationPortrait"])
            [orientationNumbers addObject:[NSNumber numberWithInteger:UIInterfaceOrientationPortrait]];
        
        if ([plistOrientations containsObject:@"UIInterfaceOrientationPortraitUpsideDown"])
            [orientationNumbers addObject:[NSNumber numberWithInteger:UIInterfaceOrientationPortraitUpsideDown]];
        
        if ([plistOrientations containsObject:@"UIInterfaceOrientationLandscapeLeft"])
            [orientationNumbers addObject:[NSNumber numberWithInteger:UIInterfaceOrientationLandscapeLeft]];
        
        if ([plistOrientations containsObject:@"UIInterfaceOrientationLandscapeRight"])
            [orientationNumbers addObject:[NSNumber numberWithInteger:UIInterfaceOrientationLandscapeRight]];
        
        supportedOrientations = [orientationNumbers retain];
    }
    else
    {
        supportedOrientations = [[NSArray alloc] init];
    }
    
    lookioWindow = [[UIWindow alloc] initWithFrame:keyWindow.frame];
    lookioWindow.hidden = YES;
    lookioWindow.windowLevel = 0.1;
    
    screenCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:LIOLookIOManagerScreenCaptureInterval
                                                          target:self
                                                        selector:@selector(screenCaptureTimerDidFire:)
                                                        userInfo:nil
                                                         repeats:YES];
    
    messageSeparatorData = [[LIOLookIOManagerMessageSeparator dataUsingEncoding:NSUTF8StringEncoding] retain];
    
    chatHistory = [[NSMutableArray alloc] init];
    
    controlButtonType = kLPControlButtonClassic;
    if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManagerControlButtonType:)])
        controlButtonType = [delegate lookIOManagerControlButtonType:self];
    
    if (controlButtonType == kLPControlButtonClassic) {
        controlButton = [[LIOControlButtonView alloc] initWithFrame:CGRectZero];
        controlButton.delegate = self;
        controlButton.accessibilityLabel = @"LIOLookIOManager.controlButton";
        [keyWindow addSubview:controlButton];
        [self rejiggerControlButtonFrame];
         controlButton.frame = controlButtonHiddenFrame;
    }
    
    if (controlButtonType == kLPControlButtonSquare) {
        dragToDeleteView = [[LIODragToDeleteView alloc] initWithFrame:CGRectMake(0, keyWindow.bounds.size.height, keyWindow.bounds.size.width, 110)];
        [keyWindow addSubview:dragToDeleteView];
        
        squareControlButton = [[LIOSquareControlButtonView alloc] initWithFrame:CGRectZero];
        squareControlButton.delegate = self;
        squareControlButton.accessibilityLabel = @"LIOLookIOManager.controlButton";
        [keyWindow addSubview:squareControlButton];
        [self resetSquareControlButtonPosition];
        [self rejiggerControlButtonFrame];
        squareControlButton.frame = controlButtonHiddenFrame;
        
        UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragSquareControlButton:)];
        [panRecognizer setMinimumNumberOfTouches:1];
        [panRecognizer setMaximumNumberOfTouches:1];
        [squareControlButton addGestureRecognizer:panRecognizer];
        [panRecognizer release];
    }
    
    // Restore control button settings.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [lastKnownButtonVisibility release];
    lastKnownButtonVisibility = [[userDefaults objectForKey:LIOLookIOManagerLastKnownButtonVisibilityKey] retain];
    // Sensible default
    if (nil == lastKnownButtonVisibility)
        lastKnownButtonVisibility = [[NSNumber alloc] initWithBool:NO];
    
    if (disableControlButtonOverride) {
        previousControlButtonValue = [lastKnownButtonVisibility boolValue];
        lastKnownButtonVisibility = [[NSNumber alloc] initWithBool:NO];
    }
    
    
    [lastKnownButtonText release];
    lastKnownButtonText = [[userDefaults objectForKey:LIOLookIOManagerLastKnownButtonTextKey] retain];
    controlButton.labelText = lastKnownButtonText;
    [self rejiggerControlButtonFrame];
    
    [lastKnownButtonTintColor release];
    lastKnownButtonTintColor = nil;
    NSString *tintString = [userDefaults objectForKey:LIOLookIOManagerLastKnownButtonTintColorKey];
    if (tintString)
    {
        unsigned int colorValue;
        [[NSScanner scannerWithString:tintString] scanHexInt:&colorValue];
        UIColor *aColor = HEXCOLOR(colorValue);
        lastKnownButtonTintColor = [aColor retain];
        if (controlButtonType == kLPControlButtonClassic)
            controlButton.tintColor = lastKnownButtonTintColor;
        if (controlButtonType == kLPControlButtonSquare)
            controlButton.tintColor = lastKnownButtonTintColor;
    }
    
    [lastKnownButtonTextColor release];
    lastKnownButtonTextColor = nil;
    NSString *textColorString = [userDefaults objectForKey:LIOLookIOManagerLastKnownButtonTextColorKey];
    if (textColorString)
    {
        unsigned int colorValue;
        [[NSScanner scannerWithString:textColorString] scanHexInt:&colorValue];
        UIColor *aColor = HEXCOLOR(colorValue);    
        lastKnownButtonTextColor = [aColor retain];
        
        if (controlButtonType == kLPControlButtonClassic)
            controlButton.textColor = lastKnownButtonTextColor;
        
        if (controlButtonType == kLPControlButtonSquare) {
            squareControlButton.textColor = lastKnownButtonTextColor;
            [squareControlButton updateButtonColor];
        }
    }
    
    // Restore other settings.
    [lastKnownWelcomeMessage release];
    lastKnownWelcomeMessage = [[userDefaults objectForKey:LIOLookIOManagerLastKnownWelcomeMessageKey] retain];
    
    [multiskillMapping release];
    multiskillMapping = [[userDefaults objectForKey:LIOLookIOManagerMultiskillMappingKey] retain];
    
    [self refreshControlButtonVisibility];
    
    [self applicationDidChangeStatusBarOrientation:nil];
    
    if (0.0 == nextTimeInterval)
        nextTimeInterval = LIOLookIOManagerDefaultContinuationReportInterval;
    
    if ([userDefaults objectForKey:LIOLookIOManagerLastKnownSurveysEnabled])
    {
        NSNumber* surveysEnabled = (NSNumber *)[userDefaults objectForKey:LIOLookIOManagerLastKnownSurveysEnabled];
        lastKnownSurveysEnabled = [surveysEnabled boolValue];
        LIOSurveyManager* surveyManager = [LIOSurveyManager sharedSurveyManager];
        surveyManager.surveysEnabled = lastKnownSurveysEnabled;
        
        if (disableSurveysOverride) {
            previousSurveysEnabledValue = surveyManager.surveysEnabled;
            surveyManager.surveysEnabled = NO;
        }
        
    }
    
    continuationTimer = [[LIOTimerProxy alloc] initWithTimeInterval:nextTimeInterval
                                                             target:self
                                                           selector:@selector(continuationTimerDidFire)];
        
    backgroundTaskId = UIBackgroundTaskInvalid;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillChangeStatusBarOrientation:)
                                                 name:UIApplicationWillChangeStatusBarOrientationNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidChangeStatusBarOrientation:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    previousReconnectionTimerStep = 2;
    resumeMode = NO;
    
    previousScreenshotHash = 0;
    
    [self sendLaunchReport];
    
    [LIOBundleManager sharedBundleManager];
    
    statusBarUnderlay = [[UIView alloc] initWithFrame:[[UIApplication sharedApplication] statusBarFrame]];
    statusBarUnderlay.backgroundColor = [UIColor colorWithRed:0.0 green:(100.0/256.0) blue:(137.0/256.0) alpha:1.0];
    statusBarUnderlay.hidden = YES;
    if (NO == padUI)
        [keyWindow addSubview:statusBarUnderlay];
    
    statusBarUnderlayBlackout = [[UIView alloc] initWithFrame:[[UIApplication sharedApplication] statusBarFrame]];
    statusBarUnderlayBlackout.backgroundColor = [UIColor blackColor];
    statusBarUnderlayBlackout.hidden = YES;
    if (NO == padUI)
        [keyWindow addSubview:statusBarUnderlayBlackout];

    NSString *engagementId = [userDefaults objectForKey:LIOLookIOManagerLastKnownEngagementIdKey];
    if ([engagementId length])
    {
        NSDate *lastActivity = [userDefaults objectForKey:LIOLookIOManagerLastActivityDateKey];
        NSTimeInterval timeSinceLastActivity = [lastActivity timeIntervalSinceNow];
        if (lastActivity && timeSinceLastActivity > -LIOLookIOManagerReconnectionAfterCrashTimeLimit)
        {
            LIOLog(@"Found a saved engagement id! Trying to reconnect...");
            willAskUserToReconnect = YES;
            
            chatEngagementId = engagementId;
            chatPostUrlString = [userDefaults objectForKey:LIOLookIOManagerLastKnownChatPostUrlString];
            chatMediaUrlString = [userDefaults objectForKey:LIOLookIOManagerLastKnownChatMediaUrlString];
            chatSSEUrlString = [userDefaults objectForKey:LIOLookIOManagerLastKnownChatSSEUrlStringKey];
            chatLastEventId = [userDefaults objectForKey:LIOLookIOManagerLastKnownChatLastEventIdString];
            NSData *cookieData = [userDefaults objectForKey:LIOLookIOManagerLastKnownChatCookiesKey];
            chatCookies = [[NSKeyedUnarchiver unarchiveObjectWithData:cookieData] retain];
            
            NSData *chatHistoryData = [userDefaults objectForKey:LIOLookIOManagerLastKnownChatHistoryKey];
            if (chatHistoryData) {
                [chatHistory release];
                chatHistory = [[NSKeyedUnarchiver unarchiveObjectWithData:chatHistoryData] retain];
            }

            [self setupAPIClientBaseURL];
            
            double delayInSeconds = 2.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self showReconnectionQuery];
            });
        }
        else
        {
            // Too much time has passed.
            LIOLog(@"Found a saved engagement id, but it's old. Discarding...");
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            
            [userDefaults removeObjectForKey:LIOLookIOManagerLastActivityDateKey];
            [userDefaults removeObjectForKey:LIOLookIOManagerLastKnownEngagementIdKey];
            [userDefaults removeObjectForKey:LIOLookIOManagerLastKnownChatSSEUrlStringKey];
            [userDefaults removeObjectForKey:LIOLookIOManagerLastKnownChatPostUrlString];
            [userDefaults removeObjectForKey:LIOLookIOManagerLastKnownChatMediaUrlString];
            [userDefaults removeObjectForKey:LIOLookIOManagerLastKnownChatLastEventIdString];
            [userDefaults removeObjectForKey:LIOLookIOManagerLastKnownChatHistoryKey];
            
            [userDefaults synchronize];
        }
    }
    
    if (!willAskUserToReconnect)
        [[LIOMediaManager sharedInstance] purgeAllMedia];
    
    realtimeExtrasLastKnownCellNetworkInUse = [[LIOAnalyticsManager sharedAnalyticsManager] cellularNetworkInUse];
    
    [self setupBundle];

    [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityInfo format:@"Loaded."];
}

- (void)setupBundle {
    selectedChatTheme = kLPChatThemeClassic;
    if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManagerSelectedChatTheme:)]) {
        UInt32 developerTheme = [delegate lookIOManagerSelectedChatTheme:self];
        if (developerTheme == kLPChatThemeFlat)
            selectedChatTheme = kLPChatThemeFlat;
    }
    
    [LIOBundleManager sharedBundleManager].selectedChatTheme = selectedChatTheme;
    [[LIOBundleManager sharedBundleManager] resetBundle];
    
    [controlButton updateButtonForChatTheme];
}

- (NSString *)dateToStandardizedString:(NSDate *)aDate
{
    NSString *result = [dateFormatter stringFromDate:aDate];
    
    return result;
}

- (NSString *)urlEncodedStringWithString:(NSString *)str
{
    static const CFStringRef urlEncodingCharsToEscape = CFSTR(":/?#[]@!$&’()*+,;=");
    NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)str, NULL, urlEncodingCharsToEscape, kCFStringEncodingUTF8);
    return [result autorelease];
}

- (NSString *)wwwFormEncodedDictionary:(NSDictionary *)aDictionary withName:(NSString *)aName
{
    NSMutableString *result = [NSMutableString string];
    for (NSString *aKey in aDictionary)
    {
        id anObject = [aDictionary objectForKey:aKey];
        
        if ([anObject isKindOfClass:[NSDictionary class]])
        {
            NSString *dictString = [self wwwFormEncodedDictionary:anObject withName:aKey];
            [result appendFormat:@"%@&", dictString];
        }
        else
        {
            NSString *stringValue = [NSString stringWithFormat:@"%@", anObject];
            
            if ([aName length])
                [result appendFormat:@"%@%%5B%@%%5D=%@&", [self urlEncodedStringWithString:aName], [self urlEncodedStringWithString:aKey], [self urlEncodedStringWithString:stringValue]];
            else
                [result appendFormat:@"%@=%@&", [self urlEncodedStringWithString:aKey], [self urlEncodedStringWithString:stringValue]];
        }
    }
    
    // Kill the trailing & and we're done!
    if ([result length] && [result hasSuffix:@"&"])
        return [result substringToIndex:([result length] - 1)];
    
    return result;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [lastKnownPageViewValue release];
    lastKnownPageViewValue = nil;
    
    [touchImage release];
    touchImage = nil;
    
    [cursorView release];
    cursorView = nil;
    
    [clickView release];
    clickView = nil;
    
    [controlButton release];
    controlButton = nil;
    
    [squareControlButton release];
    squareControlButton = nil;
    
    [messageSeparatorData release];
    [jsonParser release];
    [jsonWriter release];
    [chatHistory release];
    [lastKnownQueuePosition release];
    [friendlyName release];
    [appLaunchRequest release];
    [appLaunchRequestConnection release];
    [appLaunchRequestData release];
    [appContinueRequest release];
    [appContinueRequestConnection release];
    [appContinueRequestData release];
    [lastKnownButtonVisibility release];
    [lastKnownButtonText release];
    [lastKnownButtonTintColor release];
    [lastKnownButtonTextColor release];
    [lastKnownWelcomeMessage release];
    [pendingEmailAddress release];
    [supportedOrientations release];
    [screenSharingStartedDate release];
    [queuedLaunchReportDates release];
    [dateFormatter release];
    [overriddenEndpoint release];
    [proactiveChatRules release];
    [pendingIntraAppLinkURL release];
    [currentRequiredSkill release];
    [lastKnownVisitURL release];
    [currentVisitId release];
    [surveyResponsesToBeSent release];
    [lastKnownLocation release];
    [realtimeExtrasPreviousSessionExtras release];
    [registeredPlugins release];
    [sessionExtras release];
    [pendingEvents release];
    
    [reconnectionTimer stopTimer];
    [reconnectionTimer release];
    reconnectionTimer = nil;
    
    [continuationTimer stopTimer];
    [continuationTimer release];
    continuationTimer = nil;
    
    [realtimeExtrasTimer stopTimer];
    [realtimeExtrasTimer release];
    realtimeExtrasTimer = nil;
        
    [altChatViewController release];
    altChatViewController = nil;

    [lookioWindow release];
    [mainWindow release];
    
    [statusBarUnderlay release];
    [statusBarUnderlayBlackout release];
    
    [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityInfo format:@"Unloaded."];
    
    [sseManager reset];
    [sseManager release];
    sseManager = nil;
    
    [funnelRequestQueue removeAllObjects];
    [funnelRequestQueue release];
    funnelRequestQueue = nil;
    
    [super dealloc];
}

- (void)disconnectAndReset {
    sessionEnding = YES;
    userWantsSessionTermination = YES;
    
    if (NO == socketConnected)
    {
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self reset];
        });
    }
    else
    {
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            resetAfterDisconnect = YES;
            [self killConnection];
        });
    }
}

- (void)reset
{
    if (altChatViewController && !chatClosingAsPartOfReset) {
        // altChatviewController will be reset when the altChatViewControllerDidFinishDismissalAnimation method is called, to ensure clean animation
        chatClosingAsPartOfReset = YES;
        
        [altChatViewController performDismissalAnimation];
        [self dismissBlurImageView:YES];
        return;
    }
    
    chatClosingAsPartOfReset = NO;
    [LIOSurveyManager sharedSurveyManager].lastCompletedQuestionIndexPre = -1;
    [LIOSurveyManager sharedSurveyManager].lastCompletedQuestionIndexPost = -1;
    [LIOSurveyManager sharedSurveyManager].lastCompletedQuestionIndexOffline = -1;
    
    [[LIOSurveyManager sharedSurveyManager] clearTemplateForSurveyType:LIOSurveyManagerSurveyTypePre];
    [[LIOSurveyManager sharedSurveyManager] clearTemplateForSurveyType:LIOSurveyManagerSurveyTypePost];
    [[LIOSurveyManager sharedSurveyManager] clearTemplateForSurveyType:LIOSurveyManagerSurveyTypeOffline];

    [[LIOSurveyManager sharedSurveyManager] clearAllResponsesForSurveyType:LIOSurveyManagerSurveyTypePre];
    [[LIOSurveyManager sharedSurveyManager] clearAllResponsesForSurveyType:LIOSurveyManagerSurveyTypePost];
    [[LIOSurveyManager sharedSurveyManager] clearAllResponsesForSurveyType:LIOSurveyManagerSurveyTypeOffline];
    
    [LIOSurveyManager sharedSurveyManager].preSurveyCompleted = NO;
    [LIOSurveyManager sharedSurveyManager].receivedEmptyPreSurvey = NO;
    
    [altChatViewController bailOnSecondaryViews];
    [altChatViewController.view removeFromSuperview];
    [altChatViewController release];
    altChatViewController = nil;
    
    [LIOSurveyManager sharedSurveyManager].lastCompletedQuestionIndexPre = -1;
    [LIOSurveyManager sharedSurveyManager].lastCompletedQuestionIndexPost = -1;
    [[LIOSurveyManager sharedSurveyManager] clearAllResponsesForSurveyType:LIOSurveyManagerSurveyTypePre];
    [[LIOSurveyManager sharedSurveyManager] clearAllResponsesForSurveyType:LIOSurveyManagerSurveyTypePost];
    
    [interstitialViewController.view removeFromSuperview];
    [interstitialViewController release];
    interstitialViewController = nil;
    
    for (NSString *aKey in registeredPlugins)
    {
        id<LIOPlugin> aPlugin = [registeredPlugins objectForKey:aKey];
        [aPlugin resetPluginState];
    }

    [lastKnownPageViewValue release];
    lastKnownPageViewValue = nil;
    
    [chatHistory release];
    chatHistory = [[NSMutableArray alloc] init];
    
    cursorView.hidden = YES;
    clickView.hidden = YES;
        
    [backgroundedTime release];
    backgroundedTime = nil;
    
    [reconnectionTimer stopTimer];
    [reconnectionTimer release];
    reconnectionTimer = nil;
    
    [reintroTimeoutTimer stopTimer];
    [reintroTimeoutTimer release];
    reintroTimeoutTimer = nil;
    
    [realtimeExtrasTimer stopTimer];
    [realtimeExtrasTimer release];
    realtimeExtrasTimer = nil;
    
    [realtimeExtrasChangedLocation release];
    realtimeExtrasChangedLocation = nil;
    
    [realtimeExtrasPreviousSessionExtras release];
    realtimeExtrasPreviousSessionExtras = nil;
    
    [pendingIntraAppLinkURL release];
    pendingIntraAppLinkURL = nil;
    
    [surveyResponsesToBeSent release];
    surveyResponsesToBeSent = nil;
        
    previousReconnectionTimerStep = 2;
    previousScreenshotHash = 0;
    nextTimeInterval = 0.0;
    failedContinueCount = 0;
        
    waitingForScreenshotAck = NO, waitingForIntroAck = NO, controlSocketConnecting = NO, introduced = NO, enqueued = NO;
    resetAfterDisconnect = NO, killConnectionAfterChatViewDismissal = NO, screenshotsAllowed = NO, unprovisioned = NO;
    sessionEnding = NO, userWantsSessionTermination = NO, outroReceived = NO, firstChatMessageSent = NO, resumeMode = NO;
    socketConnected = NO, willAskUserToReconnect = NO, resetAfterChatViewDismissal = NO, realtimeExtrasWaitingForLocation = NO, resetAfterNextForegrounding = NO,
    cursorEnded = YES;
    chatReceivedWhileAppBackgrounded = NO;
    realtimeExtrasLastKnownCellNetworkInUse = [[LIOAnalyticsManager sharedAnalyticsManager] cellularNetworkInUse];
    
    [screenSharingStartedDate release];
    screenSharingStartedDate = nil;
    
    [queuedLaunchReportDates removeAllObjects];
    [proactiveChatRules removeAllObjects];
    
    statusBarUnderlay.hidden = YES;
    statusBarUnderlayBlackout.hidden = YES;
    
    shouldSendCapabilitiesPacket = NO;
    failedCapabilitiesCount = 0;
    
    shouldSendChatHistoryPacket = NO;
    failedChatHistoryCount = 0;
    [failedChatHistoryDict release];
    failedChatHistoryDict = nil;
    
    lastClientLineId = 0;
    
    if (NO == [[UIApplication sharedApplication] isStatusBarHidden])
        [[UIApplication sharedApplication] setStatusBarStyle:originalStatusBarStyle];
    
    [self rejiggerWindows];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:LIOLookIOManagerLastActivityDateKey];
    [userDefaults removeObjectForKey:LIOLookIOManagerLastKnownSessionIdKey];
    
    [userDefaults removeObjectForKey:LIOLookIOManagerLastKnownEngagementIdKey];
    [userDefaults removeObjectForKey:LIOLookIOManagerLastKnownChatSSEUrlStringKey];
    [userDefaults removeObjectForKey:LIOLookIOManagerLastKnownChatPostUrlString];
    [userDefaults removeObjectForKey:LIOLookIOManagerLastKnownChatMediaUrlString];
    [userDefaults removeObjectForKey:LIOLookIOManagerLastKnownChatLastEventIdString];
    [userDefaults removeObjectForKey:LIOSurveyManagerLastKnownPostChatSurveyDictKey];
    [userDefaults removeObjectForKey:LIOSurveyManagerLastKnownOfflineSurveyDictKey];
    [userDefaults removeObjectForKey:LIOLookIOManagerLastKnownChatHistoryKey];
    
    chatEngagementId = nil;
    chatSSEUrlString = nil;
    chatPostUrlString = nil;
    chatMediaUrlString = nil;
    chatLastEventId = nil;

    if (chatCookies) {
        [chatCookies removeAllObjects];
        [chatCookies release];
        chatCookies = nil;
    }
    
    [sseManager reset];
    [sseManager release];
    sseManager = nil;
    
    introPacketWasSent = NO;
    
    sseConnectionDidFail = NO;
    sseConnectionRetryAfter = -1;
    
    [sseReconnectTimer stopTimer];
    [sseReconnectTimer release];
    sseReconnectTimer = nil;
    
    LPChatAPIClient *chatClient = [LPChatAPIClient sharedClient];
    LPMediaAPIClient *mediaClient = [LPMediaAPIClient sharedClient];
    
    NSMutableArray *cookiesToDelete = [[[NSMutableArray alloc] init] autorelease];
    [cookiesToDelete addObjectsFromArray:[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:chatClient.baseURL]];
    [cookiesToDelete addObjectsFromArray:[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:mediaClient.baseURL]];
    for (NSHTTPCookie *cookie in cookiesToDelete)
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];

    if (LIOServerStaging == serverMode) {
        chatClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/api/v2/chat/", LIOLookIOManagerDefaultControlEndpoint_Dev]];
        mediaClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/api/v2/media/", LIOLookIOManagerDefaultControlEndpoint_Dev]];
    }
    
    if (LIOServerQA == serverMode) {
        chatClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/api/v2/chat/", LIOLookIOManagerDefaultControlEndpoint_QA]];
        mediaClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/api/v2/media/", LIOLookIOManagerDefaultControlEndpoint_QA]];
    }

    if (LIOServerProduction == serverMode) {
        chatClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/api/v2/chat/", LIOLookIOManagerDefaultControlEndpoint]];
        mediaClient.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/api/v2/media/", LIOLookIOManagerDefaultControlEndpoint]];
    }
    
    [userDefaults synchronize];
    
    [self updateAndReportFunnelState];
    
    LIOLog(@"Reset. Key window: 0x%08X", (unsigned int)[[UIApplication sharedApplication] keyWindow]);
}

- (void)rejiggerControlButtonLabel {
    if (controlButtonType == kLPControlButtonClassic)
        [self rejiggerClassicControlButtonLabel];
    if (controlButtonType == kLPControlButtonSquare)
        [self rejiggerSquareControlButtonLabel];
}

- (void)rejiggerClassicControlButtonLabel
{
    actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (UIInterfaceOrientationPortrait == actualInterfaceOrientation)
    {
        controlButton.label.transform = CGAffineTransformMakeRotation(-90.0 * (M_PI / 180.0));
        controlButton.label.frame = controlButton.bounds;
    }
    else if (UIInterfaceOrientationLandscapeLeft == actualInterfaceOrientation)
    {
        controlButton.label.transform = CGAffineTransformMakeRotation(-180.0 * (M_PI / 180.0));
        controlButton.label.frame = controlButton.bounds;
    }
    else if (UIInterfaceOrientationPortraitUpsideDown == actualInterfaceOrientation)
    {
        controlButton.label.transform = CGAffineTransformMakeRotation(-270.0 * (M_PI / 180.0));
        controlButton.label.frame = controlButton.bounds;
    }
    else // Landscape, home button right
    {
        controlButton.label.transform = CGAffineTransformIdentity;//CGAffineTransformMakeRotation(-90.0 * (M_PI / 180.0));
        controlButton.label.frame = controlButton.bounds;
    }
}

- (void)rejiggerSquareControlButtonLabel
{
    
}

- (void)rejiggerControlButtonFrame {
    if (controlButtonType == kLPControlButtonClassic)
        [self rejiggerClassicControlButtonFrame];
    if (controlButtonType == kLPControlButtonSquare)
        [self rejiggerSquareControlButtonFrame];
}

- (void)resetSquareControlButtonPosition {
    UIWindow *buttonWindow = (UIWindow *)squareControlButton.superview;
    CGSize screenSize = [buttonWindow bounds].size;
    actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    CGFloat buttonHeight = LIOLookIOManagerSquareControlButtonSize;
    CGFloat buttonWidth = LIOLookIOManagerSquareControlButtonSize;
    CGPoint position = squareControlButton.position;
    
    if (UIInterfaceOrientationPortrait == actualInterfaceOrientation)
    {
        position.x = screenSize.width - buttonWidth + 2.0;
        position.y = (screenSize.height / 2.0) - (buttonHeight / 2.0);
    }
    if (UIInterfaceOrientationLandscapeLeft == actualInterfaceOrientation) // Home button left
    {
        position.x = (screenSize.width / 2.0) - (buttonHeight / 2.0);
        position.y = -6.0;
    }
    if (UIInterfaceOrientationPortraitUpsideDown == actualInterfaceOrientation)
    {
        position.x = -2.0;
        position.y = (screenSize.height / 2.0) - (buttonHeight / 2.0);
    }
    if (UIInterfaceOrientationLandscapeRight == actualInterfaceOrientation)
    {
        position.x = (screenSize.width / 2.0) - (buttonHeight / 2.0);
        position.y = screenSize.height - buttonHeight + 2.0;
    }
    
    squareControlButton.position = position;
    squareControlButton.isAttachedToRight = YES;
}

- (void)rejiggerClassicControlButtonFrame
{
    if (squareControlButton.isDragging)
        return;
    
    if (NO == [controlButton.superview isKindOfClass:[UIWindow class]])
        return;
    
    UIWindow *buttonWindow = (UIWindow *)controlButton.superview;
    CGSize screenSize = [buttonWindow bounds].size;
    actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    [controlButton layoutSubviews];
    
    CGSize textSize = [controlButton.label.text sizeWithFont:controlButton.label.font];
    textSize.width += 20.0; // 10px padding on each side
    
    CGFloat extraHeight = 0.0;
    if (textSize.width > LIOLookIOManagerControlButtonMinHeight)
        extraHeight = textSize.width - LIOLookIOManagerControlButtonMinHeight;
    
    CGFloat actualHeight = LIOLookIOManagerControlButtonMinHeight + extraHeight;
    
    // Manually position the control button. Ugh.
    if (UIInterfaceOrientationPortrait == actualInterfaceOrientation)
    {
        CGRect aFrame = controlButton.frame;
        aFrame.size.width = LIOLookIOManagerControlButtonMinWidth;
        aFrame.size.height = actualHeight;
        aFrame.origin.y = (screenSize.height / 2.0) - (actualHeight / 2.0);
        aFrame.origin.x = screenSize.width - LIOLookIOManagerControlButtonMinWidth + 2.0;
        if (NO == controlButtonVisibilityAnimating && NO == controlButtonHidden) controlButton.frame = aFrame;
        //[controlButton setNeedsLayout];
        
        controlButtonShownFrame = aFrame;
        aFrame.origin.x = screenSize.width + 10.0;
        controlButtonHiddenFrame = aFrame;
        
        [self rejiggerControlButtonLabel];
    }
    else if (UIInterfaceOrientationLandscapeLeft == actualInterfaceOrientation)
    {
        CGRect aFrame = controlButton.frame;
        aFrame.size.width = actualHeight;
        aFrame.size.height = LIOLookIOManagerControlButtonMinWidth;
        aFrame.origin.y = -2.0;
        aFrame.origin.x = (screenSize.width / 2.0) - (actualHeight / 2.0);
        if (NO == controlButtonVisibilityAnimating && NO == controlButtonHidden) controlButton.frame = aFrame;
        //[controlButton setNeedsLayout];
        
        controlButtonShownFrame = aFrame;
        aFrame.origin.y = -aFrame.size.height - 15.0;
        controlButtonHiddenFrame = aFrame;
        
        [self rejiggerControlButtonLabel];
    }
    else if (UIInterfaceOrientationPortraitUpsideDown == actualInterfaceOrientation)
    {
        CGRect aFrame = controlButton.frame;
        aFrame.size.width = LIOLookIOManagerControlButtonMinWidth;
        aFrame.size.height = actualHeight;
        aFrame.origin.y = (screenSize.height / 2.0) - (actualHeight / 2.0);
        aFrame.origin.x = -2.0;
        if (NO == controlButtonVisibilityAnimating && NO == controlButtonHidden) controlButton.frame = aFrame;
        //[controlButton setNeedsLayout];
        
        controlButtonShownFrame = aFrame;
        aFrame.origin.x = -aFrame.size.width - 10.0;
        controlButtonHiddenFrame = aFrame;
        
        [self rejiggerControlButtonLabel];
    }
    else // Landscape, home button right
    {
        CGRect aFrame = controlButton.frame;
        aFrame.size.width = actualHeight;
        aFrame.size.height = LIOLookIOManagerControlButtonMinWidth;
        aFrame.origin.y = screenSize.height - LIOLookIOManagerControlButtonMinWidth + 2.0;
        aFrame.origin.x = (screenSize.width / 2.0) - (actualHeight / 2.0);
        if (NO == controlButtonVisibilityAnimating && NO == controlButtonHidden) controlButton.frame = aFrame;
        //[controlButton setNeedsLayout];
        
        controlButtonShownFrame = aFrame;
        aFrame.origin.y = screenSize.height + 10.0;
        controlButtonHiddenFrame = aFrame;
        
        [self rejiggerControlButtonLabel];
    }
    
    //[controlButton setNeedsLayout];
    [controlButton setNeedsDisplay];
}

- (void)rejiggerSquareControlButtonFrame
{
    if (squareControlButton.isDragging)
        return;
    
    if (NO == [squareControlButton.superview isKindOfClass:[UIWindow class]])
        return;
    
    UIWindow *buttonWindow = (UIWindow *)squareControlButton.superview;
    CGSize screenSize = [buttonWindow bounds].size;
    actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (UIInterfaceOrientationPortrait == actualInterfaceOrientation)
    {
        squareControlButton.transform = CGAffineTransformIdentity;
        dragToDeleteView.transform = CGAffineTransformIdentity;
        
    }
    else if (UIInterfaceOrientationLandscapeLeft == actualInterfaceOrientation)
    {
        squareControlButton.transform = CGAffineTransformMakeRotation(-90.0 * (M_PI / 180.0));
        dragToDeleteView.transform = CGAffineTransformMakeRotation(-90.0 * (M_PI / 180.0));
    }
    else if (UIInterfaceOrientationPortraitUpsideDown == actualInterfaceOrientation)
    {
        squareControlButton.transform = CGAffineTransformMakeRotation(-180.0 * (M_PI / 180.0));
        dragToDeleteView.transform = CGAffineTransformMakeRotation(-180.0 * (M_PI / 180.0));
    }
    else // Landscape, home button right
    {
        squareControlButton.transform = CGAffineTransformMakeRotation(-270.0 * (M_PI / 180.0));
        dragToDeleteView.transform = CGAffineTransformMakeRotation(-270.0 * (M_PI / 180.0));
    }
    
    [squareControlButton layoutSubviews];
    
    CGFloat buttonHeight = LIOLookIOManagerSquareControlButtonSize;
    CGFloat buttonWidth = LIOLookIOManagerSquareControlButtonSize;
    // Manually position the control button. Ugh.
    CGRect aFrame = squareControlButton.frame;

    if (UIInterfaceOrientationPortrait == actualInterfaceOrientation)
    {
        aFrame.origin.y = squareControlButton.position.y;
        aFrame.origin.x = squareControlButton.position.x;
        aFrame.size.width = buttonWidth + 4.0;
        aFrame.size.height = buttonHeight;
        
        if (NO == controlButtonVisibilityAnimating && NO == controlButtonHidden) squareControlButton.frame = aFrame;
        
        dragToDeleteView.frame = CGRectMake(0, buttonWindow.bounds.size.height, buttonWindow.bounds.size.width, 110);

        controlButtonShownFrame = aFrame;
        if (squareControlButton.isAttachedToRight)
            aFrame.origin.x = screenSize.width + 10.0;
        else
            aFrame.origin.x = -10.0 - buttonWidth;
        controlButtonHiddenFrame = aFrame;
    }
    else if (UIInterfaceOrientationLandscapeLeft == actualInterfaceOrientation) // Home button left
    {
        aFrame.origin.y = squareControlButton.position.y;
        aFrame.origin.x = squareControlButton.position.x;
        aFrame.size.width = buttonWidth;
        aFrame.size.height = buttonHeight + 4.0;

        if (NO == controlButtonVisibilityAnimating && NO == controlButtonHidden) squareControlButton.frame = aFrame;
        
        dragToDeleteView.frame = CGRectMake(buttonWindow.bounds.size.width, 0, 110, buttonWindow.bounds.size.height);

        controlButtonShownFrame = aFrame;
        if (squareControlButton.isAttachedToRight)
            aFrame.origin.y = -aFrame.size.height - 10.0;
        else
            aFrame.origin.y = screenSize.height + 10.0;
        controlButtonHiddenFrame = aFrame;
    }
    else if (UIInterfaceOrientationPortraitUpsideDown == actualInterfaceOrientation)
    {
        aFrame.origin.y = squareControlButton.position.y;
        aFrame.origin.x = squareControlButton.position.x;
        aFrame.size.width = buttonWidth + 4.0;
        aFrame.size.height = buttonHeight;

        if (NO == controlButtonVisibilityAnimating && NO == controlButtonHidden) squareControlButton.frame = aFrame;

        dragToDeleteView.frame = CGRectMake(10, -110, buttonWindow.bounds.size.width, 110);

        controlButtonShownFrame = aFrame;
        if (squareControlButton.isAttachedToRight)
            aFrame.origin.x = screenSize.width + 10.0;
        else
            aFrame.origin.x = -10 - buttonWidth;

        controlButtonHiddenFrame = aFrame;
    }
    else // Landscape, home button right
    {
        aFrame.origin.y = squareControlButton.position.y;
        aFrame.origin.x = squareControlButton.position.x;
        aFrame.size.width = buttonWidth;
        aFrame.size.height = buttonHeight + 4.0;

        if (NO == controlButtonVisibilityAnimating && NO == controlButtonHidden) squareControlButton.frame = aFrame;
        
        dragToDeleteView.frame = CGRectMake(-110, 0, 110, buttonWindow.bounds.size.height);

        controlButtonShownFrame = aFrame;
        if (squareControlButton.isAttachedToRight)
            aFrame.origin.y = screenSize.height + 10.0;
        else
            aFrame.origin.y = -aFrame.size.height - 10.0;
        controlButtonHiddenFrame = aFrame;
    }

    [squareControlButton setNeedsDisplay];
    [dragToDeleteView setNeedsLayout];
}

- (void)dragSquareControlButton:(id)sender {
    UIPanGestureRecognizer *panGestureRecognizer = (UIPanGestureRecognizer*)sender;
    UIWindow *buttonWindow = (UIWindow *)squareControlButton.superview;
    actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    CGPoint translatedPoint = [panGestureRecognizer translationInView:buttonWindow];
    
    if ([panGestureRecognizer state] == UIGestureRecognizerStateBegan) {
        squareControlButton.isDragging = YES;
        
        controlButtonPanX = [[sender view] center].x;
        controlButtonPanY = [[sender view] center].y;
        
        [dragToDeleteView presentDeleteArea];
        [squareControlButton dismissLabelWithAnimation:LIOSquareControlButtonViewAnimationFadeOut];
    }
    
    translatedPoint = CGPointMake(controlButtonPanX+translatedPoint.x, controlButtonPanY+translatedPoint.y);
    
    [[sender view] setCenter:translatedPoint];
    CGRect smallerFrame = dragToDeleteView.frame;
    smallerFrame.origin.x += buttonWindow.bounds.size.width/2 - dragToDeleteView.bounds.size.height/2;
    smallerFrame.size.width = dragToDeleteView.bounds.size.height;
    
    if (CGRectContainsPoint(dragToDeleteView.frame, translatedPoint)) {
        if (!dragToDeleteView.isZoomedIn)
            [dragToDeleteView zoomInOnDeleteArea];
    } else {
        if (dragToDeleteView.isZoomedIn)
            [dragToDeleteView zoomOutOfDeleteArea];
    }

    if ([panGestureRecognizer state] == UIGestureRecognizerStateEnded) {
        if (dragToDeleteView.isZoomedIn) {
            [UIView animateWithDuration:0.2 animations:^{
                CGRect frame = squareControlButton.frame;
                frame.size = CGSizeMake(0, 0);
                squareControlButton.frame = frame;
                squareControlButton.alpha = 0.0;
                
                squareControlButton.center = dragToDeleteView.center;
            } completion:^(BOOL finished) {
                [dragToDeleteView dismissDeleteArea];
                squareControlButton.isDragging = NO;
            }];
            
        } else {
            squareControlButton.isDragging = NO;
            [dragToDeleteView dismissDeleteArea];
            
            if (actualInterfaceOrientation == UIInterfaceOrientationPortrait) {
                // Check to see if user has attached the button to the right side
                if (translatedPoint.x > (buttonWindow.bounds.size.width - squareControlButton.frame.size.width - 10)) {
                    CGPoint position = squareControlButton.position;
                    CGFloat buttonWidth = LIOLookIOManagerSquareControlButtonSize;
                    position.x = buttonWindow.bounds.size.width - buttonWidth + 2.0;
                    position.y = translatedPoint.y - squareControlButton.bounds.size.height/2;
                    squareControlButton.position = position;
                    
                    squareControlButton.isAttachedToRight = YES;
                }
            
                // Check to see if user has attached the button to the left side
                if (translatedPoint.x < (squareControlButton.frame.size.width + 10)) {
                    CGPoint position = squareControlButton.position;
                    position.x = -4.0;
                    position.y = translatedPoint.y - squareControlButton.bounds.size.height/2;
                    squareControlButton.position = position;
                    
                    squareControlButton.isAttachedToRight = NO;
                }
            }
            
            if (actualInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
                // Check to see if user has attached the button to the right side
                if (translatedPoint.x > (buttonWindow.bounds.size.width - squareControlButton.frame.size.width - 10)) {
                    CGPoint position = squareControlButton.position;
                    CGFloat buttonWidth = LIOLookIOManagerSquareControlButtonSize;
                    position.x = buttonWindow.bounds.size.width - buttonWidth + 2.0;
                    position.y = translatedPoint.y - squareControlButton.bounds.size.height/2;
                    squareControlButton.position = position;
                    
                    squareControlButton.isAttachedToRight = YES;
                }
                
                // Check to see if user has attached the button to the left side
                if (translatedPoint.x < (squareControlButton.frame.size.width + 10)) {
                    CGPoint position = squareControlButton.position;
                    position.x = -4.0;
                    position.y = translatedPoint.y - squareControlButton.bounds.size.height/2;
                    squareControlButton.position = position;
                    
                    squareControlButton.isAttachedToRight = NO;
                }
            }
            
            if (actualInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
                // Check to see if user has attached the button to the right side
                if (translatedPoint.y > (buttonWindow.bounds.size.height - squareControlButton.frame.size.height - 10)) {
                    CGPoint position = squareControlButton.position;
                    CGFloat buttonWidth = LIOLookIOManagerSquareControlButtonSize;
                    position.y = buttonWindow.bounds.size.height - buttonWidth + 2.0;
                    position.x = translatedPoint.x - squareControlButton.bounds.size.height/2;
                    squareControlButton.position = position;
                    
                    squareControlButton.isAttachedToRight = YES;
                }
                
                // Check to see if user has attached the button to the left side
                if (translatedPoint.y < (squareControlButton.frame.size.width + 10)) {
                    CGPoint position = squareControlButton.position;
                    position.y = -6.0;
                    position.x = translatedPoint.x - squareControlButton.bounds.size.height/2;
                    squareControlButton.position = position;
                    
                    squareControlButton.isAttachedToRight = NO;
                }
            }
            
            if (actualInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
                // Check to see if user has attached the button to the right side
                if (translatedPoint.y > (buttonWindow.bounds.size.height - squareControlButton.frame.size.height - 10)) {
                    CGPoint position = squareControlButton.position;
                    CGFloat buttonWidth = LIOLookIOManagerSquareControlButtonSize;
                    position.y = buttonWindow.bounds.size.height - buttonWidth + 2.0;
                    position.x = translatedPoint.x - squareControlButton.bounds.size.height/2;
                    squareControlButton.position = position;
                    
                    squareControlButton.isAttachedToRight = NO;
                }
                
                // Check to see if user has attached the button to the left side
                if (translatedPoint.y < (squareControlButton.frame.size.width + 10)) {
                    CGPoint position = squareControlButton.position;
                    position.y = -6.0;
                    position.x = translatedPoint.x - squareControlButton.bounds.size.height/2;
                    squareControlButton.position = position;
                    
                    squareControlButton.isAttachedToRight = YES;
                }
            }

            [UIView animateWithDuration:0.2 animations:^{
                [self rejiggerSquareControlButtonFrame];
            } completion:^(BOOL finished) {
            }];
        }
    }
}

- (void)takeScreenshotAndSetBlurImageView {
    if (blurImageView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIGraphicsBeginImageContext(previousKeyWindow.bounds.size);
            blurImageView.hidden = YES;
            [previousKeyWindow.layer renderInContext:UIGraphicsGetCurrentContext()];
            blurImageView.hidden = NO;
            UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            [blurImageView setImageAndBlur:viewImage];
        });
    }
}

- (void)rejiggerWindows
{
    for (UIWindow *window in [[UIApplication sharedApplication] windows])
        [window endEditing:YES];
    
    if (altChatViewController || interstitialViewController)
    {
        if (nil == previousKeyWindow)
        {
            if (mainWindow)
            {
                previousKeyWindow = mainWindow;
                
                LIOLog(@"Got key window from mainWindow.");
            }
            else if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManagerMainWindowForHostApp:)])
            {
                previousKeyWindow = [delegate lookIOManagerMainWindowForHostApp:self];
                mainWindow = [previousKeyWindow retain];
                
                LIOLog(@"Got host app's key window from delegate: 0x%08X", (unsigned int)previousKeyWindow);
            }
            else if ([[[UIApplication sharedApplication] keyWindow] isKindOfClass:[UIWindow class]])
            {
                previousKeyWindow = [[UIApplication sharedApplication] keyWindow];
                mainWindow = [previousKeyWindow retain];
                
                LIOLog(@"Got host app's key window from UIApplication: 0x%08X", (unsigned int)previousKeyWindow);
            }
            else
            {
                [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"Could not find host app's key window! Behavior from this point on is undefined."];
            }
            
            blurView = [[DRNRealTimeBlurView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
            blurView.renderStatic = YES;
            blurView.alpha = 0.0;
            blurView.tint = [UIColor colorWithRed:68.0/255.0 green:68.0/255.0 blue:68.0/255.0 alpha:1.0];
            [previousKeyWindow addSubview:blurView];

            [UIView animateWithDuration:0.15 animations:^{
                blurView.alpha = 1.0;
            }];
            
            LIOLog(@"Making LookIO window key and visible: 0x%08X", (unsigned int)lookioWindow);
            [lookioWindow makeKeyAndVisible];
        }
    }
    else
    {
        LIOLog(@"Hiding LookIO (0x%08X), restoring 0x%08X", (unsigned int)lookioWindow, (unsigned int)previousKeyWindow);
        
        shouldLockOrientation = NO;
        
        lookioWindow.hidden = YES;
        [lookioWindow.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        cursorView.hidden = clickView.hidden = NO == screenshotsAllowed || cursorEnded;
        
        [previousKeyWindow makeKeyWindow];
        previousKeyWindow = nil;
        
        if (selectedChatTheme == kLPChatThemeFlat) {
            [UIView animateWithDuration:0.15 animations:^{
                blurView.alpha = 0.0;
            } completion:^(BOOL finished) {
                [blurView removeFromSuperview];
                [blurView release];
                blurView = nil;
            }];
        }
        
        [self refreshControlButtonVisibility];
        
        if (NO == [[UIApplication sharedApplication] isStatusBarHidden])
        {
            if (screenshotsAllowed)
            {
                statusBarUnderlay.hidden = NO;
                [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
            }
            else
            {
                statusBarUnderlay.hidden = YES;
                [[UIApplication sharedApplication] setStatusBarStyle:originalStatusBarStyle];
            }
        }
    }
}

- (UIImage *)captureScreen
{
    // CAUTION: Called on a non-main thread!
    statusBarUnderlayBlackout.hidden = NO;
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    UIGraphicsBeginImageContextWithOptions(screenSize, NO, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Iterate over every window from back to front
    for (UIWindow *window in [[UIApplication sharedApplication] windows]) 
    {
        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen])
        {
            // -renderInContext: renders in the coordinate space of the layer,
            // so we must first apply the layer's geometry to the graphics context
            CGContextSaveGState(context);
            // Center the context around the window's anchor point
            CGContextTranslateCTM(context, [window center].x, [window center].y);
            // Apply the window's transform about the anchor point
            CGContextConcatCTM(context, [window transform]);
            // Offset by the portion of the bounds left of and above the anchor point
            CGContextTranslateCTM(context,
                                  -[window bounds].size.width * [[window layer] anchorPoint].x,
                                  -[window bounds].size.height * [[window layer] anchorPoint].y);
            
            // Render the layer hierarchy to the current context
            [[window layer] renderInContext:context];
            
            // Restore the context
            CGContextRestoreGState(context);
        }
    }

    // Retrieve the screenshot image
    UIImage *screenshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // CAUTION: Called on a non-main thread!
    statusBarUnderlayBlackout.hidden = YES;
    
    return screenshotImage;
}

- (NSString *)nextGUID
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
    NSString *newUUID = (NSString *)uuidString;
    CFRelease(uuid);
    return [newUUID autorelease];
}

- (void)screenCaptureTimerDidFire:(NSTimer *)aTimer
{
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (keyWindow != lookioWindow)
    {
        if (controlButton)
            [keyWindow bringSubviewToFront:controlButton];
        
        if (squareControlButton)
            [keyWindow bringSubviewToFront:squareControlButton];

        [clickView removeFromSuperview];
        if (clickView)
        {
            [keyWindow addSubview:clickView];
            [keyWindow bringSubviewToFront:clickView];
        }
        
        [cursorView removeFromSuperview];
        if (cursorView)
        {
            [keyWindow addSubview:cursorView];
            [keyWindow bringSubviewToFront:cursorView];
        }
    }
    
    if (NO == socketConnected || waitingForScreenshotAck || NO == introduced || YES == enqueued || NO == screenshotsAllowed || altChatViewController || interstitialViewController)
    {
        return;
    }
    
    if (UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
    {
        return;
    }
    
    if (NO == [[UIApplication sharedApplication] isStatusBarHidden])
    {
        [statusBarUnderlay.superview bringSubviewToFront:statusBarUnderlay];
        [statusBarUnderlayBlackout.superview bringSubviewToFront:statusBarUnderlayBlackout];
        
        [UIView animateWithDuration:LIOLookIOManagerScreenCaptureInterval
                              delay:0.0
                            options:(UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction)
                         animations:^{
                             statusBarUnderlay.backgroundColor = [UIColor colorWithRed:0.0 green:(100.0/256.0) blue:(137.0/256.0) alpha:1.0];
                         }
                         completion:^(BOOL finished) {
                             [UIView animateWithDuration:LIOLookIOManagerScreenCaptureInterval
                                                   delay:0.0
                                                 options:(UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction)
                                              animations:^{
                                                  statusBarUnderlay.backgroundColor = [UIColor colorWithRed:(8.0/256.0) green:(141.0/256.0) blue:(178.0/256.0) alpha:1.0];
                                              }
                                              completion:^(BOOL finished) {
                                              }];
                         }];
        
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        UIImage *screenshotImage = [self captureScreen];
        CGSize screenshotSize = screenshotImage.size;
        NSData *screenshotData = UIImageJPEGRepresentation(screenshotImage, 0.0);
        [screenshotData retain];
        [pool release];
        
        unsigned long currentHash = crc32(0L, Z_NULL, 0);
        currentHash = crc32(currentHash, [screenshotData bytes], [screenshotData length]);
        
        if (0 == previousScreenshotHash || currentHash != previousScreenshotHash)
        {
            previousScreenshotHash = currentHash;
            
            NSString *orientationString = @"???";
            if (UIInterfaceOrientationPortrait == actualInterfaceOrientation)
                orientationString = @"portrait";
            else if (UIInterfaceOrientationPortraitUpsideDown == actualInterfaceOrientation)
                orientationString = @"portrait_upsidedown";
            else if (UIInterfaceOrientationLandscapeRight == actualInterfaceOrientation)
                orientationString = @"landscape";
            else
                orientationString = @"landscape_upsidedown";
            
            NSTimeInterval timeSinceSharingStarted = [[NSDate date] timeIntervalSinceDate:screenSharingStartedDate];
            
            // screenshot:ver:time:orientation:w:h:datalen:[blarghle]
            NSString *header = [NSString stringWithFormat:@"screenshot:2:%f:%@:%d:%d:%lu:", timeSinceSharingStarted, orientationString, (int)screenshotSize.width, (int)screenshotSize.height, (unsigned long)[screenshotData length]];
            NSData *headerData = [header dataUsingEncoding:NSUTF8StringEncoding];
            
            NSMutableData *dataToSend = [NSMutableData data];
            [dataToSend appendData:headerData];
            [dataToSend appendData:screenshotData];
            [dataToSend appendData:messageSeparatorData];
            
            [screenshotData release];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                waitingForScreenshotAck = YES;

                [self sendScreenshotPacketWithData:dataToSend];
                
                LIOLog(@"\n\n[SCREENSHOT] Sent %dx%d %@ screenshot (%u bytes).\nHeader: %@\n\n", (int)screenshotSize.width, (int)screenshotSize.height, orientationString, [dataToSend length], header);
            });
        }
        else
        {
            [screenshotData release];
        }
    });
}

- (void)showInterstitialAnimated:(BOOL)animated
{
    if (interstitialViewController)
        return;
    
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    
    interstitialViewController = [[LIOInterstitialViewController alloc] initWithNibName:nil bundle:nil];
    interstitialViewController.delegate = self;
    [lookioWindow addSubview:interstitialViewController.view];
    [self rejiggerWindows];
    
    if (animated)
        [interstitialViewController performRevealAnimation];
    
    [[LIOBundleManager sharedBundleManager] findBundle];
}

- (void)showChatAnimated:(BOOL)animated
{
//    if (altChatViewController)
//        return;
    
    if (NO == [[LIOBundleManager sharedBundleManager] isAvailable])
    {
        [self showInterstitialAnimated:animated];
        return;
    }
    
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    
    altChatViewController = [[LIOAltChatViewController alloc] initWithNibName:nil bundle:nil];
    altChatViewController.delegate = self;
    altChatViewController.dataSource = self;
    altChatViewController.initialChatText = pendingChatText;
    
    lookioWindow.rootViewController = altChatViewController;
    [self rejiggerWindows];
    
    if (animated)
        [altChatViewController performRevealAnimationWithFadeIn:YES];
    
    [pendingChatText release];
    pendingChatText = nil;    
    
    if (introduced)
    {
        NSDictionary *chatUp = [NSDictionary dictionaryWithObjectsAndKeys:
                                                         @"chat_up", @"action",
                                                         nil];
        [self sendAdvisoryPacketWithDict:chatUp];
    }
    
    if (controlButtonType == kLPControlButtonSquare)
        [squareControlButton dismissLabelWithAnimation:LIOSquareControlButtonViewAnimationSlideIn];
    
    [self refreshControlButtonVisibility];
}

- (NSString *)chosenEndpoint
{
    return [overriddenEndpoint length] ? overriddenEndpoint : controlEndpoint;
}

# pragma 
# pragma mark Funnel Methods

-(void)updateAndReportFunnelState {    
    // For visit state, let's see if we can upgrade to hotlead
    if (currentFunnelState == LIOFunnelStateVisit) {
        // If the tab visibility is not always, let's first check that the devloper has set the chat to available.
        // If not, it should stay a visit
        if (1 != [lastKnownButtonVisibility intValue]) {
            if (customButtonChatAvailable) {
                // If the tab visibility is not always, but chat is available, this is a hotlead
                currentFunnelState = LIOFunnelStateHotlead;
                LIOLog(@"<FUNNEL STATE> Hotlead");
                [self sendFunnelPacketForState:currentFunnelState];
            }
        } else {
            // Or, if the tab is supposed to be shown, whether or not it is actually shown, it's a hotlead
            currentFunnelState = LIOFunnelStateHotlead;
            LIOLog(@"<FUNNEL STATE> Hotlead");
            [self sendFunnelPacketForState:currentFunnelState];
        }
    }
    
    // If we're at the hot lead state, let's check if we can upgrade to invitation, or downgrade to visit
    if (currentFunnelState == LIOFunnelStateHotlead) {        
        // If the tab visibility is not always, let's first check that the developer has reported that the invitation has been shown
        // If not, it should stay a hotlead
        // If chat has been disabled, downgrade to a visit
        if (1 != [lastKnownButtonVisibility intValue]) {
            if (!customButtonChatAvailable) {
                currentFunnelState = LIOFunnelStateVisit;
                LIOLog(@"<FUNNEL STATE> Visit");
                [self sendFunnelPacketForState:currentFunnelState];
            } else {
                if (customButtonInvitationShown) {
                    currentFunnelState = LIOFunnelStateInvitation;
                    LIOLog(@"<FUNNEL STATE> Invitation");
                    [self sendFunnelPacketForState:currentFunnelState];
                }
            }
        } else {
            if (!controlButtonHidden) {
                currentFunnelState = LIOFunnelStateInvitation;
                LIOLog(@"<FUNNEL STATE> Invitation");
                [self sendFunnelPacketForState:currentFunnelState];
            }
        }
    }

    // If we're at the invitation state, let's make sure we can maintain it
    if (currentFunnelState == LIOFunnelStateInvitation) {
        // If a chat started before invitation state was reached, it will be reported here.
        // We can return from the call ebcause it is the topmost state
        if (introPacketWasSent) {
            currentFunnelState = LIOFunnelStateClicked;
            LIOLog(@"<FUNNEL STATE> Clicked");
            [self sendFunnelPacketForState:currentFunnelState];
            return;
        }
        
        // If the tab visibility is not always, let's check if the developer:
        // Set chat to unavailable, making it a visit
        // Set invitation to not shown, making it a hotlead
        if (1 != [lastKnownButtonVisibility intValue]) {
            // If chat unavailable, it's a visit
            if (!customButtonChatAvailable) {
                currentFunnelState = LIOFunnelStateVisit;
                LIOLog(@"<FUNNEL STATE> Visit");
                [self sendFunnelPacketForState:currentFunnelState];
            } else {
                // If chat available, but invitation not shown, it's a hotlead
                // Otherwise, it stays an invitation
                if (!customButtonInvitationShown) {
                    currentFunnelState = LIOFunnelStateHotlead;
                    LIOLog(@"<FUNNEL STATE> Hotlead");
                    [self sendFunnelPacketForState:currentFunnelState];
                }
            }
        } else {
            // If tab availability is always, let's check if the tab is visible, otherwise downgrade to hotlead
            if (controlButtonHidden) {
                currentFunnelState = LIOFunnelStateHotlead;
                LIOLog(@"<FUNNEL STATE> Hotlead");
                [self sendFunnelPacketForState:currentFunnelState];
            }
        }
    }
    
    // If we're at the clicked lead state, and the chat has ended, let's downgrade it
    // We can return from each condition because there the final state is set here
    if (currentFunnelState == LIOFunnelStateClicked) {
        if (!introPacketWasSent) {
            // Case one - Tab is not visible, and the button is not being displayed, downgrade to a visit
            if (1 != [lastKnownButtonVisibility intValue]) {

                // If chat unavailable, it's a visit
                if (!customButtonChatAvailable) {
                    currentFunnelState = LIOFunnelStateVisit;
                    LIOLog(@"<FUNNEL STATE> Visit");
                    [self sendFunnelPacketForState:currentFunnelState];
                    return;
                }
                
                // If chat available, but invitation not shown, it's a hotlead
                if (!customButtonInvitationShown) {
                    currentFunnelState = LIOFunnelStateHotlead;
                    LIOLog(@"<FUNNEL STATE> Hotlead");
                    [self sendFunnelPacketForState:currentFunnelState];
                    return;
                }
                
                // Otherwise it's an invitation
                currentFunnelState = LIOFunnelStateInvitation;
                LIOLog(@"<FUNNEL STATE> Invitation");
                [self sendFunnelPacketForState:currentFunnelState];
                return;
            
            } else {
                // If tab is visible, it's an invitation, otherwise a hotlead
                if (!controlButtonHidden) {
                    currentFunnelState = LIOFunnelStateInvitation;
                    LIOLog(@"<FUNNEL STATE> Invitation");
                } else {
                    currentFunnelState = LIOFunnelStateHotlead;
                    LIOLog(@"<FUNNEL STATE> Hotlead");
                }
                
                [self sendFunnelPacketForState:currentFunnelState];
                return;
            }
        }
    }
}

# pragma
# pragma mark Visit API Methods

-(void)sendFunnelPacketForState:(LIOFunnelState)funnelState {
    [[LIOAnalyticsManager sharedAnalyticsManager] pumpReachabilityStatus];

    // Let's check if we are in the middle of a request, or disconnected,
    // otherwise queue this request until network returns or a new state is updated

    if (funnelRequestIsActive || (LIOAnalyticsManagerReachabilityStatusConnected != [LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)) {
        NSNumber* nextFunnelRequest = [NSNumber numberWithInt:funnelState];
        [funnelRequestQueue addObject:nextFunnelRequest];
        return;
    }    
    
    if (LIOAnalyticsManagerReachabilityStatusConnected != [LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)
    {
        
        return;        
    }

    
    funnelRequestIsActive = YES;
    
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
    
    // If not one these three value, nothing to report
    if ([currentStateString isEqualToString:@""])
        return;
    
    NSDictionary* buttonFunnelDict = [NSDictionary dictionaryWithObject:currentStateString forKey:@"current_state"];
    NSDictionary *funnelDict = [NSDictionary dictionaryWithObject:buttonFunnelDict forKey:@"button_funnel"];
    
    [[LPVisitAPIClient sharedClient] postPath:LIOLookIOManagerVisitFunnelRequestURL parameters:funnelDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
        if (responseObject)
            LIOLog(@"<FUNNEL> with data:%@ response: %@", funnelDict, responseObject);
        else
            LIOLog(@"<FUNNEL> with data:%@ success", funnelDict);
        
        funnelRequestIsActive = NO;
        if (funnelRequestQueue.count > 0) {
            NSNumber* nextFunnelState = [funnelRequestQueue objectAtIndex:0];
            [self sendFunnelPacketForState:[nextFunnelState intValue]];
            [funnelRequestQueue removeObjectAtIndex:0];
        }
    } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
        LIOLog(@"<FUNNEL> with data:%@ failure: %@", funnelDict, error);
        
        funnelRequestIsActive = NO;
        if (funnelRequestQueue.count > 0) {
            NSNumber* nextFunnelState = [funnelRequestQueue objectAtIndex:0];
            [self sendFunnelPacketForState:[nextFunnelState intValue]];
            [funnelRequestQueue removeObjectAtIndex:0];
        }
    }];
}

# pragma
# pragma mark Chat API v2 Methods

-(void)sendIntroPacket {
    introPacketWasSent = YES;
    [self updateAndReportFunnelState];
    
    LPChatAPIClient *chatClient = [LPChatAPIClient sharedClient];
    
    NSMutableArray *cookiesToDelete = [[[NSMutableArray alloc] init] autorelease];
    [cookiesToDelete addObjectsFromArray:[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:chatClient.baseURL]];
    for (NSHTTPCookie *cookie in cookiesToDelete)
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    
    NSDictionary *introDict = [self buildIntroDictionaryIncludingExtras:YES includingType:YES includingSurveyResponses:YES includingEvents:YES];
    [[LPChatAPIClient sharedClient] postPath:LIOLookIOManagerChatIntroRequestURL parameters:introDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
        
        if (responseObject)
            LIOLog(@"<INTRO> response: %@", responseObject);
        else
            LIOLog(@"<INTRO> success");        
        
        introduced = YES;
        enqueued = YES;
        
        NSDictionary* responseDict = (NSDictionary*)responseObject;
        [self saveChatCookies];
        [self parseAndSaveEngagementInfoPayload:responseDict];
    } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
        introPacketWasSent = NO;
        
        LIOLog(@"<INTRO> failure: %@", error);
        
        if (altChatViewController) {
            [altChatViewController bailOnSecondaryViews];
            [altChatViewController.view removeFromSuperview];
            [altChatViewController release];
            altChatViewController = nil;
            [self dismissBlurImageView:NO];
            
            [self rejiggerWindows];
        }
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.StartFailureAlertTitle")
                                                            message:LIOLocalizedString(@"LIOLookIOManager.StartFailureAlertBody")
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.StartFailureAlertButton"), nil];
        [alertView show];
        [alertView autorelease];
    }];
}

- (void)sendLinePacketWithMessage:(LIOChatMessage*)aMessage {
    if (chatEngagementId == nil) {
        LIOLog(@"<LINE> failure - no engagement ID");
        
        aMessage.sendingFailed = YES;
        if (altChatViewController)
            [altChatViewController reloadMessages];
        else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.FailedMessageSendTitle")
                                                                message:LIOLocalizedString(@"LIOLookIOManager.FailedMessageSendBody")
                                                               delegate:nil
                                                      cancelButtonTitle:LIOLocalizedString(@"LIOLookIOManager.FailedMessageSendButton")
                                                      otherButtonTitles:nil];
            [alertView show];
            [alertView autorelease];
        }
        
        return;
    }
    
    NSDictionary *lineDict = [NSDictionary dictionaryWithObjectsAndKeys:@"line", @"type", aMessage.text, @"text", aMessage.clientLineId, @"client_line_id", nil];
    NSString* lineRequestUrl = [NSString stringWithFormat:@"%@/%@", LIOLookIOManagerChatLineRequestURL, chatEngagementId];

    [[LPChatAPIClient sharedClient] postPath:lineRequestUrl parameters:lineDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
        if (responseObject)
            LIOLog(@"<LINE> response: %@", responseObject);
        else
            LIOLog(@"<LINE> success");

        // If this is a resending of a failed message, let's update it and refresh the tableview
        if (aMessage.sendingFailed) {
            aMessage.sendingFailed = NO;
            if (altChatViewController)
                [altChatViewController reloadMessages];
        }
        
        
    } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
        LIOLog(@"<LINE> failure: %@", error);
        
        // If we get a 404, let's terminate the engagement
        if (operation.responseCode == 404) {

            if (altChatViewController) {
                [self altChatViewControllerWantsSessionTermination:altChatViewController];
            }
            else {
                [sseManager disconnect];
                outroReceived = YES;
                [self reset];
            }
            
            [self dismissDismissibleAlertView];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertTitle")
                                                                    message:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertBody")
                                                                   delegate:nil
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertButton"), nil];
            double delayInSeconds = 1.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [alertView show];
                [alertView autorelease];
            });
        } else {
            aMessage.sendingFailed = YES;
            if (altChatViewController)
                [altChatViewController reloadMessages];
            else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.FailedMessageSendTitle")
                                                            message:LIOLocalizedString(@"LIOLookIOManager.FailedMessageSendBody")
                                                           delegate:nil
                                                  cancelButtonTitle:LIOLocalizedString(@"LIOLookIOManager.FailedMessageSendButton")
                                                  otherButtonTitles:nil];
                [alertView show];
                [alertView autorelease];
            }
        }
    }];
}

-(void)sendOutroPacket {
    if (chatEngagementId == nil) {
        LIOLog(@"<OUTRO> failure - no engagement ID");
        [sseManager disconnect];        
        return;
    }
    
    NSDictionary *outroDict = [NSDictionary dictionaryWithObjectsAndKeys:@"outro", @"type", nil];
    NSString* outroRequestUrl = [NSString stringWithFormat:@"%@/%@", LIOLookIOManagerChatOutroRequestURL, chatEngagementId];

    [[LPChatAPIClient sharedClient] postPath:outroRequestUrl parameters:outroDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
        if (responseObject)
            LIOLog(@"<OUTRO> response: %@", responseObject);
        else
            LIOLog(@"<OUTRO> success");
        
        if (sseManager)
            [sseManager disconnect];
    } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
        LIOLog(@"<OUTRO> failure: %@", error);
        if (sseManager)
            [sseManager disconnect];
    }];
}

-(void)sendCapabilitiesPacket {
    if (chatEngagementId == nil) {
        LIOLog(@"<CAPABILITIES> failure - no engagement ID");
        return;
    }
    
    shouldSendCapabilitiesPacket = NO;
    
    NSArray *capsArray = [NSArray arrayWithObjects:@"show_leavemessage", @"show_infomessage", nil];
    NSDictionary *capsDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              capsArray, @"capabilities",
                              nil];
    NSString* capsRequestUrl = [NSString stringWithFormat:@"%@/%@", LIOLookIOManagerChatCapabilitiesRequestURL, chatEngagementId];

    [[LPChatAPIClient sharedClient] postPath:capsRequestUrl parameters:capsDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
        if (responseObject)
            LIOLog(@"<CAPABILITIES> response: %@", responseObject);
        else
            LIOLog(@"<CAPABILITIES> success");
        
    } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
        LIOLog(@"<CAPABILITIES> failure: %@", error);
        
        failedCapabilitiesCount += 1;
        if (failedCapabilitiesCount < 3)
            shouldSendCapabilitiesPacket = YES;
    }];
}

-(void)sendFeedbackPacketWithDict:(NSDictionary*)feedbackDict {
    if (chatEngagementId == nil) {
        LIOLog(@"<FEEDBACK> failure - no engagement ID");
        return;
    }
    
    NSString* feedbackRequestUrl = [NSString stringWithFormat:@"%@/%@", LIOLookIOManagerChatFeedbackRequestURL, chatEngagementId];

    [[LPChatAPIClient sharedClient] postPath:feedbackRequestUrl parameters:feedbackDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
        if (responseObject)
            LIOLog(@"<FEEDBACK> with data:%@ response: %@", feedbackDict, responseObject);
        else
            LIOLog(@"<FEEDBACK> success");
        
    } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
        LIOLog(@"<FEEDBACK> failure: %@", error);
    }];
}

-(void)sendSurveyPacketWithDict:(NSDictionary*)surveyDict withType:(LIOSurveyManagerSurveyType)type {
    if (chatEngagementId == nil) {
        LIOLog(@"<SURVEY> failure - no engagement ID");
        return;
    }
    
    NSString* surveyRequestUrl = [NSString stringWithFormat:@"%@/%@", LIOLookIOManagerChatSurveyRequestURL, chatEngagementId];
    
    [[LPChatAPIClient sharedClient] postPath:surveyRequestUrl parameters:surveyDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
        if (responseObject)
            LIOLog(@"<SURVEY> with data:%@ response: %@", surveyDict, responseObject);
        else
            LIOLog(@"<SURVEY> success");
        
    } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
        LIOLog(@"<SURVEY> failure: %@", error);
        
        // If submitting the survey fails, and it's a pre chat survey, it's better to start the chat without the survey than ending the session
        if (type == LIOSurveyManagerSurveyTypePre) {
            if (altChatViewController)
                [altChatViewController engagementDidStart];
        }
    }];
}

-(void)sendChatHistoryPacketWithDict:(NSDictionary*)emailDict {
    if (chatEngagementId == nil) {
        LIOLog(@"<CHAT_HISTORY> failure - no engagement ID");
        return;
    }
    
    shouldSendChatHistoryPacket = NO;
    
    NSString* chatHistoryRequestUrl = [NSString stringWithFormat:@"%@/%@", LIOLookIOManagerChatHistoryRequestURL, chatEngagementId];

    [[LPChatAPIClient sharedClient] postPath:chatHistoryRequestUrl parameters:emailDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
        if (responseObject)
            LIOLog(@"<CHAT_HISTORY> response: %@", responseObject);
        else
            LIOLog(@"<CHAT_HISTORY> success");
    } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
        LIOLog(@"<CHAT_HISTORY> failure: %@", error);
        
        failedChatHistoryCount += 1;
        // Retry if this is not an empty dictionary request, and if we haven't surpassed our retry limit
        if (failedChatHistoryCount < 3 && emailDict.allKeys.count > 0) {
            shouldSendChatHistoryPacket = YES;
            
            if (failedChatHistoryDict) {
                [failedChatHistoryDict release];
                failedChatHistoryDict = nil;
            }
            failedChatHistoryDict = [emailDict retain];
        }
    }];
}

-(void)sendAdvisoryPacketWithDict:(NSDictionary*)advisoryDict {
    if (chatEngagementId == nil) {
        LIOLog(@"<ADVISORY> failure - no engagement ID");
        return;
    }
    
    NSString* advisoryRequestUrl = [NSString stringWithFormat:@"%@/%@", LIOLookIOManagerChatAdvisoryRequestURL, chatEngagementId];

    [[LPChatAPIClient sharedClient] postPath:advisoryRequestUrl parameters:advisoryDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
        if (responseObject)
            LIOLog(@"<ADVISORY> with data %@ response: %@", advisoryDict, responseObject);
        else
            LIOLog(@"<ADVISORY> with data %@ success", advisoryDict);
    } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
        LIOLog(@"<ADVISORY> with data %@ failure: %@", advisoryDict, error);
    }];    
}

-(void)sendCustomVarsPacketWithDict:(NSDictionary*)customVarsDict {
    if (chatEngagementId == nil) {
        LIOLog(@"<CUSTOM_VARS> failure - no engagement ID");
        return;
    }
    
    NSString* customVarsRequestUrl = [NSString stringWithFormat:@"%@/%@", LIOLookIOManagerCustomVarsRequestURL, chatEngagementId];
    [[LPChatAPIClient sharedClient] postPath:customVarsRequestUrl parameters:customVarsDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
        if (responseObject)
            LIOLog(@"<CUSTOM_VARS> with data %@ response: %@", customVarsDict, responseObject);
        else
            LIOLog(@"<CUSTOM_VARS> with data %@ success", customVarsDict);        
    } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
        LIOLog(@"<CUSTOM_VARS> with data %@ failure: %@", customVarsDict, error);
    }];
}

-(void)sendPermissionPacketWithAsset:(NSString*)asset granted:(BOOL)granted {
    if (chatEngagementId == nil) {
        LIOLog(@"<PERMISSION> failure - no engagement ID");
        return;
    }
    
    NSString* grantedString = granted ? @"granted" : @"revoked";
    NSDictionary *permissionDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                    grantedString, @"permission",
                                    asset, @"asset",
                                    nil];

    NSString* permissionRequestUrl = [NSString stringWithFormat:@"%@/%@", LIOLookIOManagerChatPermissionRequestURL, chatEngagementId];
    [[LPChatAPIClient sharedClient] postPath:permissionRequestUrl parameters:permissionDict success:^(LPHTTPRequestOperation *operation, id responseObject) {
        if (responseObject)
            LIOLog(@"<PERMISSION> with data %@ response: %@", permissionDict, responseObject);
        else
            LIOLog(@"<PERMISSION> with data %@ success", permissionDict);
    } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
        LIOLog(@"<PERMISSION> with data %@ failure: %@", permissionDict, error);
    }];
}

-(void)sendScreenshotPacketWithData:(NSData*)screenshotData {
    if (chatEngagementId == nil) {
        waitingForScreenshotAck = NO;
        LIOLog(@"<SCREENSHOT> failure - no engagement ID");
        return;
    }
    
    NSString* screenshotRequestUrl = [NSString stringWithFormat:@"%@/%@", LIOLookIOManagerChatScreenshotRequestURL, chatEngagementId];
    [[LPChatAPIClient sharedClient] postPath:screenshotRequestUrl data:screenshotData success:^(LPHTTPRequestOperation *operation, id responseObject) {
        waitingForScreenshotAck = NO;
        if (responseObject)
            LIOLog(@"<SCREENSHOT> with response: %@", responseObject);
        else
            LIOLog(@"<SCREENSHOT> success");
    } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
        waitingForScreenshotAck = NO;
        
        LIOLog(@"<SCREENSHOT> with data %@ failure: %@", screenshotData, error);
    }];
}

- (void)sendMediaPacketWithMessage:(LIOChatMessage*)aMessage
{
    if (chatEngagementId == nil) {
        aMessage.sendingFailed = YES;
        
        if (altChatViewController) {
            [altChatViewController reloadMessages];
        }
        else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.FailedAttachmentSendTitle")
                                                                message:LIOLocalizedString(@"LIOLookIOManager.FailedAttachmentSendBody")
                                                               delegate:nil
                                                      cancelButtonTitle:@"LIOLookIOManager.FailedAttachmentSendButton"
                                                      otherButtonTitles:nil];
            [alertView show];
            [alertView autorelease];
        }
        
        LIOLog(@"<PHOTO UPLOAD> failure - no engagement ID");
        return;
    }
    
    NSData *attachmentData = [[LIOMediaManager sharedInstance] mediaDataWithId:aMessage.attachmentId];
    if (attachmentData) {
        NSString *mimeType = [[LIOMediaManager sharedInstance] mimeTypeFromId:aMessage.attachmentId];
        
        NSString *sessionId = chatEngagementId;
        if (0 == [sessionId length])
            return;
        
        NSString *bundleId = [self bundleId];
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
            if (aMessage.sendingFailed) {
                aMessage.sendingFailed = NO;
                if (altChatViewController)
                    [altChatViewController reloadMessages];
            }
            if (responseObject)
                LIOLog(@"<PHOTO UPLOAD> with response: %@", responseObject);
            else
                LIOLog(@"<PHOTO UPLOAD> success");
            
        } failure:^(LPHTTPRequestOperation *operation, NSError *error) {
            aMessage.sendingFailed = YES;
            
            if (altChatViewController) {
                [altChatViewController reloadMessages];
                
                if (operation.responseCode == 413) {
                    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOAltChatViewController.AttachFailureLargeFileTitle")
                                                                        message:LIOLocalizedString(@"LIOAltChatViewController.AttachFailureLargeFileBody") delegate:nil
                                                              cancelButtonTitle:LIOLocalizedString(@"LIOAltChatViewController.AttachFailureLargeFileButton")
                                                              otherButtonTitles:nil];
                    
                    [alertView show];
                    [alertView release];
                }
            }
            else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.FailedAttachmentSendTitle")
                                                                    message:LIOLocalizedString(@"LIOLookIOManager.FailedAttachmentSendBody")
                                                                   delegate:nil
                                                          cancelButtonTitle:@"LIOLookIOManager.FailedAttachmentSendButton"
                                                          otherButtonTitles:nil];
                [alertView show];
                [alertView autorelease];
            }
            
            LIOLog(@"<PHOTO UPLOAD> with failure: %@", error);
        }];
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

- (void)saveChatCookies {
    if (chatCookies) {
        [chatCookies removeAllObjects];
        [chatCookies release];
        chatCookies = nil;
    }
    
    chatCookies = [[[NSMutableArray alloc] init] retain];
    
    NSArray *all = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[LPChatAPIClient sharedClient].baseURL];
    for (NSHTTPCookie *cookie in all) {
        [chatCookies addObject:cookie];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *cookieData = [NSKeyedArchiver archivedDataWithRootObject:chatCookies];
    [userDefaults setObject:cookieData forKey:LIOLookIOManagerLastKnownChatCookiesKey];
    [userDefaults synchronize];

}

-(void)parseAndSaveEngagementInfoPayload:(NSDictionary*)params {
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
        chatEngagementId = [[resolvedPayload objectForKey:@"engagement_id"] retain];
        chatSSEUrlString = [[resolvedPayload objectForKey:@"sse_url"] retain];
        chatPostUrlString = [[resolvedPayload objectForKey:@"post_url"] retain];
        chatMediaUrlString = [[resolvedPayload objectForKey:@"media_url"] retain];
        
        [self setupAPIClientBaseURL];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:chatEngagementId forKey:LIOLookIOManagerLastKnownEngagementIdKey];
        [userDefaults setObject:chatSSEUrlString forKey:LIOLookIOManagerLastKnownChatSSEUrlStringKey];
        [userDefaults setObject:chatPostUrlString forKey:LIOLookIOManagerLastKnownChatPostUrlString];
        [userDefaults setObject:chatMediaUrlString forKey:LIOLookIOManagerLastKnownChatMediaUrlString];
        
        [userDefaults synchronize];
        
        [self connectSSESocket];
    }
}

- (void)setupAPIClientBaseURL {
    LPChatAPIClient *chatAPIClient = [LPChatAPIClient sharedClient];
    chatAPIClient.baseURL = [NSURL URLWithString:chatPostUrlString];
    
    LPMediaAPIClient *mediaAPIClient = [LPMediaAPIClient sharedClient];
    mediaAPIClient.baseURL = [NSURL URLWithString:chatMediaUrlString];
    
    // Let's remove any cookies from previous sessions
    NSMutableArray *cookiesToDelete = [[[NSMutableArray alloc] init] autorelease];
    [cookiesToDelete addObjectsFromArray:[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:chatAPIClient.baseURL]];
    [cookiesToDelete addObjectsFromArray:[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:mediaAPIClient.baseURL]];
    for (NSHTTPCookie *cookie in cookiesToDelete)
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    
    for (NSHTTPCookie *cookie in chatCookies) {
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

- (void)connectSSESocket {
    if (sseManager) {
        [sseManager reset];
        [sseManager release];
        sseManager = nil;
    }
    
    NSNumber *portToUse = [NSNumber numberWithInteger:443];
    NSURL* url = [NSURL URLWithString:chatSSEUrlString];
    if (url.port != 0)
        portToUse = url.port;
    
    BOOL sseSocketUsesTLS = YES;
    if ([url.scheme isEqualToString:@"http"])
        sseSocketUsesTLS = NO;
    
    sseManager = [[LPSSEManager alloc] initWithHost:url.host port:portToUse urlEndpoint:[NSString stringWithFormat:@"%@/%@", url.path, chatEngagementId] usesTLS:sseSocketUsesTLS lastEventId:chatLastEventId cookies:[NSArray arrayWithArray:chatCookies]];
    
    sseManager.delegate = self;
    [sseManager connect];
}

- (void)retrySSEconnection {
    [sseReconnectTimer stopTimer];
    [sseReconnectTimer release];
    sseReconnectTimer = nil;
    
    [self connectSSESocket];
}

-(void)sseManagerDidConnect:(LPSSEManager *)aManager {
    socketConnected = YES;
    sseSocketAttemptingReconnect = NO;

    [self sendCapabilitiesPacket];
    
    // Well, we've got a session. Start the realtime extras timer.
    [realtimeExtrasTimer stopTimer];
    [realtimeExtrasTimer release];
    realtimeExtrasTimer = [[LIOTimerProxy alloc] initWithTimeInterval:LIOLookIOManagerRealtimeExtrasTimeInterval target:self selector:@selector(realtimeExtrasTimerDidFire)];
}

-(void)forceSSEManagerDisconnect {
    if (sseManager)
        [sseManager disconnect];
}

-(void)sseManagerWillDisconnect:(LPSSEManager *)aManager withError:(NSError *)err
{
    LIOLog(@"Socket will disconnect. Reason: %@", [err localizedDescription]);
    
    // If the socket disconnected without an outro and without the user asking to disconnect, let's try to reconnect it immediately
    if (NO == userWantsSessionTermination && NO == outroReceived && NO == sseSocketAttemptingReconnect && NO == sseConnectionDidFail) {
        sseSocketAttemptingReconnect = YES;
        [self connectSSESocket];
        return;
    }

    sseSocketAttemptingReconnect = NO;

    // If the user in the process of trying to reconnect, we should show a different alert view, and not the general
    // failure alert view
    
    if (resumeMode) {
        resetAfterDisconnect = YES;
        userWantsSessionTermination = NO;
        introduced = NO;
        resumeMode = NO;
        if (controlButtonType == kLPControlButtonClassic) {
            controlButton.currentMode = LIOControlButtonViewModeDefault;
            [controlButton layoutSubviews];
        }
        if (controlButtonType == kLPControlButtonSquare) {
            squareControlButton.currentMode = LIOControlButtonViewModeDefault;
            [squareControlButton layoutSubviews];
        }

        [self refreshControlButtonVisibility];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.ReconnectFailureAlertTitle")
                                                            message:LIOLocalizedString(@"LIOLookIOManager.ReconnectFailureAlertBody")
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.ReconnectFailureAlertButton"), nil];
        [alertView show];
        [alertView autorelease];
        
        [[LIOMediaManager sharedInstance] purgeAllMedia];
        
        return;
    }
    
    // We don't show error boxes if resume mode is possible, or if we're unprovisioned.
    if (/*NO == firstChatMessageSent && */NO == unprovisioned)
    {
        // We don't show error boxes if the user specifically requested a termination.
        if (NO == userWantsSessionTermination && (err != nil || NO == outroReceived))
        {
            [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
            
            if (introduced)
            {
                // Is this an expected disconnection? If so, show an alert. Otherwise, we will ask for reconnect
                if (sseConnectionDidFail) {
                    if (sseConnectionRetryAfter != -1)
                        return;
                    else {
                        [self dismissDismissibleAlertView];
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertTitle")
                                                                        message:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertBody")
                                                                       delegate:self
                                                              cancelButtonTitle:nil
                                                              otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertButton"), nil];
                        alertView.tag = LIOLookIOManagerSSEConnectionFailedAlertViewTag;
                        
                        double delayInSeconds = 1.0;
                        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                            [alertView show];
                            [alertView autorelease];
                        });
                    }
                }

                resetAfterDisconnect = NO;
                
                LIOLog(@"Session forcibly terminated. Reason: socket closed unexpectedly during an introduced session.");
            }
            else
            {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.StartFailureAlertTitle")
                                                                    message:LIOLocalizedString(@"LIOLookIOManager.StartFailureAlertBody")
                                                                   delegate:self
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.StartFailureAlertButton"), nil];
                alertView.tag = LIOLookIOManagerDisconnectErrorAlertViewTag;
                [alertView show];
                [alertView autorelease];
                
                resetAfterDisconnect = YES;
            }
        }
        
        // Wacky special case: server terminates session.
        else if (NO == userWantsSessionTermination && err == nil)
        {
            [altChatViewController dismissExistingAlertView];

            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertTitle")
                                                                message:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertBody")
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertButton"), nil];
            if (outroReceived)
                alertView.tag = LIOLookIOManagerDisconnectOutroAlertViewTag;
            else
                alertView.tag = LIOLookIOManagerDisconnectErrorAlertViewTag;
            
            [alertView show];
            [alertView autorelease];
            
            if (outroReceived)
                LIOLog(@"Session forcibly terminated. Reason: socket closed cleanly by server (with outro).");
            else
                LIOLog(@"Session forcibly terminated. Reason: socket closed cleanly by server but WITHOUT outro.");
            
            return;
        }
    }
    
    userWantsSessionTermination = NO;
    introduced = NO;
    [self refreshControlButtonVisibility];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDate *lastActivity = [userDefaults objectForKey:LIOLookIOManagerLastActivityDateKey];
    if ([lastActivity timeIntervalSinceNow] <= -LIOLookIOManagerReconnectionTimeLimit)
        resetAfterDisconnect = YES;
    
    // Just in case...
    clickView.hidden = YES;
    cursorView.hidden = YES;
}

- (void)sseManagerDidDisconnect:(LPSSEManager *)aManager {

    LIOLog(@"Socket did disconnect.");
    
    // If we're reconnecting, let's not do anything yet
    if (sseSocketAttemptingReconnect)
        return;
    
    socketConnected = NO;
    sseSocketAttemptingReconnect = NO;
    controlSocketConnecting = NO;
    
    if (resetAfterDisconnect)
    {
        if ((NSObject *)[delegate respondsToSelector:@selector(lookIOManagerDidEndChat:)])
            [delegate lookIOManagerDidEndChat:self];
        
        sessionEnding = YES;
        [self reset];
    }
    else if (NO == resumeMode && NO == outroReceived && firstChatMessageSent && NO == sseConnectionDidFail)
    {
        LIOLog(@"Unexpected disconnection! Asking user for resume mode...");
        
        [altChatViewController bailOnSecondaryViews];
        [altChatViewController.view removeFromSuperview];
        [altChatViewController release];
        altChatViewController = nil;
        [self dismissBlurImageView:NO];
        
        [self rejiggerWindows];
        
        [self showReconnectionQuery];
    }
}

-(void)sseManager:(LPSSEManager *)aManager didDispatchEvent:(LPSSEvent *)anEvent {
    NSDictionary *aPacket = [jsonParser objectWithString:anEvent.data];
    if (nil == aPacket)
    {
        [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"Invalid JSON received from server: \"%@\"", anEvent.data];
        return;
    }
    
    if (anEvent.eventId)
        if (![anEvent.eventId isEqualToString:@""])
            chatLastEventId = anEvent.eventId;
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:chatLastEventId forKey:LIOLookIOManagerLastKnownChatLastEventIdString];
    [userDefaults synchronize];
        
    LIOLog(@"<LPSSEManager> Dispatch event with data:\n%@\n", aPacket);
    
    NSString *type = [aPacket objectForKey:@"type"];
    if ([type isEqualToString:@"engagement_info"]) {
    }
    else if ([type isEqualToString:@"dispatch_error"]) {
        sseConnectionDidFail = YES;
        sessionEnding = YES;
        
        if ([aPacket objectForKey:@"retry_after"]) {
            NSNumber *sseConnectionRetryAfterObject = [aPacket objectForKey:@"retry_after"];
            sseConnectionRetryAfter = sseConnectionRetryAfterObject.intValue;
            if (sseConnectionRetryAfter != -1) {
                sseReconnectTimer = [[LIOTimerProxy alloc] initWithTimeInterval:sseConnectionRetryAfter target:self selector:@selector(retrySSEconnection)];
                sessionEnding = NO;
                
                LIOLog(@"<LPSSEManager> Attempting reconnection in %d seconds..", sseConnectionRetryAfter);
            }
        }
    }
    else if ([type isEqualToString:@"line"])
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
        
        LIOChatMessage *newMessage = [LIOChatMessage chatMessage];
        newMessage.text = text;
        newMessage.senderName = senderName;
        newMessage.kind = LIOChatMessageKindRemote;
        newMessage.date = [NSDate date];
        newMessage.lineId = lineId;
        newMessage.clientLineId = clientLineId;
        
        BOOL shouldAddMessage = YES;
        // Don't add messages which originated from the visitor and are echoed back to the client
        // but add their line_id by matching their client_line_id
        if ([aPacket objectForKey:@"source"]) {
            NSString *source = [aPacket objectForKey:@"source"];
            if ([source isEqualToString:@"visitor"]) {
                shouldAddMessage = NO;
            
                NSPredicate *clientLineIdPredicate = [NSPredicate predicateWithFormat:@"clientLineId = %@", newMessage.clientLineId];
                NSArray *messagesWithClientLineId = [chatHistory filteredArrayUsingPredicate:clientLineIdPredicate];
                if (messagesWithClientLineId.count > 0) {
                    LIOChatMessage *matchedClientLineIdMessage = [messagesWithClientLineId objectAtIndex:0];
                    if (matchedClientLineIdMessage.lineId == nil)
                        matchedClientLineIdMessage.lineId = newMessage.lineId;
                }
            }
        }
        
        
        if (newMessage.lineId) {
            NSPredicate *lineIdPredicate = [NSPredicate predicateWithFormat:@"lineId = %@", newMessage.lineId];
            NSArray *messagesWithLineId = [chatHistory filteredArrayUsingPredicate:lineIdPredicate];
            if (messagesWithLineId.count > 0)
                shouldAddMessage = NO;
        }
        
        if (shouldAddMessage) {
            [chatHistory addObject:newMessage];
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            NSData *chatHistoryData = [NSKeyedArchiver archivedDataWithRootObject:chatHistory];
            [userDefaults setObject:chatHistoryData forKey:LIOLookIOManagerLastKnownChatHistoryKey];
            [userDefaults synchronize];
            
            if (nil == altChatViewController)
            {
                [self showChatAnimated:YES];
            }
            else
            {
                [altChatViewController reloadMessages];
                [altChatViewController scrollToBottomDelayed:YES];
            }
        
            if (UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
            {
                UILocalNotification *localNotification = [[[UILocalNotification alloc] init] autorelease];
                localNotification.soundName = @"LookIODing.caf";
                localNotification.alertBody = LIOLocalizedString(@"LIOLookIOManager.LocalNotificationChatBody");
                localNotification.alertAction = LIOLocalizedString(@"LIOLookIOManager.LocalNotificationChatButton");
                [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
            
                chatReceivedWhileAppBackgrounded = YES;
            }
        }
    }
    else if ([type isEqualToString:@"permission"])
    {
        NSString *asset = [aPacket objectForKey:@"asset"];
        if ([asset isEqualToString:@"screenshare"] && NO == screenshotsAllowed)
        {
            if (UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
            {
                UILocalNotification *localNotification = [[[UILocalNotification alloc] init] autorelease];
                localNotification.soundName = @"LookIODing.caf";
                localNotification.alertBody = LIOLocalizedString(@"LIOLookIOManager.LocalNotificationScreenshareBody");
                localNotification.alertAction = LIOLocalizedString(@"LIOLookIOManager.LocalNotificationScreenshareButton");
                [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
            }
            
            [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.ScreenshareAlertTitle")
                                                                message:LIOLocalizedString(@"LIOLookIOManager.ScreenshareAlertBody")
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.ScreenshareAlertButtonDisallow"), LIOLocalizedString(@"LIOLookIOManager.ScreenshareAlertButtonAllow"), nil];
            alertView.tag = LIOLookIOManagerScreenshotPermissionAlertViewTag;
            [alertView show];
            [alertView autorelease];
        }
    }
    else if ([type isEqualToString:@"advisory"])
    {
        NSString *action = [aPacket objectForKey:@"action"];
        
        if ([action isEqualToString:@"notification"])
        {
            NSDictionary *data = [aPacket objectForKey:@"data"];
            NSString *message = [data objectForKey:@"message"];
            if ([message length] && altChatViewController)
                [altChatViewController revealNotificationString:message withAnimatedKeyboard:NO];
        }
        else if ([action isEqualToString:@"send_logs"])
        {
            [[LIOLogManager sharedLogManager] uploadLog];
        }
        else if ([action isEqualToString:@"typing_start"])
        {
            altChatViewController.agentTyping = YES;
        }
        else if ([action isEqualToString:@"typing_stop"])
        {
            altChatViewController.agentTyping = NO;
        }
        else if ([action isEqualToString:@"connected"])
        {
            LIOLog(@"We're live!");
            enqueued = NO;
            
            if (UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
            {
                UILocalNotification *localNotification = [[[UILocalNotification alloc] init] autorelease];
                localNotification.soundName = @"LookIODing.caf";
                localNotification.alertBody = LIOLocalizedString(@"LIOLookIOManager.LocalNotificationReadyBody");
                localNotification.alertAction = LIOLocalizedString(@"LIOLookIOManager.LocalNotificationReadyButton");
                [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                
                [self showChatAnimated:NO];
            }
        }
        else if ([action isEqualToString:@"unprovisioned"])
        {
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
        }
        else if ([action isEqualToString:@"leave_message"])
        {            
            // By default, we're not calling the custom chat not answered method.
            // If the developer has implemented both relevant methods, and shouldUseCustomactionForNotChatAnswered returns YES,
            // we do want to use this method
            
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
        } else if ([action isEqualToString:@"engagement_started"])
        {
            if (altChatViewController)
                [altChatViewController engagementDidStart];            
        }
    }
    else if ([type isEqualToString:@"survey"]) {
        // Check if this is an offline survey
        if ([aPacket objectForKey:@"offline"]) {
            // By default, we're not calling the custom chat not answered method.
            // If the developer has implemented both relevant methods, and shouldUseCustomactionForNotChatAnswered returns YES,
            // we do want to use this method
            
            callChatNotAnsweredAfterDismissal = NO;
            
            if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManagerShouldUseCustomActionForChatNotAnswered:)])
                if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManagerCustomActionForChatNotAnswered:)])
                    callChatNotAnsweredAfterDismissal = [delegate lookIOManagerShouldUseCustomActionForChatNotAnswered:self];
            
            LIOSurveyManager* surveyManager = [LIOSurveyManager sharedSurveyManager];

            if (callChatNotAnsweredAfterDismissal) {
                [self altChatViewControllerWantsSessionTermination:altChatViewController];
            } else {
                NSDictionary *offlineSurveyDict = [aPacket objectForKey:@"offline"];
                if (offlineSurveyDict && [offlineSurveyDict isKindOfClass:[NSDictionary class]] && surveyManager.surveysEnabled)
                {
                    [[LIOSurveyManager sharedSurveyManager] populateTemplateWithDictionary:offlineSurveyDict type:LIOSurveyManagerSurveyTypeOffline];
                    surveyManager.offlineSurveyIsDefault = NO;
                } else {
                    LIOSurveyManager* surveyManager = [LIOSurveyManager sharedSurveyManager];
                    surveyManager.offlineSurveyIsDefault = YES;
                    
                    NSString *lastSentMessageText = nil;
                    if (altChatViewController)
                        lastSentMessageText = altChatViewController.lastSentMessageText;
                    
                    [[LIOSurveyManager sharedSurveyManager] populateDefaultOfflineSurveyWithResponse:lastSentMessageText];
                }
                
                [altChatViewController forceLeaveMessageScreen];
            }
        }
        
        // Check if this is a postchat survey
        if ([aPacket objectForKey:@"postchat"]) {
            NSDictionary *postSurveyDict = [aPacket objectForKey:@"postchat"];
            if (postSurveyDict && [postSurveyDict isKindOfClass:[NSDictionary class]])
            {
                [[LIOSurveyManager sharedSurveyManager] populateTemplateWithDictionary:postSurveyDict type:LIOSurveyManagerSurveyTypePost];
            }
        }

        if ([aPacket objectForKey:@"prechat"]) {
            NSDictionary *preSurveyDict = [aPacket objectForKey:@"prechat"];
            if (preSurveyDict && [preSurveyDict isKindOfClass:[NSDictionary class]])
            {
                [[LIOSurveyManager sharedSurveyManager] populateTemplateWithDictionary:preSurveyDict type:LIOSurveyManagerSurveyTypePre];
                
                [self presentPreChatSurvey];
            }
        }
    }
    else if ([type isEqualToString:@"screen_cursor"])
    {
        if (altChatViewController)
            return;
        
        cursorView.hidden = NO == screenshotsAllowed || cursorEnded;
        
        
        NSNumber *x = [aPacket objectForKey:@"x"];
        NSNumber *y = [aPacket objectForKey:@"y"];
        
        CGRect aFrame = [self cursorViewFrameForX:x y:y];        
        
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState)
                         animations:^{ cursorView.frame = aFrame; }
                         completion:nil];
    }
    else if ([type isEqualToString:@"screen_cursor_start"])
    {
        cursorEnded = NO;
        
        if (altChatViewController)
        {
            cursorView.hidden = YES;
            return;
        }
        
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        
        CGRect aFrame = CGRectZero;
        aFrame.size.width = cursorView.image.size.width * 8.0;
        aFrame.size.height = cursorView.image.size.height * 8.0;
        aFrame.origin.x = (keyWindow.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
        aFrame.origin.y = (keyWindow.frame.size.height / 2.0) - (aFrame.size.height / 2.0);
        cursorView.frame = aFrame;
        cursorView.alpha = 0.0;
        
        aFrame.size.width = cursorView.image.size.width;
        aFrame.size.height = cursorView.image.size.height;
        aFrame.origin.x = (keyWindow.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
        aFrame.origin.y = (keyWindow.frame.size.height / 2.0) - (aFrame.size.height / 2.0);
        
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseIn)
                         animations:^{
                             cursorView.frame = aFrame;
                             cursorView.alpha = 1.0;
                         }
                         completion:nil];
        
    }
    else if ([type isEqualToString:@"screen_cursor_stop"])
    {
        cursorEnded = YES;
        cursorView.hidden = YES;
    }
    else if ([type isEqualToString:@"screen_click"])
    {
        if (altChatViewController)
            return;
        
        clickView.hidden = NO == screenshotsAllowed || cursorEnded;
        
        NSNumber *x = [aPacket objectForKey:@"x"];
        NSNumber *y = [aPacket objectForKey:@"y"];
        
        
        CGRect aFrame = CGRectZero;
        aFrame.size.width = clickView.image.size.width;
        aFrame.size.height = clickView.image.size.height;
        clickView.bounds = aFrame;
        clickView.alpha = 0.0;
        
        clickView.center = CGPointMake([x floatValue], [y floatValue]);
        
        aFrame = CGRectZero;
        aFrame.size.width = clickView.image.size.width * 3.0;
        aFrame.size.height = clickView.image.size.height * 3.0;
        
        
        CGRect correctFrame = [self clickViewFrameForX:x y:y];
        aFrame.origin.x = correctFrame.origin.x;
        aFrame.origin.y = correctFrame.origin.y;
        
        [UIView animateWithDuration:0.1
                              delay:0.0
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut)
                         animations:^{
                             clickView.frame = aFrame;
                             clickView.alpha = 1.0;
                         }
                         completion:^(BOOL finished) {
                             [UIView animateWithDuration:0.1
                                                   delay:0.2
                                                 options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseIn)
                                              animations:^{
                                                  clickView.alpha = 0.0;
                                              }
                                              completion:nil];
                         }];
    }
    else if ([type isEqualToString:@"outro"])
    {
        sessionEnding = YES;
        outroReceived = YES;
    }
    else if ([type isEqualToString:@"reintroed"])
    {
        NSNumber *success = [aPacket objectForKey:@"success"];
        
        if ([success boolValue] && resumeMode)
        {
            [reintroTimeoutTimer stopTimer];
            [reintroTimeoutTimer release];
            reintroTimeoutTimer = nil;
            
            resumeMode = NO;
            sessionEnding = NO;
            resetAfterDisconnect = NO;
            introduced = YES;
            introPacketWasSent = YES;
            killConnectionAfterChatViewDismissal = NO;
            firstChatMessageSent = YES;
            
            [LIOSurveyManager sharedSurveyManager].receivedEmptyPreSurvey = YES;
            
            [self populateChatWithFirstMessage];
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.ReconnectedAlertTitle")
                                                                message:LIOLocalizedString(@"LIOLookIOManager.ReconnectedAlertBody")
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.ReconnectedAlertButtonHide"), LIOLocalizedString(@"LIOLookIOManager.ReconnectedAlertButtonOpen"), nil];
            alertView.tag = LIOLookIOManagerReconnectionSucceededAlertViewTag;
            [alertView show];
            [alertView autorelease];
            
            if (chatHistory.count == 1)
                [self sendChatHistoryPacketWithDict:[NSDictionary dictionary]];
        }
        
        if (![success boolValue]) {
            sseConnectionDidFail = YES;
            sessionEnding = YES;
            
            if ([aPacket objectForKey:@"retry_after"]) {
                NSNumber *sseConnectionRetryAfterObject = [aPacket objectForKey:@"retry_after"];
                sseConnectionRetryAfter = sseConnectionRetryAfterObject.intValue;
                if (sseConnectionRetryAfter != -1) {
                    sseReconnectTimer = [[LIOTimerProxy alloc] initWithTimeInterval:sseConnectionRetryAfter target:self selector:@selector(retrySSEconnection)];
                    sessionEnding = NO;
                    
                    LIOLog(@"<LPSSEManager> Attempting reconnection in %d seconds..", sseConnectionRetryAfter);
                }
            }
        }
    }
}

-(CGRect)cursorViewFrameForX:(NSNumber*)x y:(NSNumber*)y {
    CGRect aFrame = cursorView.frame;
    actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (actualInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
        
        aFrame.origin.x = [y floatValue];
        aFrame.origin.y = applicationFrame.size.height - [x floatValue] - aFrame.size.height;
    } else if (actualInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
        
        aFrame.origin.x = applicationFrame.size.width - [y floatValue] - aFrame.size.width/2;
        aFrame.origin.y = [x floatValue];
    } else
    {
        aFrame.origin.x = [x floatValue];
        aFrame.origin.y = [y floatValue];
    }
    return aFrame;
}

-(CGRect)clickViewFrameForX:(NSNumber*)x y:(NSNumber*)y {
    CGRect aFrame = clickView.frame;
    actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (actualInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
        
        aFrame.origin.x = [y floatValue] - aFrame.size.width*1.5;
        aFrame.origin.y = applicationFrame.size.height - [x floatValue] - aFrame.size.height*1.5;
    } else if (actualInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
        aFrame.origin.x = applicationFrame.size.width - [y floatValue] - aFrame.size.width*1;
        aFrame.origin.y = [x floatValue] - aFrame.size.height*1.5;
    } else
    {
        aFrame.origin.x = [x floatValue] - aFrame.size.width*1.5;
        aFrame.origin.y = [y floatValue] - aFrame.size.height*1.5;
    }
    return aFrame;
}


-(void)beginSessionAfterSurveyImmediatelyShowingChat:(BOOL)showChat
{
    // Waiting for the "do you want to reconnect?" alert view.
    if (willAskUserToReconnect)
        return;
    
    // Prevent a new session from being established if the current one
    // is ending.
    if (sessionEnding)
    {
        LIOLog(@"beginSession ignored: current session is still ending...");
        return;
    }
    
    if (controlSocketConnecting)
    {
        LIOLog(@"beginSession ignored: still waiting for previous connection attempt to finish...");
        return;
    }
    
    if (socketConnected)
    {
        if (introduced)
        {
            [self showChatAnimated:YES];
            return;
        }
        else
        {
            LIOLog(@"beginSession ignored: already connected! (But not introduced)");
            return;
        }
    }
    
    [self sendIntroPacket];
    
    [self populateChatWithFirstMessage];
    
    if (showChat)
        [self showChatAnimated:YES];
}

- (void)presentPreChatSurvey {
    LIOSurveyManager* surveyManager = [LIOSurveyManager sharedSurveyManager];

    if (altChatViewController && surveyManager.surveysEnabled) {
        if (surveyManager.preChatTemplate.questions.count == 0)
               [altChatViewController noSurveyRecieved];
        else
            [altChatViewController showSurveyViewForType:LIOSurveyManagerSurveyTypePre];
    }
}

- (void)beginSessionImmediatelyShowingChat:(BOOL)showChat
{
    // Waiting for the "do you want to reconnect?" alert view.
    if (willAskUserToReconnect)
        return;

    // Prevent a new session from being established if the current one
    // is ending.
    if (sessionEnding)
    {
        LIOLog(@"beginSession ignored: current session is still ending...");
        return;
    }
    
    if (controlSocketConnecting)
    {
        LIOLog(@"beginSession ignored: still waiting for previous connection attempt to finish...");
        return;
    }
    
    if (socketConnected)
    {
        if (introduced)
        {
            [self showChatAnimated:YES];
            return;
        }
        else
        {
            LIOLog(@"beginSession ignored: already connected! (But not introduced)");
            return;
        }
    }
    
    [self sendIntroPacket];
    
    [self populateChatWithFirstMessage];
    
    if (showChat)
        [self showChatAnimated:YES];
}

- (void)beginSession
{
    if (badInitialization)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.BadInitAlertTitle")
                                                            message:LIOLocalizedString(@"LIOLookIOManager.BadInitAlertBody")
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.BadInitButton"), nil];
        [alertView show];
        [alertView autorelease];
        
        return;
    }
    
    [self beginSessionImmediatelyShowingChat:YES];
}

- (void)beginChat
{
    [self beginSession];
}

- (void)endChatAndShowAlert:(BOOL)showAlert {
    // If chat not in progress, abort
    if (![self chatInProgress])
        return;
    
    if (showAlert)
    {
        [self dismissDismissibleAlertView];

        dismissibleAlertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertTitle")
                                                          message:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertBody")
                                                         delegate:self
                                                cancelButtonTitle:nil                                              otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertButton"), nil];
        dismissibleAlertView.tag = LIOLookIOManagerDisconnectedByDeveloperAlertViewTag;
        [dismissibleAlertView show];
        [dismissibleAlertView autorelease];
    }
    else
    {
        [self endChat];
    }
}

- (void)endChat
{
    // Let's see if there's a post chat survey to display
    LIOSurveyManager* surveryManager = [LIOSurveyManager sharedSurveyManager];
    if (surveryManager.postChatTemplate && surveryManager.surveysEnabled) {
        // Let's check to see if the chat view controller is visible. If not, present it before
        // killing the session or presenting the survey

        if (altChatViewController)
            [altChatViewController showSurveyViewForType:LIOSurveyManagerSurveyTypePost];
        else {
            [self showChatAnimated:YES];

            BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
            
            if (!padUI) {
                [altChatViewController showSurveyViewForType:LIOSurveyManagerSurveyTypePost];
            } else {
                [altChatViewController hideChatUIForSurvey:NO];
                double delayInSeconds = 1.0;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [altChatViewController showSurveyViewForType:LIOSurveyManagerSurveyTypePost];
                });
            }
        }
        return;
    }

    // Call for session termination
    [self altChatViewControllerWantsSessionTermination:altChatViewController];
    
}

- (BOOL)beginConnectingWithError:(NSError **)anError
{
    return NO;
}

- (void)killConnection
{
    [self sendOutroPacket];
}

- (void)setSkill:(NSString *)aRequiredSkill
{
    [currentRequiredSkill release];
    currentRequiredSkill = [aRequiredSkill retain];
    
    [self sendContinuationReport];
    [self refreshControlButtonVisibility];
    
    if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManager:didUpdateEnabledStatus:)])
        [delegate lookIOManager:self didUpdateEnabledStatus:[self enabled]];
}

- (void)refreshControlButtonVisibility
{
    if (controlButtonType == kLPControlButtonClassic)
        [self refreshClassicControlButtonVisibility];
    if (controlButtonType == kLPControlButtonSquare)
        [self refreshSquareControlButtonVisibility];
}

- (void)refreshClassicControlButtonVisibility {
    [controlButton.layer removeAllAnimations];
    
    // Trump card #-1: If the session is ending, button is hidden.
    if (sessionEnding)
    {
        controlButtonHidden = YES;
        controlButton.frame = controlButtonHiddenFrame;
        [self rejiggerControlButtonLabel];
        LIOLog(@"<<CONTROL>> Hiding. Reason: session is ending.");
        return;
    }
    
    // Trump card #0: If we have no visibility information, button is hidden.
    if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:LIOLookIOManagerLastKnownButtonVisibilityKey] ||
        nil == [[NSUserDefaults standardUserDefaults] objectForKey:LIOLookIOManagerMultiskillMappingKey])
    {
        controlButtonHidden = YES;
        controlButton.frame = controlButtonHiddenFrame;
        [self rejiggerControlButtonLabel];
        LIOLog(@"<<CONTROL>> Hiding. Reason: never got any visibility or enabled-status settings from the server.");
        return;
    }
    
    // Trump card #1: Not in a session, and not "enabled" from server-side settings.
    if (NO == socketConnected && NO == [self enabled])
    {
        controlButtonHidden = YES;
        controlButton.frame = controlButtonHiddenFrame;
        [self rejiggerControlButtonLabel];
        LIOLog(@"<<CONTROL>> Hiding. Reason: [self enabled] == NO.");
        return;
    }
    
    BOOL willHide = NO, willShow = NO;
    NSString *aReason;
    
    if (lastKnownButtonVisibility)
    {
        int val = [lastKnownButtonVisibility intValue];
        if (0 == val) // never
        {
            // Want to hide.
            willHide = NO == controlButtonHidden;
            aReason = @"lastKnownButtonVisibility == 0 (never)";
        }
        else if (1 == val) // always
        {
            // Want to show.
            willShow = controlButtonHidden;
            aReason = @"lastKnownButtonVisibility == 1 (always)";
        }
        else // 3 = only in session
        {
            if (introduced || resumeMode)
            {
                // Want to show.
                willShow = controlButtonHidden;
                aReason = @"lastKnownButtonVisibility == 3 (in-session only) && (introduced || resumeMode)";
            }
            else
            {
                // Want to hide.
                willHide = NO == controlButtonHidden;
                aReason = @"lastKnownButtonVisibility == 3 (in-session only)";
            }
        }
    }
    else
    {
        willShow = controlButtonHidden;
        aReason = @"no visibility setting";
    }
    
    // Trump card #2: If chat is up, button is always hidden.
    if (altChatViewController)
    {
        willShow = NO;
        willHide = NO == controlButtonHidden;
        aReason = @"chat is up";
    }
    
    if (willHide)
    {
        LIOLog(@"<<CONTROL>> Hiding. Reason: %@", aReason);
        
        controlButtonVisibilityAnimating = YES;
        controlButtonHidden = YES;
        
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:0
                         animations:^{
                             controlButton.frame = controlButtonHiddenFrame;
                         } completion:^(BOOL finished) {
                             controlButtonVisibilityAnimating = NO;
                             [self rejiggerControlButtonLabel];
                         }];
                
        if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManagerDidHideControlButton:)])
            [delegate lookIOManagerDidHideControlButton:self];
    }
    else if (willShow)
    {
        LIOLog(@"<<CONTROL>> Showing. Reason: %@", aReason);
        
        controlButtonVisibilityAnimating = YES;
        controlButtonHidden = NO;
        
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:0
                         animations:^{
                             controlButton.frame = controlButtonShownFrame;
                         } completion:^(BOOL finished) {
                             controlButtonVisibilityAnimating = NO;
                             [self rejiggerControlButtonLabel];
                         }];
        
        if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManagerDidShowControlButton:)])
            [delegate lookIOManagerDidShowControlButton:self];
    }
    
    if (controlButtonType == kLPControlButtonClassic) {
        if (resumeMode && NO == socketConnected)
            controlButton.currentMode = LIOControlButtonViewModePending;
        else
            controlButton.currentMode = LIOControlButtonViewModeDefault;
    }
    
    if (controlButtonType == kLPControlButtonSquare) {
        if (resumeMode && NO == socketConnected)
            squareControlButton.currentMode = LIOControlButtonViewModePending;
        else
            squareControlButton.currentMode = LIOControlButtonViewModeDefault;
    }

}

- (void)refreshSquareControlButtonVisibility {
    [squareControlButton.layer removeAllAnimations];
    squareControlButton.alpha = 1.0;
    
    // Trump card #-1: If the session is ending, button is hidden.
    if (sessionEnding)
    {
        controlButtonHidden = YES;
        squareControlButton.frame = controlButtonHiddenFrame;
        LIOLog(@"<<CONTROL>> Hiding. Reason: session is ending.");
        return;
    }
    
    // Trump card #0: If we have no visibility information, button is hidden.
    if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:LIOLookIOManagerLastKnownButtonVisibilityKey] ||
        nil == [[NSUserDefaults standardUserDefaults] objectForKey:LIOLookIOManagerMultiskillMappingKey])
    {
        controlButtonHidden = YES;
        squareControlButton.frame = controlButtonHiddenFrame;
        LIOLog(@"<<CONTROL>> Hiding. Reason: never got any visibility or enabled-status settings from the server.");
        return;
    }
    
    // Trump card #1: Not in a session, and not "enabled" from server-side settings.
    if (NO == socketConnected && NO == [self enabled])
    {
        controlButtonHidden = YES;
        squareControlButton.frame = controlButtonHiddenFrame;
        LIOLog(@"<<CONTROL>> Hiding. Reason: [self enabled] == NO.");
        return;
    }
    
    BOOL willHide = NO, willShow = NO;
    NSString *aReason;
    
    if (lastKnownButtonVisibility)
    {
        int val = [lastKnownButtonVisibility intValue];
        if (0 == val) // never
        {
            // Want to hide.
            willHide = NO == controlButtonHidden;
            aReason = @"lastKnownButtonVisibility == 0 (never)";
        }
        else if (1 == val) // always
        {
            // Want to show.
            willShow = controlButtonHidden;
            aReason = @"lastKnownButtonVisibility == 1 (always)";
        }
        else // 3 = only in session
        {
            if (introduced || resumeMode)
            {
                // Want to show.
                willShow = controlButtonHidden;
                aReason = @"lastKnownButtonVisibility == 3 (in-session only) && (introduced || resumeMode)";
            }
            else
            {
                // Want to hide.
                willHide = NO == controlButtonHidden;
                aReason = @"lastKnownButtonVisibility == 3 (in-session only)";
            }
        }
    }
    else
    {
        willShow = controlButtonHidden;
        aReason = @"no visibility setting";
    }
    
    // Trump card #2: If chat is up, button is always hidden.
    if (altChatViewController)
    {
        willShow = NO;
        willHide = NO == controlButtonHidden;
        aReason = @"chat is up";
    }
    
    if (willHide)
    {
        LIOLog(@"<<CONTROL>> Hiding. Reason: %@", aReason);
        
        controlButtonVisibilityAnimating = YES;
        controlButtonHidden = YES;
        
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:0
                         animations:^{
                             squareControlButton.frame = controlButtonHiddenFrame;
                         } completion:^(BOOL finished) {
                             controlButtonVisibilityAnimating = NO;
                         }];
        
        if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManagerDidHideControlButton:)])
            [delegate lookIOManagerDidHideControlButton:self];
    }
    else if (willShow)
    {
        LIOLog(@"<<CONTROL>> Showing. Reason: %@", aReason);
        
        controlButtonVisibilityAnimating = YES;
        controlButtonHidden = NO;
        
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:0
                         animations:^{
                             squareControlButton.frame = controlButtonShownFrame;
                         } completion:^(BOOL finished) {
                             controlButtonVisibilityAnimating = NO;
                         }];
        
        if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManagerDidShowControlButton:)])
            [delegate lookIOManagerDidShowControlButton:self];
    }
    
    if (resumeMode && NO == socketConnected)
        squareControlButton.currentMode = LIOSquareControlButtonViewModePending;
    else
        squareControlButton.currentMode = LIOSquareControlButtonViewModeDefault;
}

- (NSDictionary *)resolveSettingsPayload:(NSDictionary *)params fromContinue:(BOOL)fromContinue
{
    NSMutableDictionary *resolvedSettings = [NSMutableDictionary dictionary];
    
    /*
    NSNumber *visitorIdNumber = [params objectForKey:@"visitor_id"];
    if (visitorIdNumber)
        [resolvedSettings setObject:visitorIdNumber forKey:@"visitor_id"];
    */
    
    NSDictionary *skillsDict = [params objectForKey:@"skills"];
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
            NSMutableDictionary *newMap = [[multiskillMapping mutableCopy] autorelease];
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
                        newDefault = aSkillKey;;
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
    
    NSNumber *buttonVisibility = [params objectForKey:@"button_visibility"];
    if (buttonVisibility)
        [resolvedSettings setObject:buttonVisibility forKey:@"button_visibility"];
    
    NSString *buttonText = [params objectForKey:@"button_text"];
    if ([buttonText length])
        [resolvedSettings setObject:buttonText forKey:@"button_text"];
    
    NSString *welcomeText = [params objectForKey:@"welcome_text"];
    if ([welcomeText length])
        [resolvedSettings setObject:welcomeText forKey:@"welcome_text"];
    
    NSString *buttonTint = [params objectForKey:@"button_tint"];
    if ([buttonTint length])
        [resolvedSettings setObject:buttonTint forKey:@"button_tint"];
    
    NSString *buttonTextColor = [params objectForKey:@"button_text_color"];
    if ([buttonTextColor length])
        [resolvedSettings setObject:buttonTextColor forKey:@"button_text_color"];
    
    /*
    NSDictionary *proactiveChat = [params objectForKey:@"proactive_chat"];
    if (proactiveChat)
    {
        [proactiveChatRules removeAllObjects];
        [proactiveChatRules addEntriesFromDictionary:proactiveChat];
    }
    */
    
    NSString *visitIdString = [params objectForKey:@"visit_id"];
    if ([visitIdString length])
        [resolvedSettings setObject:visitIdString forKey:@"visit_id"];
    
    NSDictionary *localizedStrings = [params objectForKey:@"localized_strings"];
    if ([localizedStrings count])
        [resolvedSettings setObject:localizedStrings forKey:@"localized_strings"];
    
    NSString *visitURLString = [params objectForKey:@"visit_url"];
    if ([visitURLString length])
        [resolvedSettings setObject:visitURLString forKey:@"visit_url"];
    
    NSNumber *nextIntervalNumber = [params objectForKey:@"next_interval"];
    if (nextIntervalNumber)
        [resolvedSettings setObject:nextIntervalNumber forKey:@"next_interval"];

    NSNumber *surveysEnabledNumber = [params objectForKey:@"surveys_enabled"];
    if (surveysEnabledNumber)
        [resolvedSettings setObject:surveysEnabledNumber forKey:@"surveys_enabled"];
    
    NSNumber *hideEmailChatNumber = [params objectForKey:@"hide_email_chat"];
    if (hideEmailChatNumber)
        [resolvedSettings setObject:hideEmailChatNumber forKey:@"hide_email_chat"];

    return resolvedSettings;
}

- (void)parseAndSaveSettingsPayload:(NSDictionary *)params fromContinue:(BOOL)fromContinue
{
    LIOLog(@"Got settings payload: %@", params);

    // Parse.
    NSDictionary *resolvedSettings = nil;
    @try
    {
        resolvedSettings = [self resolveSettingsPayload:params fromContinue:fromContinue];
    }
    @catch (NSException *exception)
    {
        [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"Invalid settings payload received from the server! Exception: %@", exception];
        
        // Delete multiskill mapping. This should force
        // the lib to report "disabled" back to the host app.
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:LIOLookIOManagerMultiskillMappingKey];
        [multiskillMapping release];
        multiskillMapping = nil;
    }
    
    
    // Save.
    if ([resolvedSettings count])
    {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        NSDictionary *skillsMap = [resolvedSettings objectForKey:@"skills"];
        if (skillsMap)
        {
            [multiskillMapping release];
            multiskillMapping = [skillsMap retain];
            [userDefaults setObject:multiskillMapping forKey:LIOLookIOManagerMultiskillMappingKey];
            
            if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManager:didUpdateEnabledStatus:)])
                [delegate lookIOManager:self didUpdateEnabledStatus:[self enabled]];
        }
        
        NSNumber *buttonVisibility = [resolvedSettings objectForKey:@"button_visibility"];
        if (buttonVisibility)
        {
            [lastKnownButtonVisibility release];
            lastKnownButtonVisibility = [buttonVisibility retain];
            
            [userDefaults setObject:lastKnownButtonVisibility forKey:LIOLookIOManagerLastKnownButtonVisibilityKey];
            
            if (disableControlButtonOverride) {
                previousControlButtonValue = [lastKnownButtonVisibility boolValue];
                lastKnownButtonVisibility = [NSNumber numberWithBool:NO];
            }
            
            [self refreshControlButtonVisibility];
        }
        
        NSString *buttonText = [resolvedSettings objectForKey:@"button_text"];
        if ([buttonText length])
        {
            [lastKnownButtonText release];
            lastKnownButtonText = [buttonText retain];
            
            [userDefaults setObject:lastKnownButtonText forKey:LIOLookIOManagerLastKnownButtonTextKey];
            
            controlButton.labelText = buttonText;
            [self rejiggerControlButtonFrame];
        }
        
        NSString *welcomeText = [resolvedSettings objectForKey:@"welcome_text"];
        if ([welcomeText length])
        {
            [lastKnownWelcomeMessage release];
            lastKnownWelcomeMessage = [welcomeText retain];
            
            [userDefaults setObject:lastKnownWelcomeMessage forKey:LIOLookIOManagerLastKnownWelcomeMessageKey];
        }
        
        NSString *buttonTint = [resolvedSettings objectForKey:@"button_tint"];
        if ([buttonTint length])
        {
            [userDefaults setObject:buttonTint forKey:LIOLookIOManagerLastKnownButtonTintColorKey];
            
            unsigned int colorValue;
            [[NSScanner scannerWithString:buttonTint] scanHexInt:&colorValue];
            UIColor *color = HEXCOLOR(colorValue);
            
            if (controlButtonType == kLPControlButtonClassic)
                controlButton.tintColor = color;
            if (controlButtonType == kLPControlButtonSquare)
                squareControlButton.tintColor = color;
            
            [lastKnownButtonTintColor release];
            lastKnownButtonTintColor = [color retain];
        }
        
        NSString *buttonTextColor = [resolvedSettings objectForKey:@"button_text_color"];
        if ([buttonTextColor length])
        {
            [userDefaults setObject:buttonTextColor forKey:LIOLookIOManagerLastKnownButtonTextColorKey];
            
            unsigned int colorValue;
            [[NSScanner scannerWithString:buttonTextColor] scanHexInt:&colorValue];
            UIColor *color = HEXCOLOR(colorValue);
            
            if (controlButtonType == kLPControlButtonClassic)
                controlButton.textColor = color;

            if (controlButtonType == kLPControlButtonSquare) {
                squareControlButton.textColor = color;
                [squareControlButton updateButtonColor];
                
                if (!altChatViewController && !squareControlButton.isDragging && !controlButtonHidden)
                    [squareControlButton presentLabel];
            }
            
            [lastKnownButtonTextColor release];
            lastKnownButtonTextColor = [color retain];
        }
        
        NSString *visitIdString = [resolvedSettings objectForKey:@"visit_id"];
        if ([visitIdString length])
        {
            [currentVisitId release];
            currentVisitId = [visitIdString retain];
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
            [lastKnownVisitURL release];
            lastKnownVisitURL = [visitURLString retain];

            LPVisitAPIClient* visitAPIClient = [LPVisitAPIClient sharedClient];
            visitAPIClient.baseURL = [NSURL URLWithString:lastKnownVisitURL];
        }
        
        NSNumber *nextIntervalNumber = [resolvedSettings objectForKey:@"next_interval"];
        if (nextIntervalNumber)
        {
            nextTimeInterval = [nextIntervalNumber doubleValue];
            
            [continuationTimer stopTimer];
            [continuationTimer release];
            continuationTimer = [[LIOTimerProxy alloc] initWithTimeInterval:nextTimeInterval
                                                                     target:self
                                                                   selector:@selector(continuationTimerDidFire)];
        }
        
        NSNumber *surveysEnabled = [resolvedSettings objectForKey:@"surveys_enabled"];
        if (surveysEnabled)
        {
            [userDefaults setObject:surveysEnabled forKey:LIOLookIOManagerLastKnownSurveysEnabled];
            lastKnownSurveysEnabled = [surveysEnabled boolValue];
            LIOSurveyManager* surveyManager = [LIOSurveyManager sharedSurveyManager];
            surveyManager.surveysEnabled = lastKnownSurveysEnabled;
        }
        
        if (disableSurveysOverride) {
            LIOSurveyManager* surveyManager = [LIOSurveyManager sharedSurveyManager];

            previousSurveysEnabledValue = surveyManager.surveysEnabled;
            surveyManager.surveysEnabled = NO;
        }
        
        [self refreshControlButtonVisibility];
        [self applicationDidChangeStatusBarOrientation:nil];
    }
}

- (BOOL)shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation
{
    UIWindow *hostAppWindow = [[UIApplication sharedApplication] keyWindow];
    if (previousKeyWindow && previousKeyWindow != hostAppWindow)
        hostAppWindow = previousKeyWindow;
    
    // Ask delegate.
    if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManager:shouldRotateToInterfaceOrientation:)])
        return [delegate lookIOManager:self shouldRotateToInterfaceOrientation:anOrientation];
    
    // Ask root view controller.
    if (hostAppWindow.rootViewController)
        return [hostAppWindow.rootViewController shouldAutorotateToInterfaceOrientation:anOrientation];
    
    // Fall back on plist settings.
    [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"Using .plist keys to determine rotation behavior. This may not be accurate. You may want to make use of the following LIOLookIOManagerDelegate method: lookIOManager:shouldRotateToInterfaceOrientation:"];
    return [supportedOrientations containsObject:[NSNumber numberWithInteger:anOrientation]];
}

- (BOOL)shouldAutorotate // iOS >= 6.0
{
    UIWindow *hostAppWindow = [[UIApplication sharedApplication] keyWindow];
    if (previousKeyWindow && previousKeyWindow != hostAppWindow)
        hostAppWindow = previousKeyWindow;
    
    // Ask delegate.
    if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManagerShouldAutorotate:)])
        return [delegate lookIOManagerShouldAutorotate:self];
    
    // Ask root view controller.
    if (hostAppWindow.rootViewController)
        return [hostAppWindow.rootViewController shouldAutorotate];
    
    return NO;
}

- (NSInteger)supportedInterfaceOrientations // iOS >= 6.0
{
    UIWindow *hostAppWindow = [[UIApplication sharedApplication] keyWindow];
    if (previousKeyWindow && previousKeyWindow != hostAppWindow)
        hostAppWindow = previousKeyWindow;
    
    // Ask delegate.
    if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManagerSupportedInterfaceOrientations:)])
        return [delegate lookIOManagerSupportedInterfaceOrientations:self];
    
    // Ask root view controller.
    if (hostAppWindow.rootViewController)
        return [hostAppWindow.rootViewController supportedInterfaceOrientations];
    
    // UIInterfaceOrientationMaskPortrait is 2 as of 10/18/12.
    return 2;
}

- (void)setSessionExtra:(id)anObject forKey:(NSString *)aKey
{
    if (anObject)
    {
        // We only allow JSONable objects.
        NSString *test = [jsonWriter stringWithObject:[NSArray arrayWithObject:anObject]];
        if ([test length])
        {
            [sessionExtras setObject:anObject forKey:aKey];
            [self sendContinuationReport];
        }
        else
            [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"Can't add object of class \"%@\" to session extras! Use simple classes like NSString, NSArray, NSDictionary, NSNumber, NSDate, etc.", NSStringFromClass([anObject class])];
    }
    else
    {
        [sessionExtras removeObjectForKey:aKey];
        [self sendContinuationReport];
    }
}

- (void)setCustomVariable:(id)anObject forKey:(NSString *)aKey
{
    [self setSessionExtra:anObject forKey:aKey];
}

- (id)sessionExtraForKey:(NSString *)aKey
{
    return [sessionExtras objectForKey:aKey];
}

- (id)customVariableForKey:(NSString *)aKey
{
    return [self sessionExtraForKey:aKey];
}

- (void)addSessionExtras:(NSDictionary *)aDictionary
{
    // We only allow JSONable objects.
    NSString *test = [jsonWriter stringWithObject:aDictionary];
    if ([test length])
    {
        [sessionExtras addEntriesFromDictionary:aDictionary];
        [self sendContinuationReport];
    }
    else
        [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"Can't add dictionary of objects to session extras! Use classes like NSString, NSArray, NSDictionary, NSNumber, NSDate, etc."];
}

- (void)addCustomVariables:(NSDictionary *)aDictionary
{
    [self addSessionExtras:aDictionary];
}

- (void)clearSessionExtras
{
    [sessionExtras removeAllObjects];
    
    [self sendContinuationReport];
}

- (void)clearCustomVariables
{
    [self clearSessionExtras];
}

- (NSString *)bundleId
{
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManagerAppIdOverride:)])
    {
        NSString *overriddenBundleId = [delegate lookIOManagerAppIdOverride:self];
        if ([overriddenBundleId length])
            bundleId = overriddenBundleId;
    }
    
    return bundleId;
}

- (NSString *)currentSessionId
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:LIOLookIOManagerLastKnownSessionIdKey];
}

- (NSString*) currentChatEngagementId
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:LIOLookIOManagerLastKnownEngagementIdKey];
}

- (UInt32)enabledCollaborationComponents
{
    UInt32 result = kLPCollaborationComponentNone;
    if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManagerEnabledCollaborationComponents:)])
        result = [delegate lookIOManagerEnabledCollaborationComponents:self];
    
    return result;
}

- (NSDictionary *)buildIntroDictionaryIncludingExtras:(BOOL)includeExtras includingType:(BOOL)includesType includingSurveyResponses:(BOOL)includesSurveyResponses includingEvents:(BOOL)includeEvents
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);  
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);  
    NSString *deviceType = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
    free(machine);
    
    NSString *bundleId = [self bundleId];
    NSMutableDictionary *introDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      deviceType, @"device_type",
                                      bundleId, @"app_id",
                                      @"Apple iOS", @"platform",
                                      [[UIDevice currentDevice] systemVersion], @"platform_version",
                                      LOOKIO_VERSION_STRING, @"sdk_version",
                                      nil];
    
    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
        NSString *vendorDeviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];

        [introDict setObject:vendorDeviceId forKey:@"device_id"];
    } else {
        NSString *udid = uniqueIdentifier();
        
        [introDict setObject:udid forKey:@"device_id"];
    }
    
    if (includeEvents && [pendingEvents count])
        [introDict setObject:pendingEvents forKey:@"events"];
    
    if ([currentVisitId length])
        [introDict setObject:currentVisitId forKey:@"visit_id"];
    
    NSNumber *visitorId = [[NSUserDefaults standardUserDefaults] objectForKey:LIOLookIOManagerLastKnownVisitorIdKey];
    if (visitorId)
        [introDict setObject:visitorId forKey:@"visitor_id"];
    
    if (includesType)
        [introDict setObject:@"intro" forKey:@"type"];
    
    if (badInitialization)
        [introDict setObject:[NSNumber numberWithBool:YES] forKey:@"bad_init"];
    
    if (includesSurveyResponses && [surveyResponsesToBeSent count])
    {
        [introDict setObject:surveyResponsesToBeSent forKey:@"prechat_survey"];
        
        [surveyResponsesToBeSent release];
        surveyResponsesToBeSent = nil;
    }
    
    if ([currentRequiredSkill length])
        [introDict setObject:currentRequiredSkill forKey:@"skill"];
    
    [introDict setObject:[NSNumber numberWithBool:appForegrounded] forKey:@"app_foregrounded"];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *localizationTableHash = [userDefaults objectForKey:LIOBundleManagerStringTableHashKey];
    if ([localizationTableHash length])
        [introDict setObject:localizationTableHash forKey:@"strings_hash"];

    NSString *localeId = [[NSLocale currentLocale] objectForKey:NSLocaleIdentifier];
    if ([localeId length])
        [introDict setObject:localeId forKey:@"locale"];
    
    NSString *languageId = [[NSLocale preferredLanguages] objectAtIndex:0];
    if ([languageId length])
        [introDict setObject:languageId forKey:@"language"];
    
    if (includeExtras)
    {
        [introDict setObject:LIOLookIOManagerVersion forKey:@"version"];
        
        // Detect some stuff about the client.
        NSMutableDictionary *detectedDict = [NSMutableDictionary dictionary];
        
        NSString *carrierName = [[LIOAnalyticsManager sharedAnalyticsManager] cellularCarrierName];
        if ([carrierName length])
            [detectedDict setObject:carrierName forKey:@"carrier_name"];
        
        NSString *bundleVersion = [[LIOAnalyticsManager sharedAnalyticsManager] hostAppBundleVersion];
        if ([bundleVersion length])
            [detectedDict setObject:bundleVersion forKey:@"app_bundle_version"];
        
        if ([[LIOAnalyticsManager sharedAnalyticsManager] locationServicesEnabled])
            [detectedDict setObject:@"enabled"/*[NSNumber numberWithBool:YES]*/ forKey:@"location_services"];
        else
            [detectedDict setObject:@"disabled"/*[NSNumber numberWithBool:NO]*/ forKey:@"location_services"];
        
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
        
        if (lastKnownLocation)
        {
            NSNumber *lat = [NSNumber numberWithDouble:lastKnownLocation.coordinate.latitude];
            NSNumber *lon = [NSNumber numberWithDouble:lastKnownLocation.coordinate.longitude];
            NSDictionary *location = [NSDictionary dictionaryWithObjectsAndKeys:lat, @"latitude", lon, @"longitude", nil];
            [detectedDict setObject:location forKey:@"location"];
        }
                                       
        NSMutableDictionary *extrasDict = [NSMutableDictionary dictionary];
        if ([sessionExtras count])
            [extrasDict setDictionary:sessionExtras];
        
        if ([detectedDict count])
            [extrasDict setObject:detectedDict forKey:@"detected_settings"];
        
        if ([lastKnownPageViewValue length])
            [extrasDict setObject:lastKnownPageViewValue forKey:@"view_name"];
        
        if ([extrasDict count])
        {
            [introDict setObject:extrasDict forKey:@"extras"];
            
            NSString *emailAddress = [extrasDict objectForKey:@"email_address"];
            if ([emailAddress length])
            {
                [pendingEmailAddress release];
                pendingEmailAddress = [emailAddress retain];
            }
        }
    }
    
    return introDict;
}

- (void)configureReconnectionTimer
{
    /*
    // Are we done?
    if (socketConnected)
    {
        LIOLog(@"RESUME MODE TERMINATED: socket did reconnect.");
        
        [self killReconnectionTimer];
        resumeMode = NO;
        previousReconnectionTimerStep = 2;
        
        return;
    }
    
    // Reset session if the last activity was more than 10 minutes ago.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDate *lastActivity = [userDefaults objectForKey:LIOLookIOManagerLastActivityDateKey];
    if ([lastActivity timeIntervalSinceNow] < -LIOLookIOManagerReconnectionTimeLimit)
    {
        [self reset];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertTitle")
                                                            message:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertBody")
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertButton"), nil];
        [alertView show];
        [alertView autorelease];
        
        LIOLog(@"Session forcibly terminated. Reason: reconnection mode terminated due to last activity being too far in the past.");
        
        return;
    }
        
    // Guard against the case where we are in the process of reconnecting.
    if (NO == controlSocketConnecting)
    {
        [altChatViewController showReconnectionOverlay];
        [self beginConnectingWithError:nil];
    }
    
    NSTimeInterval timerInterval = exp2(previousReconnectionTimerStep);
    reconnectionTimer = [[LIOTimerProxy alloc] initWithTimeInterval:timerInterval
                                                             target:self
                                                           selector:@selector(reconnectionTimerDidFire)];
        
    // Max: 2**6, or 64 seconds
    previousReconnectionTimerStep++;
    if (previousReconnectionTimerStep > 6)
        previousReconnectionTimerStep = 6;
     */
}

- (void)killReconnectionTimer
{
    [reconnectionTimer stopTimer];
    [reconnectionTimer release];
    reconnectionTimer = nil;
}

- (void)reconnectionTimerDidFire
{
    [self killReconnectionTimer];
    
    [self configureReconnectionTimer];
}

- (void)reintroTimeoutTimerDidFire
{
    resetAfterDisconnect = YES;
    [self killConnection];
    
    [self dismissDismissibleAlertView];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertTitle")
                                                        message:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertBody")
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertButton"), nil];
    [alertView show];
    [alertView autorelease];
        
    LIOLog(@"Session forcibly terminated. Reason: reintro process took too long!");
}

- (void)continuationTimerDidFire
{
    [continuationTimer stopTimer];
    [continuationTimer release];
    
    if (0.0 == nextTimeInterval)
        nextTimeInterval = LIOLookIOManagerDefaultContinuationReportInterval;
    
    continuationTimer = [[LIOTimerProxy alloc] initWithTimeInterval:nextTimeInterval
                                                             target:self
                                                           selector:@selector(continuationTimerDidFire)];
    
    [self sendContinuationReport];
}

- (void)realtimeExtrasTimerDidFire
{
    if (shouldSendCapabilitiesPacket)
        [self sendCapabilitiesPacket];
    
    if (shouldSendChatHistoryPacket)
        [self sendChatHistoryPacketWithDict:failedChatHistoryDict];
    
    // We watch for changes to:
    // 1) the extras dictionary
    // 2) network: wifi / cell
    // 3) location
    
    // Run a location check?
    // FIXME: Do this as a callback, not as a poll.
    /*
    if (NO == realtimeExtrasWaitingForLocation && [[LIOAnalyticsManager sharedAnalyticsManager] locationServicesEnabled] && nil == realtimeExtrasChangedLocation)
    {
        // We don't ask for a location update if we've already got a pending changed location that we need to submit.
        realtimeExtrasWaitingForLocation = YES;
        [[LIOAnalyticsManager sharedAnalyticsManager] beginLocationCheck];
    }
    */
    
    if (nil == realtimeExtrasPreviousSessionExtras)
        realtimeExtrasPreviousSessionExtras = [sessionExtras copy];
    
    BOOL significantChangeWasDetected = NO;
    
    if (NO == [sessionExtras isEqualToDictionary:realtimeExtrasPreviousSessionExtras])
    {
        [realtimeExtrasPreviousSessionExtras release];
        realtimeExtrasPreviousSessionExtras = [sessionExtras copy];
        
        significantChangeWasDetected = YES;
    }
    
    if (realtimeExtrasChangedLocation)
        significantChangeWasDetected = YES;
    
    if (realtimeExtrasLastKnownCellNetworkInUse != [[LIOAnalyticsManager sharedAnalyticsManager] cellularNetworkInUse])
    {
        realtimeExtrasLastKnownCellNetworkInUse = [[LIOAnalyticsManager sharedAnalyticsManager] cellularNetworkInUse];
        significantChangeWasDetected = YES;
    }
    
    if (significantChangeWasDetected)
    {
        [realtimeExtrasChangedLocation release];
        realtimeExtrasChangedLocation = nil;

        // Send an update.
        NSDictionary *introDict = [self buildIntroDictionaryIncludingExtras:YES includingType:NO includingSurveyResponses:NO includingEvents:NO];
        NSDictionary *extrasDict = [introDict objectForKey:@"extras"];

        [self sendCustomVarsPacketWithDict:extrasDict];
    }
}

- (void)showReconnectionQuery
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.ReconnectQuestionAlertTitle")
                                                        message:LIOLocalizedString(@"LIOLookIOManager.ReconnectQuestionAlertBody")
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.ReconnectQuestionAlertButtonClose"), LIOLocalizedString(@"LIOLookIOManager.ReconnectQuestionAlertButtonReconnect"), nil];
    alertView.tag = LIOLookIOManagerReconnectionModeAlertViewTag;
    [alertView show];
    [alertView autorelease];
}

- (void)populateChatWithFirstMessage
{
    if (0 == [chatHistory count])
    {
        LIOChatMessage *firstMessage = [LIOChatMessage chatMessage];
        firstMessage.kind = LIOChatMessageKindRemote;
        firstMessage.date = [NSDate date];
        firstMessage.lineId = nil;
        [chatHistory addObject:firstMessage];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSData *chatHistoryData = [NSKeyedArchiver archivedDataWithRootObject:chatHistory];
        [userDefaults setObject:chatHistoryData forKey:LIOLookIOManagerLastKnownChatHistoryKey];
        [userDefaults synchronize];
        
        if ([lastKnownWelcomeMessage length])
            firstMessage.text = lastKnownWelcomeMessage;
        else
            firstMessage.text = LIOLocalizedString(@"LIOLookIOManager.DefaultWelcomeMessage");
    }
}

- (BOOL)isIntraLink:(NSURL *)aURL
{
    return [urlSchemes containsObject:[aURL scheme]];
}

- (id)linkViewForURL:(NSURL *)aURL
{
    if (NO == [urlSchemes containsObject:[aURL scheme]])
        return nil;
    
    if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManager:linkViewForURL:)])
        return [delegate lookIOManager:self linkViewForURL:aURL];
    
    return nil;
}

- (void)beginTransitionWithIntraAppLinkURL:(NSURL *)aURL
{
    [pendingIntraAppLinkURL release];
    pendingIntraAppLinkURL = [aURL retain];
    
    [altChatViewController performDismissalAnimation];
    [self dismissBlurImageView:YES];
}

- (BOOL)customBrandingAvailable
{
    return [(NSObject *)delegate respondsToSelector:@selector(lookIOManager:brandingImageForDimensions:)];
}

- (BOOL)supportDeprecatedXcodeVersions
{
    BOOL supportDeprecatedXcodeVersions = NO;
    if ([(NSObject *)delegate respondsToSelector:@selector(supportDeprecatedXcodeVersions)])
        supportDeprecatedXcodeVersions = [delegate supportDeprecatedXcodeVersions];
    
    
    return supportDeprecatedXcodeVersions;
}

- (id)brandingViewWithDimensions:(CGSize)aSize
{
    if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManager:brandingImageForDimensions:)])
    {
        id aView = [delegate lookIOManager:self brandingImageForDimensions:aSize];
        if (aView)
        {
            if ([aView isKindOfClass:[UIImage class]])
            {
                UIImage *anImage = (UIImage *)aView;
                return anImage;
            }
            else 
            {
                [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"Expected a UIImage from \"brandingImageForDimensions\". Got: \"%@\". Falling back to default branding!", NSStringFromClass([aView class])];
            }
        }
    }
    
    return nil;
}

- (void)setUsesTLS:(NSNumber *)aNumber
{
    usesTLS = [aNumber boolValue];
}

- (BOOL)registerPlugin:(id<LIOPlugin>)aPlugin
{
    NSString *pluginId = [aPlugin pluginId];
    if ([registeredPlugins objectForKey:pluginId])
    {
        [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"Ignoring attempt to register duplicate plugin with id \"%@\"", pluginId];
        return NO;
    }
    
    [registeredPlugins setObject:aPlugin forKey:pluginId];
    [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityInfo format:@"Registered new plugin with id \"%@\"", pluginId];
    
    return YES;
}

- (void)reportEvent:(NSString *)anEvent
{
    [self reportEvent:anEvent withData:nil];
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
    [newEvent setObject:[self dateToStandardizedString:[NSDate date]] forKey:@"timestamp"];
    
    [pendingEvents addObject:newEvent];
    
    // Queue is capped. Remove oldest entry on overflow.
    if ([pendingEvents count] > LIOLookIOMAnagerMaxEventQueueSize)
        [pendingEvents removeObjectAtIndex:0];
    
    [[NSUserDefaults standardUserDefaults] setObject:pendingEvents forKey:LIOLookIOManagerPendingEventsKey];
    
    // Immediately make a continue call, unless the event is the built-in "page view" one.
    if (NO == [anEvent isEqualToString:kLPEventPageView])
    {
        [self sendContinuationReport];
    }
    else if ([someData isKindOfClass:[NSString class]])
    {
        // Okay, this IS a pageview event. Record it as the last known.
        [lastKnownPageViewValue release];
        lastKnownPageViewValue = (NSString *)[someData retain];
    }
}



#pragma mark -
#pragma mark LIOAltChatViewControllerDataSource methods

- (NSArray *)altChatViewControllerChatMessages:(LIOAltChatViewController *)aController
{
    return chatHistory;
}

#pragma mark -
#pragma mark LIOAltChatViewController delegate methods

- (void)altChatViewController:(LIOAltChatViewController *)aController wasDismissedWithPendingChatText:(NSString *)aString
{
    [pendingChatText release];
    pendingChatText = [aString retain];

    // In case the user hasn't typed in any messages, and either surveys are turned off, or he recived and empty survey, we can reset the session
    LIOSurveyManager *surveyManager = [LIOSurveyManager sharedSurveyManager];
    if (!firstChatMessageSent && (!surveyManager.surveysEnabled || (surveyManager.surveysEnabled && surveyManager.receivedEmptyPreSurvey)))
        [self altChatViewControllerWantsSessionTermination:altChatViewController];
    else {
        [altChatViewController performDismissalAnimation];
        [self dismissBlurImageView:YES];
    }
}

-(void)dismissBlurImageView:(BOOL)animated {
    if (!selectedChatTheme == kLPChatThemeFlat)
        return;
    
    if (!animated) {
        [blurImageView removeFromSuperview];
        [blurImageView release];
        blurImageView = nil;
    } else {
        [UIView animateWithDuration:0.15 animations:^{
            blurImageView.alpha = 0.0;
        } completion:^(BOOL finished) {
            [blurImageView removeFromSuperview];
            [blurImageView release];
            blurImageView = nil;
        }];
    }
}

- (void)altChatViewController:(LIOAltChatViewController *)aController didChatWithText:(NSString *)aString
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSDate date] forKey:LIOLookIOManagerLastActivityDateKey];
    [userDefaults synchronize];
    
    LIOChatMessage *newMessage = [LIOChatMessage chatMessage];
    newMessage.date = [NSDate date];
    newMessage.kind = LIOChatMessageKindLocal;
    newMessage.text = aString;
    newMessage.sendingFailed = NO;
    newMessage.lineId = nil;
    newMessage.clientLineId = [NSString stringWithFormat:@"%d", lastClientLineId];
    lastClientLineId += 1;
    [chatHistory addObject:newMessage];
    
    NSData *chatHistoryData = [NSKeyedArchiver archivedDataWithRootObject:chatHistory];
    [userDefaults setObject:chatHistoryData forKey:LIOLookIOManagerLastKnownChatHistoryKey];
    [userDefaults synchronize];
    
    [altChatViewController reloadMessages];
    [altChatViewController scrollToBottomDelayed:YES];
    
    firstChatMessageSent = YES;

    [self sendLinePacketWithMessage:newMessage];
}

- (void)altChatViewController:(LIOAltChatViewController *)aController didResendChatMessage:(LIOChatMessage *)aMessage {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSDate date] forKey:LIOLookIOManagerLastActivityDateKey];
    [userDefaults synchronize];
    
    if ([aMessage.attachmentId length])
        [self sendMediaPacketWithMessage:aMessage];
    else
        [self sendLinePacketWithMessage:aMessage];
}

- (void)altChatViewController:(LIOAltChatViewController *)aController didChatWithAttachmentId:(NSString *)aString
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSDate date] forKey:LIOLookIOManagerLastActivityDateKey];
    [userDefaults synchronize];
    
    NSData *attachmentData = [[LIOMediaManager sharedInstance] mediaDataWithId:aString];
    if (attachmentData)
    {
        LIOChatMessage *newMessage = [LIOChatMessage chatMessage];
        newMessage.text = aString;
        newMessage.date = [NSDate date];
        newMessage.kind = LIOChatMessageKindLocal;
        newMessage.attachmentId = aString;
        [chatHistory addObject:newMessage];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSData *chatHistoryData = [NSKeyedArchiver archivedDataWithRootObject:chatHistory];
        [userDefaults setObject:chatHistoryData forKey:LIOLookIOManagerLastKnownChatHistoryKey];
        [userDefaults synchronize];
        
        [altChatViewController reloadMessages];
        [altChatViewController scrollToBottomDelayed:YES];
        
        firstChatMessageSent = YES;
        
        // Upload the attachment.
        [self sendMediaPacketWithMessage:newMessage];
    }
}

- (void)altChatViewControllerDidTapEndSessionButton:(LIOAltChatViewController *)aController
{
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    
    dismissibleAlertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.EndSessionQuestionAlertTitle")
                                                        message:LIOLocalizedString(@"LIOLookIOManager.EndSessionQuestionAlertBody")
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.EndSessionQuestionAlertButtonNo"), LIOLocalizedString(@"LIOLookIOManager.EndSessionQuestionAlertButtonYes"), nil];
    dismissibleAlertView.tag = LIOLookIOManagerDisconnectConfirmAlertViewTag;
    [dismissibleAlertView show];
    [dismissibleAlertView autorelease];
}

- (void)altChatViewControllerDidTapEndScreenshotsButton:(LIOAltChatViewController *)aController
{
    screenshotsAllowed = NO;
    
    statusBarUnderlay.hidden = YES;
    statusBarUnderlayBlackout.hidden = YES;
    if (NO == [[UIApplication sharedApplication] isStatusBarHidden])
        [[UIApplication sharedApplication] setStatusBarStyle:originalStatusBarStyle];
    
    [self sendPermissionPacketWithAsset:@"screenshare" granted:NO];
    
    [screenSharingStartedDate release];
    screenSharingStartedDate = nil;
}

- (void)altChatViewControllerDidStartDismissalAnimation:(LIOAltChatViewController *)aController
{
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
}


- (void)altChatViewControllerDidFinishDismissalAnimation:(LIOAltChatViewController *)aController
{
    if (dismissibleAlertView) {
        [dismissibleAlertView dismissWithClickedButtonIndex:-1 animated:NO];
        dismissibleAlertView = nil;
    }
    
    if (chatClosingAsPartOfReset) {
        [self reset];
        return;
    }
    
    if (altChatViewController) {
        [pendingChatText release];
        pendingChatText = [[altChatViewController currentChatText] retain];
        [altChatViewController bailOnSecondaryViews];
        [altChatViewController.view removeFromSuperview];
        [altChatViewController release];
        altChatViewController = nil;
    }
    
    int64_t delayInSeconds = 0.25;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self rejiggerControlButtonFrame];
        controlButtonHidden = YES;
        if (controlButtonType == kLPControlButtonClassic)
            controlButton.frame = controlButtonHiddenFrame;
        if (controlButtonType == kLPControlButtonSquare)
            squareControlButton.frame = controlButtonHiddenFrame;
        [self rejiggerControlButtonLabel];
        [self rejiggerWindows];
    });
    
    if (callChatNotAnsweredAfterDismissal) {
        callChatNotAnsweredAfterDismissal = NO;

        double delayInSeconds = 0.25;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW,(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManagerCustomActionForChatNotAnswered:)])
                [delegate lookIOManagerCustomActionForChatNotAnswered:self];
        });
    }
    
    if (socketConnected)
    {
        NSDictionary *chatDown = [NSDictionary dictionaryWithObjectsAndKeys:
                                                           @"chat_down", @"action",
                                                           nil];
        [self sendAdvisoryPacketWithDict:chatDown];
    }
    
    if (killConnectionAfterChatViewDismissal)
    {
        resetAfterDisconnect = YES;
        [self killConnection];
        return;
    }
    else if (resetAfterChatViewDismissal)
    {
        [self reset];
        return;
    }
    
    if (pendingIntraAppLinkURL)
    {
        [[UIApplication sharedApplication] openURL:pendingIntraAppLinkURL];
        [pendingIntraAppLinkURL release];
        pendingIntraAppLinkURL = nil;
    }
    
}

- (void)altChatViewControllerTypingDidStart:(LIOAltChatViewController *)aController
{
    if (introduced)
    {
        NSDictionary *typingStart = [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"typing_start", @"action",
                                     nil];
        [self sendAdvisoryPacketWithDict:typingStart];
    }
}

- (void)altChatViewControllerTypingDidStop:(LIOAltChatViewController *)aController
{
    if (introduced)
    {
        NSDictionary *typingStop = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"typing_stop", @"action",
                                    nil];
        [self sendAdvisoryPacketWithDict:typingStop];

    }
}

// iOS >= 6.0
- (BOOL)altChatViewControllerShouldAutorotate:(LIOAltChatViewController *)aController
{
    return [self shouldAutorotate];
}

// iOS >= 6.0
- (NSInteger)altChatViewControllerSupportedInterfaceOrientations:(LIOAltChatViewController *)aController
{
    return [self supportedInterfaceOrientations];
}

- (BOOL)altChatViewController:(LIOAltChatViewController *)aController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation
{
    return [self shouldRotateToInterfaceOrientation:anOrientation];
}

- (void)altChatViewController:(LIOAltChatViewController *)aController didEnterTranscriptEmail:(NSString *)anEmail
{
    NSDictionary *aDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:anEmail], @"email_addresses", nil];

    [self sendChatHistoryPacketWithDict:aDict];
}

- (void)altChatViewController:(LIOAltChatViewController *)aController didEnterLeaveMessageEmail:(NSString *)anEmail withMessage:(NSString *)aMessage
{
    if ([anEmail length] && [aMessage length])
    {
        userWantsSessionTermination = YES;
        
        NSMutableDictionary *feedbackDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             anEmail, @"email_address",
                                             aMessage, @"message",
                                             nil];
        
        [self sendFeedbackPacketWithDict:feedbackDict];
        
    }
}

- (void)altChatViewController:(LIOAltChatViewController *)aController didFinishOfflineSurveyWithResponses:(NSDictionary*)aResponseDict {
    userWantsSessionTermination = YES;
    
    [surveyResponsesToBeSent release];
    surveyResponsesToBeSent = [aResponseDict retain];
    
    LIOSurveyManager* surveyManager = [LIOSurveyManager sharedSurveyManager];
    
    if (!surveyManager.offlineSurveyIsDefault) {

        NSMutableDictionary* surveyDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             aResponseDict, @"offline",
                                             nil];
        
        [self sendSurveyPacketWithDict:surveyDict withType:LIOSurveyManagerSurveyTypeOffline];
    
    } else {
        NSString* anEmail = [surveyManager answerObjectForSurveyType:LIOSurveyManagerSurveyTypeOffline withQuestionIndex:0];
        NSString* aMessage = [surveyManager answerObjectForSurveyType:LIOSurveyManagerSurveyTypeOffline withQuestionIndex:1];
        if ([anEmail length] && [aMessage length])
        {
            userWantsSessionTermination = YES;
            
            NSMutableDictionary *feedbackDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                 anEmail, @"email_address",
                                                 aMessage, @"message",
                                                 nil];
            
            [self sendFeedbackPacketWithDict:feedbackDict];
        }
    }
}

- (void)altChatViewController:(LIOAltChatViewController *)aController didFinishPostSurveyWithResponses:(NSDictionary*)aResponseDict {
    userWantsSessionTermination = YES;
    
    [surveyResponsesToBeSent release];
    surveyResponsesToBeSent = [aResponseDict retain];
    
    NSMutableDictionary* surveyDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           aResponseDict, @"postchat",
                                           nil];
        
    [self sendSurveyPacketWithDict:surveyDict withType:LIOSurveyManagerSurveyTypePost];
}

- (void)altChatViewControllerWantsSessionTermination:(LIOAltChatViewController *)aController
{
    if (socketConnected || outroReceived)
    {
        // In rare cases, this method is called when there is not altChatViewController
        // In that case, we should just terminate the session

        sessionEnding = YES;
        userWantsSessionTermination = YES;
        resetAfterDisconnect = YES;

        if (outroReceived)
            resetAfterChatViewDismissal = YES;
        else
            killConnectionAfterChatViewDismissal = YES;
        
        if (altChatViewController) {
            [altChatViewController performDismissalAnimation];
            [self dismissBlurImageView:YES];
        }
        else
            [self altChatViewControllerDidFinishDismissalAnimation:nil];

    }
    else
    {
        [self reset];
    }
}

- (void)altChatViewControllerWantsToLeaveSurvey:(LIOAltChatViewController *)aController
{
    resetAfterChatViewDismissal = YES;
    [altChatViewController performDismissalAnimation];
    [self dismissBlurImageView:YES];
}

- (void)altChatViewController:(LIOAltChatViewController *)aController didFinishPreSurveyWithResponses:(NSDictionary *)aResponseDict
{
    [surveyResponsesToBeSent release];
    surveyResponsesToBeSent = [aResponseDict retain];

//    NSDictionary* surveyDict = [NSDictionary dictionaryWithObject:surveyResponsesToBeSent forKey:@"prechat_survey"];
//    [self sendCustomVarsPacketWithDict:surveyDict];
    
    NSMutableDictionary* surveyDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       surveyResponsesToBeSent, @"prechat",
                                       nil];
    
    [self sendSurveyPacketWithDict:surveyDict withType:LIOSurveyManagerSurveyTypePre];

}

- (void)altChatViewControllerWillPresentImagePicker:(LIOAltChatViewController *)aController
{
    shouldLockOrientation = YES;
}

- (void)altChatViewControllerWillDismissImagePicker:(LIOAltChatViewController *)aController
{
    shouldLockOrientation = NO;
}

- (BOOL)altChatViewControllerShouldHideEmailChat:(LIOAltChatViewController *)aController
{
    return lastKnownHideEmailChat;
}


- (BOOL)shouldLockInterfaceOrientation
{
    if (altChatViewController && shouldLockOrientation)
        return shouldLockOrientation;
    
    return NO;
}


#pragma mark -
#pragma mark LIOInterstitialViewControllerDelegate methods

- (void)interstitialViewControllerWasDismissed:(LIOInterstitialViewController *)aController
{
    [interstitialViewController.view removeFromSuperview];
    [interstitialViewController release];
    interstitialViewController = nil;
    
    [self rejiggerWindows];
}

- (void)interstitialViewControllerWantsChatInterface:(LIOInterstitialViewController *)aController
{
    [interstitialViewController.view removeFromSuperview];
    [interstitialViewController release];
    interstitialViewController = nil;
    
    [self showChatAnimated:NO];
}

- (BOOL)interstitialViewController:(LIOInterstitialViewController *)aController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation
{
    return [self shouldRotateToInterfaceOrientation:anOrientation];
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag)
    {
        case LIOLookIOManagerReconnectionFailedAlertViewTag:
        {
            if (kLPControlButtonClassic == controlButtonType) {
                controlButton.currentMode = LIOControlButtonViewModeDefault;
                [controlButton setNeedsLayout];
            }
            if (kLPControlButtonSquare == controlButtonType) {
                squareControlButton.currentMode = LIOControlButtonViewModeDefault;
                [squareControlButton setNeedsLayout];
            }
            [self rejiggerControlButtonFrame];

            [self reset];
            break;
        }
            
        case LIOLookIOManagerReconnectionSucceededAlertViewTag:
        {
            willAskUserToReconnect = NO;
            
            // In case we've disconnected in the meantime, just don't do anything
            if (!socketConnected)
                break;
            
            if (1 == buttonIndex && !altChatViewController)
                [self showChatAnimated:YES];
            
            if (0 == buttonIndex && altChatViewController)
                [altChatViewController performDismissalAnimation];
            
            if (controlButtonType == kLPControlButtonClassic) {
                controlButton.currentMode = LIOControlButtonViewModeDefault;
                [controlButton setNeedsLayout];
            }
            if (controlButtonType == kLPControlButtonSquare) {
                squareControlButton.currentMode = LIOControlButtonViewModeDefault;
                [controlButton setNeedsLayout];
            }
            [self rejiggerControlButtonFrame];
            
            break;
        }
            
        case LIOLookIOManagerReconnectionCancelAlertViewTag:
        {
            if (0 == buttonIndex) // Cancel
                [self reset];
            
            break;
        }
            
        case LIOLookIOManagerReconnectionModeAlertViewTag:
        {
            if (1 == buttonIndex) // "Try Reconnect"
            {
                [self connectSSESocket];
                
                if (kLPControlButtonClassic == controlButtonType) {
                    controlButton.currentMode = LIOControlButtonViewModePending;
                    [controlButton layoutSubviews];
                }
                if (kLPControlButtonSquare == controlButtonType) {
                    squareControlButton.currentMode = LIOControlButtonViewModePending;
                    [squareControlButton layoutSubviews];
                }
                [self rejiggerControlButtonFrame];
                [self applicationDidChangeStatusBarOrientation:nil]; // update tab to show "Reconnecting", etc
                resumeMode = YES;
                
                willAskUserToReconnect = NO;
            }
            else // Close
            {
                [self reset];
            }
            
            break;
        }
            
        case LIOLookIOManagerSSEConnectionFailedAlertViewTag:
        {
            [self reset];
            break;
        }
            
        case LIOLookIOManagerDisconnectErrorAlertViewTag:
        {
            [self rejiggerWindows];
            break;
        }
            
        case LIOLookIOManagerDisconnectOutroAlertViewTag:
        {
            LIOSurveyManager* surveryManager = [LIOSurveyManager sharedSurveyManager];
            if (surveryManager.postChatTemplate && surveryManager.surveysEnabled) {
                // Let's check to see if the chat view controller is visible. If not, present it before
                // killing the session or presenting the survey
                
                if (altChatViewController) {
                    double delayInSeconds = 0.2;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        [altChatViewController showSurveyViewForType:LIOSurveyManagerSurveyTypePost];
                    });
                }
                else {
                    [self showChatAnimated:YES];
                    
                    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
                    
                    if (!padUI) {
                        [altChatViewController showSurveyViewForType:LIOSurveyManagerSurveyTypePost];
                    } else {
                        [altChatViewController hideChatUIForSurvey:NO];
                        double delayInSeconds = 0.5;
                        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (delayInSeconds * NSEC_PER_SEC));
                        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                            [altChatViewController showSurveyViewForType:LIOSurveyManagerSurveyTypePost];
                        });
                    }
                }
                return;
            }
        
            [self altChatViewControllerWantsSessionTermination:altChatViewController];
            return;

            
            break;
        }
            
            
        case LIOLookIOManagerDisconnectConfirmAlertViewTag:
        {
            dismissibleAlertView = nil;
            
            if (1 == buttonIndex) // "Yes"
            {
                [self endChat];
            }
            
            break;
        }
            
        case LIOLookIOManagerDisconnectedByDeveloperAlertViewTag:
        {
            dismissibleAlertView = nil;
            [self endChat];
            
            break;
        }
            
        case LIOLookIOManagerScreenshotPermissionAlertViewTag:
        {
            if (1 == buttonIndex) // "Yes"
            {
                screenshotsAllowed = YES;
                statusBarUnderlay.hidden = NO;
                if (NO == [[UIApplication sharedApplication] isStatusBarHidden])
                    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
                
                [self sendPermissionPacketWithAsset:@"screenshare" granted:YES];
                
                screenSharingStartedDate = [[NSDate date] retain];
                
                if (altChatViewController)
                {
                    [pendingChatText release];
                    pendingChatText = [[altChatViewController currentChatText] retain];
                    [altChatViewController bailOnSecondaryViews];
                    [altChatViewController.view removeFromSuperview];
                    [altChatViewController release];
                    altChatViewController = nil;
                    [self dismissBlurImageView:NO];
                    [self rejiggerWindows];
                }
            }
            if (0 == buttonIndex)
                [self sendPermissionPacketWithAsset:@"screenshare" granted:NO];
            
            break;
        }
                        
        case LIOLookIOManagerUnprovisionedAlertViewTag:
        {
            resetAfterChatViewDismissal = YES;
            [altChatViewController performDismissalAnimation];
            [self dismissBlurImageView:YES];
            break;
        }
    }
}

#pragma mark -
#pragma mark Notification handlers

- (void)dismissDismissibleAlertView
{
    if (dismissibleAlertView) {
        [dismissibleAlertView dismissWithClickedButtonIndex:-1 animated:NO];
        dismissibleAlertView = nil;
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)aNotification
{
    appForegrounded = NO;
    
    if (dismissibleAlertView) {
        [dismissibleAlertView dismissWithClickedButtonIndex:-1 animated:NO];
        dismissibleAlertView = nil;
    }
    
    if (UIBackgroundTaskInvalid == backgroundTaskId)
    {
        backgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskId];
            backgroundTaskId = UIBackgroundTaskInvalid;
        }];
        
        [backgroundedTime release];
        backgroundedTime = [[NSDate date] retain];
        
        [self sendContinuationReport];
    }
    
    if (socketConnected)
    {
        NSMutableDictionary *backgroundedDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                 @"app_backgrounded", @"action",
                                                 nil];
        
        [self sendAdvisoryPacketWithDict:backgroundedDict];
    }
    
    if (altChatViewController)
    {
        [altChatViewController dismissSurveyView];
        
        [pendingChatText release];
        pendingChatText = [[altChatViewController currentChatText] retain];
        [altChatViewController bailOnSecondaryViews];
        [altChatViewController.view removeFromSuperview];
        [altChatViewController release];
        altChatViewController = nil;

        // In case the user hasn't typed in any messages, and either surveys are turned off, or he recived and empty survey, we can reset the session
        LIOSurveyManager *surveyManager = [LIOSurveyManager sharedSurveyManager];
        if (!firstChatMessageSent) {
            if (!surveyManager.surveysEnabled || (surveyManager.surveysEnabled && surveyManager.receivedEmptyPreSurvey)) {
                userWantsSessionTermination = YES;
                resetAfterDisconnect = YES;
                [self killConnection];
            }
        }
        
        [self dismissBlurImageView:NO];
    }
    
    [pendingIntraAppLinkURL release];
    pendingIntraAppLinkURL = nil;

    // The delayed execution here is required to avoid stuck keyboard issues. -_-
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self rejiggerWindows];
    });
}

- (void)applicationWillEnterForeground:(NSNotification *)aNotification
{
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];

    appForegrounded = YES;
    
    if (UIBackgroundTaskInvalid != backgroundTaskId)
    {
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskId];
        backgroundTaskId = UIBackgroundTaskInvalid;
        
        if ([backgroundedTime timeIntervalSinceNow] <= -1800.0)
        {
            // It's been 30 minutes! Send a launch packet.
            [overriddenEndpoint release];
            overriddenEndpoint = nil;
            [currentVisitId release];
            currentVisitId = nil;
            [lastKnownVisitURL release];
            lastKnownVisitURL = nil;
            [continuationTimer stopTimer];
            [continuationTimer release];
            continuationTimer = nil;
            
            [self reset];
            [self sendLaunchReport];
        }
        else
            [self sendContinuationReport];
        
        [backgroundedTime release];
        backgroundedTime = nil;
    }
    
    if (socketConnected)
    {
        NSMutableDictionary *foregroundedDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                    @"app_foregrounded", @"action",
                                                    nil];

        [self sendAdvisoryPacketWithDict:foregroundedDict];
        
        // We also force the LookIO UI to the foreground here.
        // This prevents any jank: the user can always go out of the app and come back in
        // to correct any wackiness that might occur.
        if (chatReceivedWhileAppBackgrounded)
        {
            chatReceivedWhileAppBackgrounded = NO;
            [self showChatAnimated:NO];
        }
        
        if (resetAfterNextForegrounding)
        {
            int64_t delayInSeconds = 0.1;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                if (socketConnected)
                {
                    resetAfterDisconnect = YES;
                    userWantsSessionTermination = YES;
                    if (sseManager)
                        [sseManager disconnect];
                }
                else
                    [self reset];
            });
        }
    }

    [self refreshControlButtonVisibility];
    [self rejiggerControlButtonFrame];
    [self rejiggerControlButtonLabel];
}

- (void)applicationWillChangeStatusBarOrientation:(NSNotification *)aNotification
{
    rotationIsActuallyHappening = YES;
    if (kLPControlButtonClassic == controlButtonType)
        controlButton.hidden = YES;
    if (kLPControlButtonSquare == controlButtonType)
        squareControlButton.hidden = YES;
    statusBarUnderlay.hidden = YES;
    statusBarUnderlayBlackout.hidden = YES;
    if (selectedChatTheme == kLPChatThemeFlat)
        [self takeScreenshotAndSetBlurImageView];
}

- (void)applicationDidChangeStatusBarOrientation:(NSNotification *)aNotification
{
    double delayInSeconds = 0.2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (kLPControlButtonClassic == controlButtonType)
            controlButton.hidden = NO;
        if (kLPControlButtonSquare == controlButtonType)
            squareControlButton.hidden = NO;
        
        if (kLPControlButtonClassic == controlButtonType) {
            if (NO == controlButtonHidden && (NO == CGRectEqualToRect(controlButton.frame, controlButtonShownFrame) || rotationIsActuallyHappening))
            {
                [self rejiggerControlButtonFrame];
                rotationIsActuallyHappening = NO;
                controlButtonHidden = YES;
                controlButton.frame = controlButtonHiddenFrame;

        controlButton.hidden = NO;
        if (NO == controlButtonHidden && (NO == CGRectEqualToRect(controlButton.frame, controlButtonShownFrame) || rotationIsActuallyHappening))
        {
            [self rejiggerControlButtonFrame];
            rotationIsActuallyHappening = NO;
            controlButtonHidden = YES;
            controlButton.frame = controlButtonHiddenFrame;
            [self rejiggerControlButtonLabel];
            

        }
        
        [self refreshControlButtonVisibility];
        
        statusBarUnderlay.frame = [[UIApplication sharedApplication] statusBarFrame];
        statusBarUnderlay.hidden = NO == screenshotsAllowed;

        statusBarUnderlayBlackout.frame = [[UIApplication sharedApplication] statusBarFrame];
        statusBarUnderlayBlackout.hidden = YES;
    });
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (UIInterfaceOrientationPortrait == actualInterfaceOrientation)
    {
    }
    else if (UIInterfaceOrientationLandscapeLeft == actualInterfaceOrientation)
    {
        transform = CGAffineTransformRotate(transform, -90.0 / 180.0 * M_PI);
    }
    else if (UIInterfaceOrientationPortraitUpsideDown == actualInterfaceOrientation)
    {
        transform = CGAffineTransformRotate(transform, -180.0 / 180.0 * M_PI);
    }
    else // Landscape, home button right
    {
        transform = CGAffineTransformRotate(transform, -270.0 / 180.0 * M_PI);
    }
    
    clickView.transform = transform;
    cursorView.transform = transform;
}

- (void)reachabilityDidChange:(NSNotification *)aNotification
{
    switch ([LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)
    {
        case LIOAnalyticsManagerReachabilityStatusConnected:
        {
            // Fire and forget a launch packet for each queued launch event.
            for (NSDate *aDate in queuedLaunchReportDates)
            {
                NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:nil
                                                                            cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                                        timeoutInterval:10.0];
                [request setHTTPMethod:@"POST"];
                [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                
                if ([overriddenEndpoint length])
                {
                    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http%@://%@/%@", usesTLS ? @"s" : @"", overriddenEndpoint, LIOLookIOManagerAppLaunchRequestURL]];
                    [request setURL:url];
                }
                else
                {
                    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http%@://%@/%@", usesTLS ? @"s" : @"", controlEndpoint, LIOLookIOManagerAppLaunchRequestURL]];
                    [request setURL:url];
                }
                
                NSDictionary *introDict = [self buildIntroDictionaryIncludingExtras:YES includingType:NO includingSurveyResponses:NO includingEvents:NO];
                NSString *introDictJSONEncoded = [jsonWriter stringWithObject:introDict];
                [request setHTTPBody:[introDictJSONEncoded dataUsingEncoding:NSUTF8StringEncoding]];
                [NSURLConnection connectionWithRequest:request delegate:nil];
                [request autorelease];
                LIOLog(@"<QUEUED_LAUNCH> Sent old launch packet for date: %@", aDate);
            }
            
            [queuedLaunchReportDates removeAllObjects];
            [[NSUserDefaults standardUserDefaults] setObject:queuedLaunchReportDates forKey:LIOLookIOManagerLaunchReportQueueKey];
            
            // Send out packets in the funnel queue in case network was disconnected
            if (funnelRequestQueue.count > 0) {
                NSNumber* nextFunnelState = [funnelRequestQueue objectAtIndex:0];
                [self sendFunnelPacketForState:[nextFunnelState intValue]];
                [funnelRequestQueue removeObjectAtIndex:0];
            }
            
            break;
        }
            
        case LIOAnalyticsManagerReachabilityStatusDisconnected:
        case LIOAnalyticsManagerReachabilityStatusUnknown:
            break;
    }
}

- (void)locationWasDetermined:(NSNotification *)aNotification
{
    NSDictionary *userInfo = [aNotification userInfo];
    CLLocation *newLocation = [userInfo objectForKey:LIOAnalyticsManagerLocationObjectKey];

    if (realtimeExtrasWaitingForLocation)
    {
        realtimeExtrasWaitingForLocation = NO;
        if (lastKnownLocation)
        {
            CGFloat latDelta = fabsf(newLocation.coordinate.latitude - lastKnownLocation.coordinate.latitude);
            CGFloat lonDelta = fabsf(newLocation.coordinate.longitude - lastKnownLocation.coordinate.longitude);
            
            if (latDelta >= LIOLookIOManagerRealtimeExtrasLocationChangeThreshhold || lonDelta >= LIOLookIOManagerRealtimeExtrasLocationChangeThreshhold)
            {
                // There was indeed a significant change...!
                [realtimeExtrasChangedLocation release];
                realtimeExtrasChangedLocation = [newLocation retain];
            }
        }
    }
    
    [lastKnownLocation release];
    lastKnownLocation = [newLocation retain];
    
    //LIOLog(@"\n\nLocation was determined!\n%@\n\n", lastKnownLocation);
}

#pragma mark -
#pragma mark NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    
    if (appLaunchRequestConnection == connection)
    {
        [appLaunchRequestData setData:[NSData data]];
        appLaunchRequestResponseCode = [httpResponse statusCode];
    
        // If there's a Location header, cancel this request and start a new one with
        // the overridden endpoint thingermadoo.
        NSString *location = [[httpResponse allHeaderFields] objectForKey:@"Location"];
        if ([location length])
        {
            [overriddenEndpoint release];
            overriddenEndpoint = [location retain];
            
            [connection cancel];
            
            appLaunchRequestIgnoringLocationHeader = YES;
            
            LIOLog(@"\n\n<<< REDIRECT >>>\n<<< REDIRECT >>> Location: %@\n<<< REDIRECT >>>\n\n", overriddenEndpoint);
            
            [self sendLaunchReport];
        }
        else
        {
            // We don't want the app/launch call that follows an endpoint override to
            // blow away the endpoint override that was just set!
            if (appLaunchRequestIgnoringLocationHeader)
                appLaunchRequestIgnoringLocationHeader = NO;
            else
            {
                [overriddenEndpoint release];
                overriddenEndpoint = nil;
            }
        }
    }
    else if (appContinueRequestConnection == connection)
    {
        [appContinueRequestData setData:[NSData data]];
        appContinueRequestResponseCode = [httpResponse statusCode];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (appLaunchRequestConnection == connection)
    {
        [appLaunchRequestData appendData:data];
    }
    else if (appContinueRequestConnection == connection)
    {
        [appContinueRequestData appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (appLaunchRequestConnection == connection)
    {
        if (appLaunchRequestResponseCode >= 400)
        {
            LIOLog(@"<LAUNCH> Failure. HTTP code: %d.", appLaunchRequestResponseCode);
            
            if (404 == appLaunchRequestResponseCode)
            {
                [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"The server has reported that your app is not configured for use with LivePerson Mobile. Please contact mobile@liveperson.com for assistance."];
            }
                
            // Disable the library explicitly.
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:LIOLookIOManagerMultiskillMappingKey];
            [multiskillMapping release];
            multiskillMapping = nil;
        }
        
        else if (appLaunchRequestResponseCode < 300)
        {
            NSString *responseString = [[[NSString alloc] initWithData:appLaunchRequestData encoding:NSUTF8StringEncoding] autorelease];
            NSDictionary *responseDict = [jsonParser objectWithString:responseString];
        
            LIOLog(@"<LAUNCH> Success. HTTP code: %d. Response: %@", appLaunchRequestResponseCode, responseString);
            [self parseAndSaveSettingsPayload:responseDict fromContinue:NO];
            
            LIOLog(@"<FUNNEL STATE> Visit");
            currentFunnelState = LIOFunnelStateVisit;
        }
        
        else
        {
            LIOLog(@"<LAUNCH> Unhandled HTTP code: %d", appLaunchRequestResponseCode);
        }
        
        [appLaunchRequestConnection release];
        appLaunchRequestConnection = nil;
        
        appLaunchRequestResponseCode = -1;
    }
    else if (appContinueRequestConnection == connection)
    {
        BOOL failure = NO;
        
        if (404 == appContinueRequestResponseCode)
        {
            // New launch.
            
            failure = YES;
            
            LIOLog(@"<CONTINUE> Failure. HTTP code: 404. The visit no longer exists. Starting a clean visit.");
            [currentVisitId release];
            currentVisitId = nil;
            [lastKnownVisitURL release];
            lastKnownVisitURL = nil;
            [continuationTimer stopTimer];
            [continuationTimer release];
            continuationTimer = nil;
            
            [self sendLaunchReport];
        }
        else if (appContinueRequestResponseCode >= 400)
        {
            // Retry logic.
            
            if (failedContinueCount < LIOLookIOManagerMaxContinueFailures)
            {
                failedContinueCount++;
                LIOLog(@"<CONTINUE> Retry attempt %u of %u...", failedContinueCount, LIOLookIOManagerMaxContinueFailures);
                
                // The timer should automatically trigger the next continue call.
            }
            else
            {
                LIOLog(@"<CONTINUE> Retries exhausted. Stopping future continue calls.");
                
                [continuationTimer stopTimer];
                [continuationTimer release];
                continuationTimer = nil;
                
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:LIOLookIOManagerLastKnownVisitorIdKey];
                [lastKnownVisitURL release];
                lastKnownVisitURL = nil;
                
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:LIOLookIOManagerMultiskillMappingKey];
                [multiskillMapping release];
                multiskillMapping = nil;
            }
        }
        else if (appContinueRequestResponseCode < 300 && appContinueRequestResponseCode >= 200)
        {
            // Success.
            NSString *responseString = [[[NSString alloc] initWithData:appContinueRequestData encoding:NSUTF8StringEncoding] autorelease];
            NSDictionary *responseDict = [jsonParser objectWithString:responseString];
            LIOLog(@"<CONTINUE> Success. HTTP code: %d. Response: %@", appContinueRequestResponseCode, responseString);
            
            failedContinueCount = 0;
            
            [self parseAndSaveSettingsPayload:responseDict fromContinue:YES];
            
            // Continue call succeeded! Purge the event queue.
            [pendingEvents removeAllObjects];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:LIOLookIOManagerPendingEventsKey];
            
            [self updateAndReportFunnelState];
        }
        else
        {
            // Wat.
            
            LIOLog(@"<CONTINUE> Unhandled HTTP code: %d", appContinueRequestResponseCode);            
        }
                
        [appContinueRequestConnection release];
        appContinueRequestConnection = nil;
        
        appContinueRequestResponseCode = -1;
        
        if (failure && [pendingEvents count])
        {
            // Oh crap, the continue call failed!
            // Save all queued events to the user defaults store.
            [[NSUserDefaults standardUserDefaults] setObject:pendingEvents forKey:LIOLookIOManagerPendingEventsKey];
        }
    } 
    
    [self refreshControlButtonVisibility];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (appLaunchRequestConnection == connection)
    {
        LIOLog(@"<LAUNCH> Connection failed. Reason: %@", [error localizedDescription]);
        
        [appLaunchRequestConnection release];
        appLaunchRequestConnection = nil;
        
        appLaunchRequestResponseCode = -1;
        
        // Disable the library explicitly.
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:LIOLookIOManagerMultiskillMappingKey];
        [multiskillMapping release];
        multiskillMapping = nil;
    }
    else if (appContinueRequestConnection == connection)
    {
        LIOLog(@"<CONTINUE> Failed. Reason: %@", [error localizedDescription]);
        
        [appContinueRequestConnection release];
        appContinueRequestConnection = nil;
        
        appContinueRequestResponseCode = -1;
        
        // Oh crap, the continue call failed!
        // Save all queued events to the user defaults store.
        if ([pendingEvents count])
            [[NSUserDefaults standardUserDefaults] setObject:pendingEvents forKey:LIOLookIOManagerPendingEventsKey];
        
        if (failedContinueCount < LIOLookIOManagerMaxContinueFailures)
        {
            failedContinueCount++;
            LIOLog(@"<CONTINUE> Retry attempt %u of %u...", failedContinueCount, LIOLookIOManagerMaxContinueFailures);
            
            // The timer should automatically trigger the next continue call.
        }
        else
        {
            LIOLog(@"<CONTINUE> Retries exhausted. Stopping future continue calls.");
            
            [continuationTimer stopTimer];
            [continuationTimer release];
            continuationTimer = nil;
            
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:LIOLookIOManagerLastKnownVisitorIdKey];
            [lastKnownVisitURL release];
            lastKnownVisitURL = nil;
        }
    }
    
    [self refreshControlButtonVisibility];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

#pragma mark -
#pragma mark LIOControlButtonViewDelegate methods

- (void)controlButtonViewWasTapped:(LIOControlButtonView *)aControlButton
{
    if (resumeMode)
    {        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.ReconnectCancelAlertTitle")
                                                            message:LIOLocalizedString(@"LIOLookIOManager.ReconnectCancelAlertBody")
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.ReconnectCancelAlertButtonStop"), LIOLocalizedString(@"LIOLookIOManager.ReconnectCancelAlertButtonContinue"), nil];
        alertView.tag = LIOLookIOManagerReconnectionCancelAlertViewTag;
        [alertView show];
        [alertView autorelease];
    }
    else if (socketConnected && introduced && NO == willAskUserToReconnect)
        [self showChatAnimated:YES];
    else
        [self beginSession];
}

#pragma mark -
#pragma mark Dynamic property accessors

- (BOOL)enabled
{
    // nil or empty
    if (0 == [multiskillMapping count])
        return NO;
    
    // See if the current skill has a mapping.
    NSDictionary *aMap = [multiskillMapping objectForKey:currentRequiredSkill];
    if ([aMap count])
    {
        NSNumber *enabledValue = [aMap objectForKey:@"enabled"];
        return [enabledValue boolValue];
    }
    
    // Nope. No current skill set. Try to find the default.
    if (0 == [currentRequiredSkill length])
    {
        for (NSString *aSkillKey in multiskillMapping)
        {
            NSDictionary *aMap = [multiskillMapping objectForKey:aSkillKey];
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

- (BOOL)chatInProgress
{
    return introduced;
}

@end
