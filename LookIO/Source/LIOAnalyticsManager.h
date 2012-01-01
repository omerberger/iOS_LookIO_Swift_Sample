//
//  LIOAnalyticsManager.h
//  LookIO
//
//  Created by Joseph Toscano on 11/10/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>

#define LIOAnalyticsManagerReachabilityDidChangeNotification @"LIOAnalyticsManagerReachabilityDidChangeNotification"

typedef enum
{
    LIOAnalyticsManagerReachabilityStatusUnknown,
    LIOAnalyticsManagerReachabilityStatusDisconnected,
    LIOAnalyticsManagerReachabilityStatusConnected
} LIOAnalyticsManagerReachabilityStatus;

@class LIOAnalyticsManager;

@interface LIOAnalyticsManager : NSObject
{
    LIOAnalyticsManagerReachabilityStatus lastKnownReachabilityStatus;
    SCNetworkReachabilityRef reachabilityRef;
}

@property(nonatomic, readonly) LIOAnalyticsManagerReachabilityStatus lastKnownReachabilityStatus;

+ (LIOAnalyticsManager *)sharedAnalyticsManager;
- (NSString *)cellularCarrierName;
- (NSString *)hostAppBundleVersion;
- (BOOL)locationServicesEnabled;
- (BOOL)cellularNetworkInUse;
- (BOOL)jailbroken;
- (NSString *)distributionType;
- (BOOL)pushEnabled;
- (void)pumpReachabilityStatus;

@end