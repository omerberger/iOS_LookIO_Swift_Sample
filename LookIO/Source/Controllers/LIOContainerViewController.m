//
//  LIOContainerViewController.m
//  LookIO
//
//  Created by Yaron Karasik on 12/9/13.
//
//

#import "LIOContainerViewController.h"

#import "LIOChatViewController.h"

#import "LIOBlurImageView.h"

@interface LIOContainerViewController () <LIOChatViewControllerDelegate>

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

#pragma mark ChatViewController Delegate Methods

- (void)chatViewControllerDidDismissChat:(LIOChatViewController *)chatViewController
{
    [UIView animateWithDuration:0.3 animations:^{
        self.blurImageView.alpha = 0.0;
        self.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.delegate containerViewControllerDidDismiss:self];
        [self swapCurrentControllerWith:self.loadingViewController animated:NO];
    }];
}


- (void)presentChatForEngagement:(LIOEngagement *)anEngagement
{
    self.engagement = anEngagement;
    [self presentChatViewController:YES];
}


- (void)chatViewController:(LIOChatViewController *)didDismissChat
{
    
}

- (void)presentChatViewController:(BOOL)animated
{
    [self.chatViewController setEngagement:self.engagement];
    [self swapCurrentControllerWith:self.chatViewController animated:animated];
}

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
                                    viewController.view.frame = self.view.bounds;
                                    
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
        viewController.view.frame = self.view.bounds;
        [self.currentViewController removeFromParentViewController];
        [self.currentViewController.view removeFromSuperview];
        
        [self.view addSubview:viewController.view];

        self.currentViewController = viewController;
        [self.currentViewController didMoveToParentViewController:self];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.blurImageView = [[LIOBlurImageView alloc] initWithFrame:self.view.bounds];
    self.blurImageView.alpha = 0.0;
    [self.view addSubview:self.blurImageView];
    
    self.chatViewController = [[LIOChatViewController alloc] init];
    self.chatViewController.delegate = self;
    
    self.loadingViewController = [[UIViewController alloc] init];
    self.loadingViewController.view.backgroundColor = [UIColor redColor];

    [self addChildViewController:self.loadingViewController];
    self.loadingViewController.view.frame = self.view.bounds;
    [self.view addSubview:self.loadingViewController.view];
    self.currentViewController = self.loadingViewController;
    [self.loadingViewController didMoveToParentViewController:self];
}



#pragma mark ChatViewController Delegate Methods

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
