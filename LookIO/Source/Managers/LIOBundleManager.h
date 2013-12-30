//
//  LIOBundleManager.h
//  LookIO
//
//  Created by Joseph Toscano on 3/26/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define LIOLocalizedString(key) [[LIOBundleManager sharedBundleManager] localizedStringWithKey:key]

// Notifications
#define LIOBundleManagerBundleDownloadDidFinishNotification @"LIOBundleManagerBundleDownloadDidFinishNotification"

// UserInfo keys
#define LIOBundleManagerErrorKey @"LIOBundleManagerErrorKey"

// Defaults keys
#define LIOBundleManagerStringTableDictKey  @"LIOBundleManagerStringTableDictKey"
#define LIOBundleManagerStringTableHashKey  @"LIOBundleManagerStringTableHashKey"

#ifndef kCFCoreFoundationVersionNumber_iOS_7_0
#define kCFCoreFoundationVersionNumber_iOS_7_0 847.2
#endif

#define LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

BOOL LIOIsUIKitFlatMode(void);

@class LIOBundleManager;

@interface LIOBundleManager : NSObject
{
    NSBundle *lioBundle;
    NSURLRequest *bundleDownloadRequest;
    NSURLConnection *bundleDownloadConnection;
    NSInteger bundleDownloadResponseCode;
    NSOutputStream *bundleDownloadOutputStream;
    UIImage *lioTabInnerShadow, *lioTabInnerShadow2x;
    NSMutableDictionary *imageCache;
    UInt32 selectedChatTheme;
}

@property(nonatomic, readonly) UIImage *lioTabInnerShadow, *lioTabInnerShadow2x;
@property(nonatomic, assign) UInt32 selectedChatTheme;

+ (LIOBundleManager *)sharedBundleManager;
- (void)findBundle;
- (UIImage *)imageNamed:(NSString *)aString;
- (UIImage *)imageNamed:(NSString *)aString withTint:(UIColor *)color;
- (BOOL)isAvailable;
- (void)pruneImageCache;
- (NSString *)localizedStringWithKey:(NSString *)aKey;
- (NSString *)hashForLocalizedStringTable:(NSDictionary *)aTable;
- (NSDictionary *)localizedStringTableForLanguage:(NSString *)aLangCode;
- (void)resetBundle;

@end