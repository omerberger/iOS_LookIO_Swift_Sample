//
//  LIOTextEntryViewController.m
//  LookIO
//
//  Created by Joe Toscano on 9/9/11.
//  Copyright 2011 LookIO, Inc. All rights reserved.
//

#import "LIOTextEntryViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "LIOLookIOManager.h"

@implementation LIOTextEntryViewController

@synthesize delegate, instructionsText;

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
    
    cancelButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    cancelButton.frame = rootView.bounds;
    cancelButton.backgroundColor = [UIColor blackColor];
    cancelButton.alpha = 0.33;
    cancelButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [cancelButton addTarget:self action:@selector(cancelButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    [rootView addSubview:cancelButton];
    
    CGRect aFrame = CGRectZero;
    aFrame.origin.x = 10.0;
    aFrame.origin.y = 10.0;
    aFrame.size.width = rootView.frame.size.width - 20.0;
    aFrame.size.height = 110.0;
    
    bubbleView = [[UIView alloc] initWithFrame:aFrame];
    bubbleView.backgroundColor = [UIColor blackColor];
    bubbleView.alpha = 0.7;
    bubbleView.layer.masksToBounds = YES;
    bubbleView.layer.cornerRadius = 12.0;
    bubbleView.layer.borderColor = [UIColor whiteColor].CGColor;
    bubbleView.layer.borderWidth = 2.0;
    bubbleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [rootView addSubview:bubbleView];
    
    instructionsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    instructionsLabel.font = textEditor.font;
    instructionsLabel.textColor = [UIColor whiteColor];
    instructionsLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    instructionsLabel.text = @"QQQ";
    [instructionsLabel sizeToFit];
    aFrame = instructionsLabel.frame;
    aFrame.origin.x = bubbleView.frame.origin.x + 10.0;
    aFrame.origin.y = bubbleView.frame.origin.y + 5.0;
    instructionsLabel.frame = aFrame;
    instructionsLabel.layer.shadowOpacity = 1.0;
    instructionsLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    instructionsLabel.layer.shadowOffset = CGSizeMake(1.0, 2.0);
    instructionsLabel.layer.shadowRadius = 1.0;
    //instructionsLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [rootView addSubview:instructionsLabel];
    
    sendButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    [sendButton setBackgroundImage:[UIImage imageNamed:@"LIOSendActive"] forState:UIControlStateNormal];
    aFrame = sendButton.frame;
    aFrame.size.width = 59.0;
    aFrame.size.height = 27.0;
    aFrame.origin.x = bubbleView.frame.origin.x + bubbleView.frame.size.width - aFrame.size.width - 10.0;
    aFrame.origin.y = bubbleView.frame.origin.y + bubbleView.frame.size.height - aFrame.size.height - 10.0;
    sendButton.frame = aFrame;
    [sendButton addTarget:self action:@selector(sendButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    sendButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [rootView addSubview:sendButton];
    
    textEditor = [[UITextView alloc] initWithFrame:CGRectZero];
    textEditor.font = [UIFont systemFontOfSize:16.0];
    aFrame.size.width = bubbleView.frame.size.width - sendButton.frame.size.width - 25.0;
    aFrame.origin.x = instructionsLabel.frame.origin.x;
    aFrame.origin.y = instructionsLabel.frame.origin.y + instructionsLabel.frame.size.height + 5.0;
    aFrame.size.height = bubbleView.frame.size.height - instructionsLabel.frame.size.height - 20.0;
    textEditor.frame = aFrame;
    textEditor.layer.masksToBounds = YES;
    textEditor.layer.cornerRadius = 7.0;
    textEditor.layer.shadowOpacity = 1.0;
    textEditor.layer.shadowColor = [UIColor blackColor].CGColor;
    textEditor.layer.shadowRadius = 1.0;
    textEditor.layer.shadowOffset = CGSizeMake(0.0, 2.0);
    textEditor.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [rootView addSubview:textEditor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([delegate respondsToSelector:@selector(textEntryViewControllerReturnKeyType:)])
        textEditor.returnKeyType = [delegate textEntryViewControllerReturnKeyType:self];
    
    if ([delegate respondsToSelector:@selector(textEntryViewControllerKeyboardType:)])
        textEditor.keyboardType = [delegate textEntryViewControllerKeyboardType:self];
    
    if ([delegate respondsToSelector:@selector(textEntryViewControllerAutocorrectionType:)])
        textEditor.autocorrectionType = [delegate textEntryViewControllerAutocorrectionType:self];
    
    if ([delegate respondsToSelector:@selector(textEntryViewControllerAutocapitalizationType:)])
        textEditor.autocapitalizationType = [delegate textEntryViewControllerAutocapitalizationType:self];
    
    [textEditor becomeFirstResponder];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [cancelButton release];
    cancelButton = nil;
    
    [bubbleView release];
    bubbleView = nil;
    
    [sendButton release];
    sendButton = nil;
    
    [textEditor release];
    textEditor = nil;
    
    [instructionsLabel release];
    instructionsLabel = nil;
}

- (void)dealloc
{
    [cancelButton release];
    [sendButton release];
    [textEditor release];
    [instructionsLabel release];
    [bubbleView release];
    [instructionsText release];
    
    [super dealloc];
}

- (void)rejiggerLayout
{
    CGRect aFrame = CGRectMake(10.0, 10.0, self.view.bounds.size.width - 20.0, 110.0);
    if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom])
    {
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
            aFrame = CGRectMake(213.0, 10.0, 598.0, 110.0);
        else
            aFrame = CGRectMake(85.0, 10.0, 598.0, 110.0);
    }
    bubbleView.frame = aFrame;
    
    instructionsLabel.text = instructionsText;
    [instructionsLabel sizeToFit];
    aFrame = instructionsLabel.frame;
    aFrame.origin.x = bubbleView.frame.origin.x + 10.0;
    aFrame.origin.y = bubbleView.frame.origin.y + 5.0;
    instructionsLabel.frame = aFrame;
    
    aFrame = sendButton.frame;
    aFrame.size.width = 59.0;
    aFrame.size.height = 27.0;
    aFrame.origin.x = bubbleView.frame.origin.x + bubbleView.frame.size.width - aFrame.size.width - 10.0;
    aFrame.origin.y = bubbleView.frame.origin.y + bubbleView.frame.size.height - aFrame.size.height - 10.0;
    sendButton.frame = aFrame;
    
    aFrame.size.width = bubbleView.frame.size.width - sendButton.frame.size.width - 25.0;
    aFrame.origin.x = instructionsLabel.frame.origin.x;
    aFrame.origin.y = instructionsLabel.frame.origin.y + instructionsLabel.frame.size.height + 5.0;
    aFrame.size.height = bubbleView.frame.size.height - instructionsLabel.frame.size.height - 20.0;
    textEditor.frame = aFrame;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self rejiggerLayout];
    
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return [[LIOLookIOManager sharedLookIOManager].supportedOrientations containsObject:[NSNumber numberWithInt:toInterfaceOrientation]];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self rejiggerLayout];
}

#pragma mark -
#pragma mark UIControl actions

- (void)cancelButtonWasTapped
{
    [delegate textEntryViewControllerWasDismissed:self];
}

- (void)sendButtonWasTapped
{
    [delegate textEntryViewController:self wasDismissedWithText:textEditor.text];
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
