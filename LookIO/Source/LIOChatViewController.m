//
//  LIOChatViewController.m
//  LookIO
//
//  Created by Joe Toscano on 8/27/11.
//  Copyright 2011 LookIO, Inc. All rights reserved.
//

#import "LIOChatViewController.h"
#import "LIOChatboxView.h"
#import "LIONiceTextField.h"

#define LIOChatViewControllerChatboxMinHeight  100.0
#define LIOChatViewControllerChatboxPadding     10.0

@implementation LIOChatViewController

@synthesize delegate, dataSource;

- (void)loadView
{
    [super loadView];
    UIView *rootView = self.view;
    
    backgroundView = [[UIView alloc] initWithFrame:rootView.bounds];
    backgroundView.backgroundColor = [UIColor blackColor];
    backgroundView.alpha = 0.33;
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [rootView addSubview:backgroundView];
    
    scrollView = [[UIScrollView alloc] initWithFrame:rootView.bounds];
    scrollView.autoresizingMask = backgroundView.autoresizingMask;
    scrollView.backgroundColor = [UIColor clearColor];
    [rootView addSubview:scrollView];
    
    dismissalButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    [dismissalButton addTarget:self action:@selector(dismissalButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    //dismissalButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    dismissalButton.backgroundColor = [UIColor clearColor];
    [scrollView addSubview:dismissalButton];
    
    /*
    Class $UIGlassButton = NSClassFromString(@"UIGlassButton");
    
    endSessionButton = [[$UIGlassButton alloc] initWithFrame:CGRectZero];
    [endSessionButton setTitle:@"End Session" forState:UIControlStateNormal];
    [endSessionButton addTarget:self action:@selector(endSessionButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    [endSessionButton sizeToFit];
    CGRect aFrame = [endSessionButton frame];
    aFrame.origin.y = rootView.bounds.size.height - aFrame.size.height - 5.0;
    aFrame.origin.x = (rootView.bounds.size.width / 2.0) - (aFrame.size.width / 2.0);
    [endSessionButton setFrame:aFrame];
    [endSessionButton setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    [rootView addSubview:endSessionButton];
     */
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self reloadMessages];
}

- (void)reloadMessages
{
    // First check to see if the user has entered anything into the input field.    
    NSString *savedChat = nil;
    BOOL hadFocus = NO;
    if ([messageViews count])
    {
        LIOChatboxView *aView = [messageViews lastObject];
        hadFocus = [aView.inputField isFirstResponder];
        if ([aView.inputField.text length])
            savedChat = [[aView.inputField.text retain] autorelease];
        
        [self.view endEditing:YES];
    }    
    
    for (LIOChatboxView *aView in messageViews)
        [aView removeFromSuperview];
    
    [messageViews removeAllObjects];
    
    CGFloat contentHeight = LIOChatViewControllerChatboxPadding;
    NSArray *textMessages = [dataSource chatViewControllerChatMessages:self];
    for (NSString *aMessage in textMessages)
    {
        CGRect aFrame = CGRectMake(10.0, 0.0, self.view.bounds.size.width - 20.0, LIOChatViewControllerChatboxMinHeight);
        LIOChatboxView *newChatbox = [[[LIOChatboxView alloc] initWithFrame:aFrame] autorelease];
        [newChatbox populateMessageViewWithText:aMessage];
        //newChatbox.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [messageViews addObject:newChatbox];
        [scrollView addSubview:newChatbox];
        
        aFrame = newChatbox.frame;
        aFrame.origin.y = contentHeight;
        newChatbox.frame = aFrame;
        
        contentHeight += newChatbox.frame.size.height + LIOChatViewControllerChatboxPadding;
    }
    
    CGFloat lastChatboxHeight = 0.0;
    if ([messageViews count])
    {
        LIOChatboxView *lastChatbox = [messageViews lastObject];
        lastChatboxHeight = lastChatbox.frame.size.height;
    }

    /*
    NSUInteger count = 0;
    if ([messageViews count])
        count = [messageViews count] - 1;
    
    CGFloat contentHeight = count * (LIOChatViewControllerChatboxHeight + LIOChatViewControllerChatboxPadding);
    */
    contentHeight -= lastChatboxHeight + (LIOChatViewControllerChatboxPadding * 2.0);
    CGSize contentSize = contentSize = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height + contentHeight);
    scrollView.contentSize = contentSize;
    
    CGRect buttonFrame = CGRectZero;
    buttonFrame.origin.x = 0.0;
    buttonFrame.size.width = scrollView.frame.size.width;
    buttonFrame.origin.y = contentHeight;
    buttonFrame.size.height = scrollView.frame.size.height;
    dismissalButton.frame = buttonFrame;
    
    for (int i=0; i<[messageViews count]; i++)
    {
        LIOChatboxView *aChatbox = [messageViews objectAtIndex:i];
        BOOL canTakeInput = i == [messageViews count] - 1;
        aChatbox.delegate = canTakeInput ? self : nil;
        
        if (canTakeInput)
        {
            aChatbox.inputField.hidden = NO;
            aChatbox.sendButton.hidden = NO;
            [aChatbox.settingsButton setHidden:NO];
            
            if (savedChat)
                aChatbox.inputField.text = savedChat;
            
            if (hadFocus)
                [aChatbox.inputField becomeFirstResponder];
        }
        else
        {
            aChatbox.inputField.hidden = YES;
            aChatbox.sendButton.hidden = YES;
            [aChatbox.settingsButton setHidden:YES];
        }
    }
}

- (void)scrollToBottom
{
    [scrollView scrollRectToVisible:CGRectMake(0.0, scrollView.contentSize.height - LIOChatViewControllerChatboxMinHeight, scrollView.frame.size.width, LIOChatViewControllerChatboxMinHeight) animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self reloadMessages];
}

- (void)showSettingsMenu
{
    [self.view endEditing:YES];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"End Session"
                                                    otherButtonTitles:@"End Screen Sharing", @"E-Mail Chat History", nil];
    [actionSheet showInView:self.view];
    [actionSheet autorelease];
}

#pragma mark -
#pragma mark LIOChatboxView delegate methods

- (void)chatboxView:(LIOChatboxView *)aView didReturnWithText:(NSString *)aString
{
    if ([aString length])
        [delegate chatViewController:self didChatWithText:aString];
    
    [self.view endEditing:YES];
}

- (void)chatboxViewDidTapSettingsButton:(LIOChatboxView *)aView
{
    [self showSettingsMenu];
}

#pragma mark -
#pragma mark UIControl actions

- (void)dismissalButtonWasTapped
{
    [delegate chatViewControllerWasDismissed:self];
}

/*
- (void)endSessionButtonWasTapped
{
    [delegate chatViewControllerDidTapEndSessionButton:self];
}
*/
                                  
#pragma mark -
#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // 0 = end, 1 = end sharing, 2 = email, 3 = cancel
    switch (buttonIndex)
    {
        case 0:
        {
            [delegate chatViewControllerDidTapEndSessionButton:self];
            break;
        }
            
        case 1:
        {
            break;
        }
            
        case 2:
        {
            break;
        }
    }
}

@end
