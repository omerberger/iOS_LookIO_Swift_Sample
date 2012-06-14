//
//  LIOBundleManager.h
//  LookIO
//
//  Created by Joseph Toscano on 3/26/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

// Notifications
#define LIOBundleManagerBundleDownloadDidFinishNotification @"LIOBundleManagerBundleDownloadDidFinishNotification"

// UserInfo keys
#define LIOBundleManagerErrorKey @"LIOBundleManagerErrorKey"

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

@end