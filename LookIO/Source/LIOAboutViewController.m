//
//  LIOAboutViewController.m
//  LookIO
//
//  Created by Joseph Toscano on 10/25/11.
//  Copyright (c) 2011 LookIO, Inc. All rights reserved.
//

#import "LIOAboutViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "LIOLookIOManager.h"

@interface LIOAboutViewController ()
- (void)rejiggerInterface;
@end

@implementation LIOAboutViewController

@synthesize delegate;

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
        
    scrollView = [[UIScrollView alloc] init];
    scrollView.frame = rootView.bounds;
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [rootView addSubview:scrollView];
    
    UINavigationBar *navBar = [[[UINavigationBar alloc] init] autorelease];
    navBar.barStyle = UIBarStyleBlackOpaque;
    CGRect aFrame = navBar.frame;
    aFrame.size.width = rootView.frame.size.width;
    aFrame.size.height = 44.0;
    navBar.frame = aFrame;
    navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UINavigationItem *anItem = [[[UINavigationItem alloc] initWithTitle:@"About LookIO"] autorelease];
    UIBarButtonItem *closeItem = [[[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(closeButtonWasTapped)] autorelease];
    anItem.leftBarButtonItem = closeItem;
    [navBar pushNavigationItem:anItem animated:NO];
    navBar.delegate = self;
    [rootView addSubview:navBar];
    
    UIImageView *logoView = [[[UIImageView alloc] initWithImage:lookioImage(@"LIOAboutTitle")] autorelease];
    aFrame = logoView.frame;
    aFrame.origin.x = (rootView.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = navBar.frame.size.height + 5.0;
    logoView.frame = aFrame;
    logoView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [scrollView addSubview:logoView];
    
    UIImage *separatorImage = lookioImage(@"LIOAboutStretchableSeparator");
    UIImage *stretchableSeparatorImage = [separatorImage stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    
    UIImageView *topSeparator = [[[UIImageView alloc] initWithImage:stretchableSeparatorImage] autorelease];
    aFrame = topSeparator.frame;
    aFrame.origin.y = logoView.frame.origin.y + logoView.frame.size.height + 8.0;
    aFrame.size.width = rootView.frame.size.width;
    aFrame.size.height = 3.0;
    topSeparator.frame = aFrame;
    topSeparator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:topSeparator];
    
    UILabel *label01 = [[[UILabel alloc] init] autorelease];
    label01.text = @"Are you a developer? Join our beta:";
    label01.textColor = [UIColor whiteColor];
    label01.backgroundColor = [UIColor clearColor];
    label01.layer.shadowColor = [UIColor blackColor].CGColor;
    label01.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    label01.layer.shadowOpacity = 0.5;
    label01.layer.shadowRadius = 1.0;
    label01.font = [UIFont boldSystemFontOfSize:14.0];
    [label01 sizeToFit];
    aFrame = label01.frame;
    aFrame.origin.y = topSeparator.frame.origin.y + topSeparator.frame.size.height + 5.0;
    aFrame.origin.x = (rootView.frame.size.width / 2.0) - (label01.frame.size.width / 2.0);
    label01.frame = aFrame;
    label01.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [scrollView addSubview:label01];
    
    UILabel *label02 = [[[UILabel alloc] init] autorelease];
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
    
    inputField = [[UITextField alloc] init];
    inputField.backgroundColor = [UIColor clearColor];
    aFrame.origin.x = 10.0;
    aFrame.origin.y = 14.0;
    aFrame.size.width = 269.0;
    aFrame.size.height = 28.0;
    inputField.frame = aFrame;
    inputField.font = [UIFont systemFontOfSize:14.0];
    inputField.keyboardType = UIKeyboardTypeEmailAddress;
    inputField.autocorrectionType = UITextAutocorrectionTypeNo;
    inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [fieldBackground addSubview:inputField];
    
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
    aFrame.origin.y = fieldBackground.frame.origin.y + fieldBackground.frame.size.height + 3.0;
    submitButton.frame = aFrame;
    submitButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:submitButton];
    
    UIImageView *bottomSeparator = [[[UIImageView alloc] initWithImage:stretchableSeparatorImage] autorelease];
    aFrame = bottomSeparator.frame;
    aFrame.origin.y = submitButton.frame.origin.y + submitButton.frame.size.height + 8.0;
    aFrame.size.width = rootView.frame.size.width;
    aFrame.size.height = 3.0;
    bottomSeparator.frame = aFrame;
    bottomSeparator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:bottomSeparator];
    
    p1Container = [[UIView alloc] init];
    p1Container.backgroundColor = [UIColor clearColor];
    aFrame = p1Container.frame;
    aFrame.size.width = 290.0;
    aFrame.size.height = 84.0;
    aFrame.origin.x = (rootView.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = bottomSeparator.frame.origin.y + bottomSeparator.frame.size.height + 8.0;
    p1Container.frame = aFrame;
    p1Container.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:p1Container];
    
    UIImageView *bubbleIcon = [[[UIImageView alloc] initWithImage:lookioImage(@"LIOAboutPlusBubble")] autorelease];
    [p1Container addSubview:bubbleIcon];
    
    header01 = [[UILabel alloc] init];
    header01.text = @"About LookIO";
    header01.textColor = [UIColor whiteColor];
    header01.backgroundColor = [UIColor clearColor];
    header01.layer.shadowColor = [UIColor blackColor].CGColor;
    header01.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    header01.layer.shadowOpacity = 0.5;
    header01.layer.shadowRadius = 1.0;
    header01.font = [UIFont boldSystemFontOfSize:14.0];
    [header01 sizeToFit];
    aFrame = header01.frame;
    aFrame.origin.x = bubbleIcon.frame.origin.x + bubbleIcon.frame.size.width + 10.0;
    header01.frame = aFrame;
    [p1Container addSubview:header01];
    
    textsplosion01 = [[UILabel alloc] init];
    textsplosion01.text = @"LookIO enables developers to easily integrate live chat with visual feedback into any mobile application. It is all done with a simple SDK and one line of code.";
    textsplosion01.textColor = altBlue;
    textsplosion01.backgroundColor = [UIColor clearColor];
    textsplosion01.layer.shadowColor = [UIColor blackColor].CGColor;
    textsplosion01.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    textsplosion01.layer.shadowOpacity = 0.5;
    textsplosion01.layer.shadowRadius = 1.0;
    textsplosion01.font = [UIFont systemFontOfSize:12.0];
    CGSize restrictedSize = [textsplosion01.text sizeWithFont:textsplosion01.font constrainedToSize:CGSizeMake(p1Container.frame.size.width - header01.frame.origin.x, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    aFrame = textsplosion01.frame;
    aFrame.size = restrictedSize;
    aFrame.origin.x = header01.frame.origin.x;
    aFrame.origin.y = header01.frame.origin.y + header01.frame.size.height + 3.0;
    textsplosion01.frame = aFrame;
    textsplosion01.numberOfLines = 0;
    [p1Container addSubview:textsplosion01];
    
    p2Container = [[UIView alloc] init];
    p2Container.backgroundColor = [UIColor clearColor];
    aFrame = p2Container.frame;
    aFrame.size.width = 290.0;
    aFrame.size.height = 84.0;
    aFrame.origin.x = (rootView.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = p1Container.frame.origin.y + p1Container.frame.size.height + 8.0;
    p2Container.frame = aFrame;
    p2Container.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:p2Container];
    
    UIImageView *compassIcon = [[[UIImageView alloc] initWithImage:lookioImage(@"LIOAboutLookingGlass")] autorelease];
    [p2Container addSubview:compassIcon];
    
    header02 = [[UILabel alloc] init];
    header02.text = @"Can agents control my device?";
    header02.textColor = [UIColor whiteColor];
    header02.backgroundColor = [UIColor clearColor];
    header02.layer.shadowColor = [UIColor blackColor].CGColor;
    header02.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    header02.layer.shadowOpacity = 0.5;
    header02.layer.shadowRadius = 1.0;
    header02.font = [UIFont boldSystemFontOfSize:14.0];
    [header02 sizeToFit];
    aFrame = header02.frame;
    aFrame.origin.x = header01.frame.origin.x;
    header02.frame = aFrame;
    [p2Container addSubview:header02];
    
    textsplosion02 = [[UILabel alloc] init];
    textsplosion02.text = @"LookIO agents are only able to interact with the app that you're in & only if you accept or initiate a help session. Ending the session ends the access the agent has to your app.";
    textsplosion02.textColor = altBlue;
    textsplosion02.backgroundColor = [UIColor clearColor];
    textsplosion02.layer.shadowColor = [UIColor blackColor].CGColor;
    textsplosion02.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    textsplosion02.layer.shadowOpacity = 0.5;
    textsplosion02.layer.shadowRadius = 1.0;
    textsplosion02.font = [UIFont systemFontOfSize:12.0];
    restrictedSize = [textsplosion02.text sizeWithFont:textsplosion02.font constrainedToSize:CGSizeMake(p2Container.frame.size.width - header02.frame.origin.x, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    aFrame = textsplosion02.frame;
    aFrame.size = restrictedSize;
    aFrame.origin.x = header02.frame.origin.x;
    aFrame.origin.y = header02.frame.origin.y + header02.frame.size.height + 3.0;
    textsplosion02.frame = aFrame;
    textsplosion02.numberOfLines = 0;
    [p2Container addSubview:textsplosion02];
}

- (void)rejiggerInterface
{
    if (UIUserInterfaceIdiomPhone == [[UIDevice currentDevice] userInterfaceIdiom])
    {
        if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
        {
            CGRect aFrame = fieldBackground.frame;
            aFrame.size.width = 290.0;
            aFrame.size.height = 48.0;
            aFrame.origin.x = (self.view.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
            fieldBackground.frame = aFrame;
            
            submitButton.bounds = fieldBackground.bounds;
            aFrame = submitButton.frame;
            aFrame.origin.x = (self.view.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
            submitButton.frame = aFrame;
            
            CGSize restrictedSize = [textsplosion01.text sizeWithFont:textsplosion01.font constrainedToSize:CGSizeMake(p1Container.frame.size.width - header01.frame.origin.x, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
            aFrame = textsplosion01.frame;
            aFrame.size = restrictedSize;
            aFrame.origin.x = header01.frame.origin.x;
            aFrame.origin.y = header01.frame.origin.y + header01.frame.size.height + 3.0;
            textsplosion01.frame = aFrame;
            
            aFrame = p1Container.frame;
            aFrame.size.height = textsplosion01.frame.size.height + header01.frame.size.height;
            p1Container.frame = aFrame;
            
            restrictedSize = [textsplosion02.text sizeWithFont:textsplosion02.font constrainedToSize:CGSizeMake(p2Container.frame.size.width - header02.frame.origin.x, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
            aFrame = textsplosion02.frame;
            aFrame.size = restrictedSize;
            textsplosion02.frame = aFrame;
            
            aFrame = p2Container.frame;
            aFrame.size.height = textsplosion02.frame.size.height + header02.frame.size.height;
            aFrame.origin.y = p1Container.frame.origin.y + p1Container.frame.size.height + 8.0;
            p2Container.frame = aFrame;
        }
        else
        {
            CGSize restrictedSize = [textsplosion01.text sizeWithFont:textsplosion01.font constrainedToSize:CGSizeMake(p1Container.frame.size.width - header01.frame.origin.x, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
            CGRect aFrame = textsplosion01.frame;
            aFrame.size = restrictedSize;
            aFrame.origin.x = header01.frame.origin.x;
            aFrame.origin.y = header01.frame.origin.y + header01.frame.size.height + 3.0;
            textsplosion01.frame = aFrame;
            
            aFrame = p1Container.frame;
            aFrame.size.height = textsplosion01.frame.size.height + header01.frame.size.height;
            p1Container.frame = aFrame;
            
            restrictedSize = [textsplosion02.text sizeWithFont:textsplosion02.font constrainedToSize:CGSizeMake(p2Container.frame.size.width - header02.frame.origin.x, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
            aFrame = textsplosion02.frame;
            aFrame.size = restrictedSize;
            textsplosion02.frame = aFrame;
            
            aFrame = p2Container.frame;
            aFrame.size.height = textsplosion02.frame.size.height + header02.frame.size.height;
            aFrame.origin.y = p1Container.frame.origin.y + p1Container.frame.size.height + 8.0;
            p2Container.frame = aFrame;
        }
    }
    else
    {
        if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
        {
            CGRect aFrame = fieldBackground.frame;
            aFrame.size.width = 407.0;
            aFrame.size.height = 48.0;
            aFrame.origin.x = (self.view.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
            fieldBackground.frame = aFrame;
            
            submitButton.bounds = fieldBackground.bounds;
            aFrame = submitButton.frame;
            aFrame.origin.x = (self.view.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
            submitButton.frame = aFrame;
            
            aFrame = p1Container.frame;
            aFrame.size.width = fieldBackground.frame.size.width;
            aFrame.origin.x = (self.view.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
            p1Container.frame = aFrame;
            
            aFrame = p2Container.frame;
            aFrame.size.width = fieldBackground.frame.size.width;
            aFrame.origin.x = (self.view.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
            p2Container.frame = aFrame;
            
            CGSize restrictedSize = [textsplosion01.text sizeWithFont:textsplosion01.font constrainedToSize:CGSizeMake(p1Container.frame.size.width - header01.frame.origin.x, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
            aFrame = textsplosion01.frame;
            aFrame.size = restrictedSize;
            aFrame.origin.x = header01.frame.origin.x;
            aFrame.origin.y = header01.frame.origin.y + header01.frame.size.height + 3.0;
            textsplosion01.frame = aFrame;
            
            aFrame = p1Container.frame;
            aFrame.size.height = textsplosion01.frame.size.height + header01.frame.size.height;
            p1Container.frame = aFrame;
            
            restrictedSize = [textsplosion02.text sizeWithFont:textsplosion02.font constrainedToSize:CGSizeMake(p2Container.frame.size.width - header02.frame.origin.x, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
            aFrame = textsplosion02.frame;
            aFrame.size = restrictedSize;
            textsplosion02.frame = aFrame;
            
            aFrame = p2Container.frame;
            aFrame.size.height = textsplosion02.frame.size.height + header02.frame.size.height;
            aFrame.origin.y = p1Container.frame.origin.y + p1Container.frame.size.height + 8.0;
            p2Container.frame = aFrame;            
        }
        else
        {
            CGSize restrictedSize = [textsplosion01.text sizeWithFont:textsplosion01.font constrainedToSize:CGSizeMake(p1Container.frame.size.width - header01.frame.origin.x, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
            CGRect aFrame = textsplosion01.frame;
            aFrame.size = restrictedSize;
            aFrame.origin.x = header01.frame.origin.x;
            aFrame.origin.y = header01.frame.origin.y + header01.frame.size.height + 3.0;
            textsplosion01.frame = aFrame;
            
            aFrame = p1Container.frame;
            aFrame.size.height = textsplosion01.frame.size.height + header01.frame.size.height;
            p1Container.frame = aFrame;
            
            restrictedSize = [textsplosion02.text sizeWithFont:textsplosion02.font constrainedToSize:CGSizeMake(p2Container.frame.size.width - header02.frame.origin.x, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
            aFrame = textsplosion02.frame;
            aFrame.size = restrictedSize;
            textsplosion02.frame = aFrame;
            
            aFrame = p2Container.frame;
            aFrame.size.height = textsplosion02.frame.size.height + header02.frame.size.height;
            aFrame.origin.y = p1Container.frame.origin.y + p1Container.frame.size.height + 8.0;
            p2Container.frame = aFrame;
        }
    }
    
    scrollView.contentSize = CGSizeMake(self.view.frame.size.width, p2Container.frame.origin.y + p2Container.frame.size.height);
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
    
    [inputField release];
    inputField = nil;
    
    [p2Container release];
    p2Container = nil;
    
    [fieldBackground release];
    fieldBackground = nil;
    
    [submitButton release];
    submitButton = nil;
    
    [p1Container release];
    p1Container = nil;
    
    [textsplosion01 release];
    textsplosion01 = nil;
    
    [textsplosion02 release];
    textsplosion02 = nil;
    
    [header01 release];
    header01 = nil;
    
    [header02 release];
    header02 = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self rejiggerInterface];
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
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [scrollView release];
    [inputField release];
    [p2Container release];
    [fieldBackground release];
    [submitButton release];
    [p1Container release];
    [textsplosion01 release];
    [textsplosion02 release];
    [header01 release];
    [header02 release];
    
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [delegate aboutViewController:self shouldRotateToInterfaceOrientation:interfaceOrientation];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.view endEditing:YES];
    
    [self rejiggerInterface];
    
    scrollView.contentSize = CGSizeMake(self.view.frame.size.width, p2Container.frame.origin.y + p2Container.frame.size.height);
}

#pragma mark -
#pragma mark Control actions

- (void)closeButtonWasTapped
{
    [delegate aboutViewControllerWasDismissed:self];
}

- (void)submitButtonWasTapped
{
    if ([inputField.text length])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Thank you!"
                                                            message:@"We just sent you an e-mail with some additional information."
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Dismiss", nil];
        [alertView show];
        [alertView autorelease];
    }
    else
    {
        [delegate aboutViewController:self wasDismissedWithEmail:inputField.text];
    }
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
    
    [scrollView scrollRectToVisible:fieldBackground.frame animated:YES];
    
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
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [delegate aboutViewController:self wasDismissedWithEmail:inputField.text];
}

@end
