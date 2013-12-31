//
//  LIOContainerViewController.h
//  LookIO
//
//  Created by Yaron Karasik on 12/9/13.
//
//

#import <UIKit/UIKit.h>
#import "LIOEngagement.h";

typedef enum {
    LIOHeaderBarStateHidden = 0,
    LIOHeaderBarStateVisible,
    LIOHeaderBarStateLandscapeHidden
} LIOHeaderBarState;

@class LIOContainerViewController;

@protocol LIOContainerViewControllerDelegate <NSObject>

- (void)containerViewControllerDidDismiss:(LIOContainerViewController *)containerViewController;

@end

@interface LIOContainerViewController : UIViewController

@property (nonatomic, assign) id <LIOContainerViewControllerDelegate> delegate;

- (void)setBlurImage:(UIImage *)image;
- (void)presentChatForEngagement:(LIOEngagement *)anEngagement;
- (void)engagement:(LIOEngagement *)engagement didReceiveMessage:(LIOChatMessage *)message;
- (void)engagement:(LIOEngagement *)engagement didReceiveNotification:(NSString *)notification;

@end
