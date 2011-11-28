//
//  LIOAnalyticsManager.h
//  LookIO
//
//  Created by Joseph Toscano on 11/10/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LIOAnalyticsManager;

@interface LIOAnalyticsManager : NSObject
{
}

+ (LIOAnalyticsManager *)sharedAnalyticsManager;
- (NSString *)cellularCarrierName;
- (NSString *)hostAppBundleVersion;
- (BOOL)locationServicesEnabled;
- (BOOL)cellularNetworkInUse;
- (BOOL)jailbroken;
- (NSString *)distributionType;
- (BOOL)pushEnabled;

@end