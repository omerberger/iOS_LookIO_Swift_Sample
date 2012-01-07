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
#import <AudioToolbox/AudioToolbox.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <sys/socket.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <sys/sysctl.h>
#import <netinet/in.h>
#import "LIOLookIOManager.h"
#import "SBJSON.h"
#import "LIOChatboxView.h"
#import "NSData+Base64.h"
#import "LIOChatViewController.h"
#import "LIOLeaveMessageViewController.h"
#import "LIOEmailHistoryViewController.h"
#import "LIOControlButtonView.h"
#import "LIOAnalyticsManager.h"

#define HEXCOLOR(c) [UIColor colorWithRed:((c>>16)&0xFF)/255.0 \
                                    green:((c>>8)&0xFF)/255.0 \
                                     blue:((c)&0xFF)/255.0 \
                                    alpha:1.0]

// Misc. constants
#define LIOLookIOManagerVersion @"1.1.0"

#define LIOLookIOManagerScreenCaptureInterval   0.33

#define LIOLookIOManagerWriteTimeout            5.0

#define LIOLookIOManagerControlEndpointRequestURL   @"http://connect.look.io/api/v1/endpoint"
#define LIOLookIOManagerControlEndpointPort         8100
#define LIOLookIOManagerControlEndpointPortTLS      9000

#define LIOLookIOManagerAppLaunchRequestURL    @"http://connect.look.io/api/v1/app/launch"
#define LIOLookIOManagerAppResumeRequestURL    @"http://connect.look.io/api/v1/app/resume"

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

#define LIOLookIOManagerControlButtonHeight 110.0
#define LIOLookIOManagerControlButtonWidth  35.0

@class CTCall, CTCallCenter;

@interface LIOLookIOManager ()
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
    SystemSoundID soundYay, soundDing;
    BOOL resetAfterDisconnect, killConnectionAfterChatViewDismissal, sessionEnding;
    NSNumber *lastKnownQueuePosition;
    BOOL screenshotsAllowed;
    UIBackgroundTaskIdentifier backgroundTaskId;
    NSString *targetAgentId;
    BOOL usesTLS, usesSounds, userWantsSessionTermination;
    UIWindow *lookioWindow, *previousKeyWindow, *mainWindow;
    NSMutableURLRequest *appLaunchRequest, *appResumeRequest;
    NSURLConnection *appLaunchRequestConnection, *appResumeRequestConnection;
    NSMutableData *appLaunchRequestData, *appResumeRequestData;
    NSInteger appLaunchRequestResponseCode, appResumeRequestResponseCode;
    NSString *controlEndpoint;
    LIOChatViewController *chatViewController;
    LIOEmailHistoryViewController *emailHistoryViewController;
    LIOLeaveMessageViewController *leaveMessageViewController;
    NSString *pendingFeedbackText;
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
    id<LIOLookIOManagerDelegate> delegate;
}

@property(nonatomic, readonly) BOOL screenshotsAllowed;

- (void)controlButtonWasTapped;
- (void)rejiggerWindows;
- (void)refreshControlButtonVisibility;
- (NSDictionary *)buildIntroDictionaryIncludingExtras:(BOOL)includeExtras includingType:(BOOL)includesType;
- (NSString *)wwwFormEncodedDictionary:(NSDictionary *)aDictionary withName:(NSString *)aName;
- (void)handleCallEvent:(CTCall *)aCall;

@end

NSBundle *lookioBundle()
{
    static NSBundle *bundle = nil;
    
    if (nil == bundle)
    {
        NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"LookIO.bundle"];
        bundle = [[NSBundle bundleWithPath:path] retain];
    }
    
    return bundle;
}

UIImage *lookioImage(NSString *path)
{
    NSBundle *bundle = lookioBundle();
    if (bundle)
    {
        path = [path stringByDeletingPathExtension];
        
        if ([UIScreen instancesRespondToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2.0)
        {
            NSString *path2x = [path stringByAppendingString:@"@2x"];

            // Try @2xPNG...
            NSString *actualPath = [bundle pathForResource:path2x ofType:@"png"];
            if ([actualPath length])
            {
                NSData *fileData = [NSData dataWithContentsOfFile:actualPath];
                if (fileData)
                {
                    UIImage *newImage = [UIImage imageWithData:fileData];
                    return [[[UIImage alloc] initWithCGImage:[newImage CGImage] scale:2.0 orientation:UIImageOrientationUp] autorelease];
                }
            }
                
            // Try @2xJPG...
            actualPath = [bundle pathForResource:path2x ofType:@"jpg"];
            if ([actualPath length])
            {
                fileData = [NSData dataWithContentsOfFile:actualPath];
                if (fileData)
                {
                    UIImage *newImage = [UIImage imageWithData:fileData];
                    return [[[UIImage alloc] initWithCGImage:[newImage CGImage] scale:2.0 orientation:UIImageOrientationUp] autorelease];
                }
            }
        }
        else
        {
            NSString *actualPath = [bundle pathForResource:path ofType:@"png"];
            if ([actualPath length])
            {
                // Try PNG...
                NSData *fileData = [NSData dataWithContentsOfFile:actualPath];
                if (fileData)
                    return [UIImage imageWithData:fileData];
            }
                
            // Try JPG...
            actualPath = [bundle pathForResource:path ofType:@"jpg"];
            if ([actualPath length])
            {
                fileData = [NSData dataWithContentsOfFile:actualPath];
                if (fileData)
                    return [UIImage imageWithData:fileData];
            }
        }
        
#ifdef DEBUG
            NSLog(@"[LOOKIO] Couldn't find normal or @2x file for resource \"%@\" in LookIO bundle!", path);
#endif
    }
    else
    {
#ifdef DEBUG
        NSLog(@"[LOOKIO] No LookIO bundle! Loading \"%@\" from main bundle...", path);
#endif
        return [UIImage imageNamed:path];
    }
    
    // Never reached.
    return nil;
}

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

@synthesize touchImage, targetAgentId, usesTLS, usesSounds, screenshotsAllowed, mainWindow, delegate;
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
        usesTLS = YES;
        usesSounds = YES;
        
        sessionExtras = [[NSMutableDictionary alloc] init];
        
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm'Z'";
        dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        
        queuedLaunchReportDates = [[NSUserDefaults standardUserDefaults] objectForKey:LIOLookIOManagerLaunchReportQueueKey];
        if (nil == queuedLaunchReportDates)
            queuedLaunchReportDates = [[NSMutableArray alloc] init];
        
        // Start the reachability monitor.
        [LIOAnalyticsManager sharedAnalyticsManager];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityDidChange:)
                                                     name:LIOAnalyticsManagerReachabilityDidChangeNotification
                                                   object:[LIOAnalyticsManager sharedAnalyticsManager]];
    }
    
    return self;
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
    
    jsonParser = [[SBJsonParser_LIO alloc] init];
    jsonWriter = [[SBJsonWriter_LIO alloc] init];
    
    self.touchImage = lookioImage(@"LIODefaultTouch");
    
    chatHistory = [[NSMutableArray alloc] init];
        
    controlButton = [[LIOControlButtonView alloc] initWithFrame:CGRectZero];
    controlButton.hidden = YES;
    controlButton.delegate = self;
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
    
    appLaunchRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:LIOLookIOManagerAppLaunchRequestURL]
                                                         cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                     timeoutInterval:10.0];
    [appLaunchRequest setHTTPMethod:@"POST"];
    [appLaunchRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    appLaunchRequestData = [[NSMutableData alloc] init];
    appLaunchRequestResponseCode = -1;
    
    appResumeRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:LIOLookIOManagerAppResumeRequestURL]
                                                    cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                timeoutInterval:10.0];
    [appResumeRequest setHTTPMethod:@"POST"];
    [appResumeRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    appResumeRequestData = [[NSMutableData alloc] init];
    appResumeRequestResponseCode = -1;
    
    NSString *aPath = [lookioBundle() pathForResource:@"LookIODing" ofType:@"caf"];
    if ([aPath length])
    {
        NSURL *soundURL = [NSURL fileURLWithPath:aPath];
        AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &soundDing);
    }
    else
    {
        NSString *anotherPath = [[NSBundle mainBundle] pathForResource:@"LookIODing" ofType:@"caf"];
        if ([anotherPath length])
        {
            NSURL *soundURL = [NSURL fileURLWithPath:anotherPath];
            AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &soundDing);
        }
    }
    
    aPath = [lookioBundle() pathForResource:@"LookIOConnect" ofType:@"caf"];
    if ([aPath length])
    {
        NSURL *soundURL = [NSURL fileURLWithPath:aPath];
        AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &soundYay);
    }
    else
    {
        NSString *anotherPath = [[NSBundle mainBundle] pathForResource:@"LookIOConnect" ofType:@"caf"];
        if ([anotherPath length])
        {
            NSURL *soundURL = [NSURL fileURLWithPath:anotherPath];
            AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &soundYay);
        }
    }
    
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
                                             selector:@selector(applicationDidChangeStatusBarOrientation:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    // Send off the app launch packet, if connected.
    [[LIOAnalyticsManager sharedAnalyticsManager] pumpReachabilityStatus];
    if (LIOAnalyticsManagerReachabilityStatusConnected == [LIOAnalyticsManager sharedAnalyticsManager].lastKnownReachabilityStatus)
    {
        NSDictionary *introDict = [self buildIntroDictionaryIncludingExtras:YES includingType:NO includingWhen:nil];
        NSString *introDictWwwFormEncoded = [self wwwFormEncodedDictionary:introDict withName:nil];
        [appLaunchRequest setHTTPBody:[introDictWwwFormEncoded dataUsingEncoding:NSUTF8StringEncoding]];
    #ifdef DEBUG
        NSLog(@"[LOOKIO] <LAUNCH> Request: %@", introDictWwwFormEncoded);
    #endif
        appLaunchRequestConnection = [[NSURLConnection alloc] initWithRequest:appLaunchRequest delegate:self];
    }
    else
    {
        // Queue this launch packet.
        [queuedLaunchReportDates addObject:[NSDate date]];
        [[NSUserDefaults standardUserDefaults] setObject:queuedLaunchReportDates forKey:LIOLookIOManagerLaunchReportQueueKey];
    }
    
    NSLog(@"[LOOKIO] Loaded.");    
}

- (NSString *)dateToStandardizedString:(NSDate *)aDate
{
    NSString *result = [dateFormatter stringFromDate:aDate];
    
#ifdef DEBUG
    NSLog(@"[LOOKIO] Date conversion: [%@] => \"%@\"", aDate, result);
#endif
    
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
    [controlEndpoint release];
    [pendingFeedbackText release];
    [friendlyName release];
    [sessionId release];
    [appLaunchRequest release];
    [appResumeRequest release];
    [appLaunchRequestConnection release];
    [appResumeRequestConnection release];
    [appLaunchRequestData release];
    [appResumeRequestData release];
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
    
    [leaveMessageViewController release];
    leaveMessageViewController = nil;
    
    [emailHistoryViewController release];
    emailHistoryViewController = nil;
    
    [chatViewController release];
    chatViewController = nil;
    
    AudioServicesDisposeSystemSoundID(soundDing);
    AudioServicesDisposeSystemSoundID(soundYay);
    
    [self rejiggerWindows];
    
    [lookioWindow release];
    
    NSLog(@"[LOOKIO] Unloaded.");
    
    [super dealloc];
}

- (void)reset
{
    [chatViewController.view removeFromSuperview];
    [chatViewController release];
    chatViewController = nil;
    
    [leaveMessageViewController.view removeFromSuperview];
    [leaveMessageViewController release];
    leaveMessageViewController = nil;
    
    [emailHistoryViewController.view removeFromSuperview];
    [emailHistoryViewController release];
    emailHistoryViewController = nil;

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
    
    [pendingFeedbackText release];
    pendingFeedbackText = nil;
    
    waitingForScreenshotAck = NO, waitingForIntroAck = NO, controlSocketConnecting = NO, introduced = NO, enqueued = NO;
    resetAfterDisconnect = NO, killConnectionAfterChatViewDismissal = NO, screenshotsAllowed = NO;
    sessionEnding = NO, userWantsSessionTermination = NO;
    
    [screenSharingStartedDate release];
    screenSharingStartedDate = nil;
    
    [queuedLaunchReportDates removeAllObjects];
    
    [self rejiggerWindows];
    
    NSLog(@"[LOOKIO] Reset.");
}

- (void)rejiggerWindows
{
    if (chatViewController || leaveMessageViewController || emailHistoryViewController)
    {
        if (nil == previousKeyWindow)
        {
            if (mainWindow)
            {
                previousKeyWindow = mainWindow;
                
#ifdef DEBUG
                NSLog(@"[LOOKIO] Got key window from mainWindow.");
#endif
            }
            else if ([delegate respondsToSelector:@selector(lookIOManagerMainWindowForHostApp:)])
            {
                previousKeyWindow = [delegate lookIOManagerMainWindowForHostApp:self];
                
#ifdef DEBUG
                NSLog(@"[LOOKIO] Got key window from delegate.");
#endif
            }
            else if ([[[UIApplication sharedApplication] keyWindow] isMemberOfClass:[UIWindow class]])
            {
                previousKeyWindow = [[UIApplication sharedApplication] keyWindow];
                
#ifdef DEBUG
                NSLog(@"[LOOKIO] Got key window from UIApplication.");
#endif // DEBUG
            }
            else
            {
                NSLog(@"[LOOKIO] WARNING: Could not find host app's key window! Behavior from this point on is undefined.");
            }
            
            [lookioWindow makeKeyAndVisible];
        }
    }
    else
    {
        lookioWindow.hidden = YES;
        
        [previousKeyWindow makeKeyWindow];
        previousKeyWindow = nil;
        
        [self refreshControlButtonVisibility];
    }
    
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
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
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (keyWindow != lookioWindow)
    {
        [keyWindow bringSubviewToFront:controlButton];
        [keyWindow bringSubviewToFront:cursorView];
        [keyWindow bringSubviewToFront:clickView];
    }
    
    if (NO == [controlSocket isConnected] || waitingForScreenshotAck || NO == introduced || YES == enqueued || NO == screenshotsAllowed || chatViewController)
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
                
#ifdef DEBUG
                NSLog(@"[SCREENSHOT] Sent %dx%d %@ screenshot (%u bytes image data, %u bytes total).\nHeader: %@", (int)screenshotSize.width, (int)screenshotSize.height, orientationString, [screenshotData length], [dataToSend length], header);
#endif
            });
        }
    });
}

- (void)showChat
{
    if (chatViewController)
        return;
    
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    
    chatViewController = [[LIOChatViewController alloc] initWithNibName:nil bundle:nil];
    chatViewController.delegate = self;
    chatViewController.dataSource = self;
    chatViewController.view.alpha = 0.0;
    chatViewController.initialChatText = pendingChatText;
    [pendingChatText release];
    pendingChatText = nil;
    [lookioWindow addSubview:chatViewController.view];
    [self rejiggerWindows];
    
    [chatViewController performRevealAnimation];
    
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [chatViewController reloadMessages];
    });
    
    //[chatViewController scrollToBottom];
    
    if (usesSounds)
        AudioServicesPlaySystemSound(soundYay);
    
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

- (void)showLeaveMessageUI
{
    if (leaveMessageViewController)
        return;
    
    leaveMessageViewController = [[LIOLeaveMessageViewController alloc] initWithNibName:nil bundle:nil];
    leaveMessageViewController.delegate = self;
    leaveMessageViewController.initialMessage = pendingFeedbackText;
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
#ifdef DEBUG
        NSLog(@"[beginSession] Ignored: current session is still ending...");
#endif // DEBUG
        return;
    }
    
    if (controlSocketConnecting)
    {
        NSLog(@"[CONNECT] Connect attempt ignored: connecting or already connected.");
        return;
    }
    
    if ([controlSocket isConnected])
    {
        [self controlButtonWasTapped];
        return;
    }

    // Bypass REST call.
    [controlEndpoint release];
    controlEndpoint = [[NSString stringWithString:@"connect.look.io"] retain];
    
    NSUInteger chosenPort = LIOLookIOManagerControlEndpointPortTLS;
    if (NO == usesTLS)
        chosenPort = LIOLookIOManagerControlEndpointPort;
    
    NSError *connectError = nil;
    BOOL connectResult = [controlSocket connectToHost:controlEndpoint
                                               onPort:chosenPort
                                                error:&connectError];
    if (NO == connectResult)
    {
        [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
        
        NSLog(@"[CONNECT] Connection failed. Reason: %@", [connectError localizedDescription]);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                            message:[connectError localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"k :(", nil];
        [alertView show];
        [alertView autorelease];
        
        controlSocketConnecting = NO;
        
        return;
    }
    
    if (usesSounds)
        AudioServicesPlaySystemSound(soundDing);
    
#ifdef DEBUG
    NSLog(@"[CONNECT] Trying \"%@:%u\"...", controlEndpoint, chosenPort);
#endif
    
    controlSocketConnecting = YES;
    
    //[self showConnectionUI];
    [chatHistory addObject:LIOChatboxViewAdTextTrigger];
    if ([lastKnownWelcomeMessage length])
        [chatHistory addObject:lastKnownWelcomeMessage];
    else
        [chatHistory addObject:@"Send a message to our live service reps for immediate help."];
    
    [self showChat];
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
#ifdef DEBUG
            NSLog(@"[INTRODUCTION] Introduction complete.");
#endif
            introduced = YES;
            waitingForIntroAck = NO;
            enqueued = YES;
            
            [controlSocket readDataToData:messageSeparatorData
                              withTimeout:-1
                                      tag:0];
        }
        else if (waitingForScreenshotAck)
        {
#ifdef DEBUG
            NSLog(@"[SCREENSHOT] Screenshot received by remote host.");
#endif
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
        [chatHistory addObject:[NSString stringWithFormat:@"Agent: %@", text]];

        if (nil == chatViewController)
        {
            // First, we have to kill any existing full-screen dealios.
            [emailHistoryViewController.view removeFromSuperview];
            [emailHistoryViewController release];
            emailHistoryViewController = nil;
            
            [self showChat];
        }
        else
        {
            [chatViewController reloadMessages];
            //[chatViewController scrollToBottom];
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
        
#ifdef DEBUG
        NSLog(@"[LOOKIO] New cursor position: %@x%@ (frame: %@)", x, y, [NSValue valueWithCGRect:aFrame]);
#endif // DEBUG
        
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState)
                         animations:^{ cursorView.frame = aFrame; }
                         completion:nil];
    }
    else if ([type isEqualToString:@"advisory"])
    {
        NSString *action = [aPacket objectForKey:@"action"];
        
        if ([action isEqualToString:@"cursor_start"])
        {
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
#ifdef DEBUG
            NSLog(@"[QUEUE] We're live!");
#endif
            enqueued = NO;
            
            if (UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
            {
                UILocalNotification *localNotification = [[[UILocalNotification alloc] init] autorelease];
                localNotification.soundName = @"LookIODing.caf";
                localNotification.alertBody = @"The support agent is ready to chat with you!";
                localNotification.alertAction = @"Go!";
                [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                
                [self showChat];
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
            [chatViewController removeFromSuperview];
            [chatViewController release];
            chatViewController = nil;
            
            [self showLeaveMessageUI];
        }
    }
    else if ([type isEqualToString:@"click"])
    {
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        
        if (nil == clickView)
        {
            clickView = [[UIImageView alloc] initWithImage:lookioImage(@"LIOClickIndicator")];
            [keyWindow addSubview:clickView];
        }
        
        [keyWindow bringSubviewToFront:clickView];
        
        NSNumber *x = [aPacket objectForKey:@"x"];
        NSNumber *y = [aPacket objectForKey:@"y"];
        
#ifdef DEBUG
        NSLog(@"[LOOKIO] New click: %@x%@", x, y);
#endif
        
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
        if ([controlSocket isConnected])
        {
            resetAfterDisconnect = YES;
            [self killConnection];
        }
        else
            [self reset];
        
        //[[[UIApplication sharedApplication] keyWindow] endEditing:YES];
        
        /*
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Notice"
                                                            message:@"The remote agent ended the session."
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Dismiss", nil];
        alertView.tag = LIOLookIOManagerAgentEndedSessionAlertViewTag;
        [alertView show];
        [alertView autorelease];
        */
    }
    
    [controlSocket readDataToData:messageSeparatorData
                      withTimeout:-1
                              tag:0];
}

- (void)performIntroduction
{
    NSDictionary *introDict = [self buildIntroDictionaryIncludingExtras:YES includingType:YES includingWhen:nil];
    
    NSString *intro = [jsonWriter stringWithObject:introDict];
    
#ifdef DEBUG
    NSLog(@"[INTRO] Intro JSON: %@", intro);
#endif
    
    intro = [intro stringByAppendingString:LIOLookIOManagerMessageSeparator];
    
    waitingForIntroAck = YES;
    
    [controlSocket writeData:[intro dataUsingEncoding:NSUTF8StringEncoding]
                 withTimeout:LIOLookIOManagerWriteTimeout
                         tag:0];
    
    [controlSocket readDataToData:messageSeparatorData
                      withTimeout:-1
                              tag:0];    
}

- (void)refreshControlButtonVisibility
{
    [controlButton stopFadeTimer];
    [controlButton.layer removeAllAnimations];
    
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
    if (chatViewController)
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
        
        if ([delegate respondsToSelector:@selector(lookIOManagerDidHideControlButton:)])
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
        
        if ([delegate respondsToSelector:@selector(lookIOManagerDidShowControlButton:)])
            [delegate lookIOManagerDidShowControlButton:self];
    }
    
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
        
        if ([delegate respondsToSelector:@selector(lookIOManager:didUpdateEnabledStatus:)])
            [delegate lookIOManager:self didUpdateEnabledStatus:[lastKnownEnabledStatus boolValue]];
    }
    
    [self refreshControlButtonVisibility];
}

- (BOOL)shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation
{
    // First, ask the delegate.
    if ([delegate respondsToSelector:@selector(lookIOManager:shouldRotateToInterfaceOrientation:)])
        return [delegate lookIOManager:self shouldRotateToInterfaceOrientation:anOrientation];
    
    // Fall back on plist settings.
    return [supportedOrientations containsObject:[NSNumber numberWithInt:anOrientation]];
}

- (void)setSessionExtra:(id)anObject forKey:(NSString *)aKey
{
    if (anObject)
        [sessionExtras setObject:anObject forKey:aKey];
    else
        [sessionExtras removeObjectForKey:aKey];
}

- (id)sessionExtraForKey:(NSString *)aKey
{
    return [sessionExtras objectForKey:aKey];
}

- (void)addSessionExtras:(NSDictionary *)aDictionary
{
    [sessionExtras addEntriesFromDictionary:aDictionary];
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
                                      @"##UNKNOWN_VERSION##", @"sdk_version",
                                      nil];
    
    if (includesType)
        [introDict setObject:@"intro" forKey:@"type"];
    
    if (aDate)
        [introDict setObject:[self dateToStandardizedString:aDate] forKey:@"when"];
    
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
        
        BOOL jailbroken = [[LIOAnalyticsManager sharedAnalyticsManager] jailbroken];
        [detectedDict setObject:[NSNumber numberWithBool:jailbroken] forKey:@"jailbroken"];

        BOOL pushEnabled = [[LIOAnalyticsManager sharedAnalyticsManager] pushEnabled];
        [detectedDict setObject:[NSNumber numberWithBool:pushEnabled] forKey:@"push"];
        
        [detectedDict setObject:[[LIOAnalyticsManager sharedAnalyticsManager] distributionType] forKey:@"distribution_type"];
        
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

#pragma mark -
#pragma mark AsyncSocketDelegate methods

- (void)onSocket:(AsyncSocket_LIO *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    controlSocketConnecting = NO;
    
    NSLog(@"[CONNECT] Connected to %@:%u", host, port);
    
    if (usesTLS)
        [controlSocket startTLS:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], (NSString *)kCFStreamSSLAllowsAnyRoot, nil]];
    else
        [self performIntroduction];
}

- (void)onSocketDidSecure:(AsyncSocket_LIO *)sock
{
    NSLog(@"[CONNECT] Secured.");    
    
    [self performIntroduction];
}

- (void)onSocket:(AsyncSocket_LIO *)sock willDisconnectWithError:(NSError *)err
{
    // We don't show error boxes if the user specifically requested a termination.
    if (err && NO == userWantsSessionTermination)
    {
        [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
        
        if (introduced)
        {
            NSString *message = [NSString stringWithFormat:@"Your support session has ended. If you still need help, try connecting to a live chat agent again. (%@)", [err localizedDescription]];
            
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
            NSString *message = [NSString stringWithFormat:@"A connection error occurred. Please try again. (%@)", [err localizedDescription]];
            
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
    
    userWantsSessionTermination = NO;
        
    NSLog(@"[CONNECT] Connection terminated unexpectedly. Reason: %@", [err localizedDescription]);
}

- (void)onSocketDidDisconnect:(AsyncSocket_LIO *)sock
{
    NSLog(@"[CONNECT] Socket disconnected.");
    
    if (resetAfterDisconnect)
    {
        sessionEnding = YES;
        [self reset];
    }
}

- (void)onSocket:(AsyncSocket_LIO *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *jsonString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    jsonString = [jsonString substringToIndex:([jsonString length] - [LIOLookIOManagerMessageSeparator length])];
    NSDictionary *result = [jsonParser objectWithString:jsonString];
    
#ifdef DEBUG
    NSLog(@"\n[READ]\n%@\n", jsonString);
#endif
    
    [self performSelectorOnMainThread:@selector(handlePacket:) withObject:result waitUntilDone:NO];    
}

- (NSTimeInterval)onSocket:(AsyncSocket_LIO *)sock shouldTimeoutReadWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length;
{
    NSLog(@"\n\nREAD TIMEOUT\n\n");
    return 0;
}

- (NSTimeInterval)onSocket:(AsyncSocket_LIO *)sock shouldTimeoutWriteWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length;
{
    NSLog(@"\n\nWRITE TIMEOUT\n\n");
    return 0;
}

#pragma mark -
#pragma mark LIOChatViewControllerDataSource methods

- (NSArray *)chatViewControllerChatMessages:(LIOChatViewController *)aController
{
    return chatHistory;
}

#pragma mark -
#pragma mark LIOChatViewController delegate methods

- (void)chatViewController:(LIOChatViewController *)aController wasDismissedWithPendingChatText:(NSString *)aString
{
    [pendingChatText release];
    pendingChatText = [aString retain];
    
    [chatViewController performDismissalAnimation];
}

- (void)chatViewController:(LIOChatViewController *)aController didChatWithText:(NSString *)aString
{
    [pendingFeedbackText release];
    pendingFeedbackText = [aString retain];
    
    // No agents available? Show leave message thingy.
    if (NO == agentsAvailable)
    {
        [chatViewController.view removeFromSuperview];
        [chatViewController release];
        chatViewController = nil;
        
        [self showLeaveMessageUI];
        
        return;
    }
    
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
    
    [chatHistory addObject:[NSString stringWithFormat:@"Me: %@", aString]];
    [chatViewController reloadMessages];
    //[chatViewController scrollToBottom];
}

- (void)chatViewControllerDidTapEndSessionButton:(LIOChatViewController *)aController
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

- (void)chatViewControllerDidTapEndScreenshotsButton:(LIOChatViewController *)aController
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

- (void)chatViewControllerDidTapEmailButton:(LIOChatViewController *)aController
{
    [chatViewController.view removeFromSuperview];
    [chatViewController autorelease];
    chatViewController = nil;
    
    emailHistoryViewController = [[LIOEmailHistoryViewController alloc] initWithNibName:nil bundle:nil];
    emailHistoryViewController.delegate = self;
    emailHistoryViewController.initialEmailAddress = pendingEmailAddress;
    [lookioWindow addSubview:emailHistoryViewController.view];
    
    [self rejiggerWindows];
}

- (void)chatViewController:(LIOChatViewController *)aController didEnterBetaEmail:(NSString *)anEmail
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

- (void)chatViewControllerDidFinishDismissalAnimation:(LIOChatViewController *)aController
{
    [chatViewController.view removeFromSuperview];
    [chatViewController release];
    chatViewController = nil;
        
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

- (void)chatViewControllerTypingDidStart:(LIOChatViewController *)aController
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

- (void)chatViewControllerTypingDidStop:(LIOChatViewController *)aController
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

- (BOOL)chatViewController:(LIOChatViewController *)aController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation
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
                else if (chatViewController)
                {
                    killConnectionAfterChatViewDismissal = YES;
                    [chatViewController performDismissalAnimation];
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
                
                if (chatViewController)
                {
                    [chatViewController.view removeFromSuperview];
                    [chatViewController release];
                    chatViewController = nil;
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
            if ([controlSocket isConnected])
            {
                resetAfterDisconnect = YES;
                [self killConnection];
            }
            else
            {
                [self reset];
            }
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
    
    [chatViewController.view removeFromSuperview];
    [chatViewController release];
    chatViewController = nil;
    
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
            [self showChat];
    }
    
    // Send off the app resume packet.
    NSDictionary *introDict = [self buildIntroDictionaryIncludingExtras:NO includingType:NO includingWhen:nil];
    NSString *introDictWwwFormEncoded = [self wwwFormEncodedDictionary:introDict withName:nil];
    [appResumeRequest setHTTPBody:[introDictWwwFormEncoded dataUsingEncoding:NSUTF8StringEncoding]];
#ifdef DEBUG
    NSLog(@"[LOOKIO] <RESUME> Request: %@", introDictWwwFormEncoded);
#endif
    appResumeRequestConnection = [[NSURLConnection alloc] initWithRequest:appResumeRequest delegate:self];
    
    [self refreshControlButtonVisibility];
}

- (void)applicationDidChangeStatusBarOrientation:(NSNotification *)aNotification
{
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
    
    // Manually position the control button. Ugh.
    if (UIInterfaceOrientationPortrait == actualInterfaceOrientation)
    {
        CGRect aFrame = controlButton.frame;
        aFrame.size.width = LIOLookIOManagerControlButtonWidth;
        aFrame.size.height = LIOLookIOManagerControlButtonHeight;
        aFrame.origin.y = (screenSize.height / 2.0) - (LIOLookIOManagerControlButtonHeight / 2.0);
        aFrame.origin.x = screenSize.width - LIOLookIOManagerControlButtonWidth;
        controlButton.frame = aFrame;
        [controlButton setNeedsLayout];
        
        controlButton.label.transform = CGAffineTransformMakeRotation(-90.0 * (M_PI / 180.0));
        controlButton.label.frame = controlButton.bounds;
        
#ifdef DEBUG
        NSLog(@"[LOOKIO] Rotation event.\n    actualInterfaceOrientation: portrait\n    screenSize: %@\n    controlButton.frame: %@\n", [NSValue valueWithCGSize:screenSize], [NSValue valueWithCGRect:controlButton.frame]);
#endif
    }
    else if (UIInterfaceOrientationLandscapeLeft == actualInterfaceOrientation)
    {
        CGRect aFrame = controlButton.frame;
        aFrame.size.width = LIOLookIOManagerControlButtonHeight;
        aFrame.size.height = LIOLookIOManagerControlButtonWidth;
        aFrame.origin.y = 0.0;
        aFrame.origin.x = (screenSize.width / 2.0) - (LIOLookIOManagerControlButtonHeight / 2.0);
        controlButton.frame = aFrame;
        [controlButton setNeedsLayout];
        
        controlButton.label.transform = CGAffineTransformMakeRotation(-180.0 * (M_PI / 180.0));
        controlButton.label.frame = controlButton.bounds;

#ifdef DEBUG
        NSLog(@"[LOOKIO] Rotation event.\n    actualInterfaceOrientation: landscape left\n    screenSize: %@\n    controlButton.frame: %@\n", [NSValue valueWithCGSize:screenSize], [NSValue valueWithCGRect:controlButton.frame]);
#endif
    }
    else if (UIInterfaceOrientationPortraitUpsideDown == actualInterfaceOrientation)
    {
        CGRect aFrame = controlButton.frame;
        aFrame.size.width = LIOLookIOManagerControlButtonWidth;
        aFrame.size.height = LIOLookIOManagerControlButtonHeight;
        aFrame.origin.y = (screenSize.height / 2.0) - (LIOLookIOManagerControlButtonHeight / 2.0);
        aFrame.origin.x = 0.0;
        controlButton.frame = aFrame;
        [controlButton setNeedsLayout];
        
        controlButton.label.transform = CGAffineTransformMakeRotation(-270.0 * (M_PI / 180.0));
        controlButton.label.frame = controlButton.bounds;
        
#ifdef DEBUG
        NSLog(@"[LOOKIO] Rotation event.\n    actualInterfaceOrientation: portrait upsidedown\n    screenSize: %@\n    controlButton.frame: %@\n", [NSValue valueWithCGSize:screenSize], [NSValue valueWithCGRect:controlButton.frame]);
#endif
    }
    else // Landscape, home button right
    {
        CGRect aFrame = controlButton.frame;
        aFrame.size.width = LIOLookIOManagerControlButtonHeight;
        aFrame.size.height = LIOLookIOManagerControlButtonWidth;
        aFrame.origin.y = screenSize.height - LIOLookIOManagerControlButtonWidth;
        aFrame.origin.x = (screenSize.width / 2.0) - (LIOLookIOManagerControlButtonHeight / 2.0);
        controlButton.frame = aFrame;
        [controlButton setNeedsLayout];
        
        controlButton.label.transform = CGAffineTransformIdentity;//CGAffineTransformMakeRotation(-90.0 * (M_PI / 180.0));
        controlButton.label.frame = controlButton.bounds;
        
#ifdef DEBUG
        NSLog(@"[LOOKIO] Rotation event.\n    actualInterfaceOrientation: landscape right\n    screenSize: %@\n    controlButton.frame: %@\n", [NSValue valueWithCGSize:screenSize], [NSValue valueWithCGRect:controlButton.frame]);
#endif
    }
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
                NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:LIOLookIOManagerAppLaunchRequestURL]
                                                                            cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                                        timeoutInterval:10.0];
                [request setHTTPMethod:@"POST"];
                [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
                
                NSDictionary *introDict = [self buildIntroDictionaryIncludingExtras:YES includingType:NO includingWhen:aDate];
                NSString *introDictWwwFormEncoded = [self wwwFormEncodedDictionary:introDict withName:nil];
                [request setHTTPBody:[introDictWwwFormEncoded dataUsingEncoding:NSUTF8StringEncoding]];
                [NSURLConnection connectionWithRequest:request delegate:nil];
#ifdef DEBUG
                NSLog(@"[LOOKIO] <QUEUED_LAUNCH> Sent old launch packet for date: %@", aDate);
#endif
            }
            
            [queuedLaunchReportDates removeAllObjects];
            [[NSUserDefaults standardUserDefaults] setObject:queuedLaunchReportDates forKey:LIOLookIOManagerLaunchReportQueueKey];
            
            break;
        }
            
        case LIOAnalyticsManagerReachabilityStatusDisconnected:
        {
            break;
        }
    }
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
    }
    else if (appResumeRequestConnection == connection)
    {
        [appResumeRequestData setData:[NSData data]];
        appResumeRequestResponseCode = [httpResponse statusCode];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (appLaunchRequestConnection == connection)
    {
        [appLaunchRequestData appendData:data];
    }
    else if (appResumeRequestConnection == connection)
    {
        [appResumeRequestData appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (appLaunchRequestConnection == connection)
    {
        NSDictionary *responseDict = [jsonParser objectWithString:[[[NSString alloc] initWithData:appLaunchRequestData encoding:NSUTF8StringEncoding] autorelease]];
#ifdef DEBUG
        NSLog(@"[LOOKIO] <LAUNCH> Success (%d). Response: %@", appLaunchRequestResponseCode, responseDict);
#endif
        
        NSDictionary *params = [responseDict objectForKey:@"response"];
        [self parseAndSaveClientParams:params];
        
        [appLaunchRequestConnection release];
        appLaunchRequestConnection = nil;
        
        appLaunchRequestResponseCode = -1;
    }
    else if (appResumeRequestConnection == connection)
    {
        NSDictionary *responseDict = [jsonParser objectWithString:[[[NSString alloc] initWithData:appResumeRequestData encoding:NSUTF8StringEncoding] autorelease]];
#ifdef DEBUG
        NSLog(@"[LOOKIO] <RESUME> Success (%d). Response: %@", appResumeRequestResponseCode, responseDict);
#endif
        
        NSDictionary *params = [responseDict objectForKey:@"response"];
        [self parseAndSaveClientParams:params];
        
        [appResumeRequestConnection release];
        appResumeRequestConnection = nil;
        
        appResumeRequestResponseCode = -1;
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (appLaunchRequestConnection == connection)
    {
#ifdef DEBUG
        NSLog(@"[LOOKIO] <LAUNCH> Failed. Reason: %@", [error localizedDescription]);
#endif
        
        [appLaunchRequestConnection release];
        appLaunchRequestConnection = nil;
        
        appLaunchRequestResponseCode = -1;
        
        [self refreshControlButtonVisibility];
    }
    else if (appResumeRequestConnection == connection)
    {
#ifdef DEBUG
        NSLog(@"[LOOKIO] <RESUME> Failed. Reason: %@", [error localizedDescription]);
#endif
        
        [appResumeRequestConnection release];
        appResumeRequestConnection = nil;
        
        appResumeRequestResponseCode = -1;
        
        [self refreshControlButtonVisibility];
    }
}

#pragma mark -
#pragma mark LIOLeaveMessageViewControllerDelegate methods

- (void)leaveMessageViewControllerWasDismissed:(LIOLeaveMessageViewController *)aController
{
    [leaveMessageViewController.view removeFromSuperview];
    [leaveMessageViewController release];
    leaveMessageViewController = nil;

    [self rejiggerWindows];
    
    resetAfterDisconnect = YES;
    [self killConnection];
}

- (void)leaveMessageViewController:(LIOLeaveMessageViewController *)aController wasDismissedWithEmailAddress:(NSString *)anEmail message:(NSString *)aMessage
{
    [leaveMessageViewController.view removeFromSuperview];
    [leaveMessageViewController release];
    leaveMessageViewController = nil;

    [self rejiggerWindows];
    
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
    
    userWantsSessionTermination = YES;
    resetAfterDisconnect = YES;
    [self killConnection];
    
}

- (BOOL)leaveMessageViewController:(LIOLeaveMessageViewController *)aController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation
{
    return [self shouldRotateToInterfaceOrientation:anOrientation];
}

#pragma mark -
#pragma mark LIOEmailHistoryViewControllerDelegate methods

- (void)emailHistoryViewControllerWasDismissed:(LIOLeaveMessageViewController *)aController
{
    [emailHistoryViewController.view removeFromSuperview];
    [emailHistoryViewController release];
    emailHistoryViewController = nil;

    [self showChat];
}

- (void)emailHistoryViewController:(LIOLeaveMessageViewController *)aController wasDismissedWithEmailAddress:(NSString *)anEmail
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
    
    [self showChat];
}

- (BOOL)emailHistoryViewController:(LIOEmailHistoryViewController *)aController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation
{
    return [self shouldRotateToInterfaceOrientation:anOrientation];
}


#pragma mark -
#pragma mark UIControl actions

- (void)controlButtonWasTapped
{
    [self showChat];
}

#pragma mark -
#pragma mark LIOControlButtonViewDelegate methods

- (void)controlButtonViewWasTapped:(LIOControlButtonView *)aControlButton
{
    if ([controlSocket isConnected] && introduced)
        [self showChat];
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