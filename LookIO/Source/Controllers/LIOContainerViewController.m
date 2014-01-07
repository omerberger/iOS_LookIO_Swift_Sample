//
//  LIOContainerViewController.m
//  LookIO
//
//  Created by Yaron Karasik on 12/9/13.
//
//

#import "LIOContainerViewController.h"

#import "LIOHeaderBarView.h"
#import "LIOBlurImageView.h"

#import "LIOBundleManager.h"

#import "LIOChatViewController.h"
#import "LPSurveyViewController.h"
#import "LIOLoadingViewController.h"

#define LIOContainerViewControllerAlertViewNextStepDismiss 2001

@interface LIOContainerViewController () <LIOChatViewControllerDelegate, LPSurveyViewControllerDelegate, LIOLoadingViewControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) LIOHeaderBarView *headerBarView;
@property (nonatomic, assign) LIOHeaderBarState headerBarState;
@property (nonatomic, assign) CGFloat statusBarInset;

@property (nonatomic, assign) LIOContainerViewState containerViewState;
@property (nonatomic, strong) UIViewController *currentViewController;
@property (nonatomic, strong) LIOChatViewController *chatViewController;
@property (nonatomic, strong) LIOLoadingViewController *loadingViewController;
@property (nonatomic, strong) LPSurveyViewController *surveyViewController;

@property (nonatomic, strong) LIOEngagement *engagement;

@property (nonatomic, strong) LIOBlurImageView *blurImageView;

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

#pragma mark -
#pragma mark HeaderBarView Methods

- (void)presentHeaderBarView:(BOOL)animated
{
    CGRect headerBarFrame = self.headerBarView.frame;
    headerBarFrame.origin.y = 0;
    
    CGRect contentViewFrame = self.contentView.frame;
    contentViewFrame.origin.x = 0;
    contentViewFrame.origin.y = headerBarFrame.size.height;
    contentViewFrame.size.height = self.view.bounds.size.height - headerBarFrame.size.height;
    
    self.headerBarState = LIOHeaderBarStateVisible;
    if (animated)
    {
        [UIView animateWithDuration:0.3 animations:^{
            self.headerBarView.frame = headerBarFrame;
            self.contentView.frame = contentViewFrame;
        }];
    }
    else
    {
        self.headerBarView.frame = headerBarFrame;
        self.contentView.frame = contentViewFrame;
    }
}

- (void)dismissHeaderBarView:(BOOL)animated withState:(LIOHeaderBarState)state
{
    CGRect headerBarFrame = self.headerBarView.frame;
    headerBarFrame.origin.y = -headerBarFrame.size.height;
    
    CGRect contentViewFrame = self.contentView.frame;
    contentViewFrame.origin.x = 0;
    contentViewFrame.origin.y = self.statusBarInset;
    contentViewFrame.size.height = self.view.bounds.size.height - self.statusBarInset;
    
    self.headerBarState = state;
    if (animated)
    {
        [UIView animateWithDuration:0.3 animations:^{
            self.headerBarView.frame = headerBarFrame;
            self.contentView.frame = contentViewFrame;
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
    if (LIOContainerViewStateChat == self.containerViewState)
    {
        [self.headerBarView revealNotificationString:notification withAnimatedKeyboard:NO permanently:NO];
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
        [self dismiss];
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
    [self.chatViewController engagement:self.engagement didReceiveMessage:message];
}

- (void)presentLoadingViewController
{
    self.containerViewState = LIOContainerViewStateLoading;
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
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
        [self presentHeaderBarView:YES];
    else
        self.headerBarState = LIOHeaderBarStateLandscapeHidden;
    [self presentSurveyViewControllerWithSurvey:self.engagement.postchatSurvey animated:YES];
}

- (void)presentSurveyViewControllerWithSurvey:(LIOSurvey *)survey animated:(BOOL)animated
{
    self.surveyViewController = [[LPSurveyViewController alloc] initWithSurvey:survey];
    self.surveyViewController.delegate = self;
    self.containerViewState = LIOContainerViewStateSurvey;
    [self swapCurrentControllerWith:self.surveyViewController animated:animated];
}

#pragma mark -
#pragma mark SurveyViewControllerDelegate Methods

- (void)surveyViewController:(LPSurveyViewController *)surveyViewController didCancelSurvey:(LIOSurvey *)survey
{
    [self dismiss];
}

- (void)surveyViewController:(LPSurveyViewController *)surveyViewController didCompleteSurvey:(LIOSurvey *)survey
{
    [self.engagement submitSurvey:survey];

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
}

- (void)showSurveySubmissionAlert
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOSurveyView.SubmitOfflineSurveyAlertTitle")
                                                        message:LIOLocalizedString(@"LIOSurveyView.SubmitOfflineSurveyAlertBody")
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:LIOLocalizedString(@"LIOSurveyView.SubmitOfflineSurveyAlertButton"), nil];
    alertView.tag = LIOContainerViewControllerAlertViewNextStepDismiss;
    [alertView show];
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

- (void)dismiss
{
    [UIView animateWithDuration:0.3 animations:^{
        self.blurImageView.alpha = 0.0;
        self.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.delegate containerViewControllerDidDismiss:self];
        self.containerViewState = LIOContainerViewStateLoading;
        [self swapCurrentControllerWith:self.loadingViewController animated:NO];
        [self dismissHeaderBarView:NO withState:LIOHeaderBarStateHidden];
    }];
}

#pragma mark -
#pragma mark Status Bar Inset Methods

- (void)setupStatusBarInset
{
    self.statusBarInset = 20.0;
}

#pragma mark -
#pragma mark Rotation Methods

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation) && LIOHeaderBarStateVisible == self.headerBarState)
        [self dismissHeaderBarView:NO withState:LIOHeaderBarStateLandscapeHidden];
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation) && LIOHeaderBarStateLandscapeHidden == self.headerBarState)
        [self presentHeaderBarView:NO];
}


#pragma mark -
#pragma mark View Controller Lifecycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupStatusBarInset];
    
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
    self.headerBarState = LIOHeaderBarStateHidden;
    [self.view addSubview:self.headerBarView];
    
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
}

@end
