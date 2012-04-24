//
//  LIOEmailHistoryViewController.m
//  LookIO
//
//  Created by Joe Toscano on 9/30/11.
//  Copyright 2011 LookIO, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "LIOEmailHistoryViewController.h"
#import "LIOLookIOManager.h"
#import "LIOBundleManager.h"

@implementation LIOEmailHistoryViewController

@synthesize delegate, initialEmailAddress;

- (void)loadView
{
    [super loadView];
    UIView *rootView = self.view;
    
    UIColor *altBlue = [UIColor colorWithRed:(156.0/255.0) green:(213.0/255.0) blue:(240.0/255.0) alpha:1.0];
    
    UIImage *backgroundImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOAboutBackground"];
    UIImageView *backgroundView = [[[UIImageView alloc] initWithImage:backgroundImage] autorelease];
    backgroundView.frame = self.view.bounds;
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [rootView addSubview:backgroundView];
    
    navBar = [[UINavigationBar alloc] init];
    navBar.barStyle = UIBarStyleBlackOpaque;
    CGFloat navBarHeight = [navBar sizeThatFits:self.view.bounds.size].height;
    CGRect aFrame = navBar.frame;
    aFrame.size.width = rootView.frame.size.width;
    aFrame.size.height = navBarHeight;
    navBar.frame = aFrame;
    navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *anItem = [[[UINavigationItem alloc] initWithTitle:@"Email Conversation"] autorelease];
    UIBarButtonItem *closeItem = [[[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(closeButtonWasTapped)] autorelease];
    anItem.leftBarButtonItem = closeItem;
    [navBar pushNavigationItem:anItem animated:NO];
    navBar.delegate = self;
    [rootView addSubview:navBar];
    
    scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    aFrame = scrollView.frame;
    aFrame.origin.y = navBar.frame.size.height;
    aFrame.size.height -= aFrame.origin.y;
    scrollView.frame = aFrame;
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [rootView addSubview:scrollView];
    
    /*
    UIImageView *logoView = [[[UIImageView alloc] initWithImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOAboutTitle"]] autorelease];
    aFrame = logoView.frame;
    aFrame.size.height -= 20.0;
    aFrame.size.width -= 67.0;
    aFrame.origin.x = (rootView.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = 5.0;
    logoView.frame = aFrame;
    logoView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [scrollView addSubview:logoView];
    
    UIImage *separatorImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOAboutStretchableSeparator"];
    UIImage *stretchableSeparatorImage = [separatorImage stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    
    UIImageView *topSeparator = [[[UIImageView alloc] initWithImage:stretchableSeparatorImage] autorelease];
    aFrame = topSeparator.frame;
    aFrame.origin.y = logoView.frame.origin.y + logoView.frame.size.height + 8.0;
    aFrame.size.width = rootView.frame.size.width;
    aFrame.size.height = 3.0;
    topSeparator.frame = aFrame;
    topSeparator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:topSeparator];
     */
    
    UILabel *label01 = [[[UILabel alloc] init] autorelease];
    label01.text = @"Need a copy of this chat? No problem!";
    label01.textColor = [UIColor whiteColor];
    label01.backgroundColor = [UIColor clearColor];
    label01.layer.shadowColor = [UIColor blackColor].CGColor;
    label01.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    label01.layer.shadowOpacity = 0.5;
    label01.layer.shadowRadius = 1.0;
    label01.font = [UIFont boldSystemFontOfSize:14.0];
    [label01 sizeToFit];
    aFrame = label01.frame;
    aFrame.origin.y = 20.0; //topSeparator.frame.origin.y + topSeparator.frame.size.height + 5.0;
    aFrame.origin.x = (rootView.frame.size.width / 2.0) - (label01.frame.size.width / 2.0);
    label01.frame = aFrame;
    label01.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [scrollView addSubview:label01];
    
    label02 = [[UILabel alloc] init];
    label02.text = @"Your Email Address:";
    label02.textColor = altBlue;
    label02.backgroundColor = [UIColor clearColor];
    label02.layer.shadowColor = [UIColor blackColor].CGColor;
    label02.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    label02.layer.shadowOpacity = 0.5;
    label02.layer.shadowRadius = 1.0;
    label02.font = [UIFont systemFontOfSize:12.0];
    [label02 sizeToFit];
    aFrame = label02.frame;
    aFrame.origin.y = label01.frame.origin.y + label01.frame.size.height + 10.0;
    aFrame.origin.x = (rootView.frame.size.width / 2.0) - (label02.frame.size.width / 2.0);
    label02.frame = aFrame;
    label02.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [scrollView addSubview:label02];
    
    UIImage *fieldImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOAboutStretchableField"];
    UIImage *stretchableFieldImage = [fieldImage stretchableImageWithLeftCapWidth:11 topCapHeight:13];
    
    fieldBackground = [[UIImageView alloc] initWithImage:stretchableFieldImage];
    fieldBackground.userInteractionEnabled = YES;
    aFrame = fieldBackground.frame;
    aFrame.origin.x = 10.0;
    aFrame.size.width = self.view.bounds.size.width - 20.0;
    aFrame.size.height = 48.0;
    aFrame.origin.y = label02.frame.origin.y + label02.frame.size.height + 10.0;
    fieldBackground.frame = aFrame;
    fieldBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:fieldBackground];
    
    inputField = [[UITextField alloc] init];
    inputField.delegate = self;
    inputField.backgroundColor = [UIColor clearColor];
    aFrame.origin.x = 10.0;
    aFrame.origin.y = 14.0;
    aFrame.size.width = fieldBackground.frame.size.width - 20.0;
    aFrame.size.height = 28.0;
    inputField.frame = aFrame;
    inputField.font = [UIFont systemFontOfSize:14.0];
    inputField.placeholder = @"name@example.com";
    inputField.keyboardType = UIKeyboardTypeEmailAddress;
    inputField.autocorrectionType = UITextAutocorrectionTypeNo;
    inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    inputField.returnKeyType = UIReturnKeySend;
    inputField.keyboardAppearance = UIKeyboardAppearanceAlert;
    if ([[[LIOLookIOManager sharedLookIOManager] pendingEmailAddress] length])
        inputField.text = [[LIOLookIOManager sharedLookIOManager] pendingEmailAddress];
    [fieldBackground addSubview:inputField];
    
    UIImage *buttonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOAboutStretchableGreenButton"];
    UIImage *stretchableButtonImage = [buttonImage stretchableImageWithLeftCapWidth:15 topCapHeight:24];
    
    submitButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    [submitButton addTarget:self action:@selector(submitButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    [submitButton setBackgroundImage:stretchableButtonImage forState:UIControlStateNormal];
    [submitButton setTitle:@"Submit" forState:UIControlStateNormal];
    submitButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    submitButton.titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    submitButton.titleLabel.layer.shadowOffset = CGSizeMake(0.0, -1.0);
    submitButton.titleLabel.layer.shadowOpacity = 0.5;
    submitButton.titleLabel.layer.shadowRadius = 1.0;
    submitButton.bounds = fieldBackground.bounds;
    aFrame = submitButton.frame;
    aFrame.size.width = self.view.bounds.size.width - 20.0;
    aFrame.origin.x = 10.0; //(rootView.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = fieldBackground.frame.origin.y + fieldBackground.frame.size.height + 3.0;
    submitButton.frame = aFrame;
    submitButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:submitButton];
    
    scrollView.contentSize = CGSizeMake(rootView.frame.size.width, submitButton.frame.origin.y + submitButton.frame.size.height);
}

/*
- (void)rejiggerInterface
{
    CGRect aFrame = fieldBackground.frame;
    aFrame.size.width = 290.0;
    aFrame.size.height = 48.0;
    aFrame.origin.y = label02.frame.origin.y + label02.frame.size.height + 10.0;
    aFrame.origin.x = (self.view.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    fieldBackground.frame = aFrame;
    
    submitButton.bounds = fieldBackground.bounds;
    aFrame = submitButton.frame;
    aFrame.origin.x = (self.view.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = fieldBackground.frame.origin.y + fieldBackground.frame.size.height + 3.0;
    submitButton.frame = aFrame;
}
*/

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [scrollView release];
    scrollView = nil;
    
    [fieldBackground release];
    fieldBackground = nil;
    
    [inputField release];
    inputField = nil;
    
    [submitButton release];
    submitButton = nil;
    
    [navBar release];
    navBar = nil;
    
    [label02 release];
    label02 = nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [initialEmailAddress release];
    [scrollView release];
    [fieldBackground release];
    [inputField release];
    [submitButton release];
    [navBar release];
    [label02 release];
    
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];   
    
    //[self rejiggerInterface];
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
        [inputField becomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [delegate emailHistoryViewController:self shouldRotateToInterfaceOrientation:interfaceOrientation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [scrollView scrollRectToVisible:fieldBackground.frame animated:NO];
    
    scrollView.contentSize = CGSizeMake(self.view.frame.size.width, submitButton.frame.origin.y + submitButton.frame.size.height);
    
    CGFloat navBarHeight = [navBar sizeThatFits:self.view.bounds.size].height;
    CGRect aFrame = navBar.frame;
    aFrame.size.height = navBarHeight;
    navBar.frame = aFrame;
    
    aFrame = scrollView.frame;
    aFrame.origin.y = navBar.frame.origin.y + navBar.frame.size.height;
    CGFloat diff = aFrame.origin.y - scrollView.frame.origin.y;
    aFrame.size.height -= diff;
    scrollView.frame = aFrame;
}

#pragma mark -
#pragma mark Notification handlers

- (void)keyboardWillShow:(NSNotification *)aNotification
{
    if (keyboardShown || UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom])
        return;
    
    keyboardShown = YES;
    
    UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    NSDictionary *userInfo = [aNotification userInfo];
    
    NSTimeInterval animationDuration;
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [animationDurationValue getValue:&animationDuration];
    
    UIViewAnimationCurve animationCurve;
    NSValue *animationCurveValue = [userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    [animationCurveValue getValue:&animationCurve];
    
    NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardBounds = [keyboardBoundsValue CGRectValue];
    
    CGFloat keyboardHeight = keyboardBounds.size.height;
    if (UIInterfaceOrientationIsLandscape(actualOrientation))
        keyboardHeight = keyboardBounds.size.width;
    
    CGRect aFrame = scrollView.frame;
    aFrame.size.height -= keyboardHeight;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
        scrollView.frame = aFrame;
    [UIView commitAnimations];
    
    [scrollView scrollRectToVisible:fieldBackground.frame animated:NO];
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
    if (NO == keyboardShown || UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom])
        return;
    
    keyboardShown = NO;
    
    UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    NSDictionary *userInfo = [aNotification userInfo];
    
    NSTimeInterval animationDuration;
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [animationDurationValue getValue:&animationDuration];
    
    UIViewAnimationCurve animationCurve;
    NSValue *animationCurveValue = [userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    [animationCurveValue getValue:&animationCurve];
    
    NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardBounds = [keyboardBoundsValue CGRectValue];
    
    CGFloat keyboardHeight = keyboardBounds.size.height;
    if (UIInterfaceOrientationIsLandscape(actualOrientation))
        keyboardHeight = keyboardBounds.size.width;
    
    CGRect aFrame = scrollView.frame;
    aFrame.size.height += keyboardHeight;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
        scrollView.frame = aFrame;
    [UIView commitAnimations];
}

#pragma mark -
#pragma mark UIControl actions

- (void)closeButtonWasTapped
{
    [delegate emailHistoryViewControllerWasDismissed:self];
}

- (void)submitButtonWasTapped
{
    if ([inputField.text length])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Thank you!"
                                                            message:@"A transcript of this session has been emailed to you."
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Dismiss", nil];
        [alertView show];
        [alertView autorelease];
    }
    else
    {
        [delegate emailHistoryViewController:self wasDismissedWithEmailAddress:inputField.text];
    }
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [delegate emailHistoryViewController:self wasDismissedWithEmailAddress:inputField.text];
}

@end