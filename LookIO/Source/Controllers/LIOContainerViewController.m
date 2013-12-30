//
//  LIOContainerViewController.m
//  LookIO
//
//  Created by Yaron Karasik on 12/9/13.
//
//

#import "LIOContainerViewController.h"

#import "LIOChatViewController.h"
#import "LIOHeaderBarView.h"

#import "LIOBlurImageView.h"

@interface LIOContainerViewController () <LIOChatViewControllerDelegate>

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) LIOHeaderBarView *headerBarView;
@property (nonatomic, assign) LIOHeaderBarState headerBarState;
@property (nonatomic, assign) CGFloat statusBarInset;

@property (nonatomic, strong) LIOChatViewController *chatViewController;
@property (nonatomic, strong) UIViewController *loadingViewController;
@property (nonatomic, strong) UIViewController *currentViewController;

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
    headerBarFrame.origin.y = self.statusBarInset;
    
    CGRect contentViewFrame = self.contentView.frame;
    contentViewFrame.origin.x = 0;
    contentViewFrame.origin.y = LIOHeaderBarViewDefaultHeight + self.statusBarInset;
    contentViewFrame.size.height = self.view.bounds.size.height - LIOHeaderBarViewDefaultHeight - self.statusBarInset;
    
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

- (void)dismissHeaderBarView:(BOOL)animated
{
    CGRect headerBarFrame = self.headerBarView.frame;
    headerBarFrame.origin.y = -LIOHeaderBarViewDefaultHeight;
    
    CGRect contentViewFrame = self.contentView.frame;
    contentViewFrame.origin.x = 0;
    contentViewFrame.origin.y = self.statusBarInset;
    contentViewFrame.size.height = self.view.bounds.size.height - self.statusBarInset;
    
    self.headerBarState = LIOHeaderBarStateHidden;
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
    [self.headerBarView revealNotificationString:notification withAnimatedKeyboard:NO permanently:NO];
}

#pragma mark -
#pragma mark ChatViewController Delegate Methods

- (void)chatViewControllerDidDismissChat:(LIOChatViewController *)chatViewController
{
    [UIView animateWithDuration:0.3 animations:^{
        self.blurImageView.alpha = 0.0;
        self.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.delegate containerViewControllerDidDismiss:self];
        [self swapCurrentControllerWith:self.loadingViewController animated:NO];
        [self dismissHeaderBarView:NO];
    }];
}


- (void)presentChatForEngagement:(LIOEngagement *)anEngagement
{
    self.engagement = anEngagement;
    [self presentHeaderBarView:YES];
    [self presentChatViewController:YES];
}


- (void)engagement:(LIOEngagement *)engagement didReceiveMessage:(LIOChatMessage *)message;
{
    [self.chatViewController engagement:self didReceiveMessage:message];
}

- (void)presentChatViewController:(BOOL)animated
{
    [self.chatViewController setEngagement:self.engagement];
    [self swapCurrentControllerWith:self.chatViewController animated:animated];
}

#pragma mark -
#pragma mark Container View Controller Methods

- (void)swapCurrentControllerWith:(UIViewController*)viewController animated:(BOOL)animated
{
    [self.currentViewController willMoveToParentViewController:nil];
    [self addChildViewController:viewController];
    
    if (animated)
    {
        CGRect frame = viewController.view.frame;
        frame.origin.y = -frame.size.height;
        viewController.view.frame = frame;
        
        [self transitionFromViewController:self.currentViewController toViewController:viewController
                                  duration:0.3 options:nil
                                animations:^{
                                    viewController.view.frame = self.contentView.bounds;
                                    
                                    CGRect frame = self.currentViewController.view.frame;
                                    frame.origin.y = frame.size.height;
                                    self.currentViewController.view.frame = frame;
                                } completion:^(BOOL finished) {
                                    //Remove the old view controller
                                    [self.currentViewController removeFromParentViewController];
                                    [self.currentViewController.view removeFromSuperview];
                                    
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
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
        [self dismissHeaderBarView:NO];
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation))
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
    
    self.headerBarView = [[LIOHeaderBarView alloc] initWithFrame:CGRectMake(0, -LIOHeaderBarViewDefaultHeight, self.view.bounds.size.width, LIOHeaderBarViewDefaultHeight)];
    self.headerBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.headerBarState = LIOHeaderBarStateHidden;
    [self.view addSubview:self.headerBarView];
    
    self.chatViewController = [[LIOChatViewController alloc] init];
    self.chatViewController.delegate = self;
    
    self.loadingViewController = [[UIViewController alloc] init];
    self.loadingViewController.view.backgroundColor = [UIColor redColor];

    [self addChildViewController:self.loadingViewController];
    self.loadingViewController.view.frame = self.contentView.bounds;
    [self.contentView addSubview:self.loadingViewController.view];
    self.currentViewController = self.loadingViewController;
    [self.loadingViewController didMoveToParentViewController:self];
}

@end
