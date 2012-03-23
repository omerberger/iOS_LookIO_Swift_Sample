//
//  LIOLeaveMessageViewController.m
//  LookIO
//
//  Created by Joe Toscano on 9/30/11.
//  Copyright 2011 LookIO, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "LIOLeaveMessageViewController.h"
#import "LIOLookIOManager.h"

@implementation LIOLeaveMessageViewController

@synthesize delegate, initialMessage, initialEmailAddress;

- (void)loadView
{
    [super loadView];
    UIView *rootView = self.view;
    
    UIColor *altBlue = [UIColor colorWithRed:(156.0/255.0) green:(213.0/255.0) blue:(240.0/255.0) alpha:1.0];
    
    if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom])
    {
        UIImageView *backgroundView = [[[UIImageView alloc] initWithImage:lookioImage(@"LIOAboutBackground.jpg")] autorelease];
        CGRect aFrame = backgroundView.frame;
        aFrame.origin.x = -((aFrame.size.width - rootView.frame.size.width) / 2.0);
        backgroundView.frame = aFrame;
        backgroundView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [rootView addSubview:backgroundView];
    }
    else
    {
        UIImage *backgroundImage = lookioImage(@"LIOAboutBackgroundForiPhone.jpg");
        UIImageView *backgroundView = [[[UIImageView alloc] initWithImage:backgroundImage] autorelease];
        backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [rootView addSubview:backgroundView];
    }
    
    navBar = [[UINavigationBar alloc] init];
    navBar.barStyle = UIBarStyleBlackOpaque;
    CGFloat navBarHeight = [navBar sizeThatFits:self.view.bounds.size].height;
    CGRect aFrame = navBar.frame;
    aFrame.size.width = rootView.frame.size.width;
    aFrame.size.height = navBarHeight;
    navBar.frame = aFrame;
    navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *anItem = [[[UINavigationItem alloc] initWithTitle:@"Leave a Message"] autorelease];
    UIBarButtonItem *closeItem = [[[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(closeButtonWasTapped)] autorelease];
    anItem.leftBarButtonItem = closeItem;
    [navBar pushNavigationItem:anItem animated:NO];
    navBar.delegate = self;
    [rootView addSubview:navBar];
    
    scrollView = [[UIScrollView alloc] init];
    scrollView.frame = rootView.bounds;
    aFrame = scrollView.frame;
    aFrame.origin.y = navBar.frame.size.height;
    aFrame.size.height -= aFrame.origin.y;
    scrollView.frame = aFrame;
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [rootView addSubview:scrollView];
                
    UILabel *label01 = [[[UILabel alloc] init] autorelease];
    label01.text = @"Sorry, no agents are available.";
    label01.textColor = [UIColor whiteColor];
    label01.backgroundColor = [UIColor clearColor];
    label01.layer.shadowColor = [UIColor blackColor].CGColor;
    label01.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    label01.layer.shadowOpacity = 0.5;
    label01.layer.shadowRadius = 1.0;
    label01.font = [UIFont boldSystemFontOfSize:14.0];
    [label01 sizeToFit];
    aFrame = label01.frame;
    aFrame.origin.y = 5.0;
    aFrame.origin.x = (rootView.frame.size.width / 2.0) - (label01.frame.size.width / 2.0);
    label01.frame = aFrame;
    label01.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [scrollView addSubview:label01];
    
    UILabel *label02 = [[[UILabel alloc] init] autorelease];
    label02.text = @"Please enter your email and a message for further help:";
    label02.textColor = altBlue;
    label02.backgroundColor = [UIColor clearColor];
    label02.layer.shadowColor = [UIColor blackColor].CGColor;
    label02.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    label02.layer.shadowOpacity = 0.5;
    label02.layer.shadowRadius = 1.0;
    label02.font = [UIFont systemFontOfSize:12.0];
    [label02 sizeToFit];
    aFrame = label02.frame;
    aFrame.origin.y = label01.frame.origin.y + label01.frame.size.height;
    aFrame.origin.x = (rootView.frame.size.width / 2.0) - (label02.frame.size.width / 2.0);
    label02.frame = aFrame;
    label02.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [scrollView addSubview:label02];
    
    UIImage *fieldImage = lookioImage(@"LIOAboutStretchableField");
    UIImage *stretchableFieldImage = [fieldImage stretchableImageWithLeftCapWidth:11 topCapHeight:13];
    
    fieldBackground = [[UIImageView alloc] initWithImage:stretchableFieldImage];
    fieldBackground.userInteractionEnabled = YES;
    aFrame = fieldBackground.frame;
    aFrame.size.width = 290.0;
    aFrame.size.height = 48.0;
    aFrame.origin.y = label02.frame.origin.y + label02.frame.size.height + 5.0;
    aFrame.origin.x = (rootView.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    fieldBackground.frame = aFrame;
    fieldBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:fieldBackground];
    
    emailField = [[UITextField alloc] init];
    emailField.delegate = self;
    emailField.backgroundColor = [UIColor clearColor];
    aFrame.origin.x = 10.0;
    aFrame.origin.y = 14.0;
    aFrame.size.width = 269.0;
    aFrame.size.height = 28.0;
    emailField.frame = aFrame;
    emailField.font = [UIFont systemFontOfSize:14.0];
    emailField.placeholder = @"name@example.com";
    emailField.keyboardType = UIKeyboardTypeEmailAddress;
    emailField.autocorrectionType = UITextAutocorrectionTypeNo;
    emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    emailField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    emailField.returnKeyType = UIReturnKeyNext;
    emailField.keyboardAppearance = UIKeyboardAppearanceAlert;
    if ([initialEmailAddress length])
        emailField.text = initialEmailAddress;
    [fieldBackground addSubview:emailField];
    
    messageBackground = [[UIImageView alloc] initWithImage:stretchableFieldImage];
    messageBackground.clipsToBounds = YES;
    messageBackground.userInteractionEnabled = YES;
    aFrame.size.width = 290.0;
    aFrame.size.height = 96.0;
    aFrame.origin.y = fieldBackground.frame.origin.y + fieldBackground.frame.size.height + 5.0;
    aFrame.origin.x = (rootView.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    messageBackground.frame = aFrame;
    messageBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:messageBackground];
    
    messageView = [[UITextView alloc] init];
    messageView.keyboardAppearance = UIKeyboardAppearanceAlert;
    messageView.returnKeyType = UIReturnKeySend;
    messageView.backgroundColor = [UIColor clearColor];
    messageView.delegate = self;
    aFrame.origin.x = 1.0;
    aFrame.origin.y = 10.0;
    aFrame.size.width = 280.0;
    aFrame.size.height = 80.0;
    messageView.frame = aFrame;
    messageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [messageBackground addSubview:messageView];
    
    if ([initialMessage length])
        messageView.text = initialMessage;
    
    UIImage *buttonImage = lookioImage(@"LIOAboutStretchableGreenButton");
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
    aFrame.origin.x = (rootView.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = messageBackground.frame.origin.y + messageBackground.frame.size.height + 3.0;
    submitButton.frame = aFrame;
    submitButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:submitButton];
    
    scrollView.contentSize = CGSizeMake(rootView.frame.size.width, submitButton.frame.origin.y + submitButton.frame.size.height);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [emailField release];
    emailField = nil;
    
    [fieldBackground release];
    fieldBackground = nil;
    
    [messageView release];
    messageView = nil;
    
    [scrollView release];
    scrollView = nil;
    
    [submitButton release];
    submitButton = nil;
    
    [messageBackground release];
    messageBackground = nil;
    
    [navBar release];
    navBar = nil;
}
                   
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [emailField release];
    [fieldBackground release];
    [messageView release];
    [scrollView release];
    [submitButton release];
    [initialEmailAddress release];
    [messageBackground release];
    [navBar release];
    
    [super dealloc];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
        [emailField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [delegate leaveMessageViewController:self shouldRotateToInterfaceOrientation:interfaceOrientation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (messageViewActive)
        [scrollView scrollRectToVisible:messageBackground.frame animated:YES];
    else
        [scrollView scrollRectToVisible:fieldBackground.frame animated:YES];
    
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
    if (keyboardShown)
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
    
    if (messageViewActive)
        [scrollView scrollRectToVisible:messageBackground.frame animated:YES];
    else
        [scrollView scrollRectToVisible:fieldBackground.frame animated:YES];
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
    if (NO == keyboardShown)
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
    [delegate leaveMessageViewControllerWasDismissed:self];
}

- (void)submitButtonWasTapped
{
    if ([messageView.text length])
    {
        [delegate leaveMessageViewController:self didSubmitEmailAddress:emailField.text withMessage:messageView.text];

        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Thank you!"
                                                            message:@"Your message has been received."
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Dismiss", nil];
        [alertView show];
        [alertView autorelease];
    }
    else
    {
        [delegate leaveMessageViewControllerWasDismissed:self];
    }
}

#pragma mark -
#pragma mark UITextFieldDelegate methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    messageViewActive = NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [messageView becomeFirstResponder];
    return YES;
}

#pragma mark -
#pragma mark UITextViewDelegate methods

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    messageViewActive = YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    messageViewActive = NO;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"])
    {
        [self submitButtonWasTapped];
        return NO;
    }
    
    return YES;
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [delegate leaveMessageViewControllerWasDismissed:self];
}

@end