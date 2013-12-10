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

@property (nonatomic, strong) LIOBlurImageView *blurImageView;

@end

@implementation LIOContainerViewController

- (void)setBlurImage:(UIImage *)image
{
    [self.blurImageView setImageAndBlur:image];
    [UIView animateWithDuration:0.3 animations:^{
        self.blurImageView.alpha = 1.0;
    } completion:^(BOOL finished) {
        [self presentChatViewController];
    }];
}

#pragma mark ChatViewController Delegate Methods

- (void)chatViewControllerDidDismissChat:(LIOChatViewController *)chatViewController
{
    [UIView animateWithDuration:0.3 animations:^{
        self.blurImageView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.delegate containerViewControllerDidDismiss:self];
    }];
}

- (void)viewDidAppear:(BOOL)animated
{

}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.blurImageView = [[LIOBlurImageView alloc] initWithFrame:self.view.bounds];
    self.blurImageView.alpha = 0.0;
    [self.view addSubview:self.blurImageView];
}

#pragma mark ChatViewController Delegate Methods

- (void)chatViewController:(LIOChatViewController *)didDismissChat
{
    
}

- (void)presentChatViewController
{
    self.chatViewController = [[LIOChatViewController alloc] init];
    self.chatViewController.delegate = self;
    [self addChildViewController:self.chatViewController];
    self.chatViewController.view.frame = self.view.bounds;
    [self.view addSubview:self.chatViewController.view];
    [self.chatViewController didMoveToParentViewController:self];    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
