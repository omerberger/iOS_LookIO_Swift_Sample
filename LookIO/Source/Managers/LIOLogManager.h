//
//  LIOLogManager.h
//  LookIO
//
//  Created by Joseph Toscano on 3/26/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LIOVisit.h"

#define LIOLog(...) [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityDebug format:__VA_ARGS__]

#define LIOLogManagerMaxResidentLogCharacters   128000
#define LIOLogManagerMaxLogFileSize             512000

typedef enum {
    LIOLogManagerSeverityDebug,
    LIOLogManagerSeverityInfo,
    LIOLogManagerSeverityWarning
} LIOLogManagerSeverity;

@class LIOLogManager;

@interface LIOLogManager : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
    NSDateFormatter *dateFormatter;
    NSMutableArray *logEntries;
    NSUInteger residentLogCharacters;

    NSString *lastKnownLoggingUrl;
    LIOVisit *visit;
    
    NSInteger failedLogUploadAttempts;
    NSString *failedLogEntries;
}

@property (nonatomic, readonly) NSMutableArray *logEntries;
@property (nonatomic, retain) NSString *lastKnownLoggingUrl;

+ (LIOLogManager *)sharedLogManager;
- (void)logWithSeverity:(LIOLogManagerSeverity)severity format:(NSString *)formatString, ...;
- (void)deleteExistingLogIfOversized;
- (void)flush;
- (void)uploadLogForVisit:(LIOVisit *)visitForUpload;

@end
