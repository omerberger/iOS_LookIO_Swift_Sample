//
//  LIOCacheEntry.m
//  LookIO
//
//  Created by Joseph Toscano on 4/26/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import "LIOCacheEntry.h"

@implementation LIOCacheEntry

@synthesize cachedObject, weight;

+ (LIOCacheEntry *)cacheEntryWithCachedObject:(NSObject *)anObject
{
    LIOCacheEntry *newCacheEntry = [[LIOCacheEntry alloc] initWithCachedObject:anObject];
    return [newCacheEntry autorelease];
}

- (id)initWithCachedObject:(NSObject *)anObject
{
    self = [super init];
    
    if (self)
    {
        cachedObject = [anObject retain];
        weight = 1;
    }
    
    return self;
}

- (void)dealloc
{
    [cachedObject release];
    
    [super dealloc];
}

- (NSString *)description
{
    return [[super description] stringByAppendingFormat:@" (weight: %ld)", (long)weight];
}

@end