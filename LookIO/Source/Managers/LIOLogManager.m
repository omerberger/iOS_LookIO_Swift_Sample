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
        logEntries = [[NSMutableArray alloc] init];
        
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm'Z'";
        dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];

        failedLogEntries = nil;
        
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
    /*
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
    
    [outputStream close];
    [outputStream release];
    */
    
    [logEntries removeAllObjects];
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

    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"  +" options:NSRegularExpressionCaseInsensitive error:&error];
    stringToLog = [[stringToLog componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
    stringToLog = [regex stringByReplacingMatchesInString:stringToLog options:0 range:NSMakeRange(0, [stringToLog length]) withTemplate:@""];
    
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

- (void)uploadLogForVisit:(LIOVisit *)visitForUpload
{
    NSString *allLogEntries;
    if (failedLogEntries == nil)
    {
        allLogEntries = [self.logEntries componentsJoinedByString:@""];
        [self flush];
    }
    else
    {
        allLogEntries = [failedLogEntries stringByAppendingString:[self.logEntries componentsJoinedByString:@""]];
        [self flush];
        [failedLogEntries release];
        failedLogEntries = nil;
    }
    
    failedLogEntries = [[allLogEntries copy] retain];
    visit = visitForUpload;
    
    if ([allLogEntries length])
    {
        NSURL *url = [NSURL URLWithString:self.lastKnownLoggingUrl];
    
        NSMutableURLRequest *uploadLogRequest = [NSMutableURLRequest requestWithURL:url
                                                                        cachePolicy:NSURLCacheStorageNotAllowed
                                                                    timeoutInterval:10.0];
        [uploadLogRequest addValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
        [uploadLogRequest setHTTPBody:[allLogEntries dataUsingEncoding:NSUTF8StringEncoding]];
        [uploadLogRequest setHTTPMethod:@"PUT"];
    
        [NSURLConnection connectionWithRequest:uploadLogRequest delegate:self];
    
//        LIOLog(@"Uploading LookIO log to %@ ...", [url absoluteString]);
//        NSLog(@"Uploaded log content is <<<< %@ >>>>", allLogEntries);
    
        [self deleteExistingLog];
    }
}


#pragma mark -
#pragma mark Log upload handlers

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    LIOLog(@"<<<LOG UPLOAD>>> Upload log failed with error %@", error);
    
    failedLogUploadAttempts += 1;
    
    if (failedLogUploadAttempts == 3)
    {
        LIOLog(@"<<<LOG UPLOAD>>> Upload log failed with error %@, stopping after 3 retries", error);

        failedLogUploadAttempts = 0;
        [failedLogEntries release];
        failedLogEntries = nil;

        if (visit != nil)
        {
            [visit stopLogUploading];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger responseStatusCode = [httpResponse statusCode];
    LIOLog(@"<<<LOG UPLOAD>>> Log upload response is %ld", (long)responseStatusCode);
    if (responseStatusCode >= 200 && responseStatusCode < 300)
    {
        [failedLogEntries release];
        failedLogEntries = nil;
        failedLogUploadAttempts = 0;
    } else if (404 == responseStatusCode && visit != nil) {
        [failedLogEntries release];
        failedLogEntries = nil;
        failedLogUploadAttempts = 0;
        
        LIOLog(@"<<<LOG UPLOAD>>> Stopping logging due to 404", (long)responseStatusCode);
        [visit stopLogUploading];
    } else {
        [self connection:connection didFailWithError:nil];
    }
}

@end