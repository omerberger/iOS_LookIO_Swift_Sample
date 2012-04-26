//
//  LIOCacheEntry.h
//  LookIO
//
//  Created by Joseph Toscano on 4/26/12.
//  Copyright (c) 2012 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LIOCacheEntry;

@interface LIOCacheEntry : NSObject
{
    NSInteger weight;
    NSObject *cachedObject;
}

+ (LIOCacheEntry *)cacheEntryWithCachedObject:(NSObject *)anObject;
- (id)initWithCachedObject:(NSObject *)anObject;

@property(nonatomic, readonly) NSObject *cachedObject;
@property(nonatomic, assign) NSInteger weight;

@end