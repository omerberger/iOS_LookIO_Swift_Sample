//
//  LIOMapAnnotation.m
//  LookIO
//
//  Created by Joseph Toscano on 4/19/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import "LIOMapAnnotation.h"

@implementation LIOMapAnnotation

@synthesize coordinate, title, subtitle;

- (id)initWithCoordinate:(CLLocationCoordinate2D)aCoordinate title:(NSString *)aTitle subtitle:(NSString *)aSubtitle
{
    self = [super init];
    
    if (self)
    {
        title = [aTitle retain];
        subtitle = [aSubtitle retain];
        coordinate = aCoordinate;
    }
    
    return self;
}

- (void)dealloc
{
    [title release];
    [subtitle release];
    
    [super dealloc];
}

@end