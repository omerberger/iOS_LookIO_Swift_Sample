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

@implementation LIOEmailHistoryViewController

@synthesize delegate;

- (void)loadView
{
    [super loadView];
    UIView *rootView = self.view;
    
    UIView *backgroundView = [[[UIView alloc] initWithFrame:rootView.bounds] autorelease];
    backgroundView.backgroundColor = [UIColor blackColor];
    backgroundView.alpha = 0.33;
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [rootView addSubview:backgroundView];
    
    scrollView = [[UIScrollView alloc] init];
    scrollView.frame = rootView.bounds;
    scrollView.autoresizingMask = backgroundView.autoresizingMask;
    [rootView addSubview:scrollView];
    
    bubbleView = [[UIView alloc] init];
    CGRect aFrame = CGRectZero;
    aFrame.origin.x = 5.0;
    aFrame.size.width = rootView.frame.size.width - 10.0;
    aFrame.origin.y = 5.0;
    aFrame.size.height = 137.0;
    bubbleView.frame = aFrame;
    bubbleView.backgroundColor = [UIColor blackColor];
    bubbleView.alpha = 0.7;
    bubbleView.layer.masksToBounds = YES;
    bubbleView.layer.cornerRadius = 12.0;
    bubbleView.layer.borderColor = [UIColor whiteColor].CGColor;
    bubbleView.layer.borderWidth = 2.0;
    bubbleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;// | UIViewAutoresizingFlexibleHeight;
    [scrollView addSubview:bubbleView];
    
    UILabel *instructionsLabel = [[[UILabel alloc] init] autorelease];
    instructionsLabel.font = [UIFont boldSystemFontOfSize:13.0];
    instructionsLabel.backgroundColor = [UIColor clearColor];
    instructionsLabel.textColor = [UIColor whiteColor];
    instructionsLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    instructionsLabel.layer.shadowOpacity = 1.0;
    instructionsLabel.layer.shadowOffset = CGSizeMake(2.0, 2.0);
    instructionsLabel.layer.shadowRadius = 1.0;
    instructionsLabel.numberOfLines = 2;
    instructionsLabel.text = @"Just enter your e-mail address and we'll send you a copy of this chat history.";
    instructionsLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    aFrame.origin.x = bubbleView.frame.origin.x + 12.0;
    aFrame.size.width = bubbleView.frame.size.width - 24.0;
    aFrame.origin.y = bubbleView.frame.origin.y + 5.0;
    aFrame.size.height = 30.0;
    instructionsLabel.frame = aFrame;
    [scrollView addSubview:instructionsLabel];
    
    UILabel *emailLabel = [[[UILabel alloc] init] autorelease];
    emailLabel.font = [UIFont systemFontOfSize:14.0];
    emailLabel.backgroundColor = [UIColor clearColor];
    emailLabel.textColor = [UIColor whiteColor];
    emailLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    emailLabel.layer.shadowOpacity = 1.0;
    emailLabel.layer.shadowOffset = CGSizeMake(2.0, 2.0);
    emailLabel.layer.shadowRadius = 1.0;
    emailLabel.numberOfLines = 1;
    emailLabel.text = @"Your Email Address:";
    aFrame.origin.x = bubbleView.frame.origin.x + 12.0;
    aFrame.size.width = bubbleView.frame.size.width - 24.0;
    aFrame.origin.y = instructionsLabel.frame.origin.y + instructionsLabel.frame.size.height + 10.0;
    aFrame.size.height = 15.0;
    emailLabel.frame = aFrame;
    emailLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:emailLabel];
    
    emailField = [[LIONiceTextField alloc] init];
    emailField.delegate = self;
    emailField.placeholder = @"name@example.com";
    emailField.keyboardType = UIKeyboardTypeEmailAddress;
    emailField.autocorrectionType = UITextAutocorrectionTypeNo;
    emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    aFrame.origin.x = bubbleView.frame.origin.x + 12.0;
    aFrame.size.width = bubbleView.frame.size.width - 24.0;
    aFrame.origin.y = emailLabel.frame.origin.y + emailLabel.frame.size.height + 5.0;
    aFrame.size.height = 30.0;
    emailField.frame = aFrame;
    emailField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:emailField];
    
    UIImage *greenButtonImage = [UIImage imageNamed:@"LIOGreenButton"];
    greenButtonImage = [greenButtonImage stretchableImageWithLeftCapWidth:16 topCapHeight:13];
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    aFrame.origin.x = bubbleView.frame.origin.x + 12.0;
    aFrame.size.width = 65.0;
    aFrame.origin.y = emailField.frame.origin.y + emailField.frame.size.height + 8.0;
    aFrame.size.height = 27.0;
    cancelButton.frame = aFrame;
    [cancelButton setBackgroundImage:greenButtonImage forState:UIControlStateNormal];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    [cancelButton addTarget:self action:@selector(cancelButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:cancelButton];
    
    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    aFrame.size.width = 59.0;
    aFrame.origin.x = bubbleView.frame.origin.x + bubbleView.frame.size.width - 59.0 - 12.0;
    aFrame.origin.y = emailField.frame.origin.y + emailField.frame.size.height + 8.0;
    aFrame.size.height = 27.0;
    sendButton.frame = aFrame;
    [sendButton setBackgroundImage:greenButtonImage forState:UIControlStateNormal];
    [sendButton setTitle:@"Send" forState:UIControlStateNormal];
    sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    [sendButton addTarget:self action:@selector(sendButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    sendButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [scrollView addSubview:sendButton];
    
    scrollView.contentSize = CGSizeMake(rootView.frame.size.width, bubbleView.frame.origin.y + bubbleView.frame.size.height);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [bubbleView release];
    bubbleView = nil;
    
    [emailField release];
    emailField = nil;
    
    [scrollView release];
    scrollView = nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [emailField release];
    [bubbleView release];
    [scrollView release];
    
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    
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
    return [[LIOLookIOManager sharedLookIOManager].supportedOrientations containsObject:[NSNumber numberWithInt:interfaceOrientation]];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.view endEditing:YES];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    scrollView.contentSize = CGSizeMake(self.view.frame.size.width, bubbleView.frame.origin.y + bubbleView.frame.size.height);
}

#pragma mark -
#pragma mark Notification handlers

- (void)keyboardDidShow:(NSNotification *)aNotification
{
    if (keyboardShown)
        return;
    
    NSDictionary *userInfo = [aNotification userInfo];
    
    NSTimeInterval animationDuration;
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [animationDurationValue getValue:&animationDuration];
    
    UIViewAnimationCurve animationCurve;
    NSValue *animationCurveValue = [userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    [animationCurveValue getValue:&animationCurve];
    
    NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardBounds = [self.view convertRect:[keyboardBoundsValue CGRectValue] fromView:nil];
    
    CGFloat keyboardHeight = keyboardBounds.size.height;
    
    CGRect aFrame = scrollView.frame;
    aFrame.size.height -= keyboardHeight;
    scrollView.frame = aFrame;
    
    [scrollView scrollRectToVisible:emailField.frame animated:YES];
    
    keyboardShown = YES;
}

- (void)keyboardDidHide:(NSNotification *)aNotification
{
    if (NO == keyboardShown)
        return;
    
    NSDictionary *userInfo = [aNotification userInfo];
    
    NSTimeInterval animationDuration;
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [animationDurationValue getValue:&animationDuration];
    
    UIViewAnimationCurve animationCurve;
    NSValue *animationCurveValue = [userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    [animationCurveValue getValue:&animationCurve];
    
    NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardBounds = [self.view convertRect:[keyboardBoundsValue CGRectValue] fromView:nil];
    
    CGFloat keyboardHeight = keyboardBounds.size.height;
    
    CGRect aFrame = scrollView.frame;
    aFrame.size.height += keyboardHeight;
    scrollView.frame = aFrame;
    
    keyboardShown = NO;
}

#pragma mark -
#pragma mark UIControl actions

- (void)cancelButtonWasTapped
{
    [delegate emailHistoryViewControllerWasDismissed:self];
}

- (void)sendButtonWasTapped
{
    [delegate emailHistoryViewController:self wasDismissedWithEmailAddress:emailField.text];
}

@end
