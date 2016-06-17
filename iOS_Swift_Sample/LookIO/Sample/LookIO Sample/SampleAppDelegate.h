//
//  SampleAppDelegate.h
//  LookIO Sample
//
//  Created by Marc Campbell on 1/15/12.
//  Copyright (c) 2012 Look.IO. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LIOLookIOManager.h"

@class SampleViewController;

@interface SampleAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) SampleViewController *viewController;

@end
