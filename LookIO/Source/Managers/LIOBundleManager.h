//
//  LIOBundleManager.h
//  LookIO
//
//  Created by Joseph Toscano on 3/26/12.
//  Copyright (c) 2012 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LIOBundleManager;

@interface LIOBundleManager : NSObject
{
    NSBundle *bundle;
}

@property(nonatomic, readonly, getter=isAvailable) BOOL available;

+ (LIOBundleManager *)sharedBundleManager;

@end