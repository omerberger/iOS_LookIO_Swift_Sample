//
//  LIOLogManager.m
//  LookIO
//
//  Created by Joseph Toscano on 3/26/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import "LIOLogManager.h"
#import "LIOLookIOManager.h"

#define LIOLogManagerRecordSeparator        0x1E

static LIOLogManager *sharedLogManager = nil;

@implementation LIOLogManager

@synthesize logEntries;

+ (LIOLogManager *)sharedLogManager
{
    if (nil == sharedLogManager)
        sharedLogManager = [[LIOLogManager alloc] init];
    
    return sharedLogManager;
}

- (id)init
{
    if ((self = [super init]))
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillResignActive:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        
        logEntries = [[NSMutableArray alloc] init];
        
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm'Z'";
        dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        
        [self deleteExistingLogIfOversized];
    }
    
    return self;
}

- (void)dealloc
{
    sharedLogManager = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [logEntries release];
    [dateFormatter release];
    
    [super dealloc];
}

- (NSString *)logPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [[paths objectAtIndex:0] stringByAppendingPathComponent:@"LookIO.log"];
}

- (void)deleteExistingLogIfOversized
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [self logPath];
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:nil];
    unsigned long long fileSize = [attributes fileSize];
    if (fileSize > LIOLogManagerMaxLogFileSize)
        [fileManager removeItemAtPath:path error:nil];
}

- (void)deleteExistingLog
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [self logPath];
    [fileManager removeItemAtPath:path error:nil];
}

- (void)flush
{
    NSOutputStream *outputStream = [[NSOutputStream alloc] initToFileAtPath:[self logPath] append:YES];
    [outputStream open];
    for (NSString *aLogEntry in logEntries)
    {
        NSData *data = [aLogEntry dataUsingEncoding:NSUTF8StringEncoding];
        const uint8_t *bytes = [data bytes];
        [outputStream write:bytes maxLength:[data length]];
        const uint8_t separator = LIOLogManagerRecordSeparator;
        [outputStream write:&separator maxLength:1];
    }
    
    [logEntries removeAllObjects];
    [outputStream close];
    [outputStream release];
    
    residentLogCharacters = 0;
}

- (void)logWithSeverity:(LIOLogManagerSeverity)severity format:(NSString *)formatString, ...
{
    NSString *severityString = nil;
    switch (severity)
    {
        case LIOLogManagerSeverityDebug: severityString = @"debug"; break;
        case LIOLogManagerSeverityInfo: severityString = @"info"; break;
        case LIOLogManagerSeverityWarning: severityString = @"warning"; break;
    }
    
    va_list args;
    va_start(args, formatString);
    NSString *stringToLog = [[[NSString alloc] initWithFormat:formatString arguments:args] autorelease];
    va_end(args);
    
    NSMutableString *result = [NSMutableString string];
    [result appendFormat:@"%@ ", [dateFormatter stringFromDate:[NSDate date]]];
    [result appendString:stringToLog];
    [result appendFormat:@" #ios #%@\n", severityString];
    
    [logEntries addObject:result];
    
#ifdef DEBUG
    NSLog(@"[LPMobile//%@] %@", severityString, result);
#else
    if (severity != LIOLogManagerSeverityDebug)
        NSLog(@"[LPMobile//%@] %@", severityString, result);
#endif // DEBUG
    
    // Clamp.
    residentLogCharacters += [result length];
    if (residentLogCharacters >= LIOLogManagerMaxResidentLogCharacters)
        [self flush];
}

- (void)uploadLog
{
    [self flush];
    
    NSString *allLogEntries = [NSString stringWithContentsOfFile:[self logPath]
                                                        encoding:NSUTF8StringEncoding
                                                           error:nil];
    
    if ([allLogEntries length])
        [[LIOLookIOManager sharedLookIOManager] uploadLog:allLogEntries];
    
    [self deleteExistingLog];
}

#pragma mark -
#pragma mark Notification handlers

- (void)applicationWillResignActive:(NSNotification *)aNotification
{
    [self uploadLog];
}

@end