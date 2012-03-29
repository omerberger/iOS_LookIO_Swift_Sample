//
//  LIOInterstitialViewController.m
//  LookIO
//
//  Created by Joseph Toscano on 3/28/12.
//  Copyright (c) 2012 LookIO, Inc. All rights reserved.
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
    bezel.layer.shadowColor = [UIColor whiteColor].CGColor;
    bezel.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    bezel.layer.shadowOpacity = 0.75;
    bezel.layer.shadowRadius = 4.0;
    CGRect aFrame = bezel.frame;
    aFrame.size.height = 75.0;
    aFrame.size.width = 200.0;
    aFrame.origin.x = (self.view.bounds.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = (self.view.bounds.size.height / 2.0) - (aFrame.size.height / 2.0);
    bezel.frame = aFrame;
    bezel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:bezel];
    
    UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
    aFrame = spinner.frame;
    aFrame.origin.x = (bezel.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = 18.0;
    spinner.frame = aFrame;
    [spinner startAnimating];
    [bezel addSubview:spinner];
    
    UILabel *label = [[[UILabel alloc] init] autorelease];
    label.font = [UIFont systemFontOfSize:16.0];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    label.text = @"One moment, please...";
    [label sizeToFit];
    aFrame = label.frame;
    aFrame.origin.x = (bezel.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = spinner.frame.origin.y + spinner.frame.size.height;
    label.frame = aFrame;
    [bezel addSubview:label];
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
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [timeoutTimer stopTimer];
    [timeoutTimer release];
    
    [bezel release];
    [background release];
    
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [delegate interstitialViewController:self shouldRotateToInterfaceOrientation:interfaceOrientation];
}

- (void)performRevealAnimation
{
    background.alpha = 0.0;
    bezel.transform = CGAffineTransformMakeScale(0.1, 0.1);
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         background.alpha = 1.0;
                     }];
    
    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         bezel.transform = CGAffineTransformMakeScale(1.2, 1.2);
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.25
                                               delay:0.0
                                             options:UIViewAnimationOptionCurveEaseInOut
                                          animations:^{
                                              bezel.transform = CGAffineTransformMakeScale(0.97, 0.97);
                                          }
                                          completion:^(BOOL finished) {
                                              [UIView animateWithDuration:0.15
                                                                    delay:0.0
                                                                  options:UIViewAnimationOptionCurveEaseIn
                                                               animations:^{
                                                                   bezel.transform = CGAffineTransformIdentity;
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
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Sorry, but the service is currently unavailable. Please try again later."
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Dismiss", nil];
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
