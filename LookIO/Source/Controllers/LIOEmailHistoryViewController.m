//
//  LIOEmailHistoryViewController.m
//  LookIO
//
//  Created by Joe Toscano on 9/30/11.
//  Copyright 2011 LivePerson, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "LIOEmailHistoryViewController.h"
#import "LIOLookIOManager.h"
#import "LIOBundleManager.h"
#import "LIONavigationBar.h"

@implementation LIOEmailHistoryViewController

@synthesize delegate, initialEmailAddress;

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)loadView
{
    [super loadView];
    UIView *rootView = self.view;

    if (LIOIsUIKitFlatMode())
        if (![[UIApplication sharedApplication] isStatusBarHidden])
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    UIColor *textColor = [UIColor colorWithWhite:0.4 alpha:1.0];
        
    navBar = [[LIONavigationBar alloc] init];
    CGRect aFrame = navBar.frame;
    aFrame.size.width = rootView.frame.size.width;
    navBar.frame = aFrame;
    navBar.titleString = LIOLocalizedString(@"LIOEmailHistoryViewController.NavTitle");
    navBar.leftButtonText = LIOLocalizedString(@"LIOEmailHistoryViewController.NavLeftButton");
    navBar.delegate = self;
    [navBar layoutSubviews];
    navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [rootView addSubview:navBar];
    
    scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    aFrame = scrollView.frame;
    aFrame.origin.y = navBar.frame.size.height;
    aFrame.size.height -= aFrame.origin.y;
    scrollView.frame = aFrame;
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [rootView addSubview:scrollView];

    UIImage *texture = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOAboutRepeatableGrayTexture"];
    texture = [texture stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    
    UIImageView *backgroundView = [[[UIImageView alloc] init] autorelease];
    backgroundView.image = texture;
    aFrame = CGRectZero;
    aFrame.size.width = rootView.bounds.size.width;
    aFrame.size.height = rootView.bounds.size.height * 2.0;
    backgroundView.frame = aFrame;
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [scrollView addSubview:backgroundView];
    
    label01 = [[UILabel alloc] init];
    label01.text = LIOLocalizedString(@"LIOEmailHistoryViewController.HeaderText");
    label01.textColor = textColor;
    label01.backgroundColor = [UIColor clearColor];
    label01.font = [UIFont boldSystemFontOfSize:14.0];
    label01.minimumFontSize = 9.0;
    label01.adjustsFontSizeToFitWidth = YES;
    label01.lineBreakMode = UILineBreakModeMiddleTruncation;
    label01.textAlignment = UITextAlignmentCenter;
    [label01 sizeToFit];
    aFrame = label01.frame;
    aFrame.origin.y = 20.0;
    aFrame.origin.x = 10.0;
    aFrame.size.width = self.view.bounds.size.width - 20.0;
    label01.frame = aFrame;
    label01.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [scrollView addSubview:label01];
    
    label02 = [[UILabel alloc] init];
    label02.text = LIOLocalizedString(@"LIOEmailHistoryViewController.EmailHeader");
    label02.textColor = textColor;
    label02.backgroundColor = [UIColor clearColor];
    label02.font = [UIFont systemFontOfSize:12.0];
    [label02 sizeToFit];
    aFrame = label02.frame;
    aFrame.origin.y = label01.frame.origin.y + label01.frame.size.height + 10.0;
    aFrame.origin.x = (rootView.frame.size.width / 2.0) - (label02.frame.size.width / 2.0);
    label02.frame = aFrame;
    label02.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [scrollView addSubview:label02];
    
    UIImage *fieldImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOAboutStretchableInputField"];
    UIImage *stretchableFieldImage = [fieldImage stretchableImageWithLeftCapWidth:11 topCapHeight:0];
    
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
    inputField.accessibilityLabel = @"LIOEmailHistoryViewController.inputField";
    inputField.delegate = self;
    inputField.backgroundColor = [UIColor clearColor];
    aFrame.origin.x = 10.0;
    aFrame.origin.y = 14.0;
    if (LIOIsUIKitFlatMode())
        aFrame.origin.y = 10.0;
    aFrame.size.width = fieldBackground.frame.size.width - 20.0;
    aFrame.size.height = 28.0;
    inputField.frame = aFrame;
    inputField.font = [UIFont systemFontOfSize:14.0];
    inputField.placeholder = LIOLocalizedString(@"LIOEmailPlaceholder");
    inputField.keyboardType = UIKeyboardTypeEmailAddress;
    inputField.autocorrectionType = UITextAutocorrectionTypeNo;
    inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    inputField.returnKeyType = UIReturnKeySend;
    inputField.keyboardAppearance = UIKeyboardAppearanceAlert;
    if ([[[LIOLookIOManager sharedLookIOManager] pendingEmailAddress] length])
        inputField.text = [[LIOLookIOManager sharedLookIOManager] pendingEmailAddress];
    [fieldBackground addSubview:inputField];
    
    UIImage *buttonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOAboutStretchableMatteOrangeButton"];
    UIImage *stretchableButtonImage = [buttonImage stretchableImageWithLeftCapWidth:15 topCapHeight:0];
    
    submitButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    submitButton.accessibilityLabel = @"LIOEmailHistoryViewController.submitButton";
    [submitButton addTarget:self action:@selector(submitButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    [submitButton setBackgroundImage:stretchableButtonImage forState:UIControlStateNormal];
    [submitButton setTitle:LIOLocalizedString(@"LIOEmailHistoryViewController.SubmitButton") forState:UIControlStateNormal];
    [submitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    submitButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    submitButton.bounds = fieldBackground.bounds;
    aFrame = submitButton.frame;
    aFrame.size.width = self.view.bounds.size.width - 20.0;
    aFrame.origin.x = 10.0;
    aFrame.origin.y = fieldBackground.frame.origin.y + fieldBackground.frame.size.height + 8.0;
    submitButton.frame = aFrame;
    submitButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:submitButton];
    
    scrollView.contentSize = CGSizeMake(0.0, submitButton.frame.origin.y + submitButton.frame.size.height);
    
    [self.view bringSubviewToFront:navBar];
}

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
    
    [label01 release];
    label01 = nil;
    
    [label02 release];
    label02 = nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [alertView dismissWithClickedButtonIndex:-2742 animated:NO];
    [alertView autorelease];
    alertView = nil;
    
    [initialEmailAddress release];
    [scrollView release];
    [fieldBackground release];
    [inputField release];
    [submitButton release];
    [navBar release];
    [label01 release];
    [label02 release];
    
    [super dealloc];
}

- (void)rejiggerInterface
{
    [label01 sizeToFit];
    CGRect aFrame = label01.frame;
    aFrame.origin.y = 20.0;
    aFrame.origin.x = 10.0;
    aFrame.size.width = self.view.bounds.size.width - 20.0;
    label01.frame = aFrame;
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
    
    [self rejiggerInterface];
    
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
    
    [navBar layoutSubviews];
    
    CGRect aFrame = scrollView.frame;
    aFrame.origin.y = navBar.frame.origin.y + navBar.frame.size.height;
    CGFloat diff = aFrame.origin.y - scrollView.frame.origin.y;
    aFrame.size.height -= diff;
    scrollView.frame = aFrame;
    
    scrollView.contentSize = CGSizeMake(0.0, submitButton.frame.origin.y + submitButton.frame.size.height);
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
    [delegate emailHistoryViewController:self wasDismissedWithEmailAddress:nil];
}

- (void)submitButtonWasTapped
{
    if ([inputField.text length])
    {
        BOOL stricterFilter = YES; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
        NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
        NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
        NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        if (![emailTest evaluateWithObject:inputField.text]) {
            alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOEmailHistoryViewController.InvalidAlertTitle")
                                                   message:LIOLocalizedString(@"LIOEmailHistoryViewController.InvalidAlertBody")
                                                  delegate:nil
                                         cancelButtonTitle:nil
                                         otherButtonTitles:LIOLocalizedString(@"LIOEmailHistoryViewController.InvalidAlertButton"), nil];
            [alertView show];
            return;
        } else {
            alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOEmailHistoryViewController.SuccessAlertTitle")
                                               message:LIOLocalizedString(@"LIOEmailHistoryViewController.SuccessAlertBody")
                                              delegate:self
                                     cancelButtonTitle:nil
                                     otherButtonTitles:LIOLocalizedString(@"LIOEmailHistoryViewController.SuccessAlertButton"), nil];
            [alertView show];
        }
        
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
    if (buttonIndex < 0)
        return;
    
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [delegate emailHistoryViewController:self wasDismissedWithEmailAddress:inputField.text];
    });
}

#pragma mark -
#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.view endEditing:YES];
    [self submitButtonWasTapped];
    
    return NO;
}

#pragma mark -
#pragma mark LIONavigationBarDelegate methods

- (void)navigationBarDidTapLeftButton:(LIONavigationBar *)aBar
{
    [delegate emailHistoryViewController:self wasDismissedWithEmailAddress:nil];
}

- (void)navigationBarDidTapRightButton:(LIONavigationBar *)aBar
{
}

@end