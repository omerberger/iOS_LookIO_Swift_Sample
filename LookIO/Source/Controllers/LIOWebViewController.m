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
#import "LIOEngagement.h"

// Views
#import "LIODraggableButton.h"

//Model
#import "LIOSecuredFormInfo.h"

#define LIOWebViewControllerAlertViewNextStepOpenInSafari 2001
#define LIOWebViewControllerAlertViewNextStepCloseWebView 2002

@interface LIOWebViewController () <UIAlertViewDelegate, LIODraggableButtonDelegate, UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSURL *url;


@property (nonatomic, strong) LIODraggableButton *controlButton;

@property (nonatomic, strong) UIAlertView *alertView;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIImageView *loadingImageView;

@property (nonatomic, strong) UIView *topBarView;
@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) UIButton *closeButton;

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
    
    CGFloat topBarHeight = 44.0 + [self statusBarInset];
    
    self.topBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, topBarHeight)];
    self.topBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.topBarView.backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementWebViewHeaderBar];
    [self.view addSubview:self.topBarView];
    
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, topBarHeight, self.view.bounds.size.width, self.view.bounds.size.height -  topBarHeight)];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.scalesPageToFit = YES;
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
    
    UIColor *buttonColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorColor forElement:LIOBrandingElementWebViewHeaderBarButtons];

    self.closeButton = [[UIButton alloc] initWithFrame:CGRectMake(8.0, topBarHeight - 8.0 - 32.0, 32, 32)];
    self.closeButton.accessibilityLabel = LIOLocalizedString(@"LIOLookIOManager.WebViewCloseButton");
    [self.closeButton addTarget:self action:@selector(closeButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.closeButton setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOCloseIcon" withTint:buttonColor] forState:UIControlStateNormal];
    [self.topBarView addSubview:self.closeButton];
    
    self.shareButton = [[UIButton alloc] initWithFrame:CGRectMake(self.topBarView.bounds.size.width - 32.0 - 8.0, topBarHeight - 8.0 - 32.0, 32, 32)];
    self.shareButton.accessibilityLabel = LIOLocalizedString(@"LIOLookIOManager.WebViewOpenInBrowserButton");
    self.shareButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.shareButton addTarget:self action:@selector(openInSafariButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.shareButton setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOShareIcon" withTint:buttonColor] forState:UIControlStateNormal];
    [self.topBarView addSubview:self.shareButton];
    
    if ([self.delegate webViewControllerShowControlButtonForWebView:self])
    {
        self.controlButton = [[LIODraggableButton alloc] initWithFrame:CGRectZero];
        [self.view addSubview:self.controlButton];
        self.controlButton.delegate = self;
        self.controlButton.ignoreActualInterfaceOrientation = YES;
        self.controlButton.buttonKind = [self.delegate webViewControllerButtonKindForWebView:self];
        self.controlButton.buttonTitle = [self.delegate webViewControllerButtonTitleForWebView:self];
        [self.controlButton updateBaseValues];
        [self.controlButton updateButtonBranding];
    }
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, topBarHeight - 8.0 - 32.0, self.topBarView.frame.size.width - 100, 32)];
    self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.titleLabel.text = LIOLocalizedString(@"LIOLookIOManager.WebViewLoadingTitle");
    self.titleLabel.font = [[LIOBrandingManager brandingManager] boldFontForElement:LIOBrandingElementWebViewHeaderBar];
    self.titleLabel.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementWebViewHeaderBar];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.textAlignment = UITextAlignmentCenter;
    [self.topBarView addSubview:self.titleLabel];
    
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
    
    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        UIScreenEdgePanGestureRecognizer *swipeRightGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeRight:)];
        swipeRightGestureRecognizer.edges = UIRectEdgeLeft;
        [self.webView addGestureRecognizer:swipeRightGestureRecognizer];
    }
    else
    {
        UISwipeGestureRecognizer *swipeRightGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeRight:)];
        swipeRightGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
        [self.webView addGestureRecognizer:swipeRightGestureRecognizer];
    }
    
}

- (void)didSwipeRight:(id)sender
{
    [self.webView goBack];
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
    
    [self.webView stringByEvaluatingJavaScriptFromString:@"window._LPM_NATIVE_ = true;"];
    
    if (self.securedFormInfo)
    {
        if (![[self currentWebViewURL].absoluteString isEqualToString:self.securedFormInfo.formUrl])
        {
            [self.delegate webViewControllerDidSubmitSecuredFormWithInfo:self.securedFormInfo forWebView:self];
            [self closeWebView];

        }
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if (self.securedFormInfo)
    {
        self.shareButton.hidden = YES;
        [self.webView addSubview:self.loadingImageView];
    
    }
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
        case LIOWebViewControllerAlertViewNextStepCloseWebView:
            if (buttonIndex == 1)
            {
                [self closeWebView];
            }
        default:
            break;
    }
}

#pragma mark -
#pragma mark Action Methods

- (void)closeButtonWasTapped:(id)sender
{
    if (self.securedFormInfo)
    {
        NSString *alertCancel = LIOLocalizedString(@"LIOChatBubbleView.AlertCancelClose");
        NSString *alertClose = LIOLocalizedString(@"LIOChatBubbleView.AlertClose");
        NSString *alertMessage = LIOLocalizedString(@"LIOChatBubbleView.DistructiveCloseMessage");
        NSString *alertTitle = LIOLocalizedString(@"LIOChatBubbleView.AlertCloseTitle");
        
        [self dismissExistingAlertView];
        self.alertView = [[UIAlertView alloc] initWithTitle:alertTitle
                                                    message:alertMessage
                                                   delegate:self
                                          cancelButtonTitle:alertCancel
                                          otherButtonTitles: alertClose, nil];
        self.alertView.tag = LIOWebViewControllerAlertViewNextStepCloseWebView;
        [self.alertView show];
    }
    else
    {
        [self closeWebView];
    }
}

- (void)closeWebView
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

// iOS 8.0
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    if (self.controlButton)
    {
        [self.controlButton hide:NO];
    }
    
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (self.controlButton)
        {
            [self.controlButton resetFrame];
            [self.controlButton show:YES];
        }
    }];    
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

- (CGFloat)statusBarInset
{
    CGFloat statusBarInset = 0.0;
    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        BOOL statusBarHidden = NO;
        
        // Read the plist to see if we should use status bar appearance
        // The iOS 7.0 default is YES, so if no plist is present, use YES
        BOOL viewControllerBasedStatusBarAppearance = YES;
        if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"])
            viewControllerBasedStatusBarAppearance = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"] boolValue];
        
        // If status bar appearance, we should use the branding result
        if (viewControllerBasedStatusBarAppearance)
        {
            statusBarHidden = [[LIOBrandingManager brandingManager] booleanValueForField:@"hidden" element:LIOBrandingElementStatusBar];
        }
        // If not, just use the UIApplication result
        else
        {
            statusBarHidden = [[UIApplication sharedApplication] isStatusBarHidden];
        }
        
        statusBarInset = statusBarHidden ? 0.0 : 20.0;
    }
    else
    {
        statusBarInset = 0.0;
    }
    
    return statusBarInset;
}

- (void)updateStatusBarInset
{
    [self statusBarInset];
 
    CGFloat topBarHeight = 44.0 + [self statusBarInset];
    self.topBarView.frame = CGRectMake(0, 0, self.view.bounds.size.width, topBarHeight);
    self.webView.frame = CGRectMake(0, topBarHeight, self.view.bounds.size.width, self.view.bounds.size.height -  topBarHeight);
    self.closeButton.frame = CGRectMake(8.0, topBarHeight - 8.0 - 32.0, 32, 32);
    self.shareButton.frame = CGRectMake(self.topBarView.bounds.size.width - 32.0 - 8.0, topBarHeight - 8.0 - 32.0, 32, 32);
    self.titleLabel.frame = CGRectMake(50, topBarHeight - 8.0 - 32.0, self.topBarView.frame.size.width - 100, 32);
}

#pragma mark -
#pragma mark Autorotate Methods

- (BOOL)shouldAutorotate
{
    return [self.delegate webViewControllerShouldAutorotate:self];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return [self.delegate webViewControllerSupportedInterfaceOrientations:self];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return [self.delegate webViewController:self shouldRotateToInterfaceOrientation:toInterfaceOrientation];
}



@end
