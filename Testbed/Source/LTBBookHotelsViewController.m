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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
        CGRect aFrame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:aFrame];
        UIImageView *fakeImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TravelocityHotelDetail"]];
        [scrollView addSubview:fakeImageView];
        scrollView.contentSize = CGSizeMake(self.view.frame.size.width, fakeImageView.image.size.height);
        [self.view addSubview:scrollView];
        
        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        backButton.backgroundColor = [UIColor clearColor];
        backButton.frame = CGRectMake(0, 0, 70, 30);
        [backButton addTarget:self action:@selector(backButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:backButton];
    }
    
    return self;
}

- (void)backButtonWasTapped
{
    [delegate bookHotelsViewControllerDidTapBackButton:self];
}

@end
