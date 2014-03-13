//
//  LIOWebViewController.m
//  LookIO
//
//  Created by Yaron Karasik on 1/29/14.
//
//

#import "LIOWebViewController.h"

// Managers
#import "LIOBrandingManager.h"
#import "LIOBundleManager.h"

// Views
#import "LIODraggableButton.h"

#define LIOWebViewControllerAlertViewNextStepOpenInSafari 2001

@interface LIOWebViewController () <UIAlertViewDelegate, LIODraggableButtonDelegate, UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSURL *url;

@property (nonatomic, strong) LIODraggableButton *controlButton;

@property (nonatomic, strong) UIAlertView *alertView;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIImageView *loadingImageView;

@end

@implementation LIOWebViewController

- (id)initWithURL:(NSURL *)aURL
{
    self = [super init];
    if (self)
    {
        self.url = aURL;
    }
    return self;
}

#pragma mark -
#pragma mark ViewController LifeCycle Methods

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.controlButton removeTimers];
    [self dismissExistingAlertView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.controlButton resetFrame];
    [self.controlButton show:YES];
    
    CABasicAnimation *loadingAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    loadingAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    loadingAnimation.toValue = [NSNumber numberWithFloat: 2*M_PI];
    loadingAnimation.duration = 1.0f;
    loadingAnimation.repeatCount = HUGE_VAL;
    [self.loadingImageView.layer addAnimation:loadingAnimation forKey:@"animation"];

    self.loadingImageView.alpha = 1.0;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    CGFloat topBarHeight = LIOIsUIKitFlatMode() ? 64.0 : 44.0;
    
    UIView *topBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, topBarHeight)];
    topBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    topBarView.backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementWebViewHeaderBar];
    [self.view addSubview:topBarView];
    
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, topBarHeight, self.view.bounds.size.width, self.view.bounds.size.height -  topBarHeight)];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.scalesPageToFit = YES;
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
    
    UIColor *buttonColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorColor forElement:LIOBrandingElementWebViewHeaderBarButtons];

    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(8.0, topBarHeight - 8.0 - 32.0, 32, 32)];
    closeButton.accessibilityLabel = LIOLocalizedString(@"LIOLookIOManager.WebViewCloseButton");
    [closeButton addTarget:self action:@selector(closeButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    [closeButton setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOCloseIcon" withTint:buttonColor] forState:UIControlStateNormal];
    [topBarView addSubview:closeButton];
    
    UIButton *shareButton = [[UIButton alloc] initWithFrame:CGRectMake(topBarView.bounds.size.width - 32.0 - 8.0, topBarHeight - 8.0 - 32.0, 32, 32)];
    shareButton.accessibilityLabel = LIOLocalizedString(@"LIOLookIOManager.WebViewOpenInBrowserButton");
    shareButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [shareButton addTarget:self action:@selector(openInSafariButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    [shareButton setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOShareIcon" withTint:buttonColor] forState:UIControlStateNormal];
    [topBarView addSubview:shareButton];
    
    if ([self.delegate webViewControllerShowControlButtonForWebView:self])
    {
        self.controlButton = [[LIODraggableButton alloc] initWithFrame:CGRectZero];
        [self.view addSubview:self.controlButton];
        self.controlButton.delegate = self;
        self.controlButton.ignoreActualInterfaceOrientation = YES;
        self.controlButton.buttonKind = [self.delegate webViewControllerButtonKindForWebView:self];
        [self.controlButton updateBaseValues];
        [self.controlButton updateButtonBranding];
    }
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, topBarHeight - 8.0 - 32.0, topBarView.frame.size.width - 100, 32)];
    self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.titleLabel.text = LIOLocalizedString(@"LIOLookIOManager.WebViewLoadingTitle");
    self.titleLabel.font = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementWebViewHeaderBar];
    self.titleLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementWebViewHeaderBar];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.textAlignment = UITextAlignmentCenter;
    [topBarView addSubview:self.titleLabel];
    
    self.loadingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.webView.bounds.size.width/2 - 65, self.webView.bounds.size.height/2 - 50, 130, 50)];
    self.loadingImageView.alpha = 0.0;
    [[LIOBundleManager sharedBundleManager] cachedImageForBrandingElement:LIOBrandingElementLoadingScreen withBlock:^(BOOL success, UIImage *image) {
        if (success)
            self.loadingImageView.image = image;
        else
            self.loadingImageView.image = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOSpinningLoader"];
    }];
    self.loadingImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.loadingImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    [self.webView addSubview:self.loadingImageView];
}

- (NSURL *)currentWebViewURL
{
    NSString *currentURL = self.webView.request.URL.absoluteString;
    return [NSURL URLWithString:currentURL];
}

#pragma mark -
#pragma mark UIWebView Delegate Methods

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.titleLabel.text = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    [self.loadingImageView removeFromSuperview];
}

#pragma mark -
#pragma mark UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case LIOWebViewControllerAlertViewNextStepOpenInSafari:
            if (buttonIndex == 1)
            {
                [[UIApplication sharedApplication] openURL:[self currentWebViewURL]];
            }
            break;
            
        default:
            break;
    }
}

#pragma mark -
#pragma mark Action Methods

- (void)closeButtonWasTapped:(id)sender
{
    [self.controlButton resetUnreadMessages];
    [self.controlButton hideCurrentMessage];
    [self.controlButton removeTimers];
    [self.delegate webViewControllerCloseButtonWasTapped:self];
}

- (void)openInSafariButtonWasTapped:(id)sender
{
    NSString *alertCancel = LIOLocalizedString(@"LIOChatBubbleView.AlertCancel");
    NSString *alertOpen = LIOLocalizedString(@"LIOChatBubbleView.AlertGo");
    NSString *alertMessage = [NSString stringWithFormat:LIOLocalizedString(@"LIOChatBubbleView.LinkAlert"), [self currentWebViewURL].absoluteString];
    
    [self dismissExistingAlertView];
    self.alertView = [[UIAlertView alloc] initWithTitle:nil
                                                message:alertMessage
                                               delegate:self
                                      cancelButtonTitle:nil
                                      otherButtonTitles:alertCancel, alertOpen, nil];
    self.alertView.tag = LIOWebViewControllerAlertViewNextStepOpenInSafari;
    [self.alertView show];
}

- (void)dismissExistingAlertView
{
    if (self.alertView)
    {
        [self.alertView dismissWithClickedButtonIndex:-1 animated:NO];
        self.alertView = nil;
    }
}

#pragma mark -
#pragma mark DraggableButtonDelegate Methods

- (void)draggableButtonWasTapped:(LIODraggableButton *)draggableButton
{
    [self closeButtonWasTapped:self];
}

#pragma mark -
#pragma mark Rotation Methods

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (self.controlButton)
    {
        [self.controlButton resetFrame];
        [self.controlButton show:YES];
    }
    
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (self.controlButton)
    {
        [self.controlButton hide:NO];
    }
}

- (void)reportUnreadMessage
{
    if (self.controlButton)
        [self.controlButton reportUnreadMessage];
}

- (void)presentNotification:(NSString *)notification;
{
    if (self.controlButton)
        [self.controlButton presentMessage:notification];
}

#pragma mark -
#pragma mark StatusBar Methods

- (BOOL)prefersStatusBarHidden
{
    return [[LIOBrandingManager brandingManager] booleanValueForField:@"hidden" element:LIOBrandingElementStatusBar];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [[LIOBrandingManager brandingManager] statusBarStyleForElement:LIOBrandingElementStatusBar];
}

@end
