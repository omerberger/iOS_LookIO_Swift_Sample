//
//  LIOInterstitialViewController.m
//  LookIO
//
//  Created by Joseph Toscano on 3/28/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import "LIOInterstitialViewController.h"
#import "LIOBundleManager.h"
#import <QuartzCore/QuartzCore.h>

@implementation LIOInterstitialViewController

@synthesize delegate;

- (void)loadView
{
    [super loadView];
    
    background = [[UIView alloc] initWithFrame:self.view.bounds];
    background.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.66];
    background.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:background];
    
    bezel = [[UIView alloc] init];
    bezel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:1.0];
    bezel.layer.cornerRadius = 6.0;
    //bezel.layer.masksToBounds = YES;
    /*
    bezel.layer.shadowColor = [UIColor whiteColor].CGColor;
    bezel.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    bezel.layer.shadowOpacity = 0.75;
    bezel.layer.shadowRadius = 1.0;
    */
    CGRect aFrame = bezel.frame;
    aFrame.size.height = 75.0;
    aFrame.size.width = 175.0;
    aFrame.origin.x = (self.view.bounds.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = (self.view.bounds.size.height / 2.0) - (aFrame.size.height / 2.0);
    bezel.frame = aFrame;
    bezel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:bezel];
    
    UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
    aFrame = spinner.frame;
    aFrame.origin.x = (bezel.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = 10.0;
    spinner.frame = aFrame;
    [spinner startAnimating];
    [bezel addSubview:spinner];
    
    UILabel *label = [[[UILabel alloc] init] autorelease];
    label.font = [UIFont systemFontOfSize:13.0];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    label.text = LIOLocalizedString(@"LIOInterstitialViewController.LoadingLabel");
    label.textAlignment = UITextAlignmentCenter;
    label.numberOfLines = 2;
    [label sizeToFit];
    aFrame = label.frame;
    aFrame.origin.x = (bezel.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = spinner.frame.origin.y + spinner.frame.size.height + 2.0;
    label.frame = aFrame;
    [bezel addSubview:label];
    
    dismissButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    dismissButton.layer.borderColor = [UIColor blackColor].CGColor;
    dismissButton.layer.borderWidth = 1.0;
    dismissButton.layer.cornerRadius = 7.0;
    dismissButton.layer.masksToBounds = YES;
    dismissButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
    [dismissButton setTitle:LIOLocalizedString(@"LIOInterstitialViewController.DismissButton") forState:UIControlStateNormal];
    [dismissButton addTarget:self action:@selector(dismissButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    aFrame = dismissButton.frame;
    aFrame.size.width = bezel.frame.size.width + 40.0;
    aFrame.size.height = 35.0;
    aFrame.origin.x = (self.view.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = bezel.frame.origin.y + bezel.frame.size.height + 15.0;
    dismissButton.frame = aFrame;
    dismissButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:dismissButton];
    
    // 119 -> 41
    CGColorRef startColor = [UIColor colorWithWhite:(150.0/255.0) alpha:0.75].CGColor;
    CGColorRef endColor = [UIColor colorWithWhite:(41.0/255.0) alpha:0.75].CGColor;
    CAGradientLayer *gradientLayer = [[[CAGradientLayer alloc] init] autorelease];
    gradientLayer.frame = dismissButton.bounds;
    gradientLayer.colors = [NSArray arrayWithObjects:(id)startColor, (id)endColor, nil];
    [dismissButton.layer insertSublayer:gradientLayer atIndex:0];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(bundleDownloadDidFinish:)
                                                 name:LIOBundleManagerBundleDownloadDidFinishNotification
                                               object:[LIOBundleManager sharedBundleManager]];
    
    timeoutTimer = [[LIOTimerProxy alloc] initWithTimeInterval:LIOInterstitialViewControllerTimeout
                                                        target:self
                                                      selector:@selector(timeoutTimerDidFire)];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [timeoutTimer stopTimer];
    [timeoutTimer release];
    timeoutTimer = nil;
    
    [bezel release];
    bezel = nil;
    
    [background release];
    background = nil;
    
    [dismissButton release];
    dismissButton = nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [timeoutTimer stopTimer];
    [timeoutTimer release];
    
    [bezel release];
    [background release];
    [dismissButton release];
    
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [delegate interstitialViewController:self shouldRotateToInterfaceOrientation:interfaceOrientation];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    dismissButton.hidden = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    CGRect aFrame = dismissButton.frame;
    aFrame.origin.x = (self.view.bounds.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = bezel.frame.origin.y + bezel.frame.size.height + 15.0;
    dismissButton.frame = aFrame;
    
    dismissButton.hidden = NO;
}

- (void)performRevealAnimation
{
    background.alpha = 0.0;
    bezel.transform = CGAffineTransformMakeScale(0.1, 0.1);
    dismissButton.transform = bezel.transform;
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         background.alpha = 1.0;
                     }];
    
    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         bezel.transform = CGAffineTransformMakeScale(1.2, 1.2);
                         dismissButton.transform = bezel.transform;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.25
                                               delay:0.0
                                             options:UIViewAnimationOptionCurveEaseInOut
                                          animations:^{
                                              bezel.transform = CGAffineTransformMakeScale(0.97, 0.97);
                                              dismissButton.transform = bezel.transform;
                                          }
                                          completion:^(BOOL finished) {
                                              [UIView animateWithDuration:0.15
                                                                    delay:0.0
                                                                  options:UIViewAnimationOptionCurveEaseIn
                                                               animations:^{
                                                                   bezel.transform = CGAffineTransformIdentity;
                                                                   dismissButton.transform = bezel.transform;
                                                               }
                                                               completion:^(BOOL finished) {
                                                               }];
                                          }];
                     }];
}

- (void)performDismissalAnimation
{
}

- (void)showFailureAlert
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOInterstitialViewController.ErrorAlertTitle")
                                                        message:LIOLocalizedString(@"LIOInterstitialViewController.ErrorAlertBody")
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:LIOLocalizedString(@"LIOInterstitialViewController.ErrorAlertButton"), nil];
    [alertView show];
    [alertView autorelease];
}

- (void)timeoutTimerDidFire
{
    [timeoutTimer stopTimer];
    [timeoutTimer release];
    timeoutTimer = nil;
    
    [self showFailureAlert];
}

#pragma mark -
#pragma mark UIControl actions

- (void)dismissButtonWasTapped
{
    [delegate interstitialViewControllerWasDismissed:self];
}

#pragma mark -
#pragma mark Notification handlers

- (void)bundleDownloadDidFinish:(NSNotification *)aNotification
{
    NSDictionary *userInfo = [aNotification userInfo];
    if (userInfo)
    {
        // The download did not succeed.
        [self showFailureAlert];
    }
    else
    {
        [delegate interstitialViewControllerWantsChatInterface:self];
    }
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [delegate interstitialViewControllerWasDismissed:self];
}

@end