//
//  LIOAnalyticsManager.m
//  LookIO
//
//  Created by Joseph Toscano on 11/10/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import "LIOAnalyticsManager.h"
#import <sys/socket.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <sys/sysctl.h>
#import <netinet/in.h>

@interface LIOAnalyticsManager ()
- (void)handleReachabilityCallbackWithFlags:(SCNetworkReachabilityFlags)flags;
@end

LIOAnalyticsManager *sharedAnalyticsManager = nil;

static void reachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
    LIOAnalyticsManager *fakeSelf = (LIOAnalyticsManager *)info;
    [fakeSelf handleReachabilityCallbackWithFlags:flags];
}

@implementation LIOAnalyticsManager

@synthesize lastKnownReachabilityStatus;

+ (LIOAnalyticsManager *)sharedAnalyticsManager
{
    if (nil == sharedAnalyticsManager)
        sharedAnalyticsManager = [[LIOAnalyticsManager alloc] init];
    
    return sharedAnalyticsManager;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        struct sockaddr_in zeroAddress;
        bzero(&zeroAddress, sizeof(zeroAddress));
        zeroAddress.sin_len = sizeof(zeroAddress);
        zeroAddress.sin_family = AF_INET;
        
        reachabilityRef = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&zeroAddress);
        SCNetworkReachabilityContext context = {0, self, NULL, NULL, NULL};
        SCNetworkReachabilitySetCallback(reachabilityRef, reachabilityCallback, &context);
        SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
    
    return self;
}

- (void)dealloc
{
    SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    CFRelease(reachabilityRef);
    
    [locationManager release];
    locationManager = nil;
    
    [super dealloc];
}

- (void)pumpReachabilityStatus
{
    SCNetworkReachabilityFlags flags;
    SCNetworkReachabilityGetFlags(reachabilityRef, &flags);
    [self handleReachabilityCallbackWithFlags:flags];
}

- (void)handleReachabilityCallbackWithFlags:(SCNetworkReachabilityFlags)flags
{
    LIOAnalyticsManagerReachabilityStatus previousStatus = lastKnownReachabilityStatus;
    
	if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
	{
        lastKnownReachabilityStatus = LIOAnalyticsManagerReachabilityStatusDisconnected;
	}
    else
    {
        lastKnownReachabilityStatus = LIOAnalyticsManagerReachabilityStatusDisconnected;
        
        if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
            lastKnownReachabilityStatus = LIOAnalyticsManagerReachabilityStatusConnected;
        
        if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
             (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
        {
            if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
                lastKnownReachabilityStatus = LIOAnalyticsManagerReachabilityStatusConnected;
        }
        
        if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
        {
            lastKnownReachabilityStatus = LIOAnalyticsManagerReachabilityStatusConnected;
        }
    }
    
    if (previousStatus != lastKnownReachabilityStatus)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:LIOAnalyticsManagerReachabilityDidChangeNotification
                                                            object:self];
    }
}

- (NSString *)cellularCarrierName
{
    Class $CTTelephonyNetworkInfo = NSClassFromString(@"CTTelephonyNetworkInfo");
    if ($CTTelephonyNetworkInfo)
    {
        id networkInfo = [[[$CTTelephonyNetworkInfo alloc] init] autorelease];
        id carrier = [networkInfo subscriberCellularProvider];
        NSString *carrierName = [carrier carrierName];
        if ([carrierName length])
            return carrierName;
    }
    
    return nil;
}

- (NSString *)hostAppBundleVersion
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

- (BOOL)locationServicesEnabled
{
    Class $CLLocationManager = NSClassFromString(@"CLLocationManager");
    if ($CLLocationManager && [$CLLocationManager respondsToSelector:@selector(authorizationStatus)])
    {
        // kCLAuthorizationStatusAuthorized is 3 as of 11/7/11
        int status = [$CLLocationManager authorizationStatus];
#ifdef DEBUG
        NSLog(@"[LOOKIO] Location services authorization status: %d", status);
#endif
        return status == 3;
    }
    
    return NO;
}

- (BOOL)cellularNetworkInUse
{
	struct sockaddr_in zeroAddress;
	bzero(&zeroAddress, sizeof(zeroAddress));
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);
	SCNetworkReachabilityFlags flags;
	if (SCNetworkReachabilityGetFlags(reachability, &flags))
    {
        BOOL wifi = NO;
        
        if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
            wifi = YES;
        
        if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
             (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
        {
			if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
				wifi = YES;
		}
        
        if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
            wifi = NO;
        
        return NO == wifi;
    }
    CFRelease(reachability);
    
    return NO;
}

- (BOOL)jailbroken
{
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    NSArray *jailbrokenPaths = [NSArray arrayWithObjects:
                                @"/Applications/Cydia.app",
                                @"/Applications/RockApp.app",
                                @"/Applications/Icy.app",
                                @"/usr/sbin/sshd",
                                @"/usr/bin/sshd",
                                @"/usr/libexec/sftp-server",
                                @"/Applications/WinterBoard.app",
                                @"/Applications/SBSettings.app",
                                @"/Applications/MxTube.app",
                                @"/Applications/IntelliScreen.app",
                                @"/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
                                @"/Applications/FakeCarrier.app",
                                @"/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
                                @"/private/var/lib/apt",
                                @"/Applications/blackra1n.app",
                                @"/private/var/stash",
                                @"/private/var/mobile/Library/SBSettings/Themes",
                                @"/System/Library/LaunchDaemons/com.ikey.bbot.plist",
                                @"/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
                                @"/private/var/tmp/cydia.log",
                                @"/private/var/lib/cydia", nil];
    for (NSString *aPath in jailbrokenPaths)
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:aPath])
        {
            return YES;
        }
    }
    
    return NO;
#endif
}

- (NSString *)distributionType
{
#if TARGET_IPHONE_SIMULATOR
    return @"other";
#else
    NSString *profilePath = [[NSBundle mainBundle] pathForResource:@"embedded.mobileprovision" ofType:nil];
    NSString *profileAsString = [NSString stringWithContentsOfFile:profilePath encoding:NSISOLatin1StringEncoding error:NULL];
    BOOL isAdHoc = [profileAsString rangeOfString:[[UIDevice currentDevice] uniqueIdentifier] options:NSCaseInsensitiveSearch].length;
    if (isAdHoc)
        return @"other";
    else
        return @"app_store";
#endif
}

- (BOOL)pushEnabled
{
    return [[UIApplication sharedApplication] enabledRemoteNotificationTypes] != UIRemoteNotificationTypeNone;
}

- (void)beginLocationCheck
{
    if (NO == [self locationServicesEnabled] || [[[UIDevice currentDevice] systemVersion] floatValue] < 5.0)
        return;
    
    if (locationManager)
        [locationManager release];

    Class $CLLocationManager = NSClassFromString(@"CLLocationManager");
    locationManager = [[$CLLocationManager alloc] init];
    [locationManager setDelegate:self];
    [locationManager startUpdatingLocation];
}

#pragma mark -
#pragma mark CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:newLocation, LIOAnalyticsManagerLocationObjectKey, nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:LIOAnalyticsManagerLocationWasDeterminedNotification
                                                        object:self
                                                      userInfo:userInfo];
    
    [locationManager release];
    locationManager = nil;
}

@end