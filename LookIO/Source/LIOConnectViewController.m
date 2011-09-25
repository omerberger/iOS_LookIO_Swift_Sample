//
//  LIOConnectViewController.m
//  LookIO
//
//  Created by Joe Toscano on 8/30/11.
//  Copyright 2011 LookIO, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "LIOConnectViewController.h"
#import "LIOLookIOManager.h"

@implementation LIOConnectViewController

@synthesize delegate, targetLogoBoundsForHiding, targetLogoCenterForHiding, connectionLabel;

- (void)loadView
{
    [super loadView];
    UIView *rootView = self.view;
    
    connectionBackground = [[UIView alloc] initWithFrame:rootView.bounds];
    connectionBackground.backgroundColor = [UIColor blackColor];
    connectionBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [rootView addSubview:connectionBackground];
    
    UIImage *logoImage = [UIImage imageNamed:@"LookIOLogo"];
    connectionLogo = [[UIImageView alloc] initWithImage:logoImage];
    connectionLogo.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [rootView addSubview:connectionLogo];
    
    connectionSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [connectionSpinner startAnimating];
    [connectionLogo addSubview:connectionSpinner];
    
    Class $UIGlassButton = NSClassFromString(@"UIGlassButton");
    
    cancelButton = [[$UIGlassButton alloc] initWithFrame:CGRectZero];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton sizeToFit];
    [cancelButton addTarget:self action:@selector(cancelButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    CGRect aFrame = [cancelButton frame];
    aFrame.origin.x = 10.0;
    if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom]) aFrame.origin.x = 75.0;
    aFrame.origin.y = (rootView.frame.size.height / 2.0) - (aFrame.size.height / 2.0);
    [cancelButton setFrame:aFrame];
    [cancelButton setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
    [rootView addSubview:(UIView *)cancelButton];
    
    hideButton = [[$UIGlassButton alloc] initWithFrame:CGRectZero];
    [hideButton setTitle:@"Hide" forState:UIControlStateNormal];
    [hideButton sizeToFit];
    [hideButton addTarget:self action:@selector(hideButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    aFrame = [hideButton frame];
    aFrame.origin.x = rootView.frame.size.width - aFrame.size.width - 10.0;
    if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom]) aFrame.origin.x = rootView.frame.size.width - aFrame.size.width - 75.0;
    aFrame.origin.y = (rootView.frame.size.height / 2.0) - (aFrame.size.height / 2.0);
    [hideButton setFrame:aFrame];
    [hideButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
    [rootView addSubview:(UIView *)hideButton];
    
    if ([hideButton frame].size.width > [cancelButton frame].size.width)
    {
        CGRect newFrame = CGRectMake([cancelButton frame].origin.x,
                                     [cancelButton frame].origin.y,
                                     [hideButton frame].size.width,
                                     [cancelButton frame].size.height);
        [cancelButton setFrame:newFrame];
    }
    else
    {
        CGRect newFrame = CGRectMake([hideButton frame].origin.x,
                                     [hideButton frame].origin.y,
                                     [cancelButton frame].size.width,
                                     [hideButton frame].size.height);
        
        newFrame.origin.x = rootView.frame.size.width - newFrame.size.width - 10.0;
        if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom]) newFrame.origin.x = rootView.frame.size.width - newFrame.size.width - 75.0;
        
        [hideButton setFrame:newFrame];
    }
    
    connectionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    connectionLabel.text = @"jY";
    connectionLabel.textColor = [UIColor whiteColor];
    connectionLabel.textAlignment = UITextAlignmentCenter;
    [connectionLabel sizeToFit];
    aFrame = connectionLabel.frame;
    aFrame.size.height = 32.0;
    aFrame.origin.y = (rootView.frame.size.height / 2.0) - (aFrame.size.height / 2.0);
    aFrame.size.width = rootView.frame.size.width;
    connectionLabel.frame = aFrame;
    connectionLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    connectionLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [rootView addSubview:connectionLabel];
    
    nameEntryBackground = [[UIView alloc] init];
    nameEntryBackground.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    nameEntryBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    nameEntryBackground.hidden = YES;
    [rootView addSubview:nameEntryBackground];
    
    nameEntryField = [[LIONiceTextField alloc] initWithFrame:CGRectZero];
    aFrame = nameEntryField.frame;
    aFrame.size.height = 29.0;
    nameEntryField.frame = aFrame;
    nameEntryField.placeholder = @"Please enter your name.";
    nameEntryField.font = [UIFont systemFontOfSize:14.0];
    //nameEntryField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    nameEntryField.delegate = self;
    nameEntryField.returnKeyType = UIReturnKeyDone;
    [nameEntryBackground addSubview:nameEntryField];
    
    UIImage *greenButtonImage = [UIImage imageNamed:@"LIOGreenButton"];
    greenButtonImage = [greenButtonImage stretchableImageWithLeftCapWidth:16 topCapHeight:13];
    
    nameEntrySendButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    [nameEntrySendButton setBackgroundImage:greenButtonImage forState:UIControlStateNormal];
    [nameEntrySendButton setTitle:@"Save" forState:UIControlStateNormal];
    nameEntrySendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    aFrame = nameEntrySendButton.frame;
    aFrame.size.width = 59.0;
    aFrame.size.height = 27.0;
    nameEntrySendButton.frame = aFrame;
    [nameEntrySendButton addTarget:self action:@selector(nameEntrySendButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    [nameEntryBackground addSubview:nameEntrySendButton];
}

- (void)dealloc
{
    [connectionLogo release];
    [hideButton release];
    [cancelButton release];
    [connectionSpinner release];
    [connectionLabel release];
    [connectionBackground release];
    [nameEntryField release];
    [nameEntryBackground release];
    [nameEntrySendButton release];
    
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
    
    [nameEntryField release];
    nameEntryField = nil;
    
    [nameEntryBackground release];
    nameEntryBackground = nil;
    
    [nameEntrySendButton release];
    nameEntrySendButton = nil;
}

- (void)showAnimated:(BOOL)animated
{
    connectionBackground.alpha = 0.0;
    
    CGSize targetSize = CGSizeMake(224.0, 224.0);
    if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom])
        targetSize = CGSizeMake(430.0, 430.0);
        
    // If in landscape mode, origin.x and origin.y must be swapped.
    // There's probably a better way to do this. D:!
    CGRect targetFrame = CGRectZero;
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
    {
        targetFrame = CGRectMake((self.view.frame.size.width / 2.0) - (targetSize.width / 2.0),
                                 (self.view.frame.size.height / 2.0) - (targetSize.height / 2.0),
                                 targetSize.width,
                                 targetSize.height);
    }
    else
    {
        targetFrame = CGRectMake((self.view.frame.size.height / 2.0) - (targetSize.height / 2.0),
                                 (self.view.frame.size.width / 2.0) - (targetSize.width / 2.0),
                                 targetSize.width,
                                 targetSize.height);
    }
    
    CGRect aFrame = connectionLabel.frame;
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
        aFrame.origin.y = targetFrame.origin.y - aFrame.size.height - 5.0;
    else
        aFrame.origin.y = targetFrame.origin.y + aFrame.size.height;
    connectionLabel.frame = aFrame;
    connectionLabel.alpha = 0.0;
    
    CGFloat spinnerSize = 64.0;
    if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom])
        spinnerSize = 128.0;
    
    connectionSpinner.frame = CGRectMake((targetFrame.size.width / 2.0) - (spinnerSize / 2.0),
                                         (targetFrame.size.height / 2.0) - (spinnerSize / 2.0),
                                         spinnerSize,
                                         spinnerSize);
    connectionSpinner.alpha = 0.0;
    
    connectionLogo.frame = CGRectZero;
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
        connectionLogo.center = CGPointMake(self.view.frame.size.width / 2.0, self.view.frame.size.height / 2.0);
    else
        connectionLogo.center = CGPointMake(self.view.frame.size.height / 2.0, self.view.frame.size.width / 2.0);
    
    [cancelButton setAlpha:0.0];
    [hideButton setAlpha:0.0];
    
    if (animated)
    {
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut)
                         animations:^{
                             connectionLogo.frame = targetFrame;
                             connectionLogo.alpha = 0.9;
                             connectionBackground.alpha = 0.33;
                             [cancelButton setAlpha:1.0];
                             [hideButton setAlpha:1.0];
                             connectionLabel.alpha = 1.0;
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
        [cancelButton setAlpha:1.0];
        [hideButton setAlpha:1.0];
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
                             connectionLogo.bounds = self.targetLogoBoundsForHiding;
                             connectionLogo.center = self.targetLogoCenterForHiding;
                             connectionSpinner.frame = CGRectMake(0.0, 0.0, self.targetLogoBoundsForHiding.size.width, self.targetLogoBoundsForHiding.size.height);
                             connectionLogo.alpha = 1.0;
                             connectionBackground.alpha = 0.0;
                             [cancelButton setAlpha:0.0];
                             [hideButton setAlpha:0.0];
                             connectionLabel.alpha = 0.0;
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

- (void)rejiggerNameEntryFieldLayout
{
    CGRect nameEntryFieldFrame = nameEntryField.frame;
    nameEntryFieldFrame.origin.y = -2.0;
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
    {
        if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom])
            nameEntryFieldFrame.size.width = self.view.frame.size.width * 0.5;
        else
            nameEntryFieldFrame.size.width = self.view.frame.size.width * 0.9;
        
        nameEntryFieldFrame.origin.x = (self.view.frame.size.width / 2.0) - (nameEntryFieldFrame.size.width / 2.0);
    }
    else
    {
        if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom])
            nameEntryFieldFrame.size.width = self.view.frame.size.height * 0.5;
        else
            nameEntryFieldFrame.size.width = self.view.frame.size.height * 0.9;
        
        nameEntryFieldFrame.origin.x = (self.view.frame.size.height / 2.0) - (nameEntryFieldFrame.size.width / 2.0);
    }
    nameEntryFieldFrame.size.width -= (nameEntrySendButton.frame.size.width * 1.4) - 15.0;
    nameEntryField.frame = nameEntryFieldFrame;
    
    CGRect aFrame = nameEntrySendButton.frame;
    aFrame.origin.x = nameEntryField.frame.origin.x + nameEntryField.frame.size.width + 7.5;
    nameEntrySendButton.frame = aFrame;
}

- (void)showNameEntryFieldAnimated:(BOOL)animated
{
    if (nameEntryShown)
        return;    
    
    CGRect connectionLabelFrame = connectionLabel.frame;
    connectionLabelFrame.origin.y -= connectionLabelFrame.size.height;
    
    [self rejiggerNameEntryFieldLayout];
    
    nameEntryField.hidden = NO;
    nameEntryField.alpha = 0.0;
    
    nameEntryBackground.hidden = NO;
    nameEntryBackground.alpha = 0.0;
    
    nameEntryBackground.frame = connectionLabel.frame;
    
    if (animated)
    {
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             connectionLabel.frame = connectionLabelFrame;
                             nameEntryField.alpha = 1.0;
                             nameEntryBackground.alpha = 1.0;
                         }
                         completion:nil];
    }
    else
    {
        connectionLabel.frame = connectionLabelFrame;
        nameEntryField.alpha = 1.0;
        nameEntryBackground.alpha = 1.0;
    }
    
    nameEntryShown = YES;
}

- (void)hideNameEntryFieldAnimated:(BOOL)animated
{
    if (NO == nameEntryShown)
        return;
    
    CGRect connectionLabelFrame = connectionLabel.frame;
    connectionLabelFrame.origin.y += connectionLabelFrame.size.height;
    
    if (animated)
    {
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             connectionLabel.frame = connectionLabelFrame;
                             nameEntryField.alpha = 0.0;
                             nameEntryBackground.alpha = 0.0;
                         }
                         completion:^(BOOL finished) {
                             nameEntryField.hidden = YES;
                             nameEntryBackground.hidden = YES;
                         }];
    }
    else
    {
        connectionLabel.frame = connectionLabelFrame;
        nameEntryField.hidden = YES;
        nameEntryBackground.hidden = YES;
    }
    
    nameEntryShown = NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return [[LIOLookIOManager sharedLookIOManager].supportedOrientations containsObject:[NSNumber numberWithInt:toInterfaceOrientation]];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self rejiggerNameEntryFieldLayout];
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

- (void)nameEntrySendButtonWasTapped
{
    if ([nameEntryField.text length])
    {
        [delegate connectViewController:self didEnterFriendlyName:nameEntryField.text];
        [self hideNameEntryFieldAnimated:YES];
        nameEntryField.text = [NSString string];
    }
    
    [self.view endEditing:YES];
}

#pragma mark -
#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([textField.text length])
    {
        [delegate connectViewController:self didEnterFriendlyName:textField.text];
        [self hideNameEntryFieldAnimated:YES];
        textField.text = [NSString string];
    }
    
    [self.view endEditing:YES];
    
    return NO;
}

@end
