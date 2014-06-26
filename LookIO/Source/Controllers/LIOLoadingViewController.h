//
//  LIOLoadingViewController.h
//  LookIO
//
//  Created by Yaron Karasik on 1/3/14.
//
//

#import <UIKit/UIKit.h>

@class LIOLoadingViewController;

@protocol LIOLoadingViewControllerDelegate <NSObject>

- (void)loadingViewControllerDidDismiss:(LIOLoadingViewController *)loadingViewController;

@end

@interface LIOLoadingViewController : UIViewController

@property (nonatomic, assign) id <LIOLoadingViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL isShowingQueueingMessage;

- (void)showBezel;
- (void)hideBezel;
- (void)showBezelForQueueingMessage:(NSString *)queueingMessage;
- (void)updateQueueingMessage:(NSString *)queueingMessage;

@end
