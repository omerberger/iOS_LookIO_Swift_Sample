//
//  LTBAppDelegate.h
//  Testbed
//
//  Created by Joe Toscano on 8/22/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LTBMainViewController.h"
#import "LIOLookIOManager.h"

@interface LTBAppDelegate : UIResponder <UIApplicationDelegate, LIOLookIOManagerDelegate>
{
    UIWindow *window;
    LTBMainViewController *mainViewController;
}

@property(nonatomic, retain) UIWindow *window;
@property(nonatomic, retain) LTBMainViewController *mainViewController;

@end
