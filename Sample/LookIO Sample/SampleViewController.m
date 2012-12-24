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

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
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
    for (int i=0; i<10; i++)
        [[LIOLookIOManager sharedLookIOManager] reportEvent:kLPEventPageView withData:[NSNumber numberWithInt:i]];
    
    int64_t delayInSeconds = 5.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [[LIOLookIOManager sharedLookIOManager] reportEvent:kLPEventAddedToCart withData:@"42"];
    });
    
    //[[LIOLookIOManager sharedLookIOManager] addSessionExtras:[NSDictionary dictionaryWithObject:@"12345abcdefgskdjgskdjg" forKey:@"nonsense"]];
    /*
    NSString *badPointer = (NSString *)0xcafebabe;
    [badPointer length];
     */
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

- (id)lookIOManager:(LIOLookIOManager *)aManager linkViewForURL:(NSURL *)aURL
{
    return @"lol";
}

/*
- (NSString *)lookIOManagerControlEndpointOverride:(LIOLookIOManager *)aManager
{
    return @"199.192.241.221:8800";
}
*/

@end
