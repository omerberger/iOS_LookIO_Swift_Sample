//
//  LIOChatViewController.m
//  LookIO
//
//  Created by Joe Toscano on 8/27/11.
//  Copyright 2011 LookIO, Inc. All rights reserved.
//

#import "LIOChatViewController.h"
#import "LIOChatboxView.h"

#define LIOChatViewControllerChatboxHeight  85.0
#define LIOChatViewControllerChatboxPadding 10.0

@implementation LIOChatViewController

@synthesize delegate;

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
    
    dismissalButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    [dismissalButton addTarget:self action:@selector(dismissalButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:dismissalButton];
    
    endSessionButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
    [endSessionButton setTitle:@"End Session" forState:UIControlStateNormal];
    [endSessionButton addTarget:self action:@selector(endSessionButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    [endSessionButton sizeToFit];
    CGRect aFrame = endSessionButton.frame;
    aFrame.origin.y = rootView.bounds.size.height - aFrame.size.height - 5.0;
    aFrame.origin.x = (rootView.bounds.size.width / 2.0) - (aFrame.size.width / 2.0);
    endSessionButton.frame = aFrame;
    [rootView addSubview:endSessionButton];
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
    
    [backgroundView release];
    backgroundView = nil;
    
    [scrollView release];
    scrollView = nil;
    
    [dismissalButton release];
    dismissalButton = nil;
}

- (void)dealloc
{
    [backgroundView release];
    [scrollView release];
    [messageViews release];
    [dismissalButton release];
    
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
    CGRect aFrame = CGRectMake(10.0, 0.0, self.view.frame.size.width - 20.0, LIOChatViewControllerChatboxHeight);
    
    LIOChatboxView *newMessage = [[[LIOChatboxView alloc] initWithFrame:aFrame] autorelease];
    newMessage.messageView.text = aMessage;
    [messageViews addObject:newMessage];
    [scrollView addSubview:newMessage];
}

- (void)addMessages:(NSArray *)messages
{
    for (NSString *aMessage in messages)
        [self addMessage:aMessage animated:NO];
    
    [self reloadMessages];
}

- (void)reloadMessages
{
    CGFloat contentHeight = ([messageViews count] - 1) * (LIOChatViewControllerChatboxHeight + LIOChatViewControllerChatboxPadding);
    CGSize contentSize = CGSizeMake(scrollView.frame.size.width, scrollView.frame.size.height + contentHeight);
    scrollView.contentSize = contentSize;
    
    CGRect buttonFrame = CGRectZero;
    buttonFrame.origin.x = 0.0;
    buttonFrame.size.width = self.view.frame.size.width;
    buttonFrame.origin.y = contentHeight;
    buttonFrame.size.height = contentSize.height - contentHeight;
    dismissalButton.frame = buttonFrame;
    
    for (int i=0; i<[messageViews count]; i++)
    {
        LIOChatboxView *aChatbox = [messageViews objectAtIndex:i];
        CGRect aFrame = aChatbox.frame;
        aFrame.origin.y = LIOChatViewControllerChatboxPadding + ((LIOChatViewControllerChatboxHeight + LIOChatViewControllerChatboxPadding) * i);
        aChatbox.frame = aFrame;
        aChatbox.canTakeInput = i == [messageViews count] - 1;
        aChatbox.delegate = aChatbox.canTakeInput ? self : nil;
    }
}

- (void)scrollToBottom
{
    [scrollView scrollRectToVisible:CGRectMake(0.0, scrollView.contentSize.height - LIOChatViewControllerChatboxHeight, scrollView.frame.size.width, LIOChatViewControllerChatboxHeight) animated:YES];
}

#pragma mark -
#pragma mark LIOChatboxView delegate methods

- (void)chatboxViewDidReturn:(LIOChatboxView *)aView withText:(NSString *)aString
{
    if ([aString length])
        [delegate chatViewController:self didChatWithText:aString];
    
    [self.view endEditing:YES];
}

#pragma mark -
#pragma mark UIControl actions

- (void)dismissalButtonWasTapped
{
    [delegate chatViewControllerWasDismissed:self];
}

- (void)endSessionButtonWasTapped
{
    [delegate chatViewControllerDidTapEndSessionButton:self];
}

@end
