//
//  LIOMediaManager.m
//  LookIO
//
//  Created by Joseph Toscano on 5/6/13.
//
//

#import "LIOMediaManager.h"
#import "LIOLookIOManager.h"
#import "NSData+Base64.h"
#import "LIOLogManager.h"
#import "LIOBundleManager.h"
#import "LPChatAPIClient.h"
#import "LIOChatMessage.h"

static LIOMediaManager *sharedInstance = nil;

@interface LIOMediaManager () <NSURLConnectionDataDelegate, NSURLConnectionDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    NSURLConnection *uploadConnection;
}

@end

@implementation LIOMediaManager

+ (LIOMediaManager *)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[LIOMediaManager alloc] init];
    });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        // Ensure that the attachments directory exists.
        NSString *attachmentsDirectory = [self mediaPath];
        NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
        BOOL isDirectory = NO;
        BOOL directoryCheckResult = [fileManager fileExistsAtPath:attachmentsDirectory isDirectory:&isDirectory];
        if (NO == directoryCheckResult)
        {
            NSError *createDirectoryError = nil;
            BOOL dirWasCreated = [fileManager createDirectoryAtPath:attachmentsDirectory withIntermediateDirectories:NO attributes:nil error:&createDirectoryError];
            if (NO == dirWasCreated)
            {
                LIOLog(@"!!! WARNING !!! Unable to create Attachments directory! Reason: %@", createDirectoryError);
                [self release];
                return nil;
            }
        }
    }
    
    return self;
}

- (UIImage*)scaleImage:(UIImage*)sourceImage toSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [sourceImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (NSString *)mediaPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *attachmentsDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"LookIOMedia"];
    return attachmentsDirectory;
}

- (void)purgeAllMedia
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSString *attachmentsDirectory = [self mediaPath];
    NSDirectoryEnumerator *directory = [fileManager enumeratorAtPath:attachmentsDirectory];
    
    NSString *aFilePath;
    while ((aFilePath = [directory nextObject]))
    {
        // Skip non-files.
        NSDictionary *fileAttribs = [directory fileAttributes];
        NSString *fileType = [fileAttribs objectForKey:NSFileType];
        if (nil == fileType || NO == [fileType isEqualToString:NSFileTypeRegular])
            continue;
        
        NSError *anError;
        NSString *fullPath = [attachmentsDirectory stringByAppendingPathComponent:aFilePath];
        if (NO == [fileManager removeItemAtPath:fullPath error:&anError])
            LIOLog(@"Unable to delete attachment file \"%@\". Reason: %@", aFilePath, [anError localizedDescription]);
    }
    [fileManager release];
}

- (NSString *)commitImageMedia:(UIImage *)anImage
{
    NSData *dataToSave = UIImageJPEGRepresentation(anImage, 0.8);
    NSString *attachmentId = [NSString stringWithFormat:@"%@.image_jpeg", [self nextGUID]];
    NSString *targetPath = [[self mediaPath] stringByAppendingPathComponent:attachmentId];
    [dataToSave writeToFile:targetPath atomically:YES];
    return attachmentId;
}

- (NSData *)mediaDataWithId:(NSString *)anId
{
    NSString *targetPath = [[self mediaPath] stringByAppendingPathComponent:anId];
    return [NSData dataWithContentsOfFile:targetPath];
}

- (NSString *)mimeTypeFromId:(NSString *)anId
{
    NSString *result = @"application/octet-stream";
    NSArray *components = [anId componentsSeparatedByString:@"."];
    if ([components count] >= 2)
        result = [[components objectAtIndex:1] stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    
    return result;
}

- (NSString *)nextGUID
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
    NSString *newUUID = (NSString *)uuidString;
    CFRelease(uuid);
    return [newUUID autorelease];
}

@end