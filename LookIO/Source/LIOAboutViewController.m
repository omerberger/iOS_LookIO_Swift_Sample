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

@implementation LIOAboutViewController

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
    
    CGFloat xInset = 5.0;
    CGFloat height = rootView.frame.size.height;
    if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom])
    {
        xInset = 100.0;
        height = 460.0;
    }
    
    bubbleView = [[UIView alloc] init];
    CGRect aFrame = CGRectZero;
    aFrame.origin.x = xInset;
    aFrame.size.width = rootView.frame.size.width - (xInset * 2.0);
    aFrame.origin.y = 5.0;
    aFrame.size.height = height;
    bubbleView.frame = aFrame;
    bubbleView.backgroundColor = [UIColor blackColor];
    bubbleView.alpha = 0.7;
    bubbleView.layer.masksToBounds = YES;
    bubbleView.layer.cornerRadius = 12.0;
    bubbleView.layer.borderColor = [UIColor whiteColor].CGColor;
    bubbleView.layer.borderWidth = 2.0;
    bubbleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:bubbleView];
    
    poweredByLabel = [[UILabel alloc] init];
    poweredByLabel.font = [UIFont boldSystemFontOfSize:14.0];
    poweredByLabel.backgroundColor = [UIColor clearColor];
    poweredByLabel.textColor = [UIColor whiteColor];
    poweredByLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    poweredByLabel.layer.shadowOpacity = 1.0;
    poweredByLabel.layer.shadowOffset = CGSizeMake(2.0, 2.0);
    poweredByLabel.layer.shadowRadius = 1.0;
    poweredByLabel.numberOfLines = 1;
    poweredByLabel.text = @"Powered by LookIO (www.look.io)";
    [poweredByLabel sizeToFit];
    aFrame = poweredByLabel.frame;
    aFrame.origin.x = bubbleView.frame.origin.x + 10.0;
    aFrame.size.width = bubbleView.frame.size.width - 20.0;
    aFrame.origin.y = bubbleView.frame.origin.y + 10.0;
    poweredByLabel.frame = aFrame;
    poweredByLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    poweredByLabel.textAlignment = UITextAlignmentCenter;
    [scrollView addSubview:poweredByLabel];
    
    UIView *blackLine = [[[UIView alloc] init] autorelease];
    blackLine.backgroundColor = [UIColor blackColor];
    aFrame = CGRectZero;
    aFrame.origin.x = bubbleView.frame.origin.x + 2.0;
    aFrame.size.width = bubbleView.frame.size.width - 4.0;
    aFrame.origin.y = poweredByLabel.frame.origin.y + poweredByLabel.frame.size.height + 10.0;
    aFrame.size.height = 1.0;
    blackLine.frame = aFrame;
    blackLine.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:blackLine];
    
    UIView *grayLine = [[[UIView alloc] init] autorelease];
    grayLine.backgroundColor = [UIColor darkGrayColor];
    aFrame = blackLine.frame;
    aFrame.origin.y = aFrame.origin.y + 1.0;
    grayLine.frame = aFrame;
    grayLine.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:grayLine];    
    
    areYouDeveloperLabel = [[UILabel alloc] init];
    areYouDeveloperLabel.font = [UIFont boldSystemFontOfSize:14.0];
    areYouDeveloperLabel.backgroundColor = [UIColor clearColor];
    areYouDeveloperLabel.textColor = [UIColor whiteColor];
    areYouDeveloperLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    areYouDeveloperLabel.layer.shadowOpacity = 1.0;
    areYouDeveloperLabel.layer.shadowOffset = CGSizeMake(2.0, 2.0);
    areYouDeveloperLabel.layer.shadowRadius = 1.0;
    areYouDeveloperLabel.numberOfLines = 1;
    areYouDeveloperLabel.text = @"Are you a developer? Join our beta:";
    [areYouDeveloperLabel sizeToFit];
    aFrame = areYouDeveloperLabel.frame;
    aFrame.origin.x = bubbleView.frame.origin.x + 10.0;
    aFrame.size.width = bubbleView.frame.size.width - 20.0;
    aFrame.origin.y = grayLine.frame.origin.y + grayLine.frame.size.height + 10.0;
    areYouDeveloperLabel.frame = aFrame;
    areYouDeveloperLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    areYouDeveloperLabel.textAlignment = UITextAlignmentCenter;
    [scrollView addSubview:areYouDeveloperLabel];
    
    emailLabel = [[UILabel alloc] init];
    emailLabel.font = [UIFont systemFontOfSize:14.0];
    emailLabel.backgroundColor = [UIColor clearColor];
    emailLabel.textColor = [UIColor whiteColor];
    emailLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    emailLabel.layer.shadowOpacity = 1.0;
    emailLabel.layer.shadowOffset = CGSizeMake(2.0, 2.0);
    emailLabel.layer.shadowRadius = 1.0;
    emailLabel.numberOfLines = 1;
    emailLabel.text = @"Your Email Address:";
    [emailLabel sizeToFit];
    aFrame = emailLabel.frame;
    aFrame.origin.x = bubbleView.frame.origin.x + 10.0;
    aFrame.origin.y = areYouDeveloperLabel.frame.origin.y + areYouDeveloperLabel.frame.size.height + 5.0;
    emailLabel.frame = aFrame;
    [scrollView addSubview:emailLabel];
    
    emailField = [[LIONiceTextField alloc] init];
    emailField.font = [UIFont systemFontOfSize:14.0];
    emailField.delegate = self;
    emailField.placeholder = @"name@example.com";
    emailField.keyboardType = UIKeyboardTypeEmailAddress;
    emailField.autocorrectionType = UITextAutocorrectionTypeNo;
    emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    aFrame.origin.x = bubbleView.frame.origin.x + 10.0;
    aFrame.size.width = bubbleView.frame.size.width - 20.0;
    aFrame.origin.y = emailLabel.frame.origin.y + emailLabel.frame.size.height + 5.0;
    aFrame.size.height = 30.0;
    emailField.frame = aFrame;
    emailField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:emailField];
    
    UIImage *glassButtonImage = lookioImage(@"LIOGlassButton");
    glassButtonImage = [glassButtonImage stretchableImageWithLeftCapWidth:15 topCapHeight:15];
    
    submitButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    aFrame.size.width = 65.0;
    aFrame.origin.x = bubbleView.frame.origin.x + bubbleView.frame.size.width - aFrame.size.width - 10.0;
    aFrame.origin.y = emailField.frame.origin.y + emailField.frame.size.height + 5.0;
    aFrame.size.height = 27.0;
    submitButton.frame = aFrame;
    [submitButton setBackgroundImage:glassButtonImage forState:UIControlStateNormal];
    [submitButton setTitle:@"Join Beta" forState:UIControlStateNormal];
    submitButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    [submitButton addTarget:self action:@selector(submitButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    submitButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [scrollView addSubview:submitButton];
    
    cancelButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    aFrame.size.width = 65.0;
    aFrame.origin.x = submitButton.frame.origin.x - aFrame.size.width - 5.0;
    aFrame.size.height = 27.0;
    aFrame.origin.y = emailField.frame.origin.y + emailField.frame.size.height + 5.0;
    cancelButton.frame = aFrame;
    [cancelButton setBackgroundImage:glassButtonImage forState:UIControlStateNormal];
    [cancelButton setTitle:@"Back" forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
    [cancelButton addTarget:self action:@selector(cancelButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [scrollView addSubview:cancelButton];
    
    UIView *blackLine2 = [[[UIView alloc] init] autorelease];
    blackLine2.backgroundColor = [UIColor blackColor];
    aFrame = CGRectZero;
    aFrame.origin.x = bubbleView.frame.origin.x + 2.0;
    aFrame.size.width = bubbleView.frame.size.width - 4.0;
    aFrame.origin.y = cancelButton.frame.origin.y + cancelButton.frame.size.height + 10.0;
    aFrame.size.height = 1.0;
    blackLine2.frame = aFrame;
    blackLine2.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:blackLine2];
    
    UIView *grayLine2 = [[[UIView alloc] init] autorelease];
    grayLine2.backgroundColor = [UIColor darkGrayColor];
    aFrame = blackLine2.frame;
    aFrame.origin.y = aFrame.origin.y + 1.0;
    grayLine2.frame = aFrame;
    grayLine2.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:grayLine2];    
    
    whatIsLabel = [[UILabel alloc] init];
    whatIsLabel.font = [UIFont boldSystemFontOfSize:14.0];
    whatIsLabel.backgroundColor = [UIColor clearColor];
    whatIsLabel.textColor = [UIColor whiteColor];
    whatIsLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    whatIsLabel.layer.shadowOpacity = 1.0;
    whatIsLabel.layer.shadowOffset = CGSizeMake(2.0, 2.0);
    whatIsLabel.layer.shadowRadius = 1.0;
    whatIsLabel.numberOfLines = 1;
    whatIsLabel.text = @"What is LookIO?";
    [whatIsLabel sizeToFit];
    aFrame = whatIsLabel.frame;
    aFrame.origin.x = bubbleView.frame.origin.x + 10.0;
    aFrame.origin.y = grayLine2.frame.origin.y + grayLine2.frame.size.height + 10.0;
    whatIsLabel.frame = aFrame;
    [scrollView addSubview:whatIsLabel];
    
    paragraphOne = [[UILabel alloc] init];
    paragraphOne.font = [UIFont systemFontOfSize:14.0];
    paragraphOne.backgroundColor = [UIColor clearColor];
    paragraphOne.textColor = [UIColor whiteColor];
    paragraphOne.layer.shadowColor = [UIColor blackColor].CGColor;
    paragraphOne.layer.shadowOpacity = 1.0;
    paragraphOne.layer.shadowOffset = CGSizeMake(2.0, 2.0);
    paragraphOne.layer.shadowRadius = 1.0;
    paragraphOne.numberOfLines = 0;
    paragraphOne.text = @"LookIO enables developers to easily integrate live chat with visual feedback into any mobile application. It's all done with a simple SDK and one line of code.";
    aFrame = paragraphOne.frame;
    aFrame.origin.x = bubbleView.frame.origin.x + 10.0;
    aFrame.size.width = bubbleView.frame.size.width - 20.0;
    aFrame.origin.y = whatIsLabel.frame.origin.y + whatIsLabel.frame.size.height + 5.0;
    aFrame.size.height = 77.0;
    paragraphOne.frame = aFrame;
    paragraphOne.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:paragraphOne];
    
    canAgentsLabel = [[UILabel alloc] init];
    canAgentsLabel.font = [UIFont boldSystemFontOfSize:14.0];
    canAgentsLabel.backgroundColor = [UIColor clearColor];
    canAgentsLabel.textColor = [UIColor whiteColor];
    canAgentsLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    canAgentsLabel.layer.shadowOpacity = 1.0;
    canAgentsLabel.layer.shadowOffset = CGSizeMake(2.0, 2.0);
    canAgentsLabel.layer.shadowRadius = 1.0;
    canAgentsLabel.numberOfLines = 1;
    canAgentsLabel.text = @"Can agents control my phone?";
    [canAgentsLabel sizeToFit];
    aFrame = canAgentsLabel.frame;
    aFrame.origin.x = bubbleView.frame.origin.x + 10.0;
    aFrame.origin.y = paragraphOne.frame.origin.y + paragraphOne.frame.size.height + 10.0;
    canAgentsLabel.frame = aFrame;
    [scrollView addSubview:canAgentsLabel];
    
    paragraphTwo = [[UILabel alloc] init];
    paragraphTwo.font = [UIFont systemFontOfSize:14.0];
    paragraphTwo.backgroundColor = [UIColor clearColor];
    paragraphTwo.textColor = [UIColor whiteColor];
    paragraphTwo.layer.shadowColor = [UIColor blackColor].CGColor;
    paragraphTwo.layer.shadowOpacity = 1.0;
    paragraphTwo.layer.shadowOffset = CGSizeMake(2.0, 2.0);
    paragraphTwo.layer.shadowRadius = 1.0;
    paragraphTwo.numberOfLines = 0;
    paragraphTwo.text = @"LookIO agents are only able to interact with the application that you're in & only if you accept or initiate a help session. Ending the session ends the access the agent has to your application.";
    [paragraphTwo sizeToFit];
    aFrame = paragraphTwo.frame;
    aFrame.origin.x = bubbleView.frame.origin.x + 10.0;
    aFrame.size.width = bubbleView.frame.size.width - 20.0;
    aFrame.origin.y = canAgentsLabel.frame.origin.y + canAgentsLabel.frame.size.height + 5.0;
    aFrame.size.height = 90.0;
    paragraphTwo.frame = aFrame;
    paragraphTwo.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:paragraphTwo];    
    
    scrollView.contentSize = CGSizeMake(rootView.frame.size.width, bubbleView.frame.origin.y + bubbleView.frame.size.height);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)dealloc
{
    [scrollView release];
    [bubbleView release];
    [cancelButton release];
    [submitButton release];
    [poweredByLabel release];
    [areYouDeveloperLabel release];
    [emailLabel release];
    [whatIsLabel release];
    [canAgentsLabel release];
    [paragraphOne release];
    [paragraphTwo release];
    [emailField release];

    
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [delegate aboutViewController:self shouldRotateToInterfaceOrientation:interfaceOrientation];
}

#pragma mark -
#pragma mark UIControl actions

- (void)cancelButtonWasTapped
{
    [delegate aboutViewControllerWasDismissed:self];
}

- (void)submitButtonWasTapped
{
    [delegate aboutViewController:self wasDismissedWithEmail:emailField.text];
}

@end
