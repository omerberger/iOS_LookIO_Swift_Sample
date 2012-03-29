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
#import "LIODismissalBarView.h"
#import "LIOEmailHistoryViewController.h"
#import "LIOLeaveMessageViewController.h"
#import "LIOBundleManager.h"

#define LIOAltChatViewControllerMaxHistoryLength   10
#define LIOAltChatViewControllerChatboxPadding     10.0
#define LIOAltChatViewControllerChatboxMinHeight   100.0

#define LIOAltChatViewControllerTableViewCellReuseId       @"LIOAltChatViewControllerTableViewCellReuseId"
#define LIOAltChatViewControllerTableViewCellBubbleViewTag 1001

@implementation LIOAltChatViewController

@synthesize delegate, dataSource, initialChatText, agentTyping;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
    }
    
    return self;
}

- (void)loadView
{
    [super loadView];
    
    UIImage *backgroundImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOAltChatBackground"];
    
    background = [[UIImageView alloc] initWithImage:backgroundImage];
    background.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:background];
    
    CGRect aFrame = self.view.bounds;
    aFrame.origin.y = 32.0;
    aFrame.size.height -= 112.0;
    
    tableView = [[UITableView alloc] initWithFrame:aFrame style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    //tableView.backgroundColor = [UIColor colorWithRed:(arc4random()%256)/255.0 green:(arc4random()%256)/255.0 blue:(arc4random()%256)/255.0 alpha:1.0];
    tableView.backgroundColor = [UIColor clearColor];
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.showsVerticalScrollIndicator = NO;
    tableView.showsHorizontalScrollIndicator = NO;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:tableView];
    
    aFrame = CGRectZero;
    aFrame.size.width = self.view.bounds.size.width;
    aFrame.size.height = 40.0;
    aFrame.origin.y = self.view.bounds.size.height - 44.0;
    
    inputBar = [[LIOInputBarView alloc] initWithFrame:aFrame];
    inputBar.delegate = self;
    inputBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:inputBar];
    
    dismissalBar = [[LIODismissalBarView alloc] init];
    //dismissalBar.backgroundColor = [UIColor colorWithRed:(arc4random()%256)/255.0 green:(arc4random()%256)/255.0 blue:(arc4random()%256)/255.0 alpha:1.0];
    dismissalBar.backgroundColor = [UIColor clearColor];
    aFrame = dismissalBar.frame;
    aFrame.size.width = self.view.frame.size.width;
    aFrame.size.height = 35.0;
    aFrame.origin.y = inputBar.frame.origin.y - aFrame.size.height;
    dismissalBar.frame = aFrame;
    dismissalBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    dismissalBar.delegate = self;
    [self.view insertSubview:dismissalBar belowSubview:inputBar];
    
    aFrame = CGRectZero;
    aFrame.size.width = self.view.bounds.size.width;
    
    headerBar = [[LIOHeaderBarView alloc] initWithFrame:aFrame];
    //headerBar.backgroundColor = [UIColor colorWithRed:(arc4random()%256)/255.0 green:(arc4random()%256)/255.0 blue:(arc4random()%256)/255.0 alpha:1.0];
    headerBar.backgroundColor = [UIColor clearColor];
    headerBar.delegate = self;
    headerBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:headerBar];
    
    UIImage *grayStretchableButtonImage = [[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableRecessedButtonGray"] stretchableImageWithLeftCapWidth:13 topCapHeight:13];
    UIImage *redStretchableButtonImage = [[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableRecessedButtonRed"] stretchableImageWithLeftCapWidth:13 topCapHeight:13];
    
    UIButton *aboutButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [aboutButton setBackgroundImage:grayStretchableButtonImage forState:UIControlStateNormal];
    aboutButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    aboutButton.titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    aboutButton.titleLabel.layer.shadowOpacity = 0.8;
    aboutButton.titleLabel.layer.shadowOffset = CGSizeMake(0.0, -1.0);
    [aboutButton setTitle:@"About LookIO" forState:UIControlStateNormal];
    [aboutButton addTarget:self action:@selector(aboutButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    aFrame = aboutButton.frame;
    aFrame.size.width = 92.0;
    aFrame.size.height = 32.0;
    aFrame.origin.x = 15.0;
    aFrame.origin.y = 16.0;
    aboutButton.frame = aFrame;
    aboutButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
    
    UIButton *emailConvoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [emailConvoButton setBackgroundImage:grayStretchableButtonImage forState:UIControlStateNormal];
    emailConvoButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    emailConvoButton.titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    emailConvoButton.titleLabel.layer.shadowOpacity = 0.8;
    emailConvoButton.titleLabel.layer.shadowOffset = CGSizeMake(0.0, -1.0);
    [emailConvoButton setTitle:@"Email Chat" forState:UIControlStateNormal];
    [emailConvoButton addTarget:self action:@selector(emailConvoButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    aFrame = emailConvoButton.frame;
    aFrame.size.width = 92.0;
    aFrame.size.height = 32.0;
    aFrame.origin.x = aboutButton.frame.origin.x + aboutButton.frame.size.width + 5.0;
    aFrame.origin.y = 16.0;
    emailConvoButton.frame = aFrame;
    emailConvoButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;

    UIButton *endSessionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [endSessionButton setBackgroundImage:redStretchableButtonImage forState:UIControlStateNormal];
    endSessionButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    endSessionButton.titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    endSessionButton.titleLabel.layer.shadowOpacity = 0.8;
    endSessionButton.titleLabel.layer.shadowOffset = CGSizeMake(0.0, -1.0);
    [endSessionButton setTitle:@"End Session" forState:UIControlStateNormal];
    [endSessionButton addTarget:self action:@selector(endSessionButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    aFrame = endSessionButton.frame;
    aFrame.size.width = 92.0;
    aFrame.size.height = 32.0;
    aFrame.origin.x = emailConvoButton.frame.origin.x + emailConvoButton.frame.size.width + 5.0;
    aFrame.origin.y = 16.0;
    endSessionButton.frame = aFrame;
    endSessionButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;
    
    functionHeader = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    functionHeader.selectionStyle = UITableViewCellSelectionStyleNone;
    [functionHeader.contentView addSubview:aboutButton];
    [functionHeader.contentView addSubview:emailConvoButton];
    [functionHeader.contentView addSubview:endSessionButton];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    
    [functionHeader release];
    functionHeader = nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    tableView.delegate = nil;
    tableView.dataSource = nil;
    [tableView release];
    
    [background release];
    [pendingChatText release];
    [initialChatText release];
    [messages release];
    [headerBar release];
    [inputBar release];
    [functionHeader release];
    
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self reloadMessages];
    
    NSIndexPath *lastRow = [NSIndexPath indexPathForRow:[messages count] - 1 inSection:0];
    [tableView scrollToRowAtIndexPath:lastRow atScrollPosition:UITableViewScrollPositionTop animated:NO];
    
    [self scrollToBottom];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [delegate altChatViewController:self shouldRotateToInterfaceOrientation:interfaceOrientation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self reloadMessages];
    [self scrollToBottom];
}

- (void)performRevealAnimation
{
    background.alpha = 0.0;
    
    [UIView animateWithDuration:0.4
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         background.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                         background.alpha = 1.0;
                     }];
    
    tableView.transform = CGAffineTransformMakeTranslation(0.0, -self.view.frame.size.height);
    headerBar.transform = CGAffineTransformMakeTranslation(0.0, -self.view.frame.size.height);
    inputBar.transform = CGAffineTransformMakeTranslation(0.0, self.view.frame.size.height);
    dismissalBar.transform = CGAffineTransformMakeTranslation(0.0, self.view.frame.size.height);
    
    [UIView animateWithDuration:0.3
                          delay:0.1
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         tableView.transform = CGAffineTransformIdentity;
                         inputBar.transform = CGAffineTransformIdentity;
                         headerBar.transform = CGAffineTransformIdentity;
                         dismissalBar.transform = CGAffineTransformIdentity;
                     }
                     completion:^(BOOL finished) {
                         tableView.transform = CGAffineTransformIdentity;
                         inputBar.transform = CGAffineTransformIdentity;
                         headerBar.transform = CGAffineTransformIdentity;
                         dismissalBar.transform = CGAffineTransformIdentity;
                     }];
}

- (void)performDismissalAnimation
{
    [delegate altChatViewControllerDidStartDismissalAnimation:self];
    
    background.alpha = 1.0;
    
    [UIView animateWithDuration:0.33
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         background.alpha = 0.0;
                         
                         tableView.transform = CGAffineTransformMakeTranslation(0.0, -self.view.frame.size.height);
                         headerBar.transform = CGAffineTransformMakeTranslation(0.0, -self.view.frame.size.height);
                         inputBar.transform = CGAffineTransformMakeTranslation(0.0, self.view.frame.size.height);
                         dismissalBar.transform = CGAffineTransformMakeTranslation(0.0, self.view.frame.size.height);
                     }
                     completion:^(BOOL finished) {
                         double delayInSeconds = 0.1;
                         dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                         dispatch_after(popTime, dispatch_get_main_queue(), ^{
                             [delegate altChatViewControllerDidFinishDismissalAnimation:self];
                         });
                     }];
}

- (void)scrollToBottom
{
    double delayInSeconds = 0.75;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(){
        NSIndexPath *lastRow = [NSIndexPath indexPathForRow:[messages count] inSection:0];
        [tableView scrollToRowAtIndexPath:lastRow atScrollPosition:UITableViewScrollPositionTop animated:YES];
    });
}

- (void)reloadMessages
{
    [messages release];
    messages = [[dataSource altChatViewControllerChatMessages:self] retain];
    
    [tableView reloadData];
}

#pragma mark -
#pragma mark UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [messages count] + 2;
}

/*
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor colorWithRed:(arc4random()%256)/255.0 green:(arc4random()%256)/255.0 blue:(arc4random()%256)/255.0 alpha:1.0];
}
*/

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (0 == indexPath.row)
        return functionHeader;
    
    if ([messages count] + 1 == indexPath.row)
    {
        UITableViewCell *expandingFooter = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
        expandingFooter.selectionStyle = UITableViewCellSelectionStyleNone;
        return expandingFooter;
    }
     
    UITableViewCell *aCell = [tableView dequeueReusableCellWithIdentifier:LIOAltChatViewControllerTableViewCellReuseId];
    LIOChatBubbleView *aBubble = (LIOChatBubbleView *)[aCell viewWithTag:LIOAltChatViewControllerTableViewCellBubbleViewTag];
    if (nil == aCell)
    {
        aCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LIOAltChatViewControllerTableViewCellReuseId];
        aCell.selectionStyle = UITableViewCellSelectionStyleNone;
        [aCell autorelease];
        
        aBubble = [[LIOChatBubbleView alloc] initWithFrame:CGRectZero];
        aBubble.backgroundColor = [UIColor clearColor];
        [aCell.contentView addSubview:aBubble];
        aBubble.tag = LIOAltChatViewControllerTableViewCellBubbleViewTag;
    }
    
    LIOChatMessage *aMessage = [messages objectAtIndex:(indexPath.row - 1)];
    if (LIOChatMessageKindLocal == aMessage.kind)
    {
        aBubble.formattingMode = LIOChatBubbleViewFormattingModeLocal;
        aBubble.senderName = @"Me";
    }
    else
    {
        aBubble.formattingMode = LIOChatBubbleViewFormattingModeRemote;
        aBubble.senderName = aMessage.senderName;
    }
    
    [aBubble populateMessageViewWithText:aMessage.text];
    
    if (LIOChatBubbleViewFormattingModeRemote == aBubble.formattingMode)
        aBubble.frame = CGRectMake(0.0, 0.0, 290.0, 0.0);
    else
        aBubble.frame = CGRectMake(self.view.bounds.size.width - 290.0, 0.0, 290.0, 0.0);
    
    [aBubble setNeedsLayout];
    [aBubble setNeedsDisplay];
    
    return aCell;
}

#pragma mark -
#pragma mark UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (0 == indexPath.row)
        return 64.0;
    
    if ([messages count] + 1 == indexPath.row)
    {
        CGFloat heightOfLastBubble = [self tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:[messages count] inSection:0]];
        return tableView.bounds.size.height - heightOfLastBubble - 10.0;
    }
    
    LIOChatMessage *aMessage = [messages objectAtIndex:(indexPath.row - 1)];
    
    CGSize maxSize = CGSizeMake(LIOChatBubbleViewMaxTextWidth, FLT_MAX);
    CGSize boxSize = [aMessage.text sizeWithFont:[UIFont systemFontOfSize:16.0] constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    
    CGFloat height = boxSize.height + 25.0;
    if (height < LIOChatBubbleViewMinTextHeight) height = LIOChatBubbleViewMinTextHeight;
    
    return height + 10.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [messages count] + 1)
        [delegate altChatViewController:self wasDismissedWithPendingChatText:pendingChatText];
}

#pragma mark -
#pragma mark UIControl actions

- (void)aboutButtonWasTapped
{
    LIOAboutViewController *aController = [[[LIOAboutViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    aController.delegate = self;
    [self presentModalViewController:aController animated:YES];
}

- (void)emailConvoButtonWasTapped
{
    LIOEmailHistoryViewController *aController = [[[LIOEmailHistoryViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    aController.delegate = self;
    [self presentModalViewController:aController animated:YES];
}

- (void)endSessionButtonWasTapped
{
    [delegate altChatViewControllerDidTapEndSessionButton:self];
}

#pragma mark -
#pragma mark Notification handlers  

- (void)keyboardWillShow:(NSNotification *)aNotification
{
    if (keyboardShowing)
        return;
    
    keyboardShowing = YES;
    
    UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    NSDictionary *userInfo = [aNotification userInfo];
    
    NSTimeInterval animationDuration;
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [animationDurationValue getValue:&animationDuration];
    
    UIViewAnimationCurve animationCurve;
    NSValue *animationCurveValue = [userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    [animationCurveValue getValue:&animationCurve];
    
    NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardBounds = [keyboardBoundsValue CGRectValue]; //[self.view convertRect:[keyboardBoundsValue CGRectValue] fromView:nil];
    
    CGFloat keyboardHeight = keyboardBounds.size.height;
    if (UIInterfaceOrientationIsLandscape(actualOrientation))
        keyboardHeight = keyboardBounds.size.width;
    
    CGRect inputBarFrame = inputBar.frame;
    inputBarFrame.origin.y -= keyboardHeight;
    
    CGRect dismissalBarFrame = dismissalBar.frame;
    dismissalBarFrame.origin.y -= keyboardHeight - 15.0; // 15.0 is the difference in dismissal bar height
    dismissalBarFrame.size.height = 20.0;
    
    CGRect headerFrame = headerBar.frame;
    if (UIInterfaceOrientationIsLandscape(actualOrientation))
        headerFrame.origin.y -= headerFrame.size.height;
    
    CGRect tableFrame = tableView.frame;
    if (UIInterfaceOrientationIsLandscape(actualOrientation))
    {
        tableFrame.origin.y = 0.0;
        tableFrame.size.height -= keyboardHeight - 15.0 - 32.0; // 32.0 is the default table origin (below header)
    }
    else
        tableFrame.size.height -= keyboardHeight - 15.0;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
        inputBar.frame = inputBarFrame;
        dismissalBar.frame = dismissalBarFrame;
        tableView.frame = tableFrame;
        headerBar.frame = headerFrame;
    [UIView commitAnimations];

    [self reloadMessages];
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
    if (NO == keyboardShowing)
        return;
    
    keyboardShowing = NO;
    
    UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    NSDictionary *userInfo = [aNotification userInfo];
    
    NSTimeInterval animationDuration;
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [animationDurationValue getValue:&animationDuration];
    
    UIViewAnimationCurve animationCurve;
    NSValue *animationCurveValue = [userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    [animationCurveValue getValue:&animationCurve];
    
    NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardBounds = [keyboardBoundsValue CGRectValue];
    
    CGFloat keyboardHeight = keyboardBounds.size.height;
    if (UIInterfaceOrientationIsLandscape(actualOrientation))
        keyboardHeight = keyboardBounds.size.width;
    
    CGRect inputBarFrame = inputBar.frame;
    inputBarFrame.origin.y += keyboardHeight;
    
    CGRect dismissalBarFrame = dismissalBar.frame;
    dismissalBarFrame.origin.y += keyboardHeight - 15.0;
    dismissalBarFrame.size.height = 35.0;
    
    CGRect headerFrame = headerBar.frame;
    headerFrame.origin.y = 0.0;

    CGFloat jitterCorrection = 0.0;
    CGRect tableFrame = tableView.frame;
    tableFrame.origin.y = 32.0;
    if (UIInterfaceOrientationIsLandscape(actualOrientation))
    {
        tableFrame.size.height += keyboardHeight - 15.0 - 32.0;
        jitterCorrection = 32.0;
    }
    else
        tableFrame.size.height += keyboardHeight - 15.0;
    
    CGPoint previousOffset = tableView.contentOffset;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
        inputBar.frame = inputBarFrame;
        dismissalBar.frame = dismissalBarFrame;
        headerBar.frame = headerFrame;
    [UIView commitAnimations];
    
    [self reloadMessages];
    
    // Resizing the table causes contentOffset to jump to 0.
    // Thus, we can't animate it.
    tableView.frame = tableFrame;
    tableView.contentOffset = CGPointMake(previousOffset.x, previousOffset.y + jitterCorrection);
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
        
        if ([[LIOLookIOManager sharedLookIOManager] agentsAvailable])
            [delegate altChatViewController:self didChatWithText:aString];
        else
        {
            NSString *pendingEmailAddress = [[LIOLookIOManager sharedLookIOManager] pendingEmailAddress];
            
            LIOLeaveMessageViewController *aController = [[[LIOLeaveMessageViewController alloc] initWithNibName:nil bundle:nil] autorelease];
            aController.delegate = self;
            
            if ([pendingEmailAddress length])
                aController.initialEmailAddress = pendingEmailAddress;
            
            if ([pendingChatText length])
                aController.initialMessage = pendingChatText;
            
            [self presentModalViewController:aController animated:YES];
        }
    }
    
    [pendingChatText release];
    pendingChatText = nil;
    
    [self.view endEditing:YES];
    
    [self reloadMessages];
}

#pragma mark -
#pragma mark UIScrollViewDelegate methods

/*
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (previousScrollHeight - scrollView.contentOffset.y > 3.0)
        [self.view endEditing:YES];
    
    previousScrollHeight = scrollView.contentOffset.y;
}
*/

#pragma mark -
#pragma mark LIOHeaderBarViewDelegate methods

- (void)headerBarViewPlusButtonWasTapped:(LIOHeaderBarView *)aView
{
    if (tableView.contentOffset.y > 0)
    {
        [UIView animateWithDuration:0.5
                         animations:^{
                             tableView.contentOffset = CGPointZero;
                         }];
    }
    
    
    [self.view endEditing:YES];
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
#pragma mark LIOEmailHistoryViewControllerDelegate methods

- (void)emailHistoryViewControllerWasDismissed:(LIOEmailHistoryViewController *)aController
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)emailHistoryViewController:(LIOEmailHistoryViewController *)aController wasDismissedWithEmailAddress:(NSString *)anEmail
{
    [self dismissModalViewControllerAnimated:YES];
    
    if ([anEmail length])
        [delegate altChatViewController:self didEnterTranscriptEmail:anEmail];
}

- (BOOL)emailHistoryViewController:(LIOEmailHistoryViewController *)aController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation
{
    return [delegate altChatViewController:self shouldRotateToInterfaceOrientation:anOrientation];
}

#pragma mark -
#pragma mark LIOLeaveMessageViewControllerDelegate methods

- (void)leaveMessageViewControllerWasDismissed:(LIOLeaveMessageViewController *)aController
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)leaveMessageViewController:(LIOLeaveMessageViewController *)aController didSubmitEmailAddress:(NSString *)anEmail withMessage:(NSString *)aMessage
{
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)leaveMessageViewController:(LIOLeaveMessageViewController *)aController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation
{
    return [delegate altChatViewController:self shouldRotateToInterfaceOrientation:anOrientation];
}

#pragma mark -
#pragma mark LIODismissalBarViewDelegate methods

- (void)dismissalBarViewButtonWasTapped:(LIODismissalBarView *)aView
{
    [delegate altChatViewController:self wasDismissedWithPendingChatText:pendingChatText];
}

@end