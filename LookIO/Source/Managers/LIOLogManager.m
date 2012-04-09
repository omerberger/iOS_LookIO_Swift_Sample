//
//  LIOLogManager.m
//  LookIO
//
//  Created by Joseph Toscano on 3/26/12.
//  Copyright (c) 2012 LookIO, Inc. All rights reserved.
//

#import "LIOLogManager.h"

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
        logEntries = [[NSMutableArray alloc] init];
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        
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
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *logPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"LookIO.log"];
    return logPath;
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

- (void)flush
{
    NSOutputStream *outputStream = [[NSOutputStream alloc] initToFileAtPath:[self logPath] append:YES];
    [outputStream open];
    for (NSString *aLogEntry in logEntries)
    {
        NSData *data = [aLogEntry dataUsingEncoding:NSUTF8StringEncoding];
        const uint8_t *bytes = [data bytes];
        [outputStream write:bytes maxLength:[data length]];
    }
    
    [logEntries removeAllObjects];
    [outputStream close];
    [outputStream release];
    
    residentLogCharacters = 0;
}

- (void)logFormat:(NSString *)formatString, ...
{
    va_list args;
    va_start(args, formatString);
    NSString *stringToLog = [[[NSString alloc] initWithFormat:formatString arguments:args] autorelease];
    va_end(args);
    
    NSMutableString *result = [NSMutableString string];
    [result appendFormat:@"[%@] ", [dateFormatter stringFromDate:[NSDate date]]];
    [result appendString:stringToLog];
    [result appendString:@" #ios\n"];
    
    [logEntries addObject:result];
    
#ifdef DEBUG
    NSLog(@"%@", result);
#endif // DEBUG
    
    // Clamp.
    residentLogCharacters += [result length];
    if (residentLogCharacters >= LIOLogManagerMaxResidentLogCharacters)
        [self flush];
}

@end