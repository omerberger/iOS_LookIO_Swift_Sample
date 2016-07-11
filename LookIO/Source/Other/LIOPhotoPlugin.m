//
//  LIOPhotoPlugin.m
//  LookIO
//
//  Created by Joe Toscano on 11/12/12.
//
//

#import "LIOPhotoPlugin.h"
#import "LIOLookIOManager.h"
#import "LIOPlugin.h"

@implementation LIOPhotoPlugin

@synthesize pluginDelegate;

- (NSString *)pluginId
{
    return @"io.look.builtin.PhotoPlugin";
}

- (NSArray *)pluginButtonLabels
{
    return nil;
}

- (UIViewController *)viewControllerForPluginButtonIndex:(NSInteger)anIndex
{
    return nil;
}

- (UIView *)thumbnailViewForPluginContentWithKey:(NSString *)aKey
{
    return nil;
}

- (UIViewController *)viewControllerForDisplayingPluginContentWithKey:(NSString *)aKey
{
    return nil;
}

- (void)resetPluginState
{
}

@end