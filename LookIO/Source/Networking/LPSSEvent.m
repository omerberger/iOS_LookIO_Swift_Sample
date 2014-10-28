//
//  LPSSEvent.m
//  LookIO
//
//  Created by Yaron Karasik on 6/27/13.
//
//

#import "LPSSEvent.h"

@implementation LPSSEvent

@synthesize eventId, eventType, data;

- (void)dealloc {
    [eventId release];
    [eventType release];
    [data release];
    
    [super dealloc];
}

@end
