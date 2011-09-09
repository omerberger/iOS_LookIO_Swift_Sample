//
//  LIOFeedbackViewController.m
//  LookIO
//
//  Created by Joe Toscano on 9/9/11.
//  Copyright 2011 LookIO, Inc. All rights reserved.
//

#import "LIOFeedbackViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation LIOFeedbackViewController

@synthesize delegate;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)loadView
{
    [super loadView];
    UIView *rootView = self.view;
    
    backgroundView = [[UIView alloc] initWithFrame:rootView.bounds];
    backgroundView.backgroundColor = [UIColor blackColor];
    backgroundView.alpha = 0.33;
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [rootView addSubview:backgroundView];
    
    /*
    scrollView = [[UIScrollView alloc] initWithFrame:rootView.bounds];
    //scrollView.autoresizingMask = backgroundView.autoresizingMask;
    scrollView.backgroundColor = [UIColor blueColor];
    [rootView addSubview:scrollView];
     */
    
    Class $UIGlassButton = NSClassFromString(@"UIGlassButton");
    
    textEditor = [[UITextView alloc] initWithFrame:CGRectZero];
    textEditor.font = [UIFont systemFontOfSize:18.0];
    CGRect aFrame = CGRectZero;
    /*
    aFrame.size.width = scrollView.frame.size.width - 20.0;
    aFrame.size.height = scrollView.frame.size.height / 3.0;
    aFrame.origin.x = (scrollView.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = (scrollView.frame.size.height / 2.0) - (aFrame.size.height / 2.0);
    */
    aFrame.size.width = rootView.frame.size.width - 20.0;
    aFrame.size.height = 60.0;
    aFrame.origin.x = (rootView.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = 30.0;
    textEditor.frame = aFrame;
    textEditor.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    textEditor.layer.masksToBounds = YES;
    textEditor.layer.cornerRadius = 7.0;
    [rootView addSubview:textEditor];
    
    instructionsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    instructionsLabel.font = textEditor.font;
    instructionsLabel.textColor = [UIColor whiteColor];
    instructionsLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    instructionsLabel.text = @"Feedback:";
    [instructionsLabel sizeToFit];
    aFrame = instructionsLabel.frame;
    aFrame.origin.x = textEditor.frame.origin.x;
    aFrame.origin.y = textEditor.frame.origin.y - aFrame.size.height - 5.0;
    instructionsLabel.frame = aFrame;
    //instructionsLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [rootView addSubview:instructionsLabel];
    
    cancelButton = [[$UIGlassButton alloc] initWithFrame:CGRectZero];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton sizeToFit];
    aFrame = [cancelButton frame];
    aFrame.origin.y = textEditor.frame.origin.y + textEditor.frame.size.height + 5.0;
    aFrame.origin.x = textEditor.frame.origin.x;
    [cancelButton setFrame:aFrame];
    //[cancelButton setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
    [rootView addSubview:cancelButton];
    
    sendButton = [[$UIGlassButton alloc] initWithFrame:CGRectZero];
    [sendButton setTitle:@"Send" forState:UIControlStateNormal];
    [sendButton addTarget:self action:@selector(sendButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    [sendButton sizeToFit];
    aFrame = [sendButton frame];
    aFrame.origin.y = textEditor.frame.origin.y + textEditor.frame.size.height + 5.0;
    aFrame.origin.x = textEditor.frame.origin.x + textEditor.frame.size.width - aFrame.size.width;
    [sendButton setFrame:aFrame];
    [sendButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    [rootView addSubview:sendButton];
    
    //scrollView.contentSize = CGSizeMake(scrollView.bounds.size.width, [sendButton frame].origin.y + [sendButton frame].size.height + 5.0);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [textEditor becomeFirstResponder];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [backgroundView release];
    backgroundView = nil;
    
    /*
    [scrollView release];
    scrollView = nil;
     */
    
    [cancelButton release];
    cancelButton = nil;
    
    [sendButton release];
    sendButton = nil;
    
    [textEditor release];
    textEditor = nil;
}

- (void)dealloc
{
    [backgroundView release];
    //[scrollView release];
    [cancelButton release];
    [sendButton release];
    [textEditor release];
    
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    /*
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
     */
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    /*
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
     */
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

/*
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    scrollView.contentSize = CGSizeMake(self.view.frame.size.width, [sendButton frame].origin.y + [sendButton frame].size.height + 5.0);
}
*/

#pragma mark -
#pragma mark UIControl actions

- (void)cancelButtonWasTapped
{
    [delegate feedbackViewControllerWasDismissed:self];
}

- (void)sendButtonWasTapped
{
    [delegate feedbackViewController:self wantsToSendMessage:textEditor.text];
}

/*
#pragma mark -
#pragma mark Notification handlers

- (void)keyboardWillShow:(NSNotification *)aNotification
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
    
    [scrollView scrollRectToVisible:[textEditor convertRect:textEditor.frame toView:scrollView] animated:NO];
    
    keyboardShown = YES;
    
    NSLog(@"\n\nKeyboard SHOWN! scrollView.frame: %@", [NSValue valueWithCGRect:scrollView.frame]);
}

- (void)keyboardWillHide:(NSNotification *)aNotification
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
    
    NSLog(@"\n\nKeyboard HIDDEN! scrollView.frame: %@", [NSValue valueWithCGRect:scrollView.frame]);
}
*/

@end
