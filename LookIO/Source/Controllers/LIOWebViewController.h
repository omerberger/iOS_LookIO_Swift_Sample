//
//  LIOWebViewController.h
//  LookIO
//
//  Created by Yaron Karasik on 1/29/14.
//
//

#import <UIKit/UIKit.h>

@class LIOWebViewController;

@protocol LIOWebViewControllerDelegate <NSObject>

- (void)webViewControllerCloseButtonWasTapped:(LIOWebViewController *)webViewController;
- (BOOL)webViewControllerShowControlButtonForWebView:(LIOWebViewController *)webViewController;
- (NSInteger)webViewControllerButtonKindForWebView:(LIOWebViewController *)webViewController;
- (NSString *)webViewControllerButtonTitleForWebView:(LIOWebViewController *)webViewController;

@end

@interface LIOWebViewController : UIViewController

@property (nonatomic, assign) id<LIOWebViewControllerDelegate> delegate;

- (id)initWithURL:(NSURL *)aURL;
- (NSURL *)currentWebViewURL;

- (void)dismissExistingAlertView;
- (void)reportUnreadMessage;
- (void)presentNotification:(NSString *)notification;

@end
