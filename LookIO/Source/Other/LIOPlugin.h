//
//  LIOPlugin.h
//  LookIO
//
//  Created by Joe Toscano on 11/19/12.
//
//

#import <UIKit/UIKit.h>

/*
 * Plugin flow for creating and sending content:
 * ---------------------------------------------
 * 1) Host registers plugin (a class conforming to LIOPlugin) using registerPlugin:.
 * 2) LookIO asks plugin for info necessary to add button(s) to attachment action sheet.
 * 3) LookIO asks plugin for a UIViewController instance which is then presented modally.
 * 4) Plugin tells LookIO that it's done/canceled via delegate. If done, a key string is
 *    returned to LookIO.
 * 5) LookIO asks plugin for a content thumbnail to be displayed in conversation flow.
 * 6) If user taps bubble, LookIO asks plugin for a UIViewController instance which is
 *    then presented modally in order to display the custom plugin content to the user.
 * 7) Plugin tells LookIO via delegate when it's done displaying content.
 */
@protocol LIOPlugin;

@protocol LIOPluginDelegate <NSObject>
- (void)plugin:(id<LIOPlugin>)aPlugin didFinishChoosingContentWithResultKey:(NSString *)aKey;
- (void)pluginDidCancelChoosingContent:(id<LIOPlugin>)aPlugin;
- (void)pluginDidFinishDisplayingContent;
@end

@protocol LIOPlugin <NSObject>
- (NSString *)pluginId; // Must be a unique string.
- (NSArray *)pluginButtonLabels; // e.g. "Take Photo", "Choose Existing"
- (UIViewController *)viewControllerForPluginButtonIndex:(NSInteger)anIndex;
- (UIView *)thumbnailViewForPluginContentWithKey:(NSString *)aKey;
- (UIViewController *)viewControllerForDisplayingPluginContentWithKey:(NSString *)aKey;
- (void)resetPluginState;
@property(nonatomic, assign) id<LIOPluginDelegate> pluginDelegate;
@end
