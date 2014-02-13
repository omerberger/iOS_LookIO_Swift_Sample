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
    [self dismissExistingAlertView];
    [self.controlButton removeTimers];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.controlButton resetFrame];
    [self.controlButton show:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
    
    UIColor *buttonColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementBrandingBarWebviewButtons];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOCloseIcon" withTint:buttonColor] style:UIBarButtonItemStylePlain target:self action:@selector(closeButtonWasTapped:)];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOShareIcon" withTint:buttonColor] style:UIBarButtonItemStylePlain target:self action:@selector(openInSafariButtonWasTapped:)];
    
    if ([self.delegate webViewControllerShowControlButtonForWebView:self])
    {
        self.controlButton = [[LIODraggableButton alloc] initWithFrame:CGRectZero];
        [self.view addSubview:self.controlButton];
        self.controlButton.delegate = self;
        self.controlButton.ignoreActualInterfaceOrientation = YES;
        self.controlButton.buttonKind = [self.delegate webViewControllerButtonKindForWebView:self];
        [self.controlButton updateBaseValues];
    }
    
    self.navigationItem.title = LIOLocalizedString(@"LIOLookIOManager.WebViewLoadingTitle");
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
    self.navigationItem.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
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

@end
