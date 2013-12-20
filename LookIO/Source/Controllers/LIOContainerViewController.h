//
//  LIOContainerViewController.h
//  LookIO
//
//  Created by Yaron Karasik on 12/9/13.
//
//

#import <UIKit/UIKit.h>
#import "LIOEngagement.h";

@class LIOContainerViewController;

@protocol LIOContainerViewControllerDelegate <NSObject>

- (void)containerViewControllerDidDismiss:(LIOContainerViewController *)containerViewController;

@end

@interface LIOContainerViewController : UIViewController

@property (nonatomic, assign) id <LIOContainerViewControllerDelegate> delegate;

- (void)setBlurImage:(UIImage *)image;
- (void)presentChatForEngagement:(LIOEngagement *)anEngagement;

@end
