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
}

@property(nonatomic, readonly) UIImage *lioTabInnerShadow, *lioTabInnerShadow2x;

+ (LIOBundleManager *)sharedBundleManager;
- (void)findBundle;
- (UIImage *)imageNamed:(NSString *)aString;
- (BOOL)isAvailable;
- (void)pruneImageCache;
- (NSString *)localizedStringWithKey:(NSString *)aKey;
- (NSString *)hashForLocalizedStringTable:(NSDictionary *)aTable;

@end