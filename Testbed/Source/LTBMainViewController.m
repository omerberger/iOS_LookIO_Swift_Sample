//
//  TravelocityMainViewController.m
//  tigertext
//
//  Created by Joseph Toscano on 8/20/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import "LTBMainViewController.h"
#import "LIOLookIOManager.h"

@implementation LTBMainViewController

@synthesize bookHotelsViewController, bookFlightsViewController;

- (void)loadView
{
    [super loadView];
    UIView *rootView = self.view;
    
    UIImageView *fakeImageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TravelocityMain"]] autorelease];
    fakeImageView.frame = rootView.bounds;
    fakeImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [rootView addSubview:fakeImageView];
    
    UIButton *flightsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    flightsButton.frame = CGRectMake(20, 70, 80, 80);
    flightsButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.33];
    [flightsButton addTarget:self action:@selector(flightsButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    [rootView addSubview:flightsButton];
    
    UIButton *hotelsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    hotelsButton.frame = CGRectMake(115, 70, 80, 80);
    hotelsButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.33];
    [hotelsButton addTarget:self action:@selector(hotelsButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    [rootView addSubview:hotelsButton];
    
    UIButton *helpButton = [UIButton buttonWithType:UIButtonTypeCustom];
    helpButton.frame = CGRectMake(25.0, self.view.frame.size.height - 60.0, 50.0, 55.0);
    helpButton.contentMode = UIViewContentModeCenter;
    [helpButton setBackgroundImage:[UIImage imageNamed:@"HelpButton"] forState:UIControlStateNormal];
    [helpButton addTarget:self action:@selector(helpButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    helpButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [rootView addSubview:helpButton];
    
    /*
     UIButton *twilioButton = [UIButton buttonWithType:UIButtonTypeCustom];
     twilioButton.frame = CGRectMake(100.0, self.view.frame.size.height - 60.0, 50.0, 55.0);
     twilioButton.contentMode = UIViewContentModeCenter;
     [twilioButton setBackgroundImage:[UIImage imageNamed:@"TalkButton"] forState:UIControlStateNormal];
     [twilioButton addTarget:self action:@selector(twilioButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
     [rootView addSubview:twilioButton];
     */
}

- (void)dealloc
{
    [bookHotelsViewController release];
    
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;//toInterfaceOrientation == UIInterfaceOrientationPortrait;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[LIOLookIOManager sharedLookIOManager] recordCurrentUILocation:@"Main Menu"];
}

#pragma mark -
#pragma mark UIControl actions

- (void)hotelsButtonWasTapped
{
    self.bookHotelsViewController = [[LTBBookHotelsViewController alloc] initWithNibName:nil bundle:nil];
    self.bookHotelsViewController.delegate = self;
    [[[UIApplication sharedApplication] keyWindow] addSubview:self.bookHotelsViewController.view];
}

- (void)flightsButtonWasTapped
{
    self.bookFlightsViewController = [[LTBBookFlightsViewController alloc] initWithNibName:nil bundle:nil];
    self.bookFlightsViewController.delegate = self;
    [self presentModalViewController:self.bookFlightsViewController animated:YES];
    //[[[UIApplication sharedApplication] keyWindow] addSubview:self.bookFlightsViewController.view];
}

- (void)helpButtonWasTapped
{
    [[LIOLookIOManager sharedLookIOManager] beginSession];
}

#pragma mark -
#pragma mark LTBBookHotelsViewControllerDelegate methods

- (void)bookHotelsViewControllerDidTapBackButton:(LTBBookHotelsViewController *)aController
{
    [bookHotelsViewController.view removeFromSuperview];
    self.bookHotelsViewController = nil;
}

#pragma mark -
#pragma mark LTBBookFlightsViewControllerDelegate methods

- (void)bookFlightsViewControllerDidTapBackButton:(LTBBookFlightsViewController *)aController
{
    //[bookFlightsViewController.view removeFromSuperview];
    [self dismissModalViewControllerAnimated:YES];
    self.bookFlightsViewController = nil;
}

@end
