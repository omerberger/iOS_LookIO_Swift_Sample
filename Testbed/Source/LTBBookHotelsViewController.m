//
//  LTBBookHotelsViewController.m
//  tigertext
//
//  Created by Joseph Toscano on 8/20/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import "LTBBookHotelsViewController.h"

@implementation LTBBookHotelsViewController

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
    UIImageView *fakeImageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TravelocityHotelDetail"]] autorelease];
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
    [delegate bookHotelsViewControllerDidTapBackButton:self];
}

@end
