//
//  LIOPhotoPlugin.h
//  LookIO
//
//  Created by Joe Toscano on 11/12/12.
//
//

#import <UIKit/UIKit.h>

@protocol LIOPlugin;
@protocol LIOPluginDelegate;

@interface LIOPhotoPlugin : NSObject <LIOPlugin>
{
    id<LIOPluginDelegate> pluginDelegate;
}

@property(nonatomic, assign) id<LIOPluginDelegate> pluginDelegate;

@end