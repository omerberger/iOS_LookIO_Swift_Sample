//
//  LTBMainViewController.h
//  tigertext
//
//  Created by Joseph Toscano on 8/20/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LTBBookHotelsViewController.h"

@interface LTBMainViewController : UIViewController <LTBBookHotelsViewControllerDelegate>

@property(nonatomic, retain) LTBBookHotelsViewController *bookHotelsViewController;

@end
