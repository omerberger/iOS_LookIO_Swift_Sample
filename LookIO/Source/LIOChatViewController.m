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
#import "LIOLookIOManager.h"

#define LIOChatViewControllerChatboxMinHeight  100.0
#define LIOChatViewControllerChatboxPadding     10.0

#define LIOChatViewControllerMaxHistoryLength   10

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
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
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
    
    [settingsActionSheet release];
    settingsActionSheet = nil;
}

- (void)dealloc
{
    [backgroundView release];
    [scrollView release];
    [messageViews release];
    [dismissalButton release];
    [settingsActionSheet release];
    
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

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [settingsActionSheet dismissWithClickedButtonIndex:2742 animated:NO];
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
    NSUInteger count = [textMessages count];
    if (count > LIOChatViewControllerMaxHistoryLength)
        textMessages = [textMessages subarrayWithRange:NSMakeRange(count - LIOChatViewControllerMaxHistoryLength, LIOChatViewControllerMaxHistoryLength)];
    
    for (NSString *aMessage in textMessages)
    {
        CGRect aFrame = CGRectMake(10.0, 0.0, self.view.bounds.size.width - 20.0, LIOChatViewControllerChatboxMinHeight);
        if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom])
        {
            if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
                aFrame = CGRectMake(228.0, 0.0, 598.0, LIOChatViewControllerChatboxMinHeight);
            else
                aFrame = CGRectMake(100.0, 0.0, 568.0, LIOChatViewControllerChatboxMinHeight);
        }
        LIOChatboxView *newChatbox = [[[LIOChatboxView alloc] initWithFrame:aFrame] autorelease];
        [newChatbox populateMessageViewWithText:aMessage];
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
    
    [self scrollToBottom];
    
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
            if (savedChat)
                aChatbox.inputField.text = savedChat;
            
            //if (hadFocus)
                [aChatbox.inputField becomeFirstResponder];
            
            [aChatbox switchToMode:LIOChatboxViewModeFull];
        }
    }
}

- (void)scrollToBottom
{
    /*
    [scrollView scrollRectToVisible:CGRectMake(0.0, scrollView.contentSize.height - LIOChatViewControllerChatboxMinHeight, scrollView.frame.size.width, 
     LIOChatViewControllerChatboxMinHeight) animated:YES];
     */

    static int numScrolls = 0;
    
    if (numScrolls < 2)
    {
        numScrolls++;
        return;
    }
    
    [UIView animateWithDuration:0.33 animations:^{
        scrollView.contentOffset = CGPointMake(0.0, scrollView.contentSize.height - scrollView.frame.size.height);
    }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return [[LIOLookIOManager sharedLookIOManager].supportedOrientations containsObject:[NSNumber numberWithInt:toInterfaceOrientation]];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self reloadMessages];
}

- (void)showSettingsMenu
{
    [self.view endEditing:YES];
    
    endSessionIndex = 0;
    endSharingIndex = NSNotFound;
    emailIndex = NSNotFound;
    NSUInteger cancelIndex = 1;
    
    if ([[LIOLookIOManager sharedLookIOManager] screenshotsAllowed])
        endSharingIndex = 1;

    if (endSharingIndex != NSNotFound)
        emailIndex = 2;
    else
        emailIndex = 1;
    
    settingsActionSheet = [[UIActionSheet alloc] init];
    [settingsActionSheet addButtonWithTitle:@"End Session"];
    
    if (endSharingIndex != NSNotFound)
    {
        [settingsActionSheet addButtonWithTitle:@"End Screen Sharing"];
        cancelIndex++;
    }
    
    if (emailIndex != NSNotFound)
    {
        [settingsActionSheet addButtonWithTitle:@"Email Chat History"];
        cancelIndex++;
    }
    
    [settingsActionSheet addButtonWithTitle:@"Cancel"];
    
    [settingsActionSheet setDestructiveButtonIndex:endSessionIndex];
    settingsActionSheet.cancelButtonIndex = cancelIndex;
    [settingsActionSheet setDelegate:self];
    
    if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom])
    {
        LIOChatboxView *chatbox = [messageViews lastObject];
        CGRect aFrame = [chatbox.settingsButton frame];
        [settingsActionSheet showFromRect:aFrame inView:chatbox animated:YES];
    }
    else
        [settingsActionSheet showInView:self.view];
    
}

- (void)performDismissalAnimation
{
    CGAffineTransform newTransform = CGAffineTransformMakeScale(0.01, 0.01);
    
    [UIView animateWithDuration:0.33
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         scrollView.transform = newTransform;
                         self.view.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         if ([delegate respondsToSelector:@selector(chatViewControllerDidFinishDismissalAnimation:)])
                             [delegate chatViewControllerDidFinishDismissalAnimation:self];
                     }];
}

- (void)performRevealAnimation
{
    self.view.alpha = 0.0;
    scrollView.transform = CGAffineTransformMakeScale(0.01, 0.01);
    
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         scrollView.transform = CGAffineTransformIdentity;
                         self.view.alpha = 1.0;
                     }
                     completion:nil];
}

#pragma mark -
#pragma mark LIOChatboxView delegate methods

- (void)chatboxView:(LIOChatboxView *)aView didReturnWithText:(NSString *)aString
{
    if ([aString length])
    {
        [delegate chatViewControllerTypingDidStop:self];
        [delegate chatViewController:self didChatWithText:aString];
    }
    
    [self.view endEditing:YES];
}

- (void)chatboxViewDidTapSettingsButton:(LIOChatboxView *)aView
{
    [self showSettingsMenu];
}

- (void)chatboxViewDidTypeStuff:(LIOChatboxView *)aView
{
    NSUInteger currentTextLength = [aView.inputField.text length];
    if (0 == previousTextLength)
    {
        // "Typing" started.
        if (currentTextLength)
            [delegate chatViewControllerTypingDidStart:self];
    }
    else
    {
        if (0 == currentTextLength)
            [delegate chatViewControllerTypingDidStop:self];
    }
    
    previousTextLength = currentTextLength;
}

#pragma mark -
#pragma mark UIControl actions

- (void)dismissalButtonWasTapped
{
    [self.view endEditing:YES];
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
    if (endSessionIndex == buttonIndex)
    {
        [delegate chatViewControllerDidTapEndSessionButton:self];
    }
    else if (endSharingIndex == buttonIndex)
    {
        [delegate chatViewControllerDidTapEndScreenshotsButton:self];
    }
    else if (emailIndex == buttonIndex)
    {
        [delegate chatViewControllerDidTapEmailButton:self];
    }
    
    [settingsActionSheet autorelease];
    settingsActionSheet = nil;
}

@end
