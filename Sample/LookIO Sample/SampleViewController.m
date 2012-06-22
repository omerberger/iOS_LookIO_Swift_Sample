//
//  SampleViewController.m
//  LookIO Sample
//
//  Created by Marc Campbell on 1/15/12.
//  Copyright (c) 2012 Look.IO. All rights reserved.
//

#import "SampleViewController.h"
#import "LIOLookIOManager.h"

@implementation SampleViewController

@synthesize  availabilityLabel, liveHelpButton, webView;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [liveHelpButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];

    NSString *urlAddress = @"http://www.google.com";
    NSURL *url = [NSURL URLWithString:urlAddress];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [webView loadRequest:requestObj];
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
 //   if ([[LIOLookIOManager sharedLookIOManager]enabled]) {
        [availabilityLabel setText:@"Agents are available"];
        [liveHelpButton setEnabled:YES];
 //   } else {
 //       [availabilityLabel setText:@"Agents are not available"];
 //       [liveHelpButton setEnabled:NO];
 //   }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (IBAction)helpButtonSelected:(id)sender  
{
    [[LIOLookIOManager sharedLookIOManager]beginSession];
}

- (IBAction)crashButtonSelected:(id)sender
{
    NSString *badPointer = (NSString *)0xcafebabe;
    [badPointer length];
}
    
#pragma mark -
#pragma mark LookIO Delegate

- (void)lookIOManager:(LIOLookIOManager *)aManager didUpdateEnabledStatus:(BOOL)lookioIsEnabled
{
    if (lookioIsEnabled) {
        [availabilityLabel setText:@"Agents are available"];
        [liveHelpButton setEnabled:YES];
    } else {
        [availabilityLabel setText:@"Agents are not available"];
        [liveHelpButton setEnabled:NO];
    }
}

- (UIView *)lookIOManager:(LIOLookIOManager *)aManager linkViewForURL:(NSURL *)aURL
{
    UIView *fakeView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)] autorelease];
    fakeView.backgroundColor = [UIColor redColor];
    return fakeView;
}

- (NSString *)lookIOManagerControlEndpointOverride:(LIOLookIOManager *)aManager
{
    return @"199.192.241.221:8800";
}

@end
