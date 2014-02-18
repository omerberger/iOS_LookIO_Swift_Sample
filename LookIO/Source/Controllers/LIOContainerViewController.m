//
//  LIOContainerViewController.m
//  LookIO
//
//  Created by Yaron Karasik on 12/9/13.
//
//

#import "LIOContainerViewController.h"

// Managers
#import "LIOBundleManager.h"
#import "LIOBrandingManager.h"

// View Controllers
#import "LIOChatViewController.h"
#import "LPSurveyViewController.h"
#import "LIOLoadingViewController.h"
#import "LIOWebViewController.h"

// Views
#import "LIOHeaderBarView.h"

#define LIOContainerViewControllerAlertViewNextStepDismiss      2001

@interface LIOContainerViewController () <LIOChatViewControllerDelegate, LPSurveyViewControllerDelegate, LIOLoadingViewControllerDelegate, UIAlertViewDelegate, LIOHeaderBarViewDelegate, LIOWebViewControllerDelegate>

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) LIOHeaderBarView *headerBarView;
@property (nonatomic, assign) LIOHeaderBarState headerBarState;
@property (nonatomic, assign) CGFloat statusBarInset;

@property (nonatomic, assign) LIOContainerViewState containerViewState;
@property (nonatomic, strong) UIViewController *currentViewController;
@property (nonatomic, strong) LIOChatViewController *chatViewController;
@property (nonatomic, strong) LIOLoadingViewController *loadingViewController;
@property (nonatomic, strong) LPSurveyViewController *surveyViewController;
@property (nonatomic, strong) LIOWebViewController *webViewController;

@property (nonatomic, strong) LIOEngagement *engagement;

@property (nonatomic, strong) UIAlertView *alertView;

@property (nonatomic, assign) BOOL isAgentTypingMessageVisible;
@property (nonatomic, assign) BOOL isNotificationVisible;

@end

@implementation LIOContainerViewController

- (void)setBlurImage:(UIImage *)image
{
    [self.blurImageView setImageAndBlur:image];
    [UIView animateWithDuration:0.3 animations:^{
        self.blurImageView.alpha = 1.0;
        self.view.alpha = 1.0;
    } completion:^(BOOL finished) {

    }];
}

- (void)updateBlurImage:(UIImage *)image
{
    [self.blurImageView setImageAndBlur:image];
}

#pragma mark -
#pragma mark WebViewController Methods

- (void)webViewControllerCloseButtonWasTapped:(LIOWebViewController *)webViewController
{
    self.containerViewState = LIOContainerViewStateChat;
    
    [self.delegate containerViewControllerWantsWindowBackgroundColor:[UIColor blackColor]];
    [self animationPopFrontScaleUp];
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate containerViewControllerWantsWindowBackgroundColor:[UIColor clearColor]];
        self.webViewController = nil;
    }];
}

- (BOOL)webViewControllerShowControlButtonForWebView:(LIOWebViewController *)webViewController
{
    return [self.delegate containerViewControllerShowControlButtonForWebView:self];
}

- (NSInteger)webViewControllerButtonKindForWebView:(LIOWebViewController *)webViewController
{
    return [self.delegate containerViewControllerButtonKindForWebView:self];
}

#pragma mark -
#pragma mark HeaderBarView Methods

- (void)headerBarViewPlusButtonWasTapped:(LIOHeaderBarView *)aView
{
    if (self.containerViewState == LIOContainerViewStateChat)
    {
        [self.chatViewController headerBarViewPlusButtonWasTapped];
    }
}

- (BOOL)headerBarShouldDismissNotification:(LIOHeaderBarView *)aView
{
    if (!self.engagement.isConnected)
    {
        return NO;
    }

    return YES;
}

- (BOOL)headerBarShouldDisplayIsTypingAfterDismiss:(LIOHeaderBarView *)aView
{
    if (self.engagement.isAgentTyping)
    {
        [self engagement:self.engagement agentIsTyping:YES];
        return YES;
    }

    return NO;
}

- (void)presentHeaderBarView:(BOOL)animated
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    if (padUI)
        return;

    CGRect headerBarFrame = self.headerBarView.frame;
    headerBarFrame.origin.y = 0;
    
    CGRect contentViewFrame = self.contentView.frame;
    contentViewFrame.origin.x = 0;
    contentViewFrame.origin.y = headerBarFrame.size.height;
    contentViewFrame.size.height = self.view.bounds.size.height - headerBarFrame.size.height;
    
    self.headerBarState = LIOHeaderBarStateVisible;
    if (animated)
    {
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.headerBarView.frame = headerBarFrame;
            self.contentView.frame = contentViewFrame;
        } completion:nil];
    }
    else
    {
        self.headerBarView.frame = headerBarFrame;
        self.contentView.frame = contentViewFrame;
    }
}

- (void)dismissHeaderBarView:(BOOL)animated withState:(LIOHeaderBarState)state
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    if (padUI)
        return;

    CGRect headerBarFrame = self.headerBarView.frame;
    headerBarFrame.origin.y = -headerBarFrame.size.height;
    
    CGRect contentViewFrame = self.contentView.frame;
    contentViewFrame.origin.x = 0;
    contentViewFrame.origin.y = self.statusBarInset;
    contentViewFrame.size.height = self.view.bounds.size.height - self.statusBarInset;
    
    self.headerBarState = state;
    if (animated)
    {
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.headerBarView.frame = headerBarFrame;
            self.contentView.frame = contentViewFrame;
        } completion:^(BOOL finished) {
            if (padUI)
                self.headerBarView.hidden = YES;
        }];
    }
    else
    {
        self.headerBarView.frame = headerBarFrame;
        self.contentView.frame = contentViewFrame;
    }
}


- (void)engagement:(LIOEngagement *)engagement didReceiveNotification:(NSString *)notification
{
    if (LIOContainerViewStateChat == self.containerViewState || LIOContainerViewStateLoading == self.containerViewState)
    {
        BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];

        self.isAgentTypingMessageVisible = NO;
        
        if (!padUI)
        {
            [self.headerBarView revealNotificationString:notification withAnimatedKeyboard:NO permanently:NO];
        }
        else
        {
            [self.chatViewController displayToasterNotification:notification];
        }
    }
    if (LIOContainerViewStateWeb == self.containerViewState)
    {
        [self.webViewController presentNotification:notification];
    }
}

- (void)dismissCurrentNotification
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    if (padUI)
    {
        [self.chatViewController hideToasterView];
    }
    else
    {
        [self.headerBarView hideCurrentNotification];
    }

}

- (void)engagement:(LIOEngagement *)engagement agentIsTyping:(BOOL)isTyping
{
    if (LIOContainerViewStateChat == self.containerViewState)
    {
        BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
        
        if (padUI)
        {
            [self.chatViewController displayToasterAgentIsTyping:isTyping];
        }
        else
        {
            // Reveal if needed
            if (isTyping && self.isAgentTypingMessageVisible == NO)
            {
                self.isAgentTypingMessageVisible = YES;

                if (padUI)
                {
                    [self.chatViewController displayToasterAgentIsTyping:isTyping];
                }
                else
                {
                    [self.headerBarView revealNotificationString:LIOLocalizedString(@"LIOAltChatViewController.AgentTypingNotification") withAnimatedKeyboard:YES permanently:YES];
                }
            }
            
            // Hide if needed
            if (!isTyping && self.isAgentTypingMessageVisible == YES)
            {
                self.isAgentTypingMessageVisible = NO;
                if (padUI)
                {
                    [self.chatViewController displayToasterAgentIsTyping:isTyping];
                }
                else
                {
                    [self.headerBarView revealNotificationString:nil withAnimatedKeyboard:NO permanently:NO];
                }
            }
        }
    }
}

#pragma mark -
#pragma mark LoadingViewController Delegate Methods

- (void)loadingViewControllerDidDismiss:(LIOLoadingViewController *)loadingViewController
{
    [self dismiss];
}

#pragma mark -
#pragma mark ChatViewController Delegate Methods

- (void)chatViewControllerDidDismissChat:(LIOChatViewController *)chatViewController
{
    [self dismiss];
}

- (void)chatViewControllerDidEndChat:(LIOChatViewController *)chatViewController
{
    // Let's see it there is a post chat survey
    if ([self.engagement shouldPresentPostChatSurvey])
    {
        [self.delegate containerViewControllerDidPresentPostChatSurvey:self];
        [self presentPostchatSurveyForEngagement:self.engagement];
    }
    else
    {
        [self.engagement endEngagement];
        [self dismiss];
    }
}

- (void)chatViewControllerDidTapIntraAppLink:(NSURL *)url
{
    [self.delegate containerViewControllerDidTapIntraAppLink:url];
}

- (void)chatViewControllerDidTapWebLink:(NSURL *)url
{
    self.containerViewState = LIOContainerViewStateWeb;
    
    [self.headerBarView hideCurrentNotification];
    
    [self.delegate containerViewControllerWantsWindowBackgroundColor:[UIColor blackColor]];
    
    self.webViewController = [[LIOWebViewController alloc] initWithURL:url];
    self.webViewController.delegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.webViewController];

    [self presentViewController:navigationController animated:YES completion:nil];
    [self animationPushBackScaleDown];
}

- (void)chatViewControllerLandscapeWantsHeaderBarHidden:(BOOL)hidden
{
    // This is only relevant if we are in landscape and in chat and not on iPad
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];

    if (!padUI && (LIOContainerViewStateChat == self.containerViewState) && UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
    {
        if (hidden)
        {
            if (LIOHeaderBarStateVisible == self.headerBarState)
                [self dismissHeaderBarView:NO withState:LIOHeaderBarStateLandscapeHidden];
        }
        else
        {
            if (LIOHeaderBarStateLandscapeHidden == self.headerBarState)
                [self presentHeaderBarView:NO];
        }
        
    }
}

- (void)presentChatForEngagement:(LIOEngagement *)anEngagement
{
    if (self.containerViewState != LIOContainerViewStateChat)
    {
        self.engagement = anEngagement;
        if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
            [self presentHeaderBarView:YES];
        else
            self.headerBarState = LIOHeaderBarStateLandscapeHidden;
        [self presentChatViewController:YES];
    }
}

- (void)presentPrechatSurveyForEngagement:(LIOEngagement *)anEngagement
{
    self.engagement = anEngagement;
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
        [self presentHeaderBarView:YES];
    else
        self.headerBarState = LIOHeaderBarStateLandscapeHidden;
    [self presentSurveyViewControllerWithSurvey:self.engagement.prechatSurvey animated:YES];
}

- (void)presentOfflineSurveyForEngagement:(LIOEngagement *)anEngagement
{
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
        [self presentHeaderBarView:YES];
    else
        self.headerBarState = LIOHeaderBarStateLandscapeHidden;
    [self presentSurveyViewControllerWithSurvey:self.engagement.offlineSurvey animated:YES];
}

- (void)engagement:(LIOEngagement *)engagement didReceiveMessage:(LIOChatMessage *)message;
{
    [self.chatViewController engagement:engagement didReceiveMessage:message];
    if (LIOContainerViewStateWeb == self.containerViewState)
    {
        [self.webViewController reportUnreadMessage];
        [self.webViewController presentNotification:LIOLocalizedString(@"LIOLookIOManager.LocalNotificationChatBody")];
    }
}

- (void)engagementChatMessageStatusDidChange:(LIOEngagement *)engagement;
{
    [self.chatViewController engagementChatMessageStatusDidChange:engagement];
}


- (void)presentLoadingViewController
{
    self.containerViewState = LIOContainerViewStateLoading;
    [self.loadingViewController showBezel];
    
    if (self.currentViewController != self.loadingViewController)
        [self swapCurrentControllerWith:self.loadingViewController animated:YES];
}

- (void)presentChatViewController:(BOOL)animated
{
    [self.chatViewController setEngagement:self.engagement];
    self.containerViewState = LIOContainerViewStateChat;
    [self swapCurrentControllerWith:self.chatViewController animated:animated];
}

- (void)presentPostchatSurveyForEngagement:(LIOEngagement *)anEngagement
{
    self.engagement = anEngagement;
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
        [self presentHeaderBarView:YES];
    else
        self.headerBarState = LIOHeaderBarStateLandscapeHidden;
    [self presentSurveyViewControllerWithSurvey:self.engagement.postchatSurvey animated:YES];
}

- (void)presentSurveyViewControllerWithSurvey:(LIOSurvey *)survey animated:(BOOL)animated
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    if (!padUI)
    {
        [self.headerBarView hideCurrentNotification];
    }
    
    if (LIOContainerViewStateWeb == self.containerViewState)
    {
        [self webViewControllerCloseButtonWasTapped:self.webViewController];
    }
    
    self.surveyViewController = [[LPSurveyViewController alloc] initWithSurvey:survey];
    self.surveyViewController.delegate = self;
    self.containerViewState = LIOContainerViewStateSurvey;
    [self swapCurrentControllerWith:self.surveyViewController animated:animated];
}

#pragma mark -
#pragma mark SurveyViewControllerDelegate Methods

- (void)surveyViewController:(LPSurveyViewController *)surveyViewController didCancelSurvey:(LIOSurvey *)survey
{
    // For a postchat survey, let's check if we can still submit it..
    if (LIOSurveyTypePostchat == survey.surveyType)
    {
        if ([survey anyQuestionsAnswered] && [survey allMandatoryQuestionsAnswered])
            [self.engagement submitSurvey:survey retries:0];
    }
  
    [self dismiss];
    self.surveyViewController = nil;
}

- (void)surveyViewController:(LPSurveyViewController *)surveyViewController didCompleteSurvey:(LIOSurvey *)survey
{
    [self.engagement submitSurvey:survey retries:0];

    // For offline survey or post chat survey, dismiss chat
    switch (survey.surveyType) {
        case LIOSurveyTypeOffline:
            [self showSurveySubmissionAlert];
            break;
            
        case LIOSurveyTypePostchat:
            [self showSurveySubmissionAlert];
            break;
            
        case LIOSurveyTypePrechat:
            [self presentLoadingViewController];
            break;
            
        default:
            break;
    }
    self.surveyViewController = nil;
}

- (void)showSurveySubmissionAlert
{
    [self dismissExistingAlertView];
    self.alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOSurveyView.SubmitOfflineSurveyAlertTitle")                                                        message:LIOLocalizedString(@"LIOSurveyView.SubmitOfflineSurveyAlertBody")
                                               delegate:self
                                      cancelButtonTitle:nil
                                      otherButtonTitles:LIOLocalizedString(@"LIOSurveyView.SubmitOfflineSurveyAlertButton"), nil];
    self.alertView.tag = LIOContainerViewControllerAlertViewNextStepDismiss;
    [self.alertView show];
}

#pragma mark -
#pragma mark UIAlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{    
    switch (alertView.tag) {
        case LIOContainerViewControllerAlertViewNextStepDismiss:
            [self dismiss];
            break;
            
        default:
            break;
    }
}

- (void)dismissExistingAlertView
{
    if (self.alertView)
    {
        [self.alertView dismissWithClickedButtonIndex:-1 animated:NO];
        self.alertView = nil;
    }
    
    switch (self.containerViewState) {
        case LIOContainerViewStateChat:
            [self.chatViewController dismissExistingAlertView];
            break;
            
        case LIOContainerViewStateSurvey:
            [self.surveyViewController dismissExistingAlertView];
            break;
            
        case LIOContainerViewStateWeb:
            [self.webViewController dismissExistingAlertView];
            break;
            
        default:
            break;
    }
}

#pragma mark -
#pragma mark Container View Controller Methods

- (void)swapCurrentControllerWith:(UIViewController*)viewController animated:(BOOL)animated
{
    if (viewController == self.currentViewController)
        return;
    
    
    [self.currentViewController willMoveToParentViewController:nil];
    [self addChildViewController:viewController];
    
    if (animated)
    {
        viewController.view.frame = self.contentView.bounds;
        viewController.view.alpha = 0.0;
        
        [self transitionFromViewController:self.currentViewController toViewController:viewController
                                  duration:0.3 options:nil
                                animations:^{
                                    viewController.view.alpha = 1.0;
                                    self.currentViewController.view.alpha = 0.0;
                                } completion:^(BOOL finished) {
                                    //Remove the old view controller
                                    [self.currentViewController removeFromParentViewController];
                                    [self.currentViewController.view removeFromSuperview];
                                    self.currentViewController.view.alpha = 1.0;
                                    
                                    //Set the new view controller as current
                                    self.currentViewController = viewController;
                                    [self.currentViewController didMoveToParentViewController:self];
                                }];
    }
    else
    {
        viewController.view.frame = self.contentView.bounds;
        [self.currentViewController removeFromParentViewController];
        [self.currentViewController.view removeFromSuperview];
        
        [self.contentView addSubview:viewController.view];

        self.currentViewController = viewController;
        [self.currentViewController didMoveToParentViewController:self];
    }
}

- (void)dismissCurrentViewController
{
    switch (self.containerViewState)
    {
        case LIOContainerViewStateChat:
            [self.chatViewController dismissChat:self];
            break;
            
        case LIOContainerViewStateSurvey:
            [self.surveyViewController cancelSurveyImmediately:self];
            break;
            
        case LIOContainerViewStateLoading:
            [self dismiss];
            break;
            
        case LIOContainerViewStateWeb:
            [self dismissModalViewControllerAnimated:NO];
            [self.delegate containerViewControllerWantsWindowBackgroundColor:[UIColor clearColor]];
            [self.chatViewController dismissChat:self];
            [self dismiss];
            self.webViewController = nil;
            break;
            
        default:
            break;
    }
}


- (void)dismiss
{
    [UIView animateWithDuration:0.3 animations:^{
        self.blurImageView.alpha = 0.0;
        self.view.alpha = 0.01;
    } completion:^(BOOL finished) {
        [self.delegate containerViewControllerDidDismiss:self];
        self.containerViewState = LIOContainerViewStateLoading;
        [self swapCurrentControllerWith:self.loadingViewController animated:NO];
        [self.loadingViewController hideBezel];
        [self dismissHeaderBarView:NO withState:LIOHeaderBarStateHidden];
        
        if (self.isAgentTypingMessageVisible)
        {
            [self engagement:self.engagement agentIsTyping:NO];
        }
    }];
}

#pragma mark -
#pragma mark Status Bar Inset Methods

- (void)setupStatusBarInset
{    
    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        BOOL statusBarHidden = NO;

        // Read the plist to see if we should use status bar appearance
        BOOL viewControllerBasedStatusBarAppearance = NO;
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

        self.statusBarInset = statusBarHidden ? 0.0 : 20.0;
    }
    else
    {
        self.statusBarInset = 0.0;
    }
}

#pragma mark -
#pragma mark Rotation Methods

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation) && LIOHeaderBarStateVisible == self.headerBarState)
    {
        if (LIOContainerViewStateChat == self.containerViewState)
            if (![self.chatViewController shouldHideHeaderBarForLandscape])
                return;
        
        [self dismissHeaderBarView:NO withState:LIOHeaderBarStateLandscapeHidden];
    }
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation) && LIOHeaderBarStateLandscapeHidden == self.headerBarState)
        [self presentHeaderBarView:NO];
}


#pragma mark -
#pragma mark View Controller Lifecycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];

    [self setupStatusBarInset];
    
    UIButton *emergencyDismissButton = [[UIButton alloc] initWithFrame:self.view.bounds];
    emergencyDismissButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [emergencyDismissButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:emergencyDismissButton];
    
	// Do any additional setup after loading the view.
    self.blurImageView = [[LIOBlurImageView alloc] initWithFrame:self.view.bounds];
    self.blurImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.blurImageView.alpha = 0.0;
    [self.view addSubview:self.blurImageView];
    
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, self.statusBarInset, self.view.bounds.size.width, self.view.bounds.size.height - self.statusBarInset)];
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.contentView];
    
    self.headerBarView = [[LIOHeaderBarView alloc] initWithFrame:CGRectMake(0, -(LIOHeaderBarViewDefaultHeight + self.statusBarInset), self.view.bounds.size.width, LIOHeaderBarViewDefaultHeight + self.statusBarInset) statusBarInset:self.statusBarInset];
    self.headerBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.headerBarView.delegate = self;
    self.headerBarState = LIOHeaderBarStateHidden;
    [self.view addSubview:self.headerBarView];
    
    // Extra precaution to not show headerbarview on iPad, other than for webview state
    if (padUI)
        self.headerBarView.hidden = YES;
    
    self.chatViewController = [[LIOChatViewController alloc] init];
    self.chatViewController.delegate = self;
    
    self.loadingViewController = [[LIOLoadingViewController alloc] init];
    self.loadingViewController.delegate = self;

    self.containerViewState = LIOContainerViewStateLoading;
    [self addChildViewController:self.loadingViewController];
    self.loadingViewController.view.frame = self.contentView.bounds;
    [self.contentView addSubview:self.loadingViewController.view];
    self.currentViewController = self.loadingViewController;
    [self.loadingViewController didMoveToParentViewController:self];
    
    [self.loadingViewController hideBezel];
}

// iOS >= 6.0
- (BOOL)shouldAutorotate
{
    return [self.delegate containerViewControllerShouldAutorotate:self];
}

// iOS >= 6.0
- (NSUInteger)supportedInterfaceOrientations
{
    return [self.delegate containerViewControllerSupportedInterfaceOrientations:self];
}


// iOS < 6.0
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [self.delegate containerViewController:self shouldRotateToInterfaceOrientation:interfaceOrientation];
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

#pragma mark -
#pragma mark Push back animations

- (void)animationPopFrontScaleUp {
	CABasicAnimation* scaleUp = [CABasicAnimation animationWithKeyPath:@"transform"];
	scaleUp.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
	scaleUp.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.8, 0.8, 0.8)];
	scaleUp.removedOnCompletion = YES;
    
	CABasicAnimation* opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
	opacity.fromValue = [NSNumber numberWithFloat:0.4];
	opacity.toValue = [NSNumber numberWithFloat:1.0f];
	opacity.removedOnCompletion = YES;
    
	CAAnimationGroup* group = [CAAnimationGroup animation];
	group.duration = 0.4;
	group.animations = [NSArray arrayWithObjects:scaleUp, opacity, nil];
    
	UIView* view = self.view;
	[view.layer addAnimation:group forKey:nil];
    
}

- (void)animationPushBackScaleDown {
	CABasicAnimation* scaleDown = [CABasicAnimation animationWithKeyPath:@"transform"];
	scaleDown.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.8, 0.8, 0.8)];
	scaleDown.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
	scaleDown.removedOnCompletion = YES;
    
	CABasicAnimation* opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
	opacity.fromValue = [NSNumber numberWithFloat:1.0f];
	opacity.toValue = [NSNumber numberWithFloat:0.4];
	opacity.removedOnCompletion = YES;
    
	CAAnimationGroup* group = [CAAnimationGroup animation];
	group.duration = 0.4;
	group.animations = [NSArray arrayWithObjects:scaleDown, opacity, nil];
    
	UIView* view = self.view;
	[view.layer addAnimation:group forKey:nil];
}



@end
