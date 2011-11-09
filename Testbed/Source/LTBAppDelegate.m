//
//  LTBAppDelegate.m
//  Testbed
//
//  Created by Joe Toscano on 8/22/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import "LTBAppDelegate.h"
#import "LIOLookIOManager.h"

//io.look.${PRODUCT_NAME:rfc1034identifier}

@implementation LTBAppDelegate

@synthesize window, mainViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window makeKeyAndVisible];
    
    self.mainViewController = [[LTBMainViewController alloc] initWithNibName:nil bundle:nil];
    [self.window addSubview:mainViewController.view];
    
    //[LIOLookIOManager sharedLookIOManager].touchImage = [UIImage imageNamed:@"DefaultTouchOrange"];
    [LIOLookIOManager sharedLookIOManager].usesControlButton = YES;
    [LIOLookIOManager sharedLookIOManager].usesTLS = NO;
    [LIOLookIOManager sharedLookIOManager].sessionExtras = [NSDictionary dictionaryWithObjectsAndKeys:@"joe@whatever.com", @"email", @"poop", @"wug", nil];
    
    return YES;
}

@end
