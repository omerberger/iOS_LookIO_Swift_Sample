//
//  LTBBookFlightsViewController.m
//  Testbed
//
//  Created by Joe Toscano on 8/26/11.
//  Copyright 2011 LookIO, Inc. All rights reserved.
//

#import "LTBBookFlightsViewController.h"

@implementation LTBBookFlightsViewController

@synthesize delegate;

- (void)loadView
{
    [super loadView];
    UIView *rootView = self.view;
    
    UIView *blackView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, rootView.frame.size.width, rootView.frame.size.height)] autorelease];
    blackView.backgroundColor = [UIColor blackColor];
    [rootView addSubview:blackView];
    
    CGRect aFrame = CGRectMake(0, 0, rootView.frame.size.width, rootView.frame.size.height);
    UIScrollView *scrollView = [[[UIScrollView alloc] initWithFrame:aFrame] autorelease];
    UIImageView *fakeImageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TravelocityFlightDetail"]] autorelease];
    [scrollView addSubview:fakeImageView];
    scrollView.contentSize = CGSizeMake(rootView.frame.size.width, fakeImageView.image.size.height);
    [rootView addSubview:scrollView];
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.backgroundColor = [UIColor clearColor];
    backButton.frame = CGRectMake(0, 0, 70, 30);
    [backButton addTarget:self action:@selector(backButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    [rootView addSubview:backButton];
}

- (void)dealloc
{
    [super dealloc];
}

- (void)backButtonWasTapped
{
    [delegate bookFlightsViewControllerDidTapBackButton:self];
}

@end
