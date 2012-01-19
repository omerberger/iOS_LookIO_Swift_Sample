//
//  LTBAppDelegate.m
//  Testbed
//
//  Created by Joe Toscano on 8/22/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import "LTBAppDelegate.h"

//io.look.${PRODUCT_NAME:rfc1034identifier}

@implementation LTBAppDelegate

@synthesize window, mainViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window makeKeyAndVisible];
    
    self.mainViewController = [[LTBMainViewController alloc] initWithNibName:nil bundle:nil];
    [self.window addSubview:mainViewController.view];

    [[LIOLookIOManager sharedLookIOManager] setSessionExtra:@"lol@clownpenis.fart" forKey:@"email_address"];
    [[LIOLookIOManager sharedLookIOManager] performSetupWithDelegate:nil];
    [LIOLookIOManager sharedLookIOManager].delegate = self;
    
    return YES;
}

- (void)lookIOManagerDidHideControlButton:(LIOLookIOManager *)aManager
{
}

- (void)lookIOManagerDidShowControlButton:(LIOLookIOManager *)aManager
{
}

- (BOOL)lookIOManager:(LIOLookIOManager *)aManager shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation
{
    return YES;
}

- (UIWindow *)lookIOManagerMainWindowForHostApp:(LIOLookIOManager *)aManager
{
    return self.window;
}

@end
