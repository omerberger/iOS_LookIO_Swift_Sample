//
//  LTBBookHotelsViewController.h
//  tigertext
//
//  Created by Joseph Toscano on 8/20/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LTBBookHotelsViewController;

@protocol LTBBookHotelsViewControllerDelegate
- (void)bookHotelsViewControllerDidTapBackButton:(LTBBookHotelsViewController *)aController;
@end

@interface LTBBookHotelsViewController : UIViewController
{
    id<LTBBookHotelsViewControllerDelegate> delegate;
}

@property(nonatomic, assign) id<LTBBookHotelsViewControllerDelegate> delegate;

@end