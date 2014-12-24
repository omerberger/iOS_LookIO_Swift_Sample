//
//  LIOBundleManager.h
//  LookIO
//
//  Created by Joseph Toscano on 3/26/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LIOBrandingManager.h"

#define LIOLocalizedString(key) [[LIOBundleManager sharedBundleManager] localizedStringWithKey:key]

// Notifications
#define LIOBundleManagerBundleDownloadDidFinishNotification @"LIOBundleManagerBundleDownloadDidFinishNotification"

// UserInfo keys
#define LIOBundleManagerErrorKey @"LIOBundleManagerErrorKey"

// Defaults keys
#define LIOBundleManagerStringTableDictKey     @"LIOBundleManagerStringTableDictKey"
#define LIOBundleManagerStringTableHashKey     @"LIOBundleManagerStringTableHashKey"
#define LIOBundleManagerBrandingImageCacheKey  @"LIOBundleManagerBrandingImageCacheKey"

#ifndef kCFCoreFoundationVersionNumber_iOS_7_0
#define kCFCoreFoundationVersionNumber_iOS_7_0 847.2
#endif

#define LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define LIO_IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )
#define LIO_IS_IPHONE_6 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )667 ) < DBL_EPSILON )
#define LIO_IS_IPHONE_6PLUS ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )736 ) < DBL_EPSILON )

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

    NSMutableDictionary *brandingImageCache;
}

@property (nonatomic, readonly) UIImage *lioTabInnerShadow, *lioTabInnerShadow2x;
@property (nonatomic, assign) BOOL isDownloadingBundle;

+ (LIOBundleManager *)sharedBundleManager;
- (void)findBundle;
- (UIImage *)imageNamed:(NSString *)aString;
- (UIImage *)imageNamed:(NSString *)aString withTint:(UIColor *)color;
- (UIImage *)imageNamed:(NSString *)aString DynamiclyColoredBasedOnBackgroundColor: (UIColor *)bgColor;
- (void)cacheImage:(UIImage *)image fromURL:(NSURL *)url forBrandingElement:(LIOBrandingElement)element;
- (void)cachedImageForBrandingElement:(LIOBrandingElement)element withBlock:(void (^)(BOOL, UIImage *))block;
- (NSDictionary *)brandingDictionary;
- (BOOL)isAvailable;
- (void)pruneImageCache;
- (NSString *)localizedStringWithKey:(NSString *)aKey;
- (NSString *)hashForLocalizedStringTable:(NSDictionary *)aTable;
- (NSString *)hashForLocalBrandingFile;
- (NSDictionary *)localizedStringTableForLanguage:(NSString *)aLangCode;
- (void)resetBundle;

@end