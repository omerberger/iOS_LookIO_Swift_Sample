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

static LIOMediaManager *sharedInstance = nil;

@interface LIOMediaManager () <NSURLConnectionDataDelegate, NSURLConnectionDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    NSURLConnection *uploadConnection;
    NSMutableURLRequest *uploadRequest;
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
        NSString *endpoint = [NSString stringWithFormat:@"https://%@/api/v1/media/upload", [[LIOLookIOManager sharedLookIOManager] chosenEndpoint]];
        uploadRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]
                                                     cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                 timeoutInterval:20.0];
        [uploadRequest setHTTPMethod:@"POST"];
        
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
                NSLog(@"!!! WARNING !!! Unable to create Attachments directory! Reason: %@", createDirectoryError);
                [self release];
                return nil;
            }
        }
    }
    
    return self;
}

// TODO: Support multiple concurrent uploads.
- (void)uploadMediaData:(NSData *)someData withType:(NSString *)aType
{
    if (uploadConnection)
        return;
    
    NSString *sessionId = [[LIOLookIOManager sharedLookIOManager] currentSessionId];
    if (0 == [sessionId length])
        return;
    
    NSString *bundleId = [[LIOLookIOManager sharedLookIOManager] bundleId];

    NSString *boundary = @"0xKhTmLbOuNdArY";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [uploadRequest addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSString *dataBase64 = base64EncodedStringFromData(someData);
    
    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"file\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", aType] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[dataBase64 dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"engagement_key\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[sessionId dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"bundle\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[bundleId dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    //NSLog(@"\n\nATTACHMENT UPLOAD REQUEST:\n%@\n\n", [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding]);
    
    [uploadRequest setHTTPBody:body];
    
    uploadConnection = [[NSURLConnection alloc] initWithRequest:uploadRequest delegate:self];
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
            NSLog(@"Unable to delete attachment file \"%@\". Reason: %@", aFilePath, [anError localizedDescription]);
    }
    [fileManager release];
}

- (NSString *)commitImageMedia:(UIImage *)anImage
{
    NSData *dataToSave = UIImageJPEGRepresentation(anImage, 0.8);
    NSString *attachmentId = [NSString stringWithFormat:@"%@.image_jpeg", [[LIOLookIOManager sharedLookIOManager] nextGUID]];
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

#pragma mark - NSURLConnectionDelegate & NSURLConnectionDataDelegate methods -

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"response: %d", [(NSHTTPURLResponse *)response statusCode]);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSString *lol = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    NSLog(@"data: %@", lol);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"finished loading");
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"hella fail: %@", error);
}

@end