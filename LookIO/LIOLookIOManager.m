//
//  LIOLookIOManager.m
//  LookIO
//
//  Created by Joseph Toscano on 8/19/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import "LIOLookIOManager.h"

// Misc. constants
#define LIOLookIOManagerScreenCaptureInterval 1.0

@implementation LIOLookIOManager

static LIOLookIOManager *sharedLookIOManager = nil;

+ (LIOLookIOManager *)sharedLookIOManager
{
    if (nil == sharedLookIOManager)
        sharedLookIOManager = [[LIOLookIOManager alloc] init];
    
    return sharedLookIOManager;
}

- (void)init
{
    self = [super init];
    
    if (self)
    {
        
    }
    
    return self;
}

@end