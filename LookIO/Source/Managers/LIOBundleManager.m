//
//  LIOBundleManager.m
//  LookIO
//
//  Created by Joseph Toscano on 3/26/12.
//  Copyright (c) 2012 LookIO, Inc. All rights reserved.
//

#import "LIOBundleManager.h"

@interface LIOBundleManager ()
- (void)beginDownloadingBundle;
@end

static LIOBundleManager *sharedBundleManager = nil;

@implementation LIOBundleManager

@dynamic available;

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
        // Is the bundle included in the host app?
        NSString *mainBundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"LookIO.bundle"];
        bundle = [[NSBundle bundleWithPath:mainBundlePath] retain];
        if (bundle)
        {
            // Yep!
            NSLog(@"[LOOKIO] BUNDLE: Found in host app's main bundle: %@", mainBundlePath);
        }
        else
        {
            // Nope. Is the downloaded bundle in the caches directory?
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *cachesPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"LookIO.bundle"];
            bundle = [[NSBundle bundleWithPath:cachesPath] retain];
            if (bundle)
            {
                // Yep!
                NSLog(@"[LOOKIO] BUNDLE: Found in caches directory: %@", cachesPath);
            }
            else
            {
                // Nope. Kick off a download request.
            }
        }
    }
    
    return self;
}
    
    

//MyImage@2x~iphone.png
- (UIImage *)imageNamed:(NSString *)aString
{
        path = [path stringByDeletingPathExtension];
        
        if ([UIScreen instancesRespondToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2.0)
        {
            NSString *path2x = [path stringByAppendingString:@"@2x"];
            
            // Try @2xPNG...
            NSString *actualPath = [bundle pathForResource:path2x ofType:@"png"];
            if ([actualPath length])
            {
                NSData *fileData = [NSData dataWithContentsOfFile:actualPath];
                if (fileData)
                {
                    UIImage *newImage = [UIImage imageWithData:fileData];
                    return [[[UIImage alloc] initWithCGImage:[newImage CGImage] scale:2.0 orientation:UIImageOrientationUp] autorelease];
                }
            }
            
            // Try @2xJPG...
            actualPath = [bundle pathForResource:path2x ofType:@"jpg"];
            if ([actualPath length])
            {
                NSData *fileData = [NSData dataWithContentsOfFile:actualPath];
                if (fileData)
                {
                    UIImage *newImage = [UIImage imageWithData:fileData];
                    return [[[UIImage alloc] initWithCGImage:[newImage CGImage] scale:2.0 orientation:UIImageOrientationUp] autorelease];
                }
            }
        }
        
        NSString *actualPath = [bundle pathForResource:path ofType:@"png"];
        if ([actualPath length])
        {
            // Try PNG...
            NSData *fileData = [NSData dataWithContentsOfFile:actualPath];
            if (fileData)
                return [UIImage imageWithData:fileData];
        }
        
        // Try JPG...
        actualPath = [bundle pathForResource:path ofType:@"jpg"];
        if ([actualPath length])
        {
            NSData *fileData = [NSData dataWithContentsOfFile:actualPath];
            if (fileData)
                return [UIImage imageWithData:fileData];
        }
        
#ifdef DEBUG
        NSLog(@"[LOOKIO] Couldn't find normal or @2x file for resource \"%@\" in LookIO bundle!", path);
#endif
    
    return nil;
}

#pragma mark -
#pragma mark Dynamic properties

- (BOOL)available
{
    return bundle != nil;
}

@end