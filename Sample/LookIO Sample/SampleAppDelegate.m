//
//  SampleAppDelegate.m
//  LookIO Sample
//
//  Created by Marc Campbell on 1/15/12.
//  Copyright (c) 2012 Look.IO. All rights reserved.
//

#import "SampleAppDelegate.h"
#import "SampleViewController.h"
#import <Accounts/Accounts.h>
#import <CoreLocation/CoreLocation.h>

#if RUN_KIF_TESTS
    #import "LIOTestController.h"
#endif

@implementation SampleAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.viewController = [[[SampleViewController alloc] initWithNibName:@"SampleViewController_iPhone" bundle:nil] autorelease];
    } else {
        self.viewController = [[[SampleViewController alloc] initWithNibName:@"SampleViewController_iPad" bundle:nil] autorelease];
    }
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    //[[LIOLookIOManager sharedLookIOManager]setSessionExtra:@"marc.e.campbell@gmail.com" forKey:@"email_address"];
    
    /*
    CLLocationManager *locMan = [[CLLocationManager alloc] init];
    [locMan startUpdatingLocation];
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [locMan stopUpdatingLocation];
        [locMan release];
        
        
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        [accountStore requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *error) {
        }];
    });
    */
    
    //[[LIOLookIOManager sharedLookIOManager] setUsesTLS:NO];
    [[LIOLookIOManager sharedLookIOManager] enableDevelopmentMode];
    [[LIOLookIOManager sharedLookIOManager] performSetupWithDelegate:self.viewController];
    
#if RUN_KIF_TESTS
    [[LIOTestController sharedInstance] startTestingWithCompletionBlock:^{
        // Exit after the tests complete so that CI knows we're done
        exit([[LIOTestController sharedInstance] failureCount]);
    }];
#endif
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSLog(@"\n\n>>> oh hi, I was asked to open a URL: \"%@\"", [url absoluteString]);
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
