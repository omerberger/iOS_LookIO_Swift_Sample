//
//  LIOLookIOManager.m
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import "AsyncSocket.h"
#import <CommonCrypto/CommonDigest.h>
#import <QuartzCore/QuartzCore.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreLocation/CoreLocation.h>
#import <sys/socket.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <sys/sysctl.h>
#import <netinet/in.h>
#import "LIOLookIOManager.h"
#import "SBJSON.h"
#import "NSData+Base64.h"
#import "LIOAltChatViewController.h"
#import "LIOLeaveMessageViewController.h"
#import "LIOEmailHistoryViewController.h"
#import "LIOControlButtonView.h"
#import "LIOAnalyticsManager.h"
#import "LIOChatMessage.h"
#import "LIOBundleManager.h"
#import "LIOInterstitialViewController.h"
#import "LIOLogManager.h"
#import "LIOTimerProxy.h"

#define HEXCOLOR(c) [UIColor colorWithRed:((c>>16)&0xFF)/255.0 \
                                    green:((c>>8)&0xFF)/255.0 \
                                     blue:((c)&0xFF)/255.0 \
                                    alpha:1.0]

// Misc. constants
#define LIOLookIOManagerVersion @"1.1.0"

#define LIOLookIOManagerScreenCaptureInterval   0.33

#define LIOLookIOManagerWriteTimeout            5.0

#define LIOLookIOManagerDefaultControlEndpoint      @"connect.look.io"
#define LIOLookIOManagerDefaultControlEndpoint_Dev  @"connect.dev.look.io"
#define LIOLookIOManagerControlEndpointPort         8100
#define LIOLookIOManagerControlEndpointPortTLS      9000

#define LIOLookIOManagerAppLaunchRequestURL     @"api/v1/app/launch"
#define LIOLookIOManagerLogUploadRequestURL     @"api/v1/app/log"

#define LIOLookIOManagerMessageSeparator        @"!look.io!"

#define LIOLookIOManagerDisconnectConfirmAlertViewTag       1
#define LIOLookIOManagerScreenshotPermissionAlertViewTag    2
#define LIOLookIOManagerDisconnectErrorAlertViewTag         3
#define LIOLookIOManagerNoAgentsOnlineAlertViewTag          4
#define LIOLookIOManagerUnprovisionedAlertViewTag           5
#define LIOLookIOManagerAgentEndedSessionAlertViewTag       6

// User defaults keys
#define LIOLookIOManagerLastKnownButtonVisibilityKey    @"LIOLookIOManagerLastKnownButtonVisibilityKey"
#define LIOLookIOManagerLastKnownButtonTextKey          @"LIOLookIOManagerLastKnownButtonTextKey"
#define LIOLookIOManagerLastKnownButtonTintColorKey     @"LIOLookIOManagerLastKnownButtonTintColorKey"
#define LIOLookIOManagerLastKnownButtonTextColorKey     @"LIOLookIOManagerLastKnownButtonTextColorKey"
#define LIOLookIOManagerLastKnownWelcomeMessageKey      @"LIOLookIOManagerLastKnownWelcomeMessageKey"
#define LIOLookIOManagerLastKnownEnabledStatusKey       @"LIOLookIOManagerLastKnownEnabledStatusKey"
#define LIOLookIOManagerLaunchReportQueueKey            @"LIOLookIOManagerLaunchReportQueueKey"

#define LIOLookIOManagerControlButtonMinHeight 110.0
#define LIOLookIOManagerControlButtonMinWidth  35.0

@class CTCall, CTCallCenter;

@interface LIOLookIOManager ()
    <LIOControlButtonViewDelegate, LIOAltChatViewControllerDataSource, LIOAltChatViewControllerDelegate, LIOInterstitialViewControllerDelegate,
     LIOLeaveMessageViewControllerDelegate>
{
    NSTimer *screenCaptureTimer;
    UIImage *touchImage;
    AsyncSocket_LIO *controlSocket;
    BOOL waitingForScreenshotAck, waitingForIntroAck, controlSocketConnecting, introduced, enqueued;
    NSData *messageSeparatorData;
    NSData *lastScreenshotSent;
    SBJsonParser_LIO *jsonParser;
    SBJsonWriter_LIO *jsonWriter;
    UIImageView *cursorView, *clickView;
    LIOControlButtonView *controlButton;
    NSMutableArray *chatHistory;
    BOOL resetAfterDisconnect, killConnectionAfterChatViewDismissal, sessionEnding, outroReceived;
    NSNumber *lastKnownQueuePosition;
    BOOL screenshotsAllowed;
    UIBackgroundTaskIdentifier backgroundTaskId;
    NSString *targetAgentId;
    BOOL usesTLS, userWantsSessionTermination;
    UIWindow *lookioWindow, *previousKeyWindow, *mainWindow;
    NSMutableURLRequest *appLaunchRequest;
    NSURLConnection *appLaunchRequestConnection;
    NSMutableData *appLaunchRequestData;
    NSInteger appLaunchRequestResponseCode;
    LIOAltChatViewController *altChatViewController;
    LIOEmailHistoryViewController *emailHistoryViewController;
    LIOLeaveMessageViewController *leaveMessageViewController;
    LIOInterstitialViewController *interstitialViewController;
    NSString *pendingEmailAddress;
    NSString *friendlyName;
    NSMutableDictionary *sessionExtras;
    UIInterfaceOrientation actualInterfaceOrientation;
    NSString *sessionId;
    NSNumber *lastKnownButtonVisibility, *lastKnownEnabledStatus;
    NSString *lastKnownButtonText;
    UIColor *lastKnownButtonTintColor, *lastKnownButtonTextColor;
    NSString *lastKnownWelcomeMessage;
    NSArray *supportedOrientations;
    NSString *pendingChatText;
    NSDate *screenSharingStartedDate;
    CTCallCenter *callCenter;
    NSMutableArray *queuedLaunchReportDates;
    NSDateFormatter *dateFormatter;
    BOOL agentsAvailable;
    NSDate *backgroundedTime;
    CLLocation *lastKnownLocation;
    NSString *overriddenEndpoint;
    BOOL appLaunchRequestIgnoringLocationHeader;
    LIOTimerProxy *reconnectionTimer;
    NSUInteger previousReconnectionTimerStep;
    BOOL firstChatMessageSent;
    BOOL resumeMode;
    BOOL developmentMode;
    NSString *controlEndpoint;
    id<LIOLookIOManagerDelegate> delegate;
}

@property(nonatomic, readonly) BOOL screenshotsAllowed;
@property(nonatomic, readonly) NSString *pendingEmailAddress;
@property(nonatomic, readonly) BOOL agentsAvailable;

- (void)controlButtonWasTapped;
- (void)rejiggerWindows;
- (void)refreshControlButtonVisibility;
- (NSDictionary *)buildIntroDictionaryIncludingExtras:(BOOL)includeExtras includingType:(BOOL)includesType includingWhen:(NSDate *)aDate;
- (NSString *)wwwFormEncodedDictionary:(NSDictionary *)aDictionary withName:(NSString *)aName;
- (void)handleCallEvent:(CTCall *)aCall;
- (void)configureReconnectionTimer;
- (BOOL)beginConnectingWithError:(NSError **)anError;
- (void)killReconnectionTimer;
- (NSString *)dateToStandardizedString:(NSDate *)aDate;

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

@synthesize touchImage, targetAgentId, usesTLS, screenshotsAllowed, mainWindow, delegate, pendingEmailAddress, agentsAvailable;
@dynamic enabled;

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
        controlEndpoint = LIOLookIOManagerDefaultControlEndpoint;
        usesTLS = YES;
        
        sessionExtras = [[NSMutableDictionary alloc] init];
        
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm'Z'";
        dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        
        queuedLaunchReportDates = [[NSUserDefaults standardUserDefaults] objectForKey:LIOLookIOManagerLaunchReportQueueKey];
        if (nil == queuedLaunchReportDates)
            queuedLaunchReportDates = [[NSMutableArray alloc] init];
        
        jsonParser = [[SBJsonParser_LIO alloc] init];
        jsonWriter = [[SBJsonWriter_LIO alloc] init];
        
        // Start the reachability monitor.
        [LIOAnalyticsManager sharedAnalyticsManager];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityDidChange:)
                                                     name:LIOAnalyticsManagerReachabilityDidChangeNotification
                                                   object:[LIOAnalyticsManager sharedAnalyticsManager]];
        
        // Start the location monitor thingy.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(locationWasDetermined:)
                                                     name:LIOAnalyticsManagerLocationWasDeterminedNotification
                                                   object:[LIOAnalyticsManager sharedAnalyticsManager]];
        [[LIOAnalyticsManager sharedAnalyticsManager] beginLocationCheck];
    }
    
    return self;
}

- (void)enableDevelopmentMode
{
    developmentMode = YES;
    controlEndpoint = LIOLookIOManagerDefaultControlEndpoint_Dev;
}

- (void)uploadLog:(NSString *)logBody
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http%@://%@/%@", usesTLS ? @"s" : @"", controlEndpoint, LIOLookIOManagerLogUploadRequestURL]];
    NSString *udid = uniqueIdentifier();
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    
    NSMutableURLRequest *uploadLogRequest = [NSMutableURLRequest requestWithURL:url
                                                                    cachePolicy:NSURLCacheStorageNotAllowed
                                                                timeoutInterval:10.0];
    [uploadLogRequest addValue:bundleId forHTTPHeaderField:@"X-Lookio-BundleID"];
    [uploadLogRequest addValue:@"Apple iOS" forHTTPHeaderField:@"X-Lookio-Platform"];
    [uploadLogRequest addValue:udid forHTTPHeaderField:@"X-Lookio-DeviceID"];
    [uploadLogRequest addValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
    [uploadLogRequest setHTTPBody:[logBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    [NSURLConnection connectionWithRequest:uploadLogRequest delegate:nil];
}

- (void)sendLaunchReport
{
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
        NSDictionary *introDict = [self buildIntroDictionaryIncludingExtras:YES includingType:NO includingWhen:nil];
        NSString *introDictWwwFormEncoded = [self wwwFormEncodedDictionary:introDict withName:nil];
        [appLaunchRequest setHTTPBody:[introDictWwwFormEncoded dataUsingEncoding:NSUTF8StringEncoding]];
        LIOLog(@"<LAUNCH> Request: %@", introDictWwwFormEncoded);
        appLaunchRequestConnection = [[NSURLConnection alloc] initWithRequest:appLaunchRequest delegate:self];
    }
    else
    {
        // Queue this launch packet.
        [queuedLaunchReportDates addObject:[NSDate date]];
        [[NSUserDefaults standardUserDefaults] setObject:queuedLaunchReportDates forKey:LIOLookIOManagerLaunchReportQueueKey];
        
        // Delete LIOLookIOManagerLastKnownEnabledStatusKey. This should force
        // the lib to report "disabled" back to the host app.
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:LIOLookIOManagerLastKnownEnabledStatusKey];
        [lastKnownEnabledStatus release];
        lastKnownEnabledStatus = nil;
        
        [self refreshControlButtonVisibility];
    }
}

- (void)performSetupWithDelegate:(id<LIOLookIOManagerDelegate>)aDelegate
{
    NSAssert([NSThread currentThread] == [NSThread mainThread], @"LookIO can only be used on the main thread!");
    
    delegate = aDelegate;
    
    // Try to get supported orientation information from plist.
    NSArray *plistOrientations = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedInterfaceOrientations"];
    if (plistOrientations)
    {
        NSMutableArray *orientationNumbers = [NSMutableArray array];
        
        if ([plistOrientations containsObject:@"UIInterfaceOrientationPortrait"])
            [orientationNumbers addObject:[NSNumber numberWithInt:UIInterfaceOrientationPortrait]];
        
        if ([plistOrientations containsObject:@"UIInterfaceOrientationPortraitUpsideDown"])
            [orientationNumbers addObject:[NSNumber numberWithInt:UIInterfaceOrientationPortraitUpsideDown]];
        
        if ([plistOrientations containsObject:@"UIInterfaceOrientationLandscapeLeft"])
            [orientationNumbers addObject:[NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft]];
        
        if ([plistOrientations containsObject:@"UIInterfaceOrientationLandscapeRight"])
            [orientationNumbers addObject:[NSNumber numberWithInt:UIInterfaceOrientationLandscapeRight]];
        
        supportedOrientations = [orientationNumbers retain];
    }
    else
    {
        supportedOrientations = [[NSArray alloc] init];
    }
    
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    
    lookioWindow = [[UIWindow alloc] initWithFrame:keyWindow.frame];
    lookioWindow.hidden = YES;
    lookioWindow.windowLevel = 0.1;
    
    controlSocket = [[AsyncSocket_LIO alloc] initWithDelegate:self];
    
    screenCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:LIOLookIOManagerScreenCaptureInterval
                                                          target:self
                                                        selector:@selector(screenCaptureTimerDidFire:)
                                                        userInfo:nil
                                                         repeats:YES];
    
    messageSeparatorData = [[LIOLookIOManagerMessageSeparator dataUsingEncoding:NSUTF8StringEncoding] retain];
    
    chatHistory = [[NSMutableArray alloc] init];
        
    controlButton = [[LIOControlButtonView alloc] initWithFrame:CGRectZero];
    controlButton.hidden = YES;
    controlButton.delegate = self;
    controlButton.accessibilityLabel = @"LIOTab";
    [keyWindow addSubview:controlButton];
    
    Class $CTCallCenter = NSClassFromString(@"CTCallCenter");
    if ($CTCallCenter)
    {
        callCenter = [[$CTCallCenter alloc] init];
        [callCenter setCallEventHandler:^(CTCall *aCall) {
            [self handleCallEvent:aCall];
        }];
    }
    
    // Restore control button settings.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [lastKnownButtonVisibility release];
    lastKnownButtonVisibility = [[userDefaults objectForKey:LIOLookIOManagerLastKnownButtonVisibilityKey] retain];
    
    [lastKnownButtonText release];
    lastKnownButtonText = [[userDefaults objectForKey:LIOLookIOManagerLastKnownButtonTextKey] retain];
    controlButton.labelText = lastKnownButtonText;
    
    [lastKnownButtonTintColor release];
    lastKnownButtonTintColor = nil;
    NSString *tintString = [userDefaults objectForKey:LIOLookIOManagerLastKnownButtonTintColorKey];
    if (tintString)
    {
        unsigned int colorValue;
        [[NSScanner scannerWithString:tintString] scanHexInt:&colorValue];
        UIColor *aColor = HEXCOLOR(colorValue);
        lastKnownButtonTintColor = [aColor retain];
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
        controlButton.textColor = lastKnownButtonTextColor;
    }
    
    [lastKnownEnabledStatus release];
    lastKnownEnabledStatus = [[userDefaults objectForKey:LIOLookIOManagerLastKnownEnabledStatusKey] retain];
    
    [self refreshControlButtonVisibility];
    
    // Restore other settings.
    [lastKnownWelcomeMessage release];
    lastKnownWelcomeMessage = [[userDefaults objectForKey:LIOLookIOManagerLastKnownWelcomeMessageKey] retain];
    
    [self applicationDidChangeStatusBarOrientation:nil];
    
    appLaunchRequest = [[NSMutableURLRequest alloc] initWithURL:nil
                                                    cachePolicy:NSURLCacheStorageNotAllowed
                                                     timeoutInterval:10.0];
    [appLaunchRequest setHTTPMethod:@"POST"];
    [appLaunchRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    appLaunchRequestData = [[NSMutableData alloc] init];
    appLaunchRequestResponseCode = -1;
        
    backgroundTaskId = UIBackgroundTaskInvalid;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
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
    
    [self sendLaunchReport];
    
    [LIOBundleManager sharedBundleManager];
    
    LIOLog(@"Loaded.");    
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
                [result appendFormat:@"%@%%91%@%%93=%@&", [self urlEncodedStringWithString:aName], [self urlEncodedStringWithString:aKey], [self urlEncodedStringWithString:stringValue]];
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
    
    self.touchImage = nil;
    
    [callCenter release];
    callCenter = nil;
    
    [controlSocket disconnect];
    [controlSocket release];
    controlSocket = nil;
    
    [cursorView release];
    cursorView = nil;
    
    [clickView release];
    clickView = nil;
    
    [controlButton release];
    controlButton = nil;
    
    [messageSeparatorData release];
    [jsonParser release];
    [jsonWriter release];
    [chatHistory release];
    [lastScreenshotSent release];
    [lastKnownQueuePosition release];
    [targetAgentId release];
    [friendlyName release];
    [sessionId release];
    [appLaunchRequest release];
    [appLaunchRequestConnection release];
    [appLaunchRequestData release];
    [lastKnownButtonVisibility release];
    [lastKnownButtonText release];
    [lastKnownButtonTintColor release];
    [lastKnownButtonTextColor release];
    [lastKnownWelcomeMessage release];
    [lastKnownEnabledStatus release];
    [pendingEmailAddress release];
    [supportedOrientations release];
    [screenSharingStartedDate release];
    [mainWindow release];
    [queuedLaunchReportDates release];
    [dateFormatter release];
    [overriddenEndpoint release];
    
    [reconnectionTimer stopTimer];
    [reconnectionTimer release];
    reconnectionTimer = nil;
    
    [leaveMessageViewController release];
    leaveMessageViewController = nil;
    
    [emailHistoryViewController release];
    emailHistoryViewController = nil;
    
    [altChatViewController release];
    altChatViewController = nil;
    
    [self rejiggerWindows];
    
    [lookioWindow release];
    
    LIOLog(@"Unloaded.");
    
    [super dealloc];
}

- (void)reset
{
    [altChatViewController dismissModalViewControllerAnimated:NO];
    [altChatViewController.view removeFromSuperview];
    [altChatViewController release];
    altChatViewController = nil;
    
    [leaveMessageViewController.view removeFromSuperview];
    [leaveMessageViewController release];
    leaveMessageViewController = nil;
    
    [emailHistoryViewController.view removeFromSuperview];
    [emailHistoryViewController release];
    emailHistoryViewController = nil;
    
    [interstitialViewController.view removeFromSuperview];
    [interstitialViewController release];
    interstitialViewController = nil;

    [callCenter release];
    callCenter = nil;
    
    [sessionId release];
    sessionId = nil;
    
    [chatHistory release];
    chatHistory = [[NSMutableArray alloc] init];
    
    [cursorView removeFromSuperview];
    [cursorView release];
    cursorView = nil;
    
    [clickView removeFromSuperview];
    [clickView release];
    clickView = nil;
    
    [lastScreenshotSent release];
    lastScreenshotSent = nil;
    
    [backgroundedTime release];
    backgroundedTime = nil;
    
    [reconnectionTimer stopTimer];
    [reconnectionTimer release];
    reconnectionTimer = nil;
    
    previousReconnectionTimerStep = 2;
    
    waitingForScreenshotAck = NO, waitingForIntroAck = NO, controlSocketConnecting = NO, introduced = NO, enqueued = NO;
    resetAfterDisconnect = NO, killConnectionAfterChatViewDismissal = NO, screenshotsAllowed = NO;
    sessionEnding = NO, userWantsSessionTermination = NO, outroReceived = NO, firstChatMessageSent = NO, resumeMode = NO;
    
    [screenSharingStartedDate release];
    screenSharingStartedDate = nil;
    
    [queuedLaunchReportDates removeAllObjects];
    
    [self rejiggerWindows];
    
    LIOLog(@"Reset. Key window: 0x%08X", (unsigned int)[[UIApplication sharedApplication] keyWindow]);
}

- (void)rejiggerWindows
{
    for (UIWindow *window in [[UIApplication sharedApplication] windows])
        [window endEditing:YES];
    
    if (altChatViewController || leaveMessageViewController || emailHistoryViewController || interstitialViewController)
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
                
                LIOLog(@"Got host app's key window from delegate: 0x%08X", (unsigned int)previousKeyWindow);
            }
            else if ([[[UIApplication sharedApplication] keyWindow] isMemberOfClass:[UIWindow class]])
            {
                previousKeyWindow = [[UIApplication sharedApplication] keyWindow];
                
                LIOLog(@"Got host app's key window from UIApplication: 0x%08X", (unsigned int)previousKeyWindow);
            }
            else
            {
                LIOLog(@"WARNING: Could not find host app's key window! Behavior from this point on is undefined.");
            }
            
            LIOLog(@"Making LookIO window key and visible: 0x%08X", (unsigned int)lookioWindow);
            [lookioWindow makeKeyAndVisible];
        }
    }
    else
    {
        LIOLog(@"Hiding 0x%08X, restoring 0x%08X", (unsigned int)lookioWindow, (unsigned int)previousKeyWindow);
        
        lookioWindow.hidden = YES;
        
        [previousKeyWindow makeKeyWindow];
        previousKeyWindow = nil;
        
        [self refreshControlButtonVisibility];
    }
}

- (UIImage *)captureScreen
{
    CGSize imageSize = [[UIScreen mainScreen] bounds].size;
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 1.0);
    
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
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
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
    static int bl0rk = 0;
    bl0rk++;
    
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (keyWindow != lookioWindow)
    {
        [keyWindow bringSubviewToFront:controlButton];
        [keyWindow bringSubviewToFront:cursorView];
        [keyWindow bringSubviewToFront:clickView];
    }
    else if (bl0rk >= 4)
    {
        bl0rk = 0;
        [lookioWindow makeKeyAndVisible];
    }
    
    if (NO == [controlSocket isConnected] || waitingForScreenshotAck || NO == introduced || YES == enqueued || NO == screenshotsAllowed || altChatViewController || interstitialViewController)
        return;
    
    if (UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
        return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *screenshotImage = [self captureScreen];
        CGSize screenshotSize = screenshotImage.size;
        NSData *screenshotData = UIImageJPEGRepresentation(screenshotImage, 0.0);
        if (nil == lastScreenshotSent || NO == [lastScreenshotSent isEqualToData:screenshotData])
        {
            [lastScreenshotSent release];
            lastScreenshotSent = [screenshotData retain];
                        
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
            NSString *header = [NSString stringWithFormat:@"screenshot:2:%f:%@:%d:%d:%u:", timeSinceSharingStarted, orientationString, (int)screenshotSize.width, (int)screenshotSize.height, [screenshotData length]];
            NSData *headerData = [header dataUsingEncoding:NSUTF8StringEncoding];
            
            NSMutableData *dataToSend = [NSMutableData data];
            [dataToSend appendData:headerData];
            [dataToSend appendData:screenshotData];
            [dataToSend appendData:messageSeparatorData];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                waitingForScreenshotAck = YES;
                [controlSocket writeData:dataToSend
                             withTimeout:-1
                                     tag:0];
                
                LIOLog(@"Sent %dx%d %@ screenshot (%u bytes image data, %u bytes total).\nHeader: %@", (int)screenshotSize.width, (int)screenshotSize.height, orientationString, [screenshotData length], [dataToSend length], header);
            });
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
    if (altChatViewController)
        return;
    
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
    [lookioWindow addSubview:altChatViewController.view];
    [self rejiggerWindows];
    
    if (animated)
        [altChatViewController performRevealAnimation];
    
    [pendingChatText release];
    pendingChatText = nil;
    
    if (introduced)
    {
        NSString *chatUp = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                         @"advisory", @"type",
                                                         @"chat_up", @"action",
                                                         nil]];
        chatUp = [chatUp stringByAppendingString:LIOLookIOManagerMessageSeparator];
        
        [controlSocket writeData:[chatUp dataUsingEncoding:NSUTF8StringEncoding]
                     withTimeout:LIOLookIOManagerWriteTimeout
                             tag:0];
    }
    
    controlButton.hidden = YES;
}

- (void)showLeaveMessage
{
    if (leaveMessageViewController)
        return;
    
    // Just in case...
    [altChatViewController.view removeFromSuperview];
    [altChatViewController release];
    altChatViewController = nil;
    
    leaveMessageViewController = [[LIOLeaveMessageViewController alloc] initWithNibName:nil bundle:nil];
    leaveMessageViewController.delegate = self;
    leaveMessageViewController.initialEmailAddress = pendingEmailAddress;
    [lookioWindow addSubview:leaveMessageViewController.view];
    
    [self rejiggerWindows];
}

- (void)beginSession
{
    // Prevent a new session from being established if the current one
    // is ending.
    if (sessionEnding)
    {
        LIOLog(@"beginSession ignored: current session is still ending...");
        return;
    }
    
    if (controlSocketConnecting)
    {
        LIOLog(@"Connect attempt ignored: connecting or already connected.");
        return;
    }
    
    if ([controlSocket isConnected])
    {
        [self controlButtonWasTapped];
        return;
    }

    NSError *connectError = nil;
    BOOL connectResult = [self beginConnectingWithError:&connectError];
    if (NO == connectResult)
    {
        [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
        
        LIOLog(@"Connection failed. Reason: %@", [connectError localizedDescription]);
        
        if (NO == firstChatMessageSent)
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Connection Failed"
                                                                message:[connectError localizedDescription]
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"Dismiss", nil];
            [alertView show];
            [alertView autorelease];
        }
        
        controlSocketConnecting = NO;
        
        [self killReconnectionTimer];
        [self configureReconnectionTimer];
        
        return;
    }
    
    controlSocketConnecting = YES;

    LIOChatMessage *firstMessage = [LIOChatMessage chatMessage];
    firstMessage.kind = LIOChatMessageKindRemote;
    firstMessage.date = [NSDate date];
    [chatHistory addObject:firstMessage];
    
    if ([lastKnownWelcomeMessage length])
        firstMessage.text = lastKnownWelcomeMessage;
    else
        firstMessage.text = @"Send a message to our live service reps for immediate help.";
    
    [self showChatAnimated:YES];
}

- (BOOL)beginConnectingWithError:(NSError **)anError
{
    NSUInteger chosenPort = LIOLookIOManagerControlEndpointPortTLS;
    if (NO == usesTLS)
        chosenPort = LIOLookIOManagerControlEndpointPort;
    
    NSString *chosenEndpoint = [overriddenEndpoint length] ? overriddenEndpoint : controlEndpoint;
    BOOL connectResult = [controlSocket connectToHost:chosenEndpoint
                                               onPort:chosenPort
                                                error:anError];
    
    LIOLog(@"Trying \"%@:%u\"...", chosenEndpoint, chosenPort);
    
    return connectResult;
}

- (void)killConnection
{
    NSString *outro = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    @"outro", @"type",
                                                    nil]];
    outro = [outro stringByAppendingString:LIOLookIOManagerMessageSeparator];
    
    [controlSocket writeData:[outro dataUsingEncoding:NSUTF8StringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [controlSocket disconnectAfterWriting];
    });
}

- (void)recordCurrentUILocation:(NSString *)aLocationString
{
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:aLocationString, @"location_name", nil];
    NSString *uiLocation = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                         @"advisory", @"type",
                                                         @"ui_location", @"action",
                                                         dataDict, @"data",
                                                         nil]];
    uiLocation = [uiLocation stringByAppendingString:LIOLookIOManagerMessageSeparator];
    
    [controlSocket writeData:[uiLocation dataUsingEncoding:NSUTF8StringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];
}

- (void)handlePacket:(NSDictionary *)aPacket
{
    NSAssert([NSThread currentThread] == [NSThread mainThread], @"LookIO cannot be used on a non-main thread!");
    
    NSString *type = [aPacket objectForKey:@"type"];
    if ([type isEqualToString:@"ack"])
    {
        if (waitingForIntroAck)
        {
            LIOLog(@"Introduction complete.");
            introduced = YES;
            waitingForIntroAck = NO;
            enqueued = YES;
            
            [self sendCapabilitiesPacket];
            
            [controlSocket readDataToData:messageSeparatorData
                              withTimeout:-1
                                      tag:0];
        }
        else if (waitingForScreenshotAck)
        {
            LIOLog(@"Screenshot received by remote host.");
            waitingForScreenshotAck = NO;
        }
    }
    else if ([type isEqualToString:@"session_info"])
    {
        NSDictionary *dataDict = [aPacket objectForKey:@"data"];
        NSString *sessionIdString = [dataDict objectForKey:@"session_id"];
        if ([sessionIdString length])
        {
            [sessionId release];
            sessionId = [sessionIdString retain];
        }
    }
    else if ([type isEqualToString:@"chat"])
    {
        NSString *text = [aPacket objectForKey:@"text"];
        NSString *senderName = [aPacket objectForKey:@"sender_name"];
        
        LIOChatMessage *newMessage = [LIOChatMessage chatMessage];
        newMessage.text = text;
        newMessage.senderName = senderName;
        newMessage.kind = LIOChatMessageKindRemote;
        newMessage.date = [NSDate date];
        [chatHistory addObject:newMessage];
        
        if (nil == altChatViewController)
        {
            // First, we have to kill any existing full-screen dealios.
            [emailHistoryViewController.view removeFromSuperview];
            [emailHistoryViewController release];
            emailHistoryViewController = nil;
            
            [self showChatAnimated:YES];
        }
        else
        {
            [altChatViewController reloadMessages];
            [altChatViewController scrollToBottom];
        }
        
        if (UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
        {
            UILocalNotification *localNotification = [[[UILocalNotification alloc] init] autorelease];
            localNotification.soundName = @"LookIODing.caf";
            localNotification.alertBody = @"The support agent has sent a chat message to you.";
            localNotification.alertAction = @"Go!";
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
        }
    }
    else if ([type isEqualToString:@"cursor"])
    {
        if (nil == touchImage)
            self.touchImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIODefaultTouch"];
        
        if (nil == cursorView)
        {
            UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
            cursorView = [[UIImageView alloc] initWithImage:touchImage];
            [keyWindow addSubview:cursorView];
        }
        
        [lookioWindow bringSubviewToFront:cursorView];
        
        NSNumber *x = [aPacket objectForKey:@"x"];
        NSNumber *y = [aPacket objectForKey:@"y"];
        CGRect aFrame = cursorView.frame;
        aFrame.origin.x = [x floatValue];
        aFrame.origin.y = [y floatValue];
        
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState)
                         animations:^{ cursorView.frame = aFrame; }
                         completion:nil];
    }
    else if ([type isEqualToString:@"advisory"])
    {
        NSString *action = [aPacket objectForKey:@"action"];
        
        if ([action isEqualToString:@"send_logs"])
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
        else if ([action isEqualToString:@"cursor_start"])
        {
            UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
            
            if (nil == touchImage)
                self.touchImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIODefaultTouch"];
            
            if (nil == cursorView)
            {
                cursorView = [[UIImageView alloc] initWithImage:touchImage];
                [keyWindow addSubview:cursorView];
            }
            
            [keyWindow bringSubviewToFront:cursorView];
            
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
        else if ([action isEqualToString:@"cursor_end"])
        {
            /*
            UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
            
            if (nil == cursorView)
            {
                cursorView = [[UIImageView alloc] initWithImage:touchImage];
                [keyWindow addSubview:cursorView];
            }
            
            [keyWindow bringSubviewToFront:cursorView];
            
            CGRect aFrame = CGRectZero;
            aFrame.size.width = cursorView.image.size.width * 8.0;
            aFrame.size.height = cursorView.image.size.height * 8.0;
            aFrame.origin.x = (keyWindow.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
            aFrame.origin.y = (keyWindow.frame.size.height / 2.0) - (aFrame.size.height / 2.0);
            
            [UIView animateWithDuration:0.25
                                  delay:0.0
                                options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut)
                             animations:^{
                                 cursorView.frame = aFrame;
                                 cursorView.alpha = 0.0;
                             }
                             completion:nil];
             */
            cursorView.alpha = 0.0;
        }
        else if ([action isEqualToString:@"connected"])
        {
            LIOLog(@"We're live!");
            enqueued = NO;
            
            if (UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
            {
                UILocalNotification *localNotification = [[[UILocalNotification alloc] init] autorelease];
                localNotification.soundName = @"LookIODing.caf";
                localNotification.alertBody = @"The support agent is ready to chat with you!";
                localNotification.alertAction = @"Go!";
                [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                
                [self showChatAnimated:NO];
            }
        }
        else if ([action isEqualToString:@"queued"])
        {
            NSDictionary *data = [aPacket objectForKey:@"data"];
            NSNumber *online = [data objectForKey:@"online"];
            if (online && NO == [online boolValue])
            {
                // not online case
                agentsAvailable = NO;
            }
            else
            {
                // online
                agentsAvailable = YES;
            }
        }
        else if ([action isEqualToString:@"permission"])
        {
            NSDictionary *data = [aPacket objectForKey:@"data"];
            NSString *permission = [data objectForKey:@"permission"];
            if ([permission isEqualToString:@"screenshot"] && NO == screenshotsAllowed)
            {
                if (UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
                {
                    UILocalNotification *localNotification = [[[UILocalNotification alloc] init] autorelease];
                    localNotification.soundName = @"LookIODing.caf";
                    localNotification.alertBody = @"The support agent wants to view your screen.";
                    localNotification.alertAction = @"Go!";
                    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                }
                
                [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Screen Share Permission"
                                                                    message:@"To better serve you, the support agent would like to view your screen. (Agent can only view this app, and only for this session.)"
                                                                   delegate:self
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"Do Not Allow", @"Allow", nil];
                alertView.tag = LIOLookIOManagerScreenshotPermissionAlertViewTag;
                [alertView show];
                [alertView autorelease];
            }
        }
        else if ([action isEqualToString:@"unprovisioned"])
        {
            [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:@"This app is not configured for live help. Please contact the app developer."
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"Dismiss", nil];
            alertView.tag = LIOLookIOManagerUnprovisionedAlertViewTag;
            [alertView show];
            [alertView autorelease];
        }
        else if ([action isEqualToString:@"leave_message"])
        {
            [altChatViewController.view removeFromSuperview];
            [altChatViewController release];
            altChatViewController = nil;
            
            [self showLeaveMessage];
        }
    }
    else if ([type isEqualToString:@"click"])
    {
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        
        if (nil == clickView)
        {
            clickView = [[UIImageView alloc] initWithImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOClickIndicator"]];
            [keyWindow addSubview:clickView];
        }
        
        [keyWindow bringSubviewToFront:clickView];
        
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
        
        [UIView animateWithDuration:0.1
                              delay:0.0
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut)
                         animations:^{
                             clickView.bounds = aFrame;
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
        resetAfterDisconnect = YES;
        outroReceived = YES;
        firstChatMessageSent = NO;
    }
    
    [controlSocket readDataToData:messageSeparatorData
                      withTimeout:-1
                              tag:0];
}

- (void)performIntroduction
{
    NSDictionary *introDict = [self buildIntroDictionaryIncludingExtras:YES includingType:YES includingWhen:nil];
    
    NSString *intro = [jsonWriter stringWithObject:introDict];
    
    LIOLog(@"Intro JSON: %@", intro);
    
    intro = [intro stringByAppendingString:LIOLookIOManagerMessageSeparator];
    
    waitingForIntroAck = YES;
    
    [controlSocket writeData:[intro dataUsingEncoding:NSUTF8StringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];
    
    [controlSocket readDataToData:messageSeparatorData
                      withTimeout:-1
                              tag:0];    
}

- (void)sendCapabilitiesPacket
{
    NSArray *capsArray = [NSArray arrayWithObjects:@"receive_leavemessage", nil];
    
    NSDictionary *capsDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"capabilities", @"type",
                              capsArray, @"capabilities",
                              nil];
    
    NSString *caps = [jsonWriter stringWithObject:capsDict];
    caps = [caps stringByAppendingString:LIOLookIOManagerMessageSeparator];
    
    [controlSocket writeData:[caps dataUsingEncoding:NSUTF8StringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];
}

- (void)refreshControlButtonVisibility
{
    [controlButton stopFadeTimer];
    [controlButton.layer removeAllAnimations];

    // Trump card #-1: If the session is ending, button is hidden.
    if (sessionEnding)
    {
        controlButton.hidden = YES;
        return;
    }
    
    // Trump card #0: If we have no visibility information, button is hidden.
    if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:LIOLookIOManagerLastKnownButtonVisibilityKey] ||
        nil == [[NSUserDefaults standardUserDefaults] objectForKey:LIOLookIOManagerLastKnownEnabledStatusKey])
    {
        controlButton.hidden = YES;
        return;
    }
    
    // Trump card #1: "enabled" from server-side settings.
    if (lastKnownEnabledStatus && NO == [lastKnownEnabledStatus boolValue])
    {
        controlButton.hidden = YES;
        return;
    }
    
    BOOL willHide = NO, willShow = NO;
    
    if (lastKnownButtonVisibility)
    {
        int val = [lastKnownButtonVisibility intValue];
        if (0 == val) // never
        {
            // Want to hide.
            willHide = NO == controlButton.hidden;
        }
        else if (1 == val) // always
        {
            // Want to show.
            willShow = controlButton.hidden;
        }
        else // 3 = only in session
        {
            if (introduced)
            {
                // Want to show.
                willShow = controlButton.hidden;
            }
            else
            {
                // Want to hide.
                willHide = NO == controlButton.hidden;
            }
        }
    }
    else
    {
        willShow = controlButton.hidden;
    }
    
    // Trump card #2: If chat is up, button is always hidden.
    if (altChatViewController)
    {
        willShow = NO;
        willHide = NO == controlButton.hidden;
    }
    
    if (willHide)
    {
        [UIView animateWithDuration:0.5
                         animations:^{
                             controlButton.alpha = 0.0;
                         }
                         completion:^(BOOL finished) {
                             controlButton.hidden = YES;
                         }];
        
        if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManagerDidHideControlButton:)])
            [delegate lookIOManagerDidHideControlButton:self];
    }
    else if (willShow)
    {
        controlButton.alpha = 0.0;
        controlButton.hidden = NO;
        
        [UIView animateWithDuration:0.5
                         animations:^{
                             controlButton.alpha = 1.0;
                         }];
        
        if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManagerDidShowControlButton:)])
            [delegate lookIOManagerDidShowControlButton:self];
    }
    
    if (resumeMode && NO == [controlSocket isConnected])
        controlButton.currentMode = LIOControlButtonViewModePending;
    else
        controlButton.currentMode = LIOControlButtonViewModeDefault;
    
    [controlButton setNeedsLayout];
    [controlButton setNeedsDisplay];
}

- (void)parseAndSaveClientParams:(NSDictionary *)params
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSNumber *buttonVisibility = [params objectForKey:@"buttonVisibility"];
    if (buttonVisibility)
    {
        [lastKnownButtonVisibility release];
        lastKnownButtonVisibility = [buttonVisibility retain];
        
        [userDefaults setObject:lastKnownButtonVisibility forKey:LIOLookIOManagerLastKnownButtonVisibilityKey];
        
        [self refreshControlButtonVisibility];
    }
    
    NSString *buttonText = [params objectForKey:@"buttonText"];
    if ([buttonText length])
    {
        controlButton.labelText = buttonText;
        
        [lastKnownButtonText release];
        lastKnownButtonText = [buttonText retain];
        
        [userDefaults setObject:lastKnownButtonText forKey:LIOLookIOManagerLastKnownButtonTextKey];
    }
    
    NSString *welcomeText = [params objectForKey:@"welcomeText"];
    if ([welcomeText length])
    {
        [lastKnownWelcomeMessage release];
        lastKnownWelcomeMessage = [welcomeText retain];
        
        [userDefaults setObject:lastKnownWelcomeMessage forKey:LIOLookIOManagerLastKnownWelcomeMessageKey];
    }
    
    NSString *buttonTint = [params objectForKey:@"buttonTint"];
    if ([buttonTint length])
    {
        [userDefaults setObject:buttonTint forKey:LIOLookIOManagerLastKnownButtonTintColorKey];
        
        unsigned int colorValue;
        [[NSScanner scannerWithString:buttonTint] scanHexInt:&colorValue];
        UIColor *color = HEXCOLOR(colorValue);
        
        controlButton.tintColor = color;
        
        [lastKnownButtonTintColor release];
        lastKnownButtonTintColor = [color retain];
    }
    
    NSString *buttonTextColor = [params objectForKey:@"buttonTextColor"];
    if ([buttonTextColor length])
    {
        [userDefaults setObject:buttonTextColor forKey:LIOLookIOManagerLastKnownButtonTextColorKey];
        
        unsigned int colorValue;
        [[NSScanner scannerWithString:buttonTextColor] scanHexInt:&colorValue];
        UIColor *color = HEXCOLOR(colorValue);
        
        controlButton.textColor = color;
        
        [lastKnownButtonTextColor release];
        lastKnownButtonTextColor = [color retain];
    }
    
    NSNumber *enabledSetting = [params objectForKey:@"enabled"];
    if (enabledSetting)
    {
        [userDefaults setObject:enabledSetting forKey:LIOLookIOManagerLastKnownEnabledStatusKey];
        
        [lastKnownEnabledStatus release];
        lastKnownEnabledStatus = [enabledSetting retain];
        
        if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManager:didUpdateEnabledStatus:)])
            [delegate lookIOManager:self didUpdateEnabledStatus:[lastKnownEnabledStatus boolValue]];
    }
    
    [self refreshControlButtonVisibility];
    [self applicationDidChangeStatusBarOrientation:nil];
}

- (BOOL)shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation
{
    // First, ask the delegate.
    if ([(NSObject *)delegate respondsToSelector:@selector(lookIOManager:shouldRotateToInterfaceOrientation:)])
        return [delegate lookIOManager:self shouldRotateToInterfaceOrientation:anOrientation];
    
    // Fall back on plist settings.
    return [supportedOrientations containsObject:[NSNumber numberWithInt:anOrientation]];
}

- (void)setSessionExtra:(id)anObject forKey:(NSString *)aKey
{
    if (anObject)
    {
        // We only allow JSONable objects.
        NSString *test = [jsonWriter stringWithObject:[NSArray arrayWithObject:anObject]];
        if ([test length])
            [sessionExtras setObject:anObject forKey:aKey];
        else
            LIOLog(@"Can't add object of class \"%@\" to session extras! >:| Use classes like NSString, NSArray, NSDictionary, NSNumber, NSDate, etc.", NSStringFromClass([anObject class]));
    }
    else
        [sessionExtras removeObjectForKey:aKey];
}

- (id)sessionExtraForKey:(NSString *)aKey
{
    return [sessionExtras objectForKey:aKey];
}

- (void)addSessionExtras:(NSDictionary *)aDictionary
{
    // We only allow JSONable objects.
    NSString *test = [jsonWriter stringWithObject:aDictionary];
    if ([test length])
        [sessionExtras addEntriesFromDictionary:aDictionary];
    else
        LIOLog(@"Can't add dictionary of objects to session extras! >:|  Use classes like NSString, NSArray, NSDictionary, NSNumber, NSDate, etc.");
}

- (void)clearSessionExtras
{
    [sessionExtras removeAllObjects];
}

- (NSDictionary *)buildIntroDictionaryIncludingExtras:(BOOL)includeExtras includingType:(BOOL)includesType includingWhen:(NSDate *)aDate
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);  
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);  
    NSString *deviceType = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
    free(machine);
    
    NSString *udid = uniqueIdentifier();
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    NSMutableDictionary *introDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      udid, @"device_id",
                                      deviceType, @"device_type",
                                      bundleId, @"app_id",
                                      @"Apple iOS", @"platform",
                                      [[UIDevice currentDevice] systemVersion], @"platform_version",
                                      LOOKIO_VERSION_STRING, @"sdk_version",
                                      nil];
    
    if (includesType)
        [introDict setObject:@"intro" forKey:@"type"];
    
    if (aDate)
        [introDict setObject:[self dateToStandardizedString:aDate] forKey:@"when"];
    
    if ([sessionId length])
        [introDict setObject:sessionId forKey:@"session_id"];
    
    if (includeExtras)
    {
        if ([targetAgentId length])
            [introDict setObject:targetAgentId forKey:@"agent_id"];
        
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
            NSArray *location = [NSDictionary dictionaryWithObjectsAndKeys:lat, @"latitude", lon, @"longitude", nil];
            [detectedDict setObject:location forKey:@"location"];
        }
        
        NSMutableDictionary *extrasDict = [NSMutableDictionary dictionary];
        if ([sessionExtras count])
            [extrasDict setDictionary:sessionExtras];
        
        if ([detectedDict count])
            [extrasDict setObject:detectedDict forKey:@"detected_settings"];
        
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

- (void)handleCallEvent:(CTCall *)aCall
{
    if ([[aCall callState] isEqualToString:@"CTCallStateConnected"])
    {
        NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"connected", @"state", nil];
        NSDictionary *callDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"advisory", @"type",
                                  @"call", @"action",
                                  dataDict, @"data",
                                  nil];
        
        NSString *call = [jsonWriter stringWithObject:callDict];
        call = [call stringByAppendingString:LIOLookIOManagerMessageSeparator];
        
        [controlSocket writeData:[call dataUsingEncoding:NSUTF8StringEncoding]
                     withTimeout:LIOLookIOManagerWriteTimeout
                             tag:0];
    }
    else
    {
        NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"disconnected", @"state", nil];
        NSDictionary *callDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"advisory", @"type",
                                  @"call", @"action",
                                  dataDict, @"data",
                                  nil];
        
        NSString *call = [jsonWriter stringWithObject:callDict];
        call = [call stringByAppendingString:LIOLookIOManagerMessageSeparator];
        
        [controlSocket writeData:[call dataUsingEncoding:NSUTF8StringEncoding]
                     withTimeout:LIOLookIOManagerWriteTimeout
                             tag:0];
    }
}

- (void)configureReconnectionTimer
{
    if ([controlSocket isConnected])
    {
        LIOLog(@"Ignoring request to configure reconnection timer: we're already connected!");
        
        [self killReconnectionTimer];
        resumeMode = NO;
        previousReconnectionTimerStep = 2;
        
        [altChatViewController hideReconnectionOverlay];
        [self showChatAnimated:NO];
        
        return;
    }
    
    [altChatViewController showReconnectionOverlay];
    [self beginConnectingWithError:nil];
    
    NSTimeInterval timerInterval = exp2(previousReconnectionTimerStep);
    LIOLog(@"Configuring reconnection timer with interval: %f", timerInterval);
    reconnectionTimer = [[LIOTimerProxy alloc] initWithTimeInterval:exp2(previousReconnectionTimerStep)
                                                             target:self
                                                           selector:@selector(reconnectionTimerDidFire)];
    
    if (altChatViewController && previousReconnectionTimerStep == 3)
    {
        [altChatViewController.view removeFromSuperview];
        [altChatViewController release];
        altChatViewController = nil;
        [self rejiggerWindows];
    }
    
    // Max: 2**6, or 64 seconds
    previousReconnectionTimerStep++;
    if (previousReconnectionTimerStep > 6)
        previousReconnectionTimerStep = 6;
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

#pragma mark -
#pragma mark AsyncSocketDelegate methods

- (void)onSocket:(AsyncSocket_LIO *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    controlSocketConnecting = NO;
    
    LIOLog(@"Connected to %@:%u", host, port);

    [self configureReconnectionTimer];
    
    if (usesTLS)
        [controlSocket startTLS:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], (NSString *)kCFStreamSSLAllowsAnyRoot, nil]];
    else
        [self performIntroduction];
}

- (void)onSocketDidSecure:(AsyncSocket_LIO *)sock
{
    LIOLog(@"Connection secured.");    
    
    [self performIntroduction];
}

- (void)onSocket:(AsyncSocket_LIO *)sock willDisconnectWithError:(NSError *)err
{
    // We don't show error boxes if resume mode is possible.
    if (NO == firstChatMessageSent)
    {
        // We don't show error boxes if the user specifically requested a termination.
        if (NO == userWantsSessionTermination && (err != nil || NO == outroReceived))
        {
            [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
            
            if (introduced)
            {
                NSString *message = [NSString stringWithFormat:@"Your support session has ended. If you still need help, try connecting to a live chat agent again."];
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Support Session Ended"
                                                                    message:message
                                                                   delegate:self
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"Dismiss", nil];
                alertView.tag = LIOLookIOManagerDisconnectErrorAlertViewTag;
                [alertView show];
                [alertView autorelease];
            }
            else
            {
                NSString *message = [NSString stringWithFormat:@"A connection error occurred. Please try again."];
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                    message:message
                                                                   delegate:self
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"Dismiss", nil];
                alertView.tag = LIOLookIOManagerDisconnectErrorAlertViewTag;
                [alertView show];
                [alertView autorelease];
            }
        }
        
        // Wacky special case: server terminates session.
        else if (NO == userWantsSessionTermination && err == nil)
        {
            NSString *message = [NSString stringWithFormat:@"Your support session has ended. If you still need help, try connecting to a live chat agent again."];
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Support Session Ended"
                                                                message:message
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"Dismiss", nil];
            alertView.tag = LIOLookIOManagerDisconnectErrorAlertViewTag;
            [alertView show];
            [alertView autorelease];
        }
    }
    
    userWantsSessionTermination = NO;
        
    LIOLog(@"Socket will disconnect. Reason: %@", [err localizedDescription]);
}

- (void)onSocketDidDisconnect:(AsyncSocket_LIO *)sock
{
    LIOLog(@"Socket did disconnect.");
    
    if (resetAfterDisconnect)
    {
        sessionEnding = YES;
        [self reset];
    }
    else if (NO == resumeMode && NO == outroReceived && firstChatMessageSent)
    {
        LIOLog(@"Unexpected disconnection! Going into resume mode...");
        
        [self configureReconnectionTimer];
        [altChatViewController showReconnectionOverlay];
        resumeMode = YES;
    }
}

- (void)onSocket:(AsyncSocket_LIO *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *jsonString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    jsonString = [jsonString substringToIndex:([jsonString length] - [LIOLookIOManagerMessageSeparator length])];
    NSDictionary *result = [jsonParser objectWithString:jsonString];
    
    LIOLog(@"\n[READ]\n%@\n", jsonString);
    
    [self performSelectorOnMainThread:@selector(handlePacket:) withObject:result waitUntilDone:NO];    
}

- (NSTimeInterval)onSocket:(AsyncSocket_LIO *)sock shouldTimeoutReadWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length;
{
    LIOLog(@"\n\nREAD TIMEOUT\n\n");
    return 0;
}

- (NSTimeInterval)onSocket:(AsyncSocket_LIO *)sock shouldTimeoutWriteWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length;
{
    LIOLog(@"\n\nWRITE TIMEOUT\n\n");
    return 0;
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

    [altChatViewController performDismissalAnimation];
}

- (void)altChatViewController:(LIOAltChatViewController *)aController didChatWithText:(NSString *)aString
{
    NSString *chat = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    @"chat", @"type",
                                                    aString, @"text",
                                                    nil]];
    
    chat = [chat stringByAppendingString:LIOLookIOManagerMessageSeparator];

    [controlSocket writeData:[chat dataUsingEncoding:NSUTF8StringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];
    
    [controlSocket readDataToData:messageSeparatorData
                      withTimeout:-1
                              tag:0];
    
    LIOChatMessage *newMessage = [LIOChatMessage chatMessage];
    newMessage.date = [NSDate date];
    newMessage.kind = LIOChatMessageKindLocal;
    newMessage.text = aString;
    [chatHistory addObject:newMessage];
    
    [altChatViewController reloadMessages];
    [altChatViewController scrollToBottom];
    
    firstChatMessageSent = YES;
}

- (void)altChatViewControllerDidTapEndSessionButton:(LIOAltChatViewController *)aController
{
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
                                                        message:@"End this session?"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"No", @"Yes", nil];
    alertView.tag = LIOLookIOManagerDisconnectConfirmAlertViewTag;
    [alertView show];
    [alertView autorelease];
}

- (void)altChatViewControllerDidTapEndScreenshotsButton:(LIOAltChatViewController *)aController
{
    screenshotsAllowed = NO;
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"screenshot", @"permission", nil];
    NSDictionary *permissionDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"advisory", @"type",
                                    @"permission_revoked", @"action",
                                    dataDict, @"data",
                                    nil];
    
    NSString *permissionRevoked = [jsonWriter stringWithObject:permissionDict];
    permissionRevoked = [permissionRevoked stringByAppendingString:LIOLookIOManagerMessageSeparator];
    
    [controlSocket writeData:[permissionRevoked dataUsingEncoding:NSUTF8StringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];
    
    [screenSharingStartedDate release];
    screenSharingStartedDate = nil;
}

/*
- (void)altChatViewControllerDidTapEmailButton:(LIOAltChatViewController *)aController
{
    [altChatViewController dismissModalViewControllerAnimated:NO];
    [altChatViewController.view removeFromSuperview];
    [altChatViewController autorelease];
    altChatViewController = nil;
    
    emailHistoryViewController = [[LIOEmailHistoryViewController alloc] initWithNibName:nil bundle:nil];
    emailHistoryViewController.delegate = self;
    emailHistoryViewController.initialEmailAddress = pendingEmailAddress;
    [lookioWindow addSubview:emailHistoryViewController.view];
    
    [self rejiggerWindows];
}
*/

- (void)altChatViewControllerDidStartDismissalAnimation:(LIOAltChatViewController *)aController
{
}

- (void)altChatViewControllerDidFinishDismissalAnimation:(LIOAltChatViewController *)aController
{
    [altChatViewController dismissModalViewControllerAnimated:NO];
    [altChatViewController.view removeFromSuperview];
    [altChatViewController release];
    altChatViewController = nil;
    
    NSString *chatDown = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                       @"advisory", @"type",
                                                       @"chat_down", @"action",
                                                       nil]];
    chatDown = [chatDown stringByAppendingString:LIOLookIOManagerMessageSeparator];
    
    [controlSocket writeData:[chatDown dataUsingEncoding:NSUTF8StringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];

    [self rejiggerWindows];
    
    if (killConnectionAfterChatViewDismissal)
    {
        resetAfterDisconnect = YES;
        [self killConnection];
    }
}

- (void)altChatViewControllerTypingDidStart:(LIOAltChatViewController *)aController
{
    if (introduced)
    {
        NSString *typingStart = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              @"advisory", @"type",
                                                              @"typing_start", @"action",
                                                              nil]];
        typingStart = [typingStart stringByAppendingString:LIOLookIOManagerMessageSeparator];
        
        [controlSocket writeData:[typingStart dataUsingEncoding:NSUTF8StringEncoding]
                     withTimeout:LIOLookIOManagerWriteTimeout
                             tag:0];
    }
}

- (void)altChatViewControllerTypingDidStop:(LIOAltChatViewController *)aController
{
    if (introduced)
    {
        NSString *typingStop = [jsonWriter stringWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             @"advisory", @"type",
                                                             @"typing_stop", @"action",
                                                             nil]];
        typingStop = [typingStop stringByAppendingString:LIOLookIOManagerMessageSeparator];
        
        [controlSocket writeData:[typingStop dataUsingEncoding:NSUTF8StringEncoding]
                     withTimeout:LIOLookIOManagerWriteTimeout
                             tag:0];
    }
}

- (BOOL)altChatViewController:(LIOAltChatViewController *)aController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation
{
    return [self shouldRotateToInterfaceOrientation:anOrientation];
}

- (void)altChatViewController:(LIOAltChatViewController *)aController didEnterBetaEmail:(NSString *)anEmail
{
    if ([anEmail length])
    {
        NSDictionary *aDict = [NSDictionary dictionaryWithObjectsAndKeys:anEmail, @"email", nil];
        NSMutableDictionary *emailDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          @"advisory", @"type",
                                          @"beta_email", @"action",
                                          aDict, @"data",
                                          nil];
        
        NSString *email = [jsonWriter stringWithObject:emailDict];
        email = [email stringByAppendingString:LIOLookIOManagerMessageSeparator];
        
        [controlSocket writeData:[email dataUsingEncoding:NSUTF8StringEncoding]
                     withTimeout:LIOLookIOManagerWriteTimeout
                             tag:0];
    }
}

- (void)altChatViewController:(LIOAltChatViewController *)aController didEnterTranscriptEmail:(NSString *)anEmail
{
    NSDictionary *aDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:anEmail], @"email_addresses", nil];
    NSMutableDictionary *emailDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      @"advisory", @"type",
                                      @"chat_history", @"action",
                                      aDict, @"data",
                                      nil];
    
    NSString *email = [jsonWriter stringWithObject:emailDict];
    email = [email stringByAppendingString:LIOLookIOManagerMessageSeparator];
    
    [controlSocket writeData:[email dataUsingEncoding:NSUTF8StringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];
    
    [emailHistoryViewController.view removeFromSuperview];
    [emailHistoryViewController release];
    emailHistoryViewController = nil;
}

- (void)altChatViewController:(LIOAltChatViewController *)aController didEnterLeaveMessageEmail:(NSString *)anEmail withMessage:(NSString *)aMessage
{
    if ([anEmail length] && [aMessage length])
    {
        NSMutableDictionary *feedbackDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             @"feedback", @"type",
                                             anEmail, @"email_address",
                                             aMessage, @"message",
                                             nil];
        
        NSString *feedback = [jsonWriter stringWithObject:feedbackDict];
        feedback = [feedback stringByAppendingString:LIOLookIOManagerMessageSeparator];
        
        [controlSocket writeData:[feedback dataUsingEncoding:NSUTF8StringEncoding]
                     withTimeout:LIOLookIOManagerWriteTimeout
                             tag:0];
    }
}

- (void)altChatViewControllerWantsSessionTermination:(LIOAltChatViewController *)aController
{
    sessionEnding = YES;
    
    [self rejiggerWindows];
    
    userWantsSessionTermination = YES;
    resetAfterDisconnect = YES;
    killConnectionAfterChatViewDismissal = YES;
    [altChatViewController performDismissalAnimation];
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
#pragma mark LIOLeaveMessageViewControllerDelegate methods

- (void)leaveMessageViewControllerWasDismissed:(LIOLeaveMessageViewController *)aController
{
    [leaveMessageViewController.view removeFromSuperview];
    [leaveMessageViewController release];
    leaveMessageViewController = nil;
    
    sessionEnding = YES;
    
    [self rejiggerWindows];
    
    userWantsSessionTermination = YES;
    resetAfterDisconnect = YES;
    [self killConnection];
}

- (void)leaveMessageViewController:(LIOLeaveMessageViewController *)aController didSubmitEmailAddress:(NSString *)anEmail withMessage:(NSString *)aMessage
{
    if ([anEmail length] && [aMessage length])
    {
        NSMutableDictionary *feedbackDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             @"feedback", @"type",
                                             anEmail, @"email_address",
                                             aMessage, @"message",
                                             nil];
        
        NSString *feedback = [jsonWriter stringWithObject:feedbackDict];
        feedback = [feedback stringByAppendingString:LIOLookIOManagerMessageSeparator];
        
        [controlSocket writeData:[feedback dataUsingEncoding:NSUTF8StringEncoding]
                     withTimeout:LIOLookIOManagerWriteTimeout
                             tag:0];
    }
}

- (BOOL)leaveMessageViewController:(LIOLeaveMessageViewController *)aController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation
{
    return [self shouldRotateToInterfaceOrientation:anOrientation];
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag)
    {
        case LIOLookIOManagerDisconnectErrorAlertViewTag:
        {
            [self reset];
            break;
        }
            
        case LIOLookIOManagerDisconnectConfirmAlertViewTag:
        {
            if (1 == buttonIndex) // "Yes"
            {
                sessionEnding = YES;
                userWantsSessionTermination = YES;
                
                if (NO == [controlSocket isConnected])
                {
                    [self reset];
                }
                else
                {
                    resetAfterDisconnect = YES;
                    [self killConnection];
                }
            }
            
            break;
        }
            
        case LIOLookIOManagerScreenshotPermissionAlertViewTag:
        {
            if (1 == buttonIndex) // "Yes"
            {
                screenshotsAllowed = YES;
                
                screenSharingStartedDate = [[NSDate date] retain];
                
                if (altChatViewController)
                {
                    [altChatViewController dismissModalViewControllerAnimated:NO];
                    [altChatViewController.view removeFromSuperview];
                    [altChatViewController release];
                    altChatViewController = nil;
                    [self rejiggerWindows];
                }
            }
            
            break;
        }
            
        /*    
        case LIOLookIOManagerNoAgentsOnlineAlertViewTag:
        {
            if (1 == buttonIndex) // "Yes"
            {
                [connectViewController.view removeFromSuperview];
                [connectViewController release];
                connectViewController = nil;
                
                feedbackViewController = [[LIOTextEntryViewController alloc] initWithNibName:nil bundle:nil];
                feedbackViewController.delegate = self;
                feedbackViewController.instructionsText = @"Please leave a message.";
                [lookioWindow addSubview:feedbackViewController.view];
                lookioWindow.hidden = NO;
            }
            else
            {
                resetAfterDisconnect = YES;
                [self killConnection];
            }
            
            break;
        }
        */
            
        case LIOLookIOManagerUnprovisionedAlertViewTag:
        {
            resetAfterDisconnect = YES;
            [self killConnection];
        }
            
        case LIOLookIOManagerAgentEndedSessionAlertViewTag:
        {
            /*
            if ([controlSocket isConnected])
            {
                resetAfterDisconnect = YES;
                [self killConnection];
            }
            else
            {
                [self reset];
            }
            */
        }
    }
}

#pragma mark -
#pragma mark Notification handlers

- (void)applicationWillResignActive:(NSNotification *)aNotification
{
    if (UIBackgroundTaskInvalid == backgroundTaskId)
    {
        backgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskId];
            backgroundTaskId = UIBackgroundTaskInvalid;
        }];
        
        [backgroundedTime release];
        backgroundedTime = [[NSDate date] retain];
    }
    
    if ([controlSocket isConnected])
    {
        NSMutableDictionary *backgroundedDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                 @"advisory", @"type",
                                                 @"app_backgrounded", @"action",
                                                 nil];
        
        NSString *backgrounded = [jsonWriter stringWithObject:backgroundedDict];
        backgrounded = [backgrounded stringByAppendingString:LIOLookIOManagerMessageSeparator];
        
        [controlSocket writeData:[backgrounded dataUsingEncoding:NSUTF8StringEncoding]
                     withTimeout:LIOLookIOManagerWriteTimeout
                             tag:0];
    }
    
    [altChatViewController dismissModalViewControllerAnimated:NO];
    [altChatViewController.view removeFromSuperview];
    [altChatViewController release];
    altChatViewController = nil;
    
    [emailHistoryViewController.view removeFromSuperview];
    [emailHistoryViewController release];
    emailHistoryViewController = nil;
    
    [leaveMessageViewController.view removeFromSuperview];
    [leaveMessageViewController release];
    leaveMessageViewController = nil;
    
    [self rejiggerWindows];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
    if (UIBackgroundTaskInvalid != backgroundTaskId)
    {
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskId];
        backgroundTaskId = UIBackgroundTaskInvalid;
        
        if ([backgroundedTime timeIntervalSinceNow] <= -1800.0)
        {
            // It's been 30 minutes! Send a launch packet.
            [overriddenEndpoint release];
            overriddenEndpoint = nil;
            
            [self sendLaunchReport];
        }
        
        [backgroundedTime release];
        backgroundedTime = nil;
    }
    
    if ([controlSocket isConnected])
    {
        NSMutableDictionary *foregroundedDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                    @"advisory", @"type",
                                                    @"app_foregrounded", @"action",
                                                    nil];
        
        NSString *foregrounded = [jsonWriter stringWithObject:foregroundedDict];
        foregrounded = [foregrounded stringByAppendingString:LIOLookIOManagerMessageSeparator];
        
        [controlSocket writeData:[foregrounded dataUsingEncoding:NSUTF8StringEncoding]
                     withTimeout:LIOLookIOManagerWriteTimeout
                             tag:0];
        
        // We also force the LookIO UI to the foreground here.
        // This prevents any jank: the user can always go out of the app and come back in
        // to correct any wackiness that might occur.
        if (nil == leaveMessageViewController && nil == emailHistoryViewController && NO == screenshotsAllowed)
            [self showChatAnimated:NO];
    }

    [self refreshControlButtonVisibility];
}

- (void)applicationWillChangeStatusBarOrientation:(NSNotification *)aNotification
{
    controlButton.hidden = YES;
}

- (void)applicationDidChangeStatusBarOrientation:(NSNotification *)aNotification
{
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self refreshControlButtonVisibility];
    });
    
    CGSize screenSize = [[[UIApplication sharedApplication] keyWindow] bounds].size;
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
    
    //clickView.transform = transform;
    //cursorView.transform = transform;
    
    CGSize textSize = [lastKnownButtonText sizeWithFont:controlButton.label.font];
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
        controlButton.frame = aFrame;
        [controlButton setNeedsLayout];
        
        controlButton.label.transform = CGAffineTransformMakeRotation(-90.0 * (M_PI / 180.0));
        controlButton.label.frame = controlButton.bounds;
    }
    else if (UIInterfaceOrientationLandscapeLeft == actualInterfaceOrientation)
    {
        CGRect aFrame = controlButton.frame;
        aFrame.size.width = actualHeight;
        aFrame.size.height = LIOLookIOManagerControlButtonMinWidth;
        aFrame.origin.y = -2.0;
        aFrame.origin.x = (screenSize.width / 2.0) - (actualHeight / 2.0);
        controlButton.frame = aFrame;
        [controlButton setNeedsLayout];
        
        controlButton.label.transform = CGAffineTransformMakeRotation(-180.0 * (M_PI / 180.0));
        controlButton.label.frame = controlButton.bounds;
    }
    else if (UIInterfaceOrientationPortraitUpsideDown == actualInterfaceOrientation)
    {
        CGRect aFrame = controlButton.frame;
        aFrame.size.width = LIOLookIOManagerControlButtonMinWidth;
        aFrame.size.height = actualHeight;
        aFrame.origin.y = (screenSize.height / 2.0) - (actualHeight / 2.0);
        aFrame.origin.x = -2.0;
        controlButton.frame = aFrame;
        [controlButton setNeedsLayout];
        
        controlButton.label.transform = CGAffineTransformMakeRotation(-270.0 * (M_PI / 180.0));
        controlButton.label.frame = controlButton.bounds;

    }
    else // Landscape, home button right
    {
        CGRect aFrame = controlButton.frame;
        aFrame.size.width = actualHeight;
        aFrame.size.height = LIOLookIOManagerControlButtonMinWidth;
        aFrame.origin.y = screenSize.height - LIOLookIOManagerControlButtonMinWidth + 2.0;
        aFrame.origin.x = (screenSize.width / 2.0) - (actualHeight / 2.0);
        controlButton.frame = aFrame;
        [controlButton setNeedsLayout];
        
        controlButton.label.transform = CGAffineTransformIdentity;//CGAffineTransformMakeRotation(-90.0 * (M_PI / 180.0));
        controlButton.label.frame = controlButton.bounds;
    }
    
    [controlButton setNeedsLayout];
    [controlButton setNeedsDisplay];
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
                [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
                
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
                
                NSDictionary *introDict = [self buildIntroDictionaryIncludingExtras:YES includingType:NO includingWhen:aDate];
                NSString *introDictWwwFormEncoded = [self wwwFormEncodedDictionary:introDict withName:nil];
                [request setHTTPBody:[introDictWwwFormEncoded dataUsingEncoding:NSUTF8StringEncoding]];
                [NSURLConnection connectionWithRequest:request delegate:nil];
                [request autorelease];
                LIOLog(@"<QUEUED_LAUNCH> Sent old launch packet for date: %@", aDate);
            }
            
            [queuedLaunchReportDates removeAllObjects];
            [[NSUserDefaults standardUserDefaults] setObject:queuedLaunchReportDates forKey:LIOLookIOManagerLaunchReportQueueKey];
            
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
    
    [lastKnownLocation release];
    lastKnownLocation = [[userInfo objectForKey:LIOAnalyticsManagerLocationObjectKey] retain];
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
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (appLaunchRequestConnection == connection)
    {
        [appLaunchRequestData appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (appLaunchRequestConnection == connection)
    {
        NSDictionary *responseDict = [jsonParser objectWithString:[[[NSString alloc] initWithData:appLaunchRequestData encoding:NSUTF8StringEncoding] autorelease]];
        LIOLog(@"<LAUNCH> Success (%d). Response: %@", appLaunchRequestResponseCode, responseDict);
        
        NSDictionary *params = [responseDict objectForKey:@"response"];
        [self parseAndSaveClientParams:params];
        
        [appLaunchRequestConnection release];
        appLaunchRequestConnection = nil;
        
        appLaunchRequestResponseCode = -1;
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (appLaunchRequestConnection == connection)
    {
        LIOLog(@"<LAUNCH> Failed. Reason: %@", [error localizedDescription]);
        
        [appLaunchRequestConnection release];
        appLaunchRequestConnection = nil;
        
        appLaunchRequestResponseCode = -1;
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:LIOLookIOManagerLastKnownEnabledStatusKey];
        [lastKnownEnabledStatus release];
        lastKnownEnabledStatus = nil;
        
        [self refreshControlButtonVisibility];
    }
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
#pragma mark UIControl actions

- (void)controlButtonWasTapped
{
    [self showChatAnimated:YES];
}

#pragma mark -
#pragma mark LIOControlButtonViewDelegate methods

- (void)controlButtonViewWasTapped:(LIOControlButtonView *)aControlButton
{
    if ([controlSocket isConnected] && introduced)
        [self showChatAnimated:YES];
    else
        [self beginSession];
}

#pragma mark -
#pragma mark Dynamic property accessors

- (BOOL)enabled
{
    return [lastKnownEnabledStatus boolValue];
}

@end
