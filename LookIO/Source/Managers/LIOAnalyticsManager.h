//
//  LIOAnalyticsManager.h
//  LookIO
//
//  Created by Joseph Toscano on 11/10/11.
//  Copyright (c) 2011 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreLocation/CoreLocation.h>

#define LIOAnalyticsManagerReachabilityDidChangeNotification    @"LIOAnalyticsManagerReachabilityDidChangeNotification"
#define LIOAnalyticsManagerLocationWasDeterminedNotification    @"LIOAnalyticsManagerLocationWasDeterminedNotification"

#define LIOAnalyticsManagerLocationObjectKey  @"LIOAnalyticsManagerLocationKey"

typedef enum
{
    LIOAnalyticsManagerReachabilityStatusUnknown,
    LIOAnalyticsManagerReachabilityStatusDisconnected,
    LIOAnalyticsManagerReachabilityStatusConnected
} LIOAnalyticsManagerReachabilityStatus;

@class LIOAnalyticsManager;

@interface LIOAnalyticsManager : NSObject <CLLocationManagerDelegate>
{
    LIOAnalyticsManagerReachabilityStatus lastKnownReachabilityStatus;
    SCNetworkReachabilityRef reachabilityRef;
    id locationManager;
}

@property(nonatomic, readonly) LIOAnalyticsManagerReachabilityStatus lastKnownReachabilityStatus;

+ (LIOAnalyticsManager *)sharedAnalyticsManager;
- (NSString *)cellularCarrierName;
- (NSString *)hostAppBundleVersion;
- (BOOL)locationServicesEnabled;
- (BOOL)cellularNetworkInUse;
- (BOOL)jailbroken;
- (BOOL)pushEnabled;
- (void)pumpReachabilityStatus;
- (void)beginLocationCheck;
- (NSArray *)twitterHandles;
- (NSString *)timezoneOffset;
- (NSString *)distributionType;

@end