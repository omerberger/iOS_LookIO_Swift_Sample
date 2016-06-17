//
//  LIOWebViewController.h
//  LookIO
//
//  Created by Yaron Karasik on 1/29/14.
//
//

#import <UIKit/UIKit.h>

@class LIOWebViewController, LIOSecuredFormInfo;

@protocol LIOWebViewControllerDelegate <NSObject>

- (void)webViewControllerCloseButtonWasTapped:(LIOWebViewController *)webViewController;
- (BOOL)webViewControllerShowControlButtonForWebView:(LIOWebViewController *)webViewController;
- (NSInteger)webViewControllerButtonKindForWebView:(LIOWebViewController *)webViewController;
- (NSString *)webViewControllerButtonTitleForWebView:(LIOWebViewController *)webViewController;
- (void)webViewControllerDidSubmitSecuredFormWithInfo:(LIOSecuredFormInfo *)securedFormInfo forWebView:(LIOWebViewController *)webViewController;

// Rotation methods
- (BOOL)webViewController:(LIOWebViewController *)webViewController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation;
- (BOOL)webViewControllerShouldAutorotate:(LIOWebViewController *)webViewController;
- (NSInteger)webViewControllerSupportedInterfaceOrientations:(LIOWebViewController *)webViewController;

@end

@interface LIOWebViewController : UIViewController

@property (nonatomic, assign) id<LIOWebViewControllerDelegate> delegate;

@property (nonatomic, strong) LIOSecuredFormInfo *securedFormInfo; //In case this is a secured form, we would like to keep the relevant indo so we can post back later on .

- (id)initWithURL:(NSURL *)aURL;
- (NSURL *)currentWebViewURL;

- (void)dismissExistingAlertView;
- (void)reportUnreadMessage;
- (void)presentNotification:(NSString *)notification;

- (void)updateStatusBarInset;

@end
