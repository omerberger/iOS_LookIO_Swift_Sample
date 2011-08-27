//
//  LTBBookFlightsViewController.h
//  Testbed
//
//  Created by Joe Toscano on 8/26/11.
//  Copyright 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LTBBookFlightsViewController;

@protocol LTBBookFlightsViewControllerDelegate
- (void)bookFlightsViewControllerDidTapBackButton:(LTBBookFlightsViewController *)aController;
@end

@interface LTBBookFlightsViewController : UIViewController
{
    id<LTBBookFlightsViewControllerDelegate> delegate;
}

@property(nonatomic, assign) id<LTBBookFlightsViewControllerDelegate> delegate;

@end
