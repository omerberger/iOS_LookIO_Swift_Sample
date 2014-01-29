//
//  LIOStatusManager.h
//  LookIO
//
//  Created by Yaron Karasik on 12/5/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface LIOStatusManager : NSObject

@property (nonatomic, assign) BOOL appForegrounded;
@property (nonatomic, assign) BOOL badInitialization;
@property (nonatomic, strong) CLLocation *lastKnownLocation;

+ (LIOStatusManager *) statusManager;

+ (NSString *)deviceType;
+ (NSString *)bundleId;
+ (NSString *)systemVersion;
+ (NSString *)udid;
+ (NSString *)alternateUdid;
+ (NSNumber *)limitAdTracking;
+ (NSString *)localeId;
+ (NSString *)languageId;

@end
