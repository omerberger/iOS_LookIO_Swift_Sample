//
//  LIOConnectViewController.m
//  LookIO
//
//  Created by Joe Toscano on 8/30/11.
//  Copyright 2011 LookIO, Inc. All rights reserved.
//

#import "LIOConnectViewController.h"

@implementation LIOConnectViewController

@synthesize delegate, targetLogoFrameForHiding;

- (void)loadView
{
    [super loadView];
    UIView *rootView = self.view;
    
    connectionBackground = [[UIView alloc] initWithFrame:rootView.bounds];
    connectionBackground.backgroundColor = [UIColor blackColor];
    [rootView addSubview:connectionBackground];
    
    UIImage *logoImage = [UIImage imageNamed:@"LookIOLogo"];
    connectionLogo = [[UIImageView alloc] initWithImage:logoImage];
    [rootView addSubview:connectionLogo];
    
    connectionSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [connectionSpinner startAnimating];
    [connectionLogo addSubview:connectionSpinner];
    
    cancelButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton sizeToFit];
    [cancelButton addTarget:self action:@selector(cancelButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    CGRect aFrame = cancelButton.frame;
    aFrame.origin.x = 10.0;
    aFrame.origin.y = (rootView.frame.size.height / 2.0) - (aFrame.size.height / 2.0);
    cancelButton.frame = aFrame;
    [rootView addSubview:cancelButton];
    
    hideButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
    [hideButton setTitle:@"Hide" forState:UIControlStateNormal];
    [hideButton sizeToFit];
    [hideButton addTarget:self action:@selector(hideButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    aFrame = hideButton.frame;
    aFrame.origin.x = rootView.frame.size.width - aFrame.size.width - 10.0;
    aFrame.origin.y = (rootView.frame.size.height / 2.0) - (aFrame.size.height / 2.0);
    hideButton.frame = aFrame;
    [rootView addSubview:hideButton];
}

- (void)dealloc
{
    [connectionLogo release];
    [hideButton release];
    [cancelButton release];
    [connectionSpinner release];
    [connectionLabel release];
    [connectionBackground release];
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [connectionLogo release];
    connectionLogo = nil;
    
    [hideButton release];
    hideButton = nil;
    
    [cancelButton release];
    cancelButton = nil;
    
    [connectionSpinner release];
    connectionSpinner = nil;
    
    [connectionLabel release];
    connectionLabel = nil;
    
    [connectionBackground release];
    connectionBackground = nil;
}

- (void)showAnimated:(BOOL)animated
{
    connectionBackground.alpha = 0.0;
    
    CGSize targetSize = CGSizeMake(224.0, 224.0);
    CGRect targetFrame = CGRectMake((self.view.frame.size.width / 2.0) - (targetSize.width / 2.0),
                                    (self.view.frame.size.height / 2.0) - (targetSize.height / 2.0),
                                    targetSize.width,
                                    targetSize.height);
    
    CGFloat spinnerSize = 64.0;
    connectionSpinner.frame = CGRectMake((targetFrame.size.width / 2.0) - (spinnerSize / 2.0),
                                         (targetFrame.size.height / 2.0) - (spinnerSize / 2.0),
                                         spinnerSize,
                                         spinnerSize);
    connectionSpinner.alpha = 0.0;
    
    connectionLogo.frame = CGRectZero;
    connectionLogo.center = CGPointMake(self.view.frame.size.width / 2.0, self.view.frame.size.height / 2.0);
    
    cancelButton.alpha = 0.0;
    hideButton.alpha = 0.0;
    
    if (animated)
    {
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut)
                         animations:^{
                             connectionLogo.frame = targetFrame;
                             connectionLogo.alpha = 0.9;
                             connectionBackground.alpha = 0.33;
                             hideButton.alpha = 1.0;
                             cancelButton.alpha = 1.0;
                         }
                         completion:^(BOOL finished) {                    
                             connectionSpinner.alpha = 1.0;
                         }];
    }
    else
    {
        connectionLogo.frame = targetFrame;
        connectionLogo.alpha = 0.9;
        connectionBackground.alpha = 0.33;
        hideButton.alpha = 1.0;
        cancelButton.alpha = 1.0;
        connectionSpinner.alpha = 1.0;
    }
}

- (void)hideAnimated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseIn)
                         animations:^{
                             connectionLogo.frame = self.targetLogoFrameForHiding;
                             connectionSpinner.frame = CGRectMake(0.0, 0.0, self.targetLogoFrameForHiding.size.width, self.targetLogoFrameForHiding.size.height);
                             connectionLogo.alpha = 1.0;
                             connectionBackground.alpha = 0.0;
                             cancelButton.alpha = 0.0;
                             hideButton.alpha = 0.0;
                         }
                         completion:^(BOOL finished) {
                             [delegate connectViewControllerWasHidden:self];
                         }];
    }
    else
    {
        [delegate connectViewControllerWasHidden:self];
    }
}

#pragma mark -
#pragma mark UIControl actions

- (void)hideButtonWasTapped
{
    [delegate connectViewControllerDidTapHideButton:self];
}

- (void)cancelButtonWasTapped
{
    [delegate connectViewControllerDidTapCancelButton:self];
}

@end
