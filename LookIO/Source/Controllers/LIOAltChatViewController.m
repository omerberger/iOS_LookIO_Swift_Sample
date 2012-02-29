//
//  LIOAltChatViewController.m
//  LookIO
//
//  Created by Joseph Toscano on 12/5/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import "LIOAltChatViewController.h"
#import "LIOLookIOManager.h"
#import "LIOChatBubbleView.h"
#import "LIOChatMessage.h"
#import <QuartzCore/QuartzCore.h>
#import "LIOInputBarView.h"
#import "LIOHeaderBarView.h"
#import "LIOAboutViewController.h"

#define LIOAltChatViewControllerMaxHistoryLength   10
#define LIOAltChatViewControllerChatboxPadding     10.0
#define LIOAltChatViewControllerChatboxMinHeight   100.0

#define LIOAltChatViewControllerTableViewCellReuseId       @"LIOAltChatViewControllerTableViewCellReuseId"
#define LIOAltChatViewControllerTableViewCellBubbleViewTag 1001

@interface LIOAltChatViewController ()
- (void)reloadMessages;
@end

@implementation LIOAltChatViewController

@synthesize delegate, dataSource, initialChatText, agentTyping;

- (void)loadView
{
    [super loadView];
    
    if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom])
        background = [[UIImageView alloc] initWithImage:lookioImage(@"LIOAltChatBackgroundForiPad")];
    else
        background = [[UIImageView alloc] initWithImage:lookioImage(@"LIOAltChatBackgroundForiPhone")];
    
    background.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:background];
    
    tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.backgroundColor = [UIColor clearColor];
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    ((UIScrollView *)tableView).delegate = self;
    [self.view addSubview:tableView];
    
    UITapGestureRecognizer *tapper = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)] autorelease];
    [tableView addGestureRecognizer:tapper];
    
    CGRect aFrame = CGRectZero;
    aFrame.size.width = self.view.bounds.size.width;
    aFrame.size.height = 40.0;
    aFrame.origin.y = self.view.bounds.size.height - 40.0;
    
    inputBar = [[LIOInputBarView alloc] initWithFrame:aFrame];
    inputBar.delegate = self;
    inputBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:inputBar];
    
    aFrame = CGRectZero;
    aFrame.size.width = self.view.bounds.size.width;
    
    headerBar = [[LIOHeaderBarView alloc] initWithFrame:aFrame];
    headerBar.delegate = self;
    headerBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:headerBar];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [headerBar switchToMode:LIOHeaderBarViewModeMinimal animated:NO];
    
    CGRect aFrame = tableView.frame;
    aFrame.origin.y = 32.0;
    tableView.frame = aFrame;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [background release];
    background = nil;
    
    [tableView release];
    tableView = nil;
    
    [inputBar release];
    inputBar = nil;
    
    [headerBar release];
    headerBar = nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [background release];
    [tableView release];
    [pendingChatText release];
    [initialChatText release];
    [messages release];
    [headerBar release];
    
    inputBar.delegate = nil;
    [inputBar release];
    
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self reloadMessages];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    // Can't do this. Breaks stuff on 4.3 :(
    //[inputBar.inputField becomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [settingsActionSheet dismissWithClickedButtonIndex:2742 animated:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [delegate altChatViewController:self shouldRotateToInterfaceOrientation:interfaceOrientation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.view endEditing:YES];
    
//    id firstResponder = [[[UIApplication sharedApplication] keyWindow] firstResponder];
//    NSLog(@"\n\nfirstResponder: %@", firstResponder);
    
    [headerBar rejiggerLayout];
    [self reloadMessages];
    [tableView reloadData];
}

/*
- (void)performRevealAnimation
{
    CGRect targetFrame = backgroundView.frame;
    targetFrame.origin.x = self.view.bounds.size.width - backgroundView.frame.size.width - 10.0; // overshoot by 10
    targetFrame.size.width += 10.0;
    
    CGRect finalFrame = targetFrame;
    finalFrame.origin.x += 10.0;
    finalFrame.size.width -= 10.0;
    
    [UIView animateWithDuration:0.33
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         backgroundView.frame = targetFrame;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.1
                                               delay:0.0
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              backgroundView.frame = finalFrame;
                                          }
                                          completion:nil];
                     }];
}

- (void)performDismissalAnimation
{
    [delegate altChatViewControllerDidStartDismissalAnimation:self];
    
    CGRect targetFrame = backgroundView.frame;
    targetFrame.origin.x = self.view.bounds.size.width;
    
    [UIView animateWithDuration:0.33
                     animations:^{
                         backgroundView.frame = targetFrame;
                     }
                     completion:^(BOOL finished) {
                         [delegate altChatViewControllerDidFinishDismissalAnimation:self];
                     }];
}
*/

- (void)reloadMessages
{
    [messages release];
    messages = [[dataSource altChatViewControllerChatMessages:self] retain];
    
    [tableView reloadData];
    
    double delayInSeconds = 0.75;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSIndexPath *lastRow = [NSIndexPath indexPathForRow:([messages count] - 1) inSection:0];
        [tableView scrollToRowAtIndexPath:lastRow atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    });
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
    settingsActionSheet.accessibilityLabel = @"LIOSettingsActionSheet";
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
        [settingsActionSheet showFromRect:inputBar.settingsButton.frame inView:inputBar animated:YES];
    }
    else
        [settingsActionSheet showInView:self.view];
}

#pragma mark -
#pragma mark UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [messages count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *aCell = [tableView dequeueReusableCellWithIdentifier:LIOAltChatViewControllerTableViewCellReuseId];
    LIOChatBubbleView *aBubble = (LIOChatBubbleView *)[aCell viewWithTag:LIOAltChatViewControllerTableViewCellBubbleViewTag];
    if (nil == aCell)
    {
        aCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LIOAltChatViewControllerTableViewCellReuseId];
        aCell.selectionStyle = UITableViewCellSelectionStyleNone;
        [aCell autorelease];
        
        aBubble = [[LIOChatBubbleView alloc] initWithFrame:CGRectZero];
        aBubble.backgroundColor = [UIColor clearColor];
        [aCell addSubview:aBubble];
        aBubble.tag = LIOAltChatViewControllerTableViewCellBubbleViewTag;
    }
    
    LIOChatMessage *aMessage = [messages objectAtIndex:indexPath.row];
    if (LIOChatMessageKindLocal == aMessage.kind)
    {
        aBubble.formattingMode = LIOChatBubbleViewFormattingModeLocal;
        aBubble.tailDirection = LIOChatBubbleViewTailDirectionRight;
    }
    else
    {
        aBubble.formattingMode = LIOChatBubbleViewFormattingModeRemote;
        aBubble.tailDirection = LIOChatBubbleViewTailDirectionLeft;
    }
    
    [aBubble populateMessageViewWithText:aMessage.text];
    
    // Size of bubbles in mockup: 306x67
    if (LIOChatBubbleViewFormattingModeRemote == aBubble.formattingMode)
        aBubble.frame = CGRectMake(0.0, 0.0, 306.0, 67.0);
    else
        aBubble.frame = CGRectMake(aCell.contentView.frame.size.width - 306.0, 0.0, 306.0, 67.0);
    
    [aBubble setNeedsLayout];
    [aBubble setNeedsDisplay];
    
    return aCell;
}

#pragma mark -
#pragma mark UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LIOChatMessage *aMessage = [messages objectAtIndex:indexPath.row];
    
    CGSize maxSize = CGSizeMake(LIOChatBubbleViewMaxTextWidth, FLT_MAX);
    CGSize boxSize = [aMessage.text sizeWithFont:[UIFont systemFontOfSize:18.0] constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    
    CGFloat height = boxSize.height;
    if (height < LIOChatBubbleViewMinTextHeight) height = LIOChatBubbleViewMinTextHeight;
    
    return height + 10.0;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForFooterInSection:(NSInteger)section
{
    CGFloat heightOfLastBubble = [self tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:([messages count] - 1) inSection:section]];
    
    return self.view.bounds.size.height - heightOfLastBubble - 10.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footer = [[[UIView alloc] init] autorelease];
    footer.backgroundColor = [UIColor clearColor];
    return footer;
}

#pragma mark -
#pragma mark UIControl actions


#pragma mark -
#pragma mark Notification handlers  

- (void)keyboardWillShow:(NSNotification *)aNotification
{
    NSDictionary *userInfo = [aNotification userInfo];
    
    NSTimeInterval animationDuration;
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [animationDurationValue getValue:&animationDuration];
    
    UIViewAnimationCurve animationCurve;
    NSValue *animationCurveValue = [userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    [animationCurveValue getValue:&animationCurve];
    
    NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardBounds = [self.view.window convertRect:[keyboardBoundsValue CGRectValue] toView:self.view];
    
    CGFloat keyboardHeight = keyboardBounds.size.height;
    
    CGRect aFrame = inputBar.frame;
    aFrame.origin.y -= keyboardHeight;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
        inputBar.frame = aFrame;
    [UIView commitAnimations];
    
    [inputBar setNeedsLayout];
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
    NSDictionary *userInfo = [aNotification userInfo];
    
    NSTimeInterval animationDuration;
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [animationDurationValue getValue:&animationDuration];
    
    UIViewAnimationCurve animationCurve;
    NSValue *animationCurveValue = [userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    [animationCurveValue getValue:&animationCurve];
    
    NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardBounds = [self.view.window convertRect:[keyboardBoundsValue CGRectValue] toView:self.view];
    
    CGFloat keyboardHeight = keyboardBounds.size.height;
    
    CGRect aFrame = inputBar.frame;
    aFrame.origin.y += keyboardHeight;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
        inputBar.frame = aFrame;
    [UIView commitAnimations];
    
    [inputBar setNeedsLayout];
}

#pragma mark -
#pragma mark LIOInputBarViewDelegate methods

- (void)inputBarView:(LIOInputBarView *)aView didChangeNumberOfLines:(NSInteger)numLinesDelta
{
    CGFloat deltaHeight = aView.singleLineHeight * numLinesDelta;
    
    CGRect aFrame = inputBar.frame;
    aFrame.origin.y -= deltaHeight;
    inputBar.frame = aFrame;
}

- (void)inputBarViewDidTypeStuff:(LIOInputBarView *)aView
{
    NSUInteger currentTextLength = [aView.inputField.text length];
    if (0 == previousTextLength)
    {
        // "Typing" started.
        if (currentTextLength)
            [delegate altChatViewControllerTypingDidStart:self];
    }
    else
    {
        if (0 == currentTextLength)
            [delegate altChatViewControllerTypingDidStop:self];
    }
    
    previousTextLength = currentTextLength;
    
    [pendingChatText release];
    pendingChatText = [aView.inputField.text retain];
}

- (void)inputBarView:(LIOInputBarView *)aView didReturnWithText:(NSString *)aString
{
    if ([aString length])
    {
        [delegate altChatViewControllerTypingDidStop:self];
        [delegate altChatViewController:self didChatWithText:aString];
    }
    
    [pendingChatText release];
    pendingChatText = nil;
    
    [self.view endEditing:YES];
    
    [self reloadMessages];
}

- (void)inputBarViewDidTapSettingsButton:(LIOInputBarView *)aView
{
    [self showSettingsMenu];
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (endSessionIndex == buttonIndex)
    {
        [delegate altChatViewControllerDidTapEndSessionButton:self];
    }
    else if (endSharingIndex == buttonIndex)
    {
        [delegate altChatViewControllerDidTapEndScreenshotsButton:self];
    }
    else if (emailIndex == buttonIndex)
    {
        [delegate altChatViewControllerDidTapEmailButton:self];
    }
    
    [settingsActionSheet autorelease];
    settingsActionSheet = nil;
}

#pragma mark -
#pragma mark UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y < 0 && headerBar.mode != LIOHeaderBarViewModeFull)
    {
        [headerBar switchToMode:LIOHeaderBarViewModeFull animated:YES];
        
        CGRect aFrame = tableView.frame;
        aFrame.origin.y = 49.0;
        tableView.frame = aFrame;
    }
    else if (scrollView.contentOffset.y > 1 && headerBar.mode != LIOHeaderBarViewModeMinimal)
    {
        [headerBar switchToMode:LIOHeaderBarViewModeMinimal animated:YES];
        
        CGRect aFrame = tableView.frame;
        aFrame.origin.y = 32.0;
        tableView.frame = aFrame;
    }
}

#pragma mark -
#pragma mark LIOHeaderBarViewDelegate methods

- (void)headerBarViewAboutButtonWasTapped:(LIOHeaderBarView *)aView
{
    LIOAboutViewController *aController = [[[LIOAboutViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    aController.delegate = self;
    [self presentModalViewController:aController animated:YES];
}

- (void)headerBarViewWasTapped:(LIOHeaderBarView *)aView
{
    if (headerBar.mode != LIOHeaderBarViewModeFull)
    {
        [headerBar switchToMode:LIOHeaderBarViewModeFull animated:YES];
        
        CGRect aFrame = tableView.frame;
        aFrame.origin.y = 49.0;
        tableView.frame = aFrame;
    }
    else if (headerBar.mode != LIOHeaderBarViewModeMinimal)
    {
        [headerBar switchToMode:LIOHeaderBarViewModeMinimal animated:YES];
        
        CGRect aFrame = tableView.frame;
        aFrame.origin.y = 32.0;
        tableView.frame = aFrame;
    }
}

#pragma mark -
#pragma mark LIOAboutViewControllerDelegate methods

- (void)aboutViewControllerWasDismissed:(LIOAboutViewController *)aController
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)aboutViewController:(LIOAboutViewController *)aController wasDismissedWithEmail:(NSString *)anEmail
{
    if ([anEmail length])
        [delegate altChatViewController:self didEnterBetaEmail:anEmail];
    
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)aboutViewController:(LIOAboutViewController *)aController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation
{
    return [delegate altChatViewController:self shouldRotateToInterfaceOrientation:anOrientation];
}

#pragma mark -
#pragma mark Gesture handlers

- (void)handleTap:(UITapGestureRecognizer *)aTapper
{
    [delegate altChatViewController:self wasDismissedWithPendingChatText:pendingChatText];
}

@end