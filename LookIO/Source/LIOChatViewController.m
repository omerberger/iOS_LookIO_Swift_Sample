//
//  LIOChatViewController.m
//  LookIO
//
//  Created by Joe Toscano on 8/27/11.
//  Copyright 2011 LookIO, Inc. All rights reserved.
//

#import "LIOChatViewController.h"
#import "LIOChatboxView.h"

@implementation LIOChatViewController

- (void)loadView
{
    [super loadView];
    UIView *rootView = self.view;
    
    backgroundView = [[UIView alloc] initWithFrame:rootView.bounds];
    backgroundView.backgroundColor = [UIColor blackColor];
    backgroundView.alpha = 0.33;
    [rootView addSubview:backgroundView];
    
    scrollView = [[UIScrollView alloc] initWithFrame:rootView.bounds];
    [rootView addSubview:scrollView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    messageViews = [[NSMutableArray alloc] init];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    [messageViews release];
    messageViews = nil;
}

- (void)dealloc
{
    [backgroundView release];
    [scrollView release];
    [messageViews release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self reloadMessages];
}

- (void)addMessage:(NSString *)aMessage animated:(BOOL)animated
{
    CGRect aFrame = CGRectMake(10.0, 0.0, self.view.frame.size.width - 20.0, 75.0);
    
    LIOChatboxView *newMessage = [[[LIOChatboxView alloc] initWithFrame:aFrame] autorelease];
    newMessage.messageView.text = aMessage;
    [messageViews addObject:newMessage];
}

- (void)addMessages:(NSArray *)messages
{
    for (NSString *aMessage in messages)
        [self addMessage:aMessage animated:NO];
    
    [self reloadMessages];
}

- (void)reloadMessages
{
    CGSize contentSize = CGSizeMake(scrollView.frame.size.width, 0.0);
    
    
}

@end
