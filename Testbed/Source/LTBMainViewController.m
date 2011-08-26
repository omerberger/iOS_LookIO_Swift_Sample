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

@synthesize bookHotelsViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
        UIImageView *fakeImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TravelocityMain"]];
        [self.view addSubview:fakeImageView];
        
        UIButton *flightsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        flightsButton.frame = CGRectMake(20, 70, 80, 80);
        flightsButton.backgroundColor = [UIColor clearColor];
        [flightsButton addTarget:self action:@selector(flightsButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:flightsButton];
        
        UIButton *hotelsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        hotelsButton.frame = CGRectMake(115, 70, 80, 80);
        hotelsButton.backgroundColor = [UIColor clearColor];
        [hotelsButton addTarget:self action:@selector(hotelsButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:hotelsButton];
        
        UIButton *helpButton = [UIButton buttonWithType:UIButtonTypeCustom];
        helpButton.frame = CGRectMake(25.0, self.view.frame.size.height - 60.0, 50.0, 55.0);
        helpButton.contentMode = UIViewContentModeCenter;
        [helpButton setBackgroundImage:[UIImage imageNamed:@"HelpButton"] forState:UIControlStateNormal];
        [helpButton addTarget:self action:@selector(helpButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:helpButton];
        
        /*
        UIButton *twilioButton = [UIButton buttonWithType:UIButtonTypeCustom];
        twilioButton.frame = CGRectMake(100.0, self.view.frame.size.height - 60.0, 50.0, 55.0);
        twilioButton.contentMode = UIViewContentModeCenter;
        [twilioButton setBackgroundImage:[UIImage imageNamed:@"TalkButton"] forState:UIControlStateNormal];
        [twilioButton addTarget:self action:@selector(twilioButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:twilioButton];
         */
    }
    
    return self;
}

- (void)hotelsButtonWasTapped
{
    self.bookHotelsViewController = [[LTBBookHotelsViewController alloc] initWithNibName:nil bundle:nil];
    self.bookHotelsViewController.delegate = self;
}

- (void)helpButtonWasTapped
{
    [[LIOLookIOManager sharedLookIOManager] beginConnecting];
}

#pragma mark -
#pragma mark LTBBookHotelsViewControllerDelegate methods

- (void)bookHotelsViewControllerDidTapBackButton:(LTBBookHotelsViewController *)aController
{
    [bookHotelsViewController.view removeFromSuperview];
    self.bookHotelsViewController = nil;
}

@end
