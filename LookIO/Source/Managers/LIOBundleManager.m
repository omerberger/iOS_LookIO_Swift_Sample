//
//  LIOBundleManager.m
//  LookIO
//
//  Created by Joseph Toscano on 3/26/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "LIOBundleManager.h"
#import "LIOLookIOManager.h"
#import "ZipFile.h"
#import "FileInZipInfo.h"
#import "ZipReadStream.h"
#import "LIOLogManager.h"
#import "LIOCacheEntry.h"

static const unsigned char lioTabInnerShadowBytes[905] = { 137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 35, 0, 0, 0, 110, 8, 6, 0, 0, 0, 173, 31, 170, 235, 0, 0, 0, 9, 112, 72, 89, 115, 0, 0, 11, 18, 0, 0, 11, 18, 1, 210, 221, 126, 252, 0, 0, 2, 33, 105, 84, 88, 116, 88, 77, 76, 58, 99, 111, 109, 46, 97, 100, 111, 98, 101, 46, 120, 109, 112, 0, 0, 0, 0, 0, 60, 120, 58, 120, 109, 112, 109, 101, 116, 97, 32, 120, 109, 108, 110, 115, 58, 120, 61, 34, 97, 100, 111, 98, 101, 58, 110, 115, 58, 109, 101, 116, 97, 47, 34, 32, 120, 58, 120, 109, 112, 116, 107, 61, 34, 88, 77, 80, 32, 67, 111, 114, 101, 32, 52, 46, 52, 46, 48, 34, 62, 10, 32, 32, 32, 60, 114, 100, 102, 58, 82, 68, 70, 32, 120, 109, 108, 110, 115, 58, 114, 100, 102, 61, 34, 104, 116, 116, 112, 58, 47, 47, 119, 119, 119, 46, 119, 51, 46, 111, 114, 103, 47, 49, 57, 57, 57, 47, 48, 50, 47, 50, 50, 45, 114, 100, 102, 45, 115, 121, 110, 116, 97, 120, 45, 110, 115, 35, 34, 62, 10, 32, 32, 32, 32, 32, 32, 60, 114, 100, 102, 58, 68, 101, 115, 99, 114, 105, 112, 116, 105, 111, 110, 32, 114, 100, 102, 58, 97, 98, 111, 117, 116, 61, 34, 34, 10, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 120, 109, 108, 110, 115, 58, 100, 99, 61, 34, 104, 116, 116, 112, 58, 47, 47, 112, 117, 114, 108, 46, 111, 114, 103, 47, 100, 99, 47, 101, 108, 101, 109, 101, 110, 116, 115, 47, 49, 46, 49, 47, 34, 62, 10, 32, 32, 32, 32, 32, 32, 32, 32, 32, 60, 100, 99, 58, 115, 117, 98, 106, 101, 99, 116, 62, 10, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 60, 114, 100, 102, 58, 66, 97, 103, 47, 62, 10, 32, 32, 32, 32, 32, 32, 32, 32, 32, 60, 47, 100, 99, 58, 115, 117, 98, 106, 101, 99, 116, 62, 10, 32, 32, 32, 32, 32, 32, 60, 47, 114, 100, 102, 58, 68, 101, 115, 99, 114, 105, 112, 116, 105, 111, 110, 62, 10, 32, 32, 32, 32, 32, 32, 60, 114, 100, 102, 58, 68, 101, 115, 99, 114, 105, 112, 116, 105, 111, 110, 32, 114, 100, 102, 58, 97, 98, 111, 117, 116, 61, 34, 34, 10, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 120, 109, 108, 110, 115, 58, 120, 109, 112, 61, 34, 104, 116, 116, 112, 58, 47, 47, 110, 115, 46, 97, 100, 111, 98, 101, 46, 99, 111, 109, 47, 120, 97, 112, 47, 49, 46, 48, 47, 34, 62, 10, 32, 32, 32, 32, 32, 32, 32, 32, 32, 60, 120, 109, 112, 58, 67, 114, 101, 97, 116, 111, 114, 84, 111, 111, 108, 62, 65, 100, 111, 98, 101, 32, 70, 105, 114, 101, 119, 111, 114, 107, 115, 32, 67, 83, 53, 60, 47, 120, 109, 112, 58, 67, 114, 101, 97, 116, 111, 114, 84, 111, 111, 108, 62, 10, 32, 32, 32, 32, 32, 32, 60, 47, 114, 100, 102, 58, 68, 101, 115, 99, 114, 105, 112, 116, 105, 111, 110, 62, 10, 32, 32, 32, 60, 47, 114, 100, 102, 58, 82, 68, 70, 62, 10, 60, 47, 120, 58, 120, 109, 112, 109, 101, 116, 97, 62, 10, 251, 139, 31, 177, 0, 0, 1, 14, 73, 68, 65, 84, 104, 222, 237, 219, 77, 11, 1, 81, 20, 135, 241, 59, 222, 66, 196, 120, 45, 172, 216, 160, 136, 108, 40, 190, 255, 215, 153, 111, 48, 254, 183, 206, 74, 97, 131, 123, 212, 179, 120, 106, 106, 38, 126, 141, 115, 237, 78, 40, 203, 50, 120, 233, 221, 3, 125, 181, 84, 59, 117, 80, 123, 187, 254, 116, 241, 115, 183, 207, 16, 35, 117, 82, 231, 248, 144, 90, 168, 161, 202, 13, 248, 141, 6, 143, 136, 76, 173, 213, 77, 173, 84, 87, 85, 83, 252, 76, 153, 189, 178, 75, 84, 170, 74, 202, 153, 89, 26, 164, 151, 122, 128, 219, 234, 170, 38, 30, 78, 211, 202, 38, 186, 230, 1, 115, 84, 51, 47, 255, 51, 7, 59, 182, 46, 48, 187, 148, 131, 11, 6, 12, 24, 48, 96, 192, 128, 1, 3, 6, 12, 24, 48, 96, 192, 128, 1, 3, 6, 12, 24, 48, 96, 192, 128, 1, 3, 6, 12, 24, 48, 96, 192, 128, 1, 3, 6, 12, 24, 48, 96, 192, 128, 1, 3, 6, 12, 24, 48, 96, 192, 128, 1, 243, 151, 152, 189, 39, 204, 198, 211, 174, 202, 220, 114, 129, 105, 218, 142, 83, 221, 203, 234, 226, 88, 77, 67, 8, 153, 7, 76, 68, 76, 139, 162, 200, 237, 58, 249, 82, 103, 102, 155, 130, 121, 138, 149, 180, 103, 55, 90, 118, 212, 59, 54, 71, 149, 95, 188, 173, 87, 55, 227, 151, 55, 108, 147, 176, 109, 67, 222, 248, 102, 110, 150, 128, 99, 119, 104, 70, 17, 139, 58, 220, 120, 235, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130 };

static const unsigned char lioTabInnerShadow2xBytes[969] = {137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 70, 0, 0, 0, 220, 8, 6, 0, 0, 0, 205, 211, 215, 161, 0, 0, 0, 4, 115, 66, 73, 84, 8, 8, 8, 8, 124, 8, 100, 136, 0, 0, 0, 9, 112, 72, 89, 115, 0, 0, 11, 18, 0, 0, 11, 18, 1, 210, 221, 126, 252, 0, 0, 0, 28, 116, 69, 88, 116, 83, 111, 102, 116, 119, 97, 114, 101, 0, 65, 100, 111, 98, 101, 32, 70, 105, 114, 101, 119, 111, 114, 107, 115, 32, 67, 83, 53, 113, 181, 227, 54, 0, 0, 0, 21, 116, 69, 88, 116, 67, 114, 101, 97, 116, 105, 111, 110, 32, 84, 105, 109, 101, 0, 49, 47, 49, 57, 47, 49, 50, 8, 101, 31, 169, 0, 0, 3, 34, 73, 68, 65, 84, 120, 218, 237, 216, 253, 79, 82, 81, 0, 198, 113, 20, 196, 226, 77, 98, 17, 218, 202, 36, 99, 180, 102, 230, 204, 205, 94, 236, 117, 109, 146, 101, 90, 255, 255, 223, 114, 233, 57, 238, 217, 184, 221, 64, 46, 252, 198, 61, 223, 187, 125, 135, 192, 197, 93, 63, 59, 231, 158, 131, 165, 241, 120, 92, 162, 255, 3, 97, 30, 204, 178, 135, 62, 187, 173, 94, 170, 119, 234, 139, 250, 169, 190, 171, 145, 58, 95, 193, 194, 117, 159, 45, 5, 163, 243, 59, 234, 141, 17, 194, 47, 250, 164, 78, 213, 145, 122, 161, 134, 106, 160, 158, 173, 96, 225, 186, 135, 11, 193, 120, 116, 124, 85, 151, 234, 179, 122, 173, 158, 171, 39, 106, 71, 221, 87, 109, 213, 82, 77, 213, 88, 193, 194, 117, 183, 114, 193, 248, 228, 48, 42, 126, 169, 143, 234, 149, 122, 170, 122, 134, 168, 169, 77, 85, 81, 229, 36, 73, 214, 74, 43, 124, 220, 92, 255, 60, 24, 143, 134, 107, 245, 77, 29, 171, 190, 234, 90, 183, 90, 4, 136, 89, 127, 248, 76, 24, 207, 185, 223, 234, 131, 167, 76, 207, 32, 27, 106, 189, 112, 24, 121, 96, 124, 35, 189, 82, 111, 213, 190, 111, 184, 97, 186, 148, 11, 13, 114, 27, 140, 71, 202, 149, 87, 158, 48, 117, 182, 194, 40, 41, 228, 148, 201, 11, 227, 145, 241, 199, 251, 146, 190, 87, 152, 184, 80, 102, 192, 140, 188, 81, 27, 120, 197, 137, 15, 37, 11, 227, 41, 116, 161, 14, 189, 242, 84, 163, 68, 153, 2, 243, 67, 189, 87, 187, 222, 155, 20, 123, 229, 201, 3, 99, 140, 48, 90, 14, 124, 159, 169, 68, 139, 146, 129, 57, 246, 238, 118, 79, 213, 163, 157, 66, 83, 96, 194, 206, 246, 196, 155, 184, 106, 212, 40, 25, 152, 203, 212, 52, 138, 99, 19, 151, 19, 230, 194, 255, 46, 104, 69, 63, 141, 50, 48, 35, 239, 93, 154, 209, 163, 100, 96, 206, 189, 143, 105, 160, 2, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 195, 1, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 7, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 0, 3, 12, 48, 192, 44, 12, 51, 82, 3, 213, 68, 229, 95, 152, 51, 53, 84, 173, 36, 73, 214, 128, 153, 192, 28, 184, 142, 42, 3, 51, 129, 121, 168, 78, 84, 79, 85, 129, 49, 140, 127, 62, 85, 123, 170, 30, 253, 116, 202, 192, 60, 74, 77, 167, 10, 48, 134, 241, 243, 35, 181, 171, 106, 106, 29, 152, 201, 243, 150, 58, 84, 221, 112, 175, 137, 118, 74, 101, 97, 252, 218, 182, 247, 52, 109, 181, 17, 37, 206, 52, 24, 191, 254, 88, 245, 61, 130, 226, 195, 153, 5, 227, 247, 186, 198, 217, 138, 14, 231, 54, 24, 191, 223, 49, 78, 120, 220, 140, 102, 243, 55, 15, 198, 231, 220, 241, 82, 30, 54, 127, 141, 48, 122, 10, 191, 98, 229, 129, 73, 157, 219, 84, 59, 158, 98, 1, 168, 26, 70, 80, 33, 167, 216, 34, 48, 169, 207, 220, 53, 206, 3, 175, 92, 53, 79, 179, 74, 17, 160, 110, 174, 127, 25, 152, 12, 82, 205, 56, 247, 252, 216, 246, 74, 214, 244, 168, 90, 181, 194, 117, 215, 211, 95, 34, 41, 21, 8, 51, 250, 11, 81, 59, 205, 51, 62, 168, 74, 139, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130 };

#define LIOBundleManagerURLRoot                 @"http://cdn.look.io/ios"
#define LIOBundleManagerDownloadRequestTimeout  10.0 // seconds
#define LIOBundleManagerExtractionBufferLength  65535
#define LIOBundleManagerImageCacheSize          5

@interface LIOBundleManager ()
- (void)beginDownloadingBundle;
- (NSString *)targetDirectory;
@end

static LIOBundleManager *sharedBundleManager = nil;

@implementation LIOBundleManager

BOOL LIOIsUIKitFlatMode(void) {
    static BOOL LIOUIKitFlatMode = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // By default, let's just check to see the version of the device
        
        LIOUIKitFlatMode = LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0");
        
        // Let's check to see if the developer specifically indicated they are using an Xcode version older than 5.
        // If they are, we should use the classic method to identify if they have flat UI.
        
        BOOL supportDeprecatedXcodeVersions = [[LIOLookIOManager sharedLookIOManager] supportDeprecatedXcodeVersions];
        
        if (supportDeprecatedXcodeVersions)
        {
            if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0) {
                
                // If your app is running in legacy mode, tintColor will be nil - else it must be set to some color.
                if (UIApplication.sharedApplication.keyWindow)
                {
                    LIOUIKitFlatMode = [UIApplication.sharedApplication.delegate.window performSelector:@selector(tintColor)] != nil;
                }
                else
                {
                    // Possible that we're called early on (e.g. when used in a Storyboard). Adapt and use a temporary window.
                    LIOUIKitFlatMode = [[UIWindow new] performSelector:@selector(tintColor)] != nil;
                }
            }
        }
    });
    
    return LIOUIKitFlatMode;
}

@synthesize lioTabInnerShadow, lioTabInnerShadow2x;

+ (LIOBundleManager *)sharedBundleManager
{
    if (nil == sharedBundleManager)
        sharedBundleManager = [[LIOBundleManager alloc] init];
    
    return sharedBundleManager;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.isDownloadingBundle = NO;
        
        // Make sure the target dir exists.
        NSString *targetDir = [self targetDirectory];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDirectory = NO;
        BOOL directoryCheckResult = [fileManager fileExistsAtPath:targetDir isDirectory:&isDirectory];
        if (NO == directoryCheckResult)
        {
            NSError *createDirectoryError = nil;
            BOOL dirWasCreated = [fileManager createDirectoryAtPath:targetDir withIntermediateDirectories:YES attributes:nil error:&createDirectoryError];
            if (NO == dirWasCreated)
            {
                LIOLog(@"BUNDLE: Warning! Unable to find/create target directory. Reason: %@", createDirectoryError);
                [self release];
                return nil;
            }
            
            LIOLog(@"BUNDLE: Created target directory: %@", targetDir);
        }
        
        // Set up the HTTP download request in case we need it.
        UIImage *initialImage = [UIImage imageWithData:[NSData dataWithBytesNoCopy:(unsigned char *)lioTabInnerShadowBytes length:905]];
        lioTabInnerShadow = [[UIImage alloc] initWithCGImage:[initialImage CGImage] scale:1.0 orientation:UIImageOrientationUp];
        
        initialImage = [UIImage imageWithData:[NSData dataWithBytesNoCopy:(unsigned char *)lioTabInnerShadow2xBytes length:969]];
        lioTabInnerShadow2x = [[UIImage alloc] initWithCGImage:[initialImage CGImage] scale:2.0 orientation:UIImageOrientationUp];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        
        [self findBundle];
        
        imageCache = [[NSMutableDictionary alloc] init];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        if ([userDefaults objectForKey:LIOBundleManagerBrandingImageCacheKey])
        {
            NSData *brandingImageCacheData = [userDefaults objectForKey:LIOBundleManagerBrandingImageCacheKey];
            brandingImageCache = [NSKeyedUnarchiver unarchiveObjectWithData:brandingImageCacheData];
        }
        else
        {
            brandingImageCache = [[NSMutableDictionary alloc] init];
        }
        [brandingImageCache retain];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [lioBundle release];
    [bundleDownloadRequest release];
    [bundleDownloadConnection release];
    [imageCache release];
    [brandingImageCache release];
    
    [bundleDownloadOutputStream close];
    [bundleDownloadOutputStream release];
    
    [lioTabInnerShadow release];
    [lioTabInnerShadow2x release];

    [super dealloc];
}

- (NSString *)targetDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDir = [paths objectAtIndex:0];
    return [cachesDir stringByAppendingPathComponent:[NSString stringWithFormat:@"_LOOKIO_%@/", LOOKIO_VERSION_STRING]];
}

- (NSString *)brandingImagesDirectory
{
    return [[self targetDirectory] stringByAppendingPathComponent:@"CustomBranding/"];
}

- (NSString *)brandingImagesDirectoryForBrandingElement:(LIOBrandingElement)element
{
    return [[self brandingImagesDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%d/", element]];
}

-(NSString*)bundleName {
    return @"LookIO.bundle";
}

-(void)resetBundle {
    [lioBundle release];
    lioBundle = nil;
    [self findBundle];

    [imageCache release];
    imageCache = [[NSMutableDictionary alloc] init];

}

- (NSString *)bundleZipPath
{
    return [[self targetDirectory] stringByAppendingPathComponent:@"bundle.zip"];
}

- (NSString *)bundlePath
{
    return [[self targetDirectory] stringByAppendingPathComponent:[self bundleName]];
}

- (void)findBundle
{
    if (lioBundle)
    {
        LIOLog(@"BUNDLE: Ignoring request to find bundle; we've already got a valid one!");
        return;
    }
    
    if (bundleDownloadConnection)
    {
        LIOLog(@"BUNDLE: Ignoring request to find bundle; a download request is already in progress!");
        return;
    }
    
    // Is the bundle in the caches dir w/ version number?
    NSString *cachesPath = [self bundlePath];
    lioBundle = [[NSBundle bundleWithPath:cachesPath] retain];
    if (lioBundle)
    {
        // Yep!
        LIOLog(@"BUNDLE: Found in caches directory: %@", cachesPath);
    }
    else
    {
        // Nope. Check the main .app bundle.
        NSString *mainBundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[self bundleName]];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = NO;
        BOOL bundleExists = [fileManager fileExistsAtPath:mainBundlePath isDirectory:&isDir];
        if (bundleExists && isDir)
        {
            // Yep! Copy it to the target dir and try loading it.
            NSString *targetDir = [NSString stringWithFormat:@"%@/%@", [self targetDirectory], [self bundleName]];
            NSError *anError = nil;
            BOOL copyResult = [fileManager copyItemAtPath:mainBundlePath toPath:targetDir error:&anError];
            if (copyResult && nil == anError)
            {
                // Copy succeeded. Try loading the bundle again.
                lioBundle = [[NSBundle bundleWithPath:cachesPath] retain];
            }
            else
            {
                LIOLog(@"Error while copying LookIO.bundle from host .app bundle: %@", [anError localizedDescription]);
            }
        }
    }
    
    // If at this point we still have no bundle, we need to download it.
    if (nil == lioBundle)
        [self beginDownloadingBundle];
}

- (void)beginDownloadingBundle
{
    if (bundleDownloadConnection)
    {
        LIOLog(@"BUNDLE: Warning! Was asked to begin bundle download, but a download request is already in progress.");
        return;
    }
    
    // First time setup.
    if (nil == bundleDownloadRequest)
    {
        NSURL *bundleDownloadURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/bundle.zip", LIOBundleManagerURLRoot, LOOKIO_VERSION_STRING]];
        bundleDownloadRequest = [[NSURLRequest alloc] initWithURL:bundleDownloadURL cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:LIOBundleManagerDownloadRequestTimeout];
    }
    
    LIOLog(@"BUNDLE: Starting bundle download...");
    
    self.isDownloadingBundle = YES;
    
    [[NSFileManager defaultManager] removeItemAtPath:[self bundleZipPath] error:nil];
    bundleDownloadOutputStream = [[NSOutputStream outputStreamToFileAtPath:[self bundleZipPath] append:NO] retain];
    [bundleDownloadOutputStream open];
    bundleDownloadConnection = [[NSURLConnection alloc] initWithRequest:bundleDownloadRequest delegate:self startImmediately:NO];
    
    double delayInSeconds = 10.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [bundleDownloadConnection start];
    });
}

- (void)pruneImageCache
{
    // Are there more than n objects in the cache?
    // If so, trim it down to the top-weighted entries.
    if ([imageCache count] > LIOBundleManagerImageCacheSize)
    {
        NSArray *topKeys = [imageCache keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            LIOCacheEntry *entry1 = (LIOCacheEntry *)obj1;
            LIOCacheEntry *entry2 = (LIOCacheEntry *)obj2;
            if (entry1.weight < entry2.weight)
                return NSOrderedDescending;
            else if (entry1.weight > entry2.weight)
                return NSOrderedAscending;
            else
                return NSOrderedSame;
        }];
        
        topKeys = [topKeys subarrayWithRange:NSMakeRange(0, LIOBundleManagerImageCacheSize)];
        
        NSMutableDictionary *newImageCache = [[NSMutableDictionary alloc] init];
        for (int i=0; i<[topKeys count]; i++)
        {
            NSString *aKey = [topKeys objectAtIndex:i];
            LIOCacheEntry *anObject = [imageCache objectForKey:aKey];
            [newImageCache setObject:anObject forKey:aKey];
        }
        
        [imageCache release];
        imageCache = newImageCache;
    }
}

#pragma mark Tint Color Methods

- (UIImage *)imageNamed:(NSString *)aString withTint:(UIColor *)color {
    UIImage *image = [self imageNamed:aString];
    
    if (!image)
        return nil;
    
    if (image.size.width == 0 || image.size.height == 0)
        return image;
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [color setFill];
    
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    CGContextDrawImage(context, rect, image.CGImage);
    
    CGContextClipToMask(context, rect, image.CGImage);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context,kCGPathFill);
    
    UIImage *coloredImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return coloredImage;
}

- (UIImage *)imageNamed:(NSString *)aString
{
    if (nil == lioBundle)
    {
        LIOLog(@"BUNDLE: Warning! Image \"%@\" requested, but no bundle is present.", aString);
        return [UIImage imageNamed:aString];
    }
    
    LIOCacheEntry *aCacheEntry = [imageCache objectForKey:aString];
    if (aCacheEntry)
    {
        aCacheEntry.weight += 1;
        return (UIImage *)aCacheEntry.cachedObject;
    }
    
    NSString *filename = [aString stringByDeletingPathExtension];
    
    NSString *scaleString = [NSString string];
    CGFloat screenScale = 1.0;
    if ([UIScreen instancesRespondToSelector:@selector(scale)])
    {
        screenScale = [[UIScreen mainScreen] scale];
        if (screenScale > 1.0)
            scaleString = [NSString stringWithFormat:@"@%dx", (int)screenScale];
    }
    
    NSString *deviceString = @"~iphone";
    if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom])
        deviceString = @"~ipad";
    
    // Order: (png, then jpg)
    // 1) base + scale + device     MyImage@2x~iphone.png / MyImage~iphone.png
    // 2) base + scale              MyImage@2x.png        / MyImage.png
    // 3) base + device             MyImage~iphone.png
    // 4) base                      MyImage.png
    
    // #1, png
    NSString *possibleFilename = [NSString stringWithFormat:@"%@%@%@", filename, scaleString, deviceString];
    NSString *actualPath = [lioBundle pathForResource:possibleFilename ofType:@"png"];
    if ([actualPath length])
    {
        NSData *fileData = [NSData dataWithContentsOfFile:actualPath];
        if (fileData)
        {
            UIImage *newImage = [UIImage imageWithData:fileData];
            UIImage *finalImage = [[[UIImage alloc] initWithCGImage:[newImage CGImage] scale:screenScale orientation:UIImageOrientationUp] autorelease];
            LIOCacheEntry *newCacheEntry = [LIOCacheEntry cacheEntryWithCachedObject:finalImage];
            [imageCache setObject:newCacheEntry forKey:aString];
            return finalImage;
        }
        else
        {
            LIOLog(@"IMAGE: Warning! Couldn't load \"%@\"", actualPath);
            return nil;
        }
    }
    
    // #1, jpg
    actualPath = [lioBundle pathForResource:possibleFilename ofType:@"jpg"];
    if ([actualPath length])
    {
        NSData *fileData = [NSData dataWithContentsOfFile:actualPath];
        if (fileData)
        {
            UIImage *newImage = [UIImage imageWithData:fileData];
            UIImage *finalImage = [[[UIImage alloc] initWithCGImage:[newImage CGImage] scale:screenScale orientation:UIImageOrientationUp] autorelease];
            LIOCacheEntry *newCacheEntry = [LIOCacheEntry cacheEntryWithCachedObject:finalImage];
            [imageCache setObject:newCacheEntry forKey:aString];
            return finalImage;
        }
        else
        {
            LIOLog(@"IMAGE: Warning! Couldn't load \"%@\"", actualPath);
            return nil;
        }
    }
    
    // #2, png
    possibleFilename = [NSString stringWithFormat:@"%@%@", filename, scaleString];
    actualPath = [lioBundle pathForResource:possibleFilename ofType:@"png"];
    if ([actualPath length])
    {
        NSData *fileData = [NSData dataWithContentsOfFile:actualPath];
        if (fileData)
        {
            UIImage *newImage = [UIImage imageWithData:fileData];
            UIImage *finalImage = [[[UIImage alloc] initWithCGImage:[newImage CGImage] scale:screenScale orientation:UIImageOrientationUp] autorelease];
            LIOCacheEntry *newCacheEntry = [LIOCacheEntry cacheEntryWithCachedObject:finalImage];
            [imageCache setObject:newCacheEntry forKey:aString];
            return finalImage;
        }
        else
        {
            LIOLog(@"IMAGE: Warning! Couldn't load \"%@\"", actualPath);
            return nil;
        }
    }
    
    // #2, jpg
    actualPath = [lioBundle pathForResource:possibleFilename ofType:@"jpg"];
    if ([actualPath length])
    {
        NSData *fileData = [NSData dataWithContentsOfFile:actualPath];
        if (fileData)
        {
            UIImage *newImage = [UIImage imageWithData:fileData];
            UIImage *finalImage = [[[UIImage alloc] initWithCGImage:[newImage CGImage] scale:screenScale orientation:UIImageOrientationUp] autorelease];;
            LIOCacheEntry *newCacheEntry = [LIOCacheEntry cacheEntryWithCachedObject:finalImage];
            [imageCache setObject:newCacheEntry forKey:aString];
            return finalImage;
        }
        else
        {
            LIOLog(@"IMAGE: Warning! Couldn't load \"%@\"", actualPath);
            return nil;
        }
    }
    
    // #3, png
    possibleFilename = [NSString stringWithFormat:@"%@%@", filename, deviceString];
    actualPath = [lioBundle pathForResource:possibleFilename ofType:@"png"];
    if ([actualPath length])
    {
        NSData *fileData = [NSData dataWithContentsOfFile:actualPath];
        if (fileData)
        {
            UIImage *newImage = [UIImage imageWithData:fileData];
            UIImage *finalImage = [[[UIImage alloc] initWithCGImage:[newImage CGImage] scale:1.0 orientation:UIImageOrientationUp] autorelease];
            LIOCacheEntry *newCacheEntry = [LIOCacheEntry cacheEntryWithCachedObject:finalImage];
            [imageCache setObject:newCacheEntry forKey:aString];
            return finalImage;
        }
        else
        {
            LIOLog(@"IMAGE: Warning! Couldn't load \"%@\"", actualPath);
            return nil;
        }
    }    
    
    // #3, jpg
    actualPath = [lioBundle pathForResource:possibleFilename ofType:@"jpg"];
    if ([actualPath length])
    {
        NSData *fileData = [NSData dataWithContentsOfFile:actualPath];
        if (fileData)
        {
            UIImage *newImage = [UIImage imageWithData:fileData];
            UIImage *finalImage = [[[UIImage alloc] initWithCGImage:[newImage CGImage] scale:1.0 orientation:UIImageOrientationUp] autorelease];
            LIOCacheEntry *newCacheEntry = [LIOCacheEntry cacheEntryWithCachedObject:finalImage];
            [imageCache setObject:newCacheEntry forKey:aString];
            return finalImage;
        }
        else
        {
            LIOLog(@"IMAGE: Warning! Couldn't load \"%@\"", actualPath);
            return nil;
        }
    }
    
    // #4, png
    actualPath = [lioBundle pathForResource:filename ofType:@"png"];
    if ([actualPath length])
    {
        NSData *fileData = [NSData dataWithContentsOfFile:actualPath];
        if (fileData)
        {
            UIImage *newImage = [UIImage imageWithData:fileData];
            UIImage *finalImage = [[[UIImage alloc] initWithCGImage:[newImage CGImage] scale:1.0 orientation:UIImageOrientationUp] autorelease];
            LIOCacheEntry *newCacheEntry = [LIOCacheEntry cacheEntryWithCachedObject:finalImage];
            [imageCache setObject:newCacheEntry forKey:aString];
            return finalImage;
        }
        else
        {
            LIOLog(@"IMAGE: Warning! Couldn't load \"%@\"", actualPath);
            return nil;
        }
    }
    
    // #4, jpg
    actualPath = [lioBundle pathForResource:filename ofType:@"jpg"];
    if ([actualPath length])
    {
        NSData *fileData = [NSData dataWithContentsOfFile:actualPath];
        if (fileData)
        {
            UIImage *newImage = [UIImage imageWithData:fileData];
            UIImage *finalImage = [[[UIImage alloc] initWithCGImage:[newImage CGImage] scale:1.0 orientation:UIImageOrientationUp] autorelease];
            LIOCacheEntry *newCacheEntry = [LIOCacheEntry cacheEntryWithCachedObject:finalImage];
            [imageCache setObject:newCacheEntry forKey:aString];
            return finalImage;
        }
        else
        {
            LIOLog(@"IMAGE: Warning! Couldn't load \"%@\"", actualPath);
            return nil;
        }
    }        
    
    LIOLog(@"IMAGE: Warning! Couldn't find \"%@\"", aString);
    
    return [UIImage imageNamed:aString];
}

- (void)cacheImage:(UIImage *)image fromURL:(NSURL *)url forBrandingElement:(LIOBrandingElement)element
{
    // Delete the previous image cached for this branding element
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([brandingImageCache objectForKey:[NSNumber numberWithInt:element]])
    {
        NSURL *oldFileURL = [brandingImageCache objectForKey:[NSNumber numberWithInt:element]];
        NSString *oldFileName = [[oldFileURL path] lastPathComponent];
        NSString *oldFilePath = [[self brandingImagesDirectoryForBrandingElement:element] stringByAppendingPathComponent:oldFileName];
        if ([fileManager fileExistsAtPath:oldFilePath])
        {
            NSError *error = nil;
            [fileManager removeItemAtPath:oldFilePath error:&error];
        }
    }
    
    // Let's check if the root directory exists, if not, create it

    BOOL isDir;
    BOOL exists = [fileManager fileExistsAtPath:[self brandingImagesDirectory] isDirectory:&isDir];
    if (!exists) {
        NSError *error = nil;
        BOOL success = [fileManager createDirectoryAtPath:[self brandingImagesDirectory] withIntermediateDirectories:NO attributes:nil error:&error];
        if (!success || error) {
            LIOLog(@"Error: %@", [error localizedDescription]);
        }
    }
    
    // Let's check if the directory exists, if not, create it
    
    exists = [fileManager fileExistsAtPath:[self brandingImagesDirectoryForBrandingElement:element] isDirectory:&isDir];
    if (!exists) {
        NSError *error = nil;
        BOOL success = [fileManager createDirectoryAtPath:[self brandingImagesDirectoryForBrandingElement:element] withIntermediateDirectories:NO attributes:nil error:&error];
        if (!success || error) {
            LIOLog(@"Error: %@", [error localizedDescription]);
        }
    }
    
    // Cache the new image

    NSString *newFilename = [[url path] lastPathComponent];
    NSString *newFilePath = [[self brandingImagesDirectoryForBrandingElement:element] stringByAppendingPathComponent:newFilename];
    
    [UIImagePNGRepresentation(image) writeToFile:newFilePath atomically:YES];
    [brandingImageCache setObject:url forKey:[NSNumber numberWithInt:element]];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *brandingImageCacheData = [NSKeyedArchiver archivedDataWithRootObject:brandingImageCache];
    [userDefaults setObject:brandingImageCacheData forKey:LIOBundleManagerBrandingImageCacheKey];
    [userDefaults synchronize];
}

- (void)cachedImageForBrandingElement:(LIOBrandingElement)element withBlock:(void (^)(BOOL, UIImage *))block;
{
    // Check if this element has a custom image. If not, report failure
    NSURL *imageURL = [[LIOBrandingManager brandingManager] customImageURLForElement:element];
    if (!imageURL)
    {
        if (block)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(NO, nil);
            });
        }
        return;
    }
    
    // Let's check if the image exists, if not, call the callback without setting an image
    if ([brandingImageCache objectForKey:[NSNumber numberWithInteger:element]])
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *fileURL = [brandingImageCache objectForKey:[NSNumber numberWithInt:element]];
        
        // Make sure that the cached image is the same URL
        if ([imageURL isEqual:fileURL])
        {
            NSString *filename = [[fileURL path] lastPathComponent];
            NSString *filePath = [[self brandingImagesDirectoryForBrandingElement:element] stringByAppendingPathComponent:filename];
        
            // Make sure the file exists
            if ([fileManager fileExistsAtPath:filePath])
            {
                // Before we use the cached file, let's make sure we have the latest version of it
                if (![self newerVersionOfCachedFile:filePath forURL:imageURL])
                {
                    // Load the image and return it
                    NSData *data = [[[NSData alloc] initWithContentsOfFile:filePath] autorelease];
                    UIImage *image = [[[UIImage alloc] initWithData:data] autorelease];
                
                    if (block)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            block(YES, image);
                        });
                    }
                    return;
                }
            }
        }
    }

    // Image with the same URL isn't cached, or a newer version exists on server side Let's download it in background.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [[[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:imageURL]] autorelease];
        if (image)
        {
            if (block)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block(YES, image);
                });
            }
            [[LIOBundleManager sharedBundleManager] cacheImage:image fromURL:imageURL forBrandingElement:element];
        }
        else
        {
            if (block)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block (NO, nil);
                });
            }
        }
    });
}

- (BOOL)newerVersionOfCachedFile:(NSString *)filePath forURL:(NSURL *)url
{
    BOOL newerVersion = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    // Let's grab the server's last modified string
    NSString *lastModifiedString = nil;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"HEAD"];
    NSHTTPURLResponse *response;
    NSError *error = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if ([response respondsToSelector:@selector(allHeaderFields)]) {
        lastModifiedString = [[response allHeaderFields] objectForKey:@"Last-Modified"];
    }
    
    // If we got an error, or didn't get a last modified from the server, we should use the local file
    if (error || lastModifiedString == nil)
    {
        return NO;
    }
    
    NSDate *lastModifiedServer = nil;
    @try {
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        dateFormatter.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
        dateFormatter.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        lastModifiedServer = [dateFormatter dateFromString:lastModifiedString];
    }
    @catch (NSException * e) {
        return NO;
    }
    
    NSDate *lastModifiedLocal = nil;
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:filePath error:&error];
    lastModifiedLocal = [fileAttributes fileModificationDate];
    
    // Download file from server if we don't have a local file
    if (!lastModifiedLocal) {
        newerVersion = YES;
    }
    // Download file from server if the server modified timestamp is later than the local modified timestamp
    if ([lastModifiedLocal laterDate:lastModifiedServer] == lastModifiedServer) {
        newerVersion = YES;
    }
    
    return newerVersion;
}

- (BOOL)isAvailable
{
    return lioBundle != nil;
}

- (NSString *)localizedStringWithKey:(NSString *)aKey
{
    // First, check to see if we've got a string for this key in
    // the downloaded tables.
    NSString *languageId = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *downloadedStrings = [userDefaults objectForKey:LIOBundleManagerStringTableDictKey];
    NSString *downloadedLocale = [downloadedStrings objectForKey:@"locale"];
    if ([downloadedLocale length] && NO == [downloadedLocale isEqualToString:languageId])
    {
        [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"The downloaded localized string table's locale (%@) does not match this device's locale (%@).", downloadedLocale, languageId];
    }
    
    NSDictionary *stringTable = [downloadedStrings objectForKey:@"strings"];
    NSString *aValue = [stringTable objectForKey:aKey];
    if ([aValue length])
        return aValue;
    
    NSString *bundlePath = [lioBundle pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:@"en"];
    NSBundle *englishBundle = [NSBundle bundleWithPath:[bundlePath stringByDeletingLastPathComponent]];
    return [englishBundle localizedStringForKey:aKey value:@"<LOCALIZATION MISSING>" table:nil];
}

- (NSDictionary *)brandingDictionary
{
    NSString *bundlePath = [lioBundle pathForResource:@"branding" ofType:@"json" inDirectory:nil];
    NSData *data = [NSData dataWithContentsOfFile:bundlePath];
    
    if (data == nil)
        return nil;
    
    return [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
}

- (NSString *)hashForLocalizedStringTable:(NSDictionary *)aTable
{
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    NSArray *sortedKeys = [[aTable allKeys] sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];
    NSMutableString *stringResult = [NSMutableString string];
    for (int i=0; i<[sortedKeys count]; i++)
    {
        NSString *aKey = [sortedKeys objectAtIndex:i];
        [stringResult appendString:[aTable objectForKey:aKey]];
    }
    return [self md5StringForString:stringResult];
}

- (NSString *)hashForLocalBrandingFile
{
    NSString *bundlePath = [lioBundle pathForResource:@"branding" ofType:@"json" inDirectory:nil];
    NSData *data = [NSData dataWithContentsOfFile:bundlePath];
    if (data == nil)
        return @"no_local_file";
    
    NSString *brandingFileString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    brandingFileString = [brandingFileString stringByReplacingOccurrencesOfString:@" " withString:@""];
    brandingFileString = [brandingFileString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    return [self md5StringForString:brandingFileString];
}

- (NSString *)md5StringForString:(NSString *)inputString
{
    const char *cString = [inputString UTF8String];
    unsigned char result[16];
    CC_MD5(cString, strlen(cString), result);
    NSMutableString *md5String = [NSMutableString string];
    for (int i=0; i<16; i++)
        [md5String appendFormat:@"%02x", result[i]];
    
    return md5String;
}

- (NSDictionary *)localizedStringTableForLanguage:(NSString *)aLangCode
{
    // Need a bundle for this to work.
    if (NO == [self isAvailable])
        return nil;
    
    NSString *path = [lioBundle pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:aLangCode];
    if (0 == [path length])
    {
        LIOLog(@"[localizedStringTableForLanguage:] Couldn't open localized string bundle: %@", path);
        return nil;
    }

    NSError *error = nil;
    NSString *contents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (0 == [contents length])
        return nil;

    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSArray *lines = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSString *aLine in lines)
    {
        if (0 == [aLine length])
            continue;
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\"(.+)\"\\s*=\\s*\"(.+)\".*;$" options:0 error:nil];
        NSArray *matches = [regex matchesInString:aLine options:0 range:NSMakeRange(0, [aLine length])];
        if ([matches count] == 1)
        {
            NSTextCheckingResult *match = [matches objectAtIndex:0];
            NSRange keyRange = [match rangeAtIndex:1];
            NSRange valueRange = [match rangeAtIndex:2];
            
            if (keyRange.location != NSNotFound || valueRange.location != NSNotFound)
            {
                NSString *aKey = [aLine substringWithRange:keyRange];
                
                NSString *aValue = [aLine substringWithRange:valueRange];
                aValue = [aValue stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
                aValue = [aValue stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
                [result setObject:aValue forKey:aKey];
            }
            else
            {
                LIOLog(@"[localizedStringTableForLanguage:] Match failed! keyRange: %@, valueRange: %@. Line was:\n%@", [NSValue valueWithRange:keyRange], [NSValue valueWithRange:valueRange], aLine);
            }
        }
        else
        {
            LIOLog(@"[localizedStringTableForLanguage:] >1 match? Fail. Line was:\n%@\n\nmatches: %@", aLine, matches);
        }
    }

    return result;
}

#pragma mark -
#pragma mark NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [bundleDownloadConnection release];
    bundleDownloadConnection = nil;
    
    bundleDownloadResponseCode = -1;
    
    [bundleDownloadOutputStream close];
    [bundleDownloadOutputStream release];
    bundleDownloadOutputStream = nil;
    
    [[NSFileManager defaultManager] removeItemAtPath:[self bundleZipPath] error:nil];
    
    LIOLog(@"BUNDLE: Warning! Bundle download failed with error: %@", [error localizedDescription]);
 
    self.isDownloadingBundle = NO;
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:error, LIOBundleManagerErrorKey, nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:LIOBundleManagerBundleDownloadDidFinishNotification
                                                        object:self
                                                      userInfo:userInfo];
}

#pragma mark -
#pragma mark NSURLConnectionDataDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    bundleDownloadResponseCode = httpResponse.statusCode;
    
    LIOLog(@"BUNDLE: HTTP response code: %d", bundleDownloadResponseCode);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [bundleDownloadOutputStream write:[data bytes] maxLength:[data length]];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{    
    NSDictionary *userInfo = nil;
    
    if (200 == bundleDownloadResponseCode)
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        // Remove any existing bundle just to be safe.
        [fileManager removeItemAtPath:[self bundlePath] error:nil];
        
        ZipFile_LIO *aZipFile = nil;
        NSMutableSet *filesToCreate = [NSMutableSet set];
        BOOL stepOneSuccess = NO;
        @try
        {
            aZipFile = [[[ZipFile_LIO alloc] initWithFileName:[self bundleZipPath] mode:ZipFileModeUnzip] autorelease];
            NSArray *infos = [aZipFile listFileInZipInfos];
            for (FileInZipInfo_LIO *info in infos)
            {
                if ([info.name hasSuffix:@"/"])
                {
                    LIOLog(@"BUNDLE: Found a directory entry in zip file. Ignoring... \"%@\"", info.name);
                }
                else
                    [filesToCreate addObject:info.name];
            }
            
            stepOneSuccess = YES;
        }
        @catch (NSException *e)
        {
            NSString *errorMessage = [NSString stringWithFormat:@"[LOOKIO] BUNDLE: Warning! Unable to read bundle archive: \"%@\". Reason: %@", [self bundleZipPath], [e reason]];
            LIOLog(@"%@", errorMessage);
            
            [aZipFile close];
            
            NSDictionary *errorUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:errorMessage, NSLocalizedDescriptionKey, nil];
            NSError *anError = [NSError errorWithDomain:@"LIOErrorDomain" code:-1 userInfo:errorUserInfo];
            userInfo = [NSDictionary dictionaryWithObjectsAndKeys:anError, LIOBundleManagerErrorKey, nil];
        }
        
        if (stepOneSuccess)
        {
            // Create the bundle directory.
            BOOL stepTwoSuccess = YES;
            NSError *dirCreateError = nil;
            BOOL dirWasCreated = [fileManager createDirectoryAtPath:[self bundlePath] withIntermediateDirectories:YES attributes:nil error:&dirCreateError];
            if (NO == dirWasCreated)
            {
                NSString *errorMessage = [NSString stringWithFormat:@"[LOOKIO] BUNDLE: Warning! Unable to create bundle directory: \"%@\". Reason: %@", [self bundlePath], [dirCreateError localizedDescription]];
                LIOLog(@"%@", errorMessage);
                
                [aZipFile close];
                
                NSDictionary *errorUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:errorMessage, NSLocalizedDescriptionKey, nil];
                NSError *anError = [NSError errorWithDomain:@"LIOErrorDomain" code:-1 userInfo:errorUserInfo];
                userInfo = [NSDictionary dictionaryWithObjectsAndKeys:anError, LIOBundleManagerErrorKey, nil];
                
                stepTwoSuccess = NO;
            }
            
            if (stepTwoSuccess)
            {
                int numFiles = 0;
                BOOL stepThreeSuccess = YES;
                
                for (NSString *aFileToCreate in filesToCreate)
                {
                    BOOL fileWasLocated = [aZipFile locateFileInZip:aFileToCreate];
                    if (NO == fileWasLocated)
                    {
                        NSString *errorMessage = [NSString stringWithFormat:@"[LOOKIO] Warning! Could not locate expected file in bundle archive: \"%@\"", aFileToCreate];
                        LIOLog(@"%@", errorMessage);
                        
                        [aZipFile close];
                        
                        NSDictionary *errorUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:errorMessage, NSLocalizedDescriptionKey, nil];
                        NSError *anError = [NSError errorWithDomain:@"LIOErrorDomain" code:-1 userInfo:errorUserInfo];
                        userInfo = [NSDictionary dictionaryWithObjectsAndKeys:anError, LIOBundleManagerErrorKey, nil];
                        
                        stepThreeSuccess = NO;
                        
                        break; // for...in loop
                    }
                    
                    NSString *targetFilePath = [[self bundlePath] stringByAppendingPathComponent:aFileToCreate];
                    
                    errno = 0;
                    FILE *fileOut = fopen([targetFilePath cStringUsingEncoding:NSASCIIStringEncoding], "w");
                    if (NULL == fileOut)
                    {
                        NSString *errorMessage = [NSString stringWithFormat:@"[LOOKIO] BUNDLE: Warning! Could not open target bundle file for writing: \"%@\" (errno %d)", targetFilePath, errno];
                        LIOLog(@"%@", errorMessage);
                        
                        [aZipFile close];
                        
                        NSDictionary *errorUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:errorMessage, NSLocalizedDescriptionKey, nil];
                        NSError *anError = [NSError errorWithDomain:@"LIOErrorDomain" code:-1 userInfo:errorUserInfo];
                        userInfo = [NSDictionary dictionaryWithObjectsAndKeys:anError, LIOBundleManagerErrorKey, nil];
                        
                        stepThreeSuccess = NO;
                        
                        break; // for...in loop
                    }
                    
                    numFiles++;
                    
                    ZipReadStream_LIO *zipIn = [aZipFile readCurrentFileInZip];
                    
                    // Expand the file in small chunks.
                    while (YES)
                    {
                        NSAutoreleasePool *aPool = [[NSAutoreleasePool alloc] init];
                        NSData *dataChunk = [zipIn readDataOfLength:LIOBundleManagerExtractionBufferLength];
                        if (0 == [dataChunk length]) break;
                        // data, size, no. items, file
                        fwrite([dataChunk bytes], 1, [dataChunk length], fileOut);
                        [aPool release];
                    }
                    
                    fclose(fileOut);
                    [zipIn finishedReading];
                }      
                
                if (stepThreeSuccess)
                {
                    [aZipFile close];
                    
                    LIOLog(@"BUNDLE: Successfully extracted %d file(s).", numFiles);
                }
            }
        }
    }
    else
    {
        NSString *errorMessage = [NSString stringWithFormat:@"[LOOKIO] BUNDLE: Warning! Bundle download failed with HTTP response code: %ld", (long)bundleDownloadResponseCode];
        LIOLog(@"%@", errorMessage);
        
        NSDictionary *errorUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:errorMessage, NSLocalizedDescriptionKey, nil];
        NSError *anError = [NSError errorWithDomain:@"LIOErrorDomain" code:-1 userInfo:errorUserInfo];
        userInfo = [NSDictionary dictionaryWithObjectsAndKeys:anError, LIOBundleManagerErrorKey, nil];
    }
    
    [bundleDownloadConnection release];
    bundleDownloadConnection = nil;
    
    bundleDownloadResponseCode = -1;
    
    [bundleDownloadOutputStream close];
    [bundleDownloadOutputStream release];
    bundleDownloadOutputStream = nil;
    
    [[NSFileManager defaultManager] removeItemAtPath:[self bundleZipPath] error:nil];
    
    if (userInfo)
    {
        // Failure cleanup.
        [[NSFileManager defaultManager] removeItemAtPath:[self bundlePath] error:nil];
        [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"BUNDLE: Warning! Failed to download/extract bundle."];
    }
    else
    {
        // Success!
        lioBundle = [[NSBundle bundleWithPath:[self bundlePath]] retain];
    }
    
    self.isDownloadingBundle = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:LIOBundleManagerBundleDownloadDidFinishNotification
                                                        object:self
                                                      userInfo:userInfo];
}

#pragma mark -
#pragma mark Notification handlers

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
    [self findBundle];
    [imageCache removeAllObjects];
}

- (void)applicationDidResignActive:(NSNotification *)aNotification
{
    [self pruneImageCache];
}

@end