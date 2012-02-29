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
    
    suppressKeyboardNotifications = YES;
    
    UIView *backgroundView = [[[UIView alloc] initWithFrame:rootView.bounds] autorelease];
    backgroundView.backgroundColor = [UIColor blackColor];
    backgroundView.alpha = 0.33;
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [rootView addSubview:backgroundView];
    
    scrollView = [[UIScrollView alloc] init];
    scrollView.frame = rootView.bounds;
    scrollView.autoresizingMask = backgroundView.autoresizingMask;
    //scrollView.backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.5];
    [rootView addSubview:scrollView];

    CGFloat xInset = 5.0;
    if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom])
        xInset = 100.0;
    
    bubbleView = [[UIView alloc] init];
    CGRect aFrame = CGRectZero;
    aFrame.origin.x = xInset;
    aFrame.size.width = rootView.frame.size.width - (xInset * 2.0);
    aFrame.origin.y = 5.0;
    aFrame.size.height = 237.0;
    bubbleView.frame = aFrame;
    bubbleView.backgroundColor = [UIColor blackColor];
    bubbleView.alpha = 0.7;
    bubbleView.layer.masksToBounds = YES;
    bubbleView.layer.cornerRadius = 12.0;
    bubbleView.layer.borderColor = [UIColor whiteColor].CGColor;
    bubbleView.layer.borderWidth = 2.0;
    bubbleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;// | UIViewAutoresizingFlexibleHeight;
    [scrollView addSubview:bubbleView];
    
    instructionsLabel = [[UILabel alloc] init];
    instructionsLabel.font = [UIFont boldSystemFontOfSize:13.0];
    instructionsLabel.backgroundColor = [UIColor clearColor];
    instructionsLabel.textColor = [UIColor whiteColor];
    instructionsLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    instructionsLabel.layer.shadowOpacity = 1.0;
    instructionsLabel.layer.shadowOffset = CGSizeMake(2.0, 2.0);
    instructionsLabel.layer.shadowRadius = 1.0;
    instructionsLabel.numberOfLines = 2;
    instructionsLabel.text = @"Sorry, no agents are available. You may submit a message below for further help.";
    instructionsLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    aFrame.origin.x = bubbleView.frame.origin.x + 12.0;
    aFrame.size.width = bubbleView.frame.size.width - 24.0;
    aFrame.origin.y = bubbleView.frame.origin.y + 5.0;
    aFrame.size.height = 30.0;
    instructionsLabel.frame = aFrame;
    [scrollView addSubview:instructionsLabel];
    
    emailLabel = [[UILabel alloc] init];
    emailLabel.font = [UIFont systemFontOfSize:13.0];
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
    aFrame.origin.y = instructionsLabel.frame.origin.y + instructionsLabel.frame.size.height + 5.0;
    aFrame.size.height = 15.0;
    emailLabel.frame = aFrame;
    emailLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:emailLabel];
    
    emailField = [[LIONiceTextField alloc] init];
    emailField.font = [UIFont systemFontOfSize:13.0];
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
    
    if ([initialEmailAddress length])
        emailField.text = initialEmailAddress;
    
    messageLabel = [[UILabel alloc] init];
    messageLabel.font = [UIFont systemFontOfSize:13.0];
    messageLabel.backgroundColor = [UIColor clearColor];
    messageLabel.textColor = [UIColor whiteColor];
    messageLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    messageLabel.layer.shadowOpacity = 1.0;
    messageLabel.layer.shadowOffset = CGSizeMake(2.0, 2.0);
    messageLabel.layer.shadowRadius = 1.0;
    messageLabel.numberOfLines = 1;
    messageLabel.text = @"Message:";
    aFrame.origin.x = bubbleView.frame.origin.x + 12.0;
    aFrame.size.width = bubbleView.frame.size.width - 24.0;
    aFrame.origin.y = emailField.frame.origin.y + emailField.frame.size.height + 10.0;
    aFrame.size.height = 15.0;
    messageLabel.frame = aFrame;
    messageLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:messageLabel];
    
    messageViewBackground = [[UIImageView alloc] init];
    messageViewBackground.image = [lookioImage(@"LIOInputBar") stretchableImageWithLeftCapWidth:13 topCapHeight:13];
    aFrame.origin.x = bubbleView.frame.origin.x + 12.0;
    aFrame.size.width = bubbleView.frame.size.width - 24.0;
    aFrame.origin.y = messageLabel.frame.origin.y + messageLabel.frame.size.height + 5.0;
    aFrame.size.height = 75.0;
    messageViewBackground.frame = aFrame;
    messageViewBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:messageViewBackground];
    
    messageView = [[UITextView alloc] init];
    messageView.backgroundColor = [UIColor clearColor];
    messageView.font = emailField.font;
    aFrame.origin.x = bubbleView.frame.origin.x + 14.0;
    aFrame.size.width = bubbleView.frame.size.width - 28.0;
    aFrame.origin.y = messageLabel.frame.origin.y + messageLabel.frame.size.height + 7.0;
    //aFrame.size.height = 71.0;
    aFrame.size.height = 95.0;
    messageView.frame = aFrame;
    messageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    messageView.text = initialMessage;
    [scrollView addSubview:messageView];

    UIImage *glassButtonImage = lookioImage(@"LIOGlassButton");
    glassButtonImage = [glassButtonImage stretchableImageWithLeftCapWidth:15 topCapHeight:15];
    
    sendButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    sendButton.accessibilityLabel = @"LIOLeaveMessageSendButton";
    aFrame.size.width = 59.0;
    aFrame.origin.x = bubbleView.frame.origin.x + bubbleView.frame.size.width - 59.0 - 12.0;
    aFrame.origin.y = messageView.frame.origin.y + messageView.frame.size.height + 8.0 - 24.0;
    aFrame.size.height = 27.0;
    sendButton.frame = aFrame;
    [sendButton setBackgroundImage:glassButtonImage forState:UIControlStateNormal];
    [sendButton setTitle:@"Send" forState:UIControlStateNormal];
    sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    [sendButton addTarget:self action:@selector(sendButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    sendButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [scrollView addSubview:sendButton];
    
    cancelButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    aFrame.size.width = 65.0;
    aFrame.origin.x = sendButton.frame.origin.x - aFrame.size.width - 10.0;
    aFrame.origin.y = messageView.frame.origin.y + messageView.frame.size.height + 8.0 - 24.0;
    aFrame.size.height = 27.0;
    cancelButton.frame = aFrame;
    [cancelButton setBackgroundImage:glassButtonImage forState:UIControlStateNormal];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    [cancelButton addTarget:self action:@selector(cancelButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [scrollView addSubview:cancelButton];
    
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
    
    [messageView release];
    messageView = nil;
    
    [scrollView release];
    scrollView = nil;
    
    [instructionsLabel release];
    instructionsLabel = nil;
    
    [emailLabel release];
    emailLabel = nil;
    
    [messageLabel release];
    messageLabel = nil;
    
    [cancelButton release];
    cancelButton = nil;
    
    [sendButton release];
    sendButton = nil;
}
                   
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [emailField release];
    [messageView release];
    [bubbleView release];
    [scrollView release];
    [instructionsLabel release];
    [emailLabel release];
    [messageLabel release];
    [cancelButton release];
    [sendButton release];
    [initialEmailAddress release];
    
    [super dealloc];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    
    // auuuguguguguuughhhhhh
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [emailField becomeFirstResponder];
    });
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    
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
    
    [scrollView scrollRectToVisible:messageView.frame animated:YES];
    
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
    [self.view endEditing:YES];
    [delegate leaveMessageViewControllerWasDismissed:self];
}

- (void)sendButtonWasTapped
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
        [self.view endEditing:YES];
        [delegate leaveMessageViewControllerWasDismissed:self];
    }
}

#pragma mark -
#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [messageView becomeFirstResponder];
    return YES;
}


#pragma mark -
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [delegate leaveMessageViewControllerWasDismissed:self];
}

@end