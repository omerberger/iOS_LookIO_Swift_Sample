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
#import "LIOLogManager.h"
#import "TTTAttributedLabel.h"
#import "LIONotificationArea.h"
#import "LIOToasterView.h"

#define LIOAltChatViewControllerMaxHistoryLength   10
#define LIOAltChatViewControllerChatboxPadding     10.0
#define LIOAltChatViewControllerChatboxMinHeight   100.0

#define LIOAltChatViewControllerTableViewCellReuseId       @"LIOAltChatViewControllerTableViewCellReuseId"
#define LIOAltChatViewControllerTableViewCellBubbleViewTag 1001

// LIOGradientLayer gets rid of implicit layer animations.
@interface LIOGradientLayer : CAGradientLayer
@end
@implementation LIOGradientLayer
+ (id<CAAction>)defaultActionForKey:(NSString *)key { return NULL; }
- (id<CAAction>)actionForKey:(NSString *)key { return NULL; }
@end

@interface LIOAltChatViewController ()
- (void)rejiggerTableViewFrame;
@end

@implementation LIOAltChatViewController

@synthesize delegate, dataSource, initialChatText;
@dynamic agentTyping;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
        chatBubbleHeights = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)loadView
{
    [super loadView];
    
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    if (padUI)
    {
        CGColorRef darkColor = [UIColor colorWithWhite:0.1 alpha:1.0].CGColor;
        CGColorRef lightColor = [UIColor colorWithWhite:0.1 alpha:0.5].CGColor;
        
        horizGradient = [[LIOGradientLayer alloc] init];
        horizGradient.colors = [NSArray arrayWithObjects:(id)lightColor, (id)darkColor, nil];
        //horizGradient.backgroundColor = [UIColor clearColor].CGColor;
        horizGradient.frame = self.view.bounds;
        horizGradient.startPoint = CGPointMake(0.0, 0.5);
        horizGradient.endPoint = CGPointMake(1.0, 0.5);
        
        background = [[UIView alloc] initWithFrame:self.view.bounds];
        background.backgroundColor = [UIColor clearColor];
        background.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [background.layer addSublayer:horizGradient];
        [self.view addSubview:background];
    }
    else
    {
        CGColorRef darkColor = [UIColor colorWithWhite:0.1 alpha:1.0].CGColor;
        CGColorRef lightColor = [UIColor colorWithWhite:0.1 alpha:0.33].CGColor;
        
        vertGradient = [[LIOGradientLayer alloc] init];
        vertGradient.colors = [NSArray arrayWithObjects:(id)darkColor, (id)lightColor, (id)lightColor, (id)darkColor, nil];
        vertGradient.backgroundColor = [UIColor clearColor].CGColor;
        vertGradient.frame = self.view.bounds;
        
        horizGradient = [[LIOGradientLayer alloc] init];
        horizGradient.colors = [NSArray arrayWithObjects:(id)darkColor, (id)lightColor, (id)lightColor, (id)darkColor, nil];
        horizGradient.backgroundColor = [UIColor clearColor].CGColor;
        horizGradient.frame = self.view.bounds;
        horizGradient.startPoint = CGPointMake(0.0, 0.5);
        horizGradient.endPoint = CGPointMake(1.0, 0.5);
        
        background = [[UIView alloc] initWithFrame:self.view.bounds];
        background.backgroundColor = [UIColor clearColor];
        background.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [background.layer addSublayer:vertGradient];
        [background.layer addSublayer:horizGradient];
        [self.view addSubview:background];
    }
    
    CGRect tableViewFrame = self.view.bounds;
    UIViewAutoresizing tableViewAutoresizing;
    if (padUI)
    {
        tableViewFrame.origin.y = 0.0;
        tableViewFrame.origin.x = self.view.bounds.size.width - 360.0;
        tableViewFrame.size.width = 360.0;
        tableViewAutoresizing = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
    }
    else
    {
        tableViewFrame.origin.y = 32.0;
        tableViewFrame.size.height -= 112.0;
        tableViewAutoresizing = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    
    tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    //tableView.backgroundColor = [UIColor colorWithRed:(arc4random()%256)/255.0 green:(arc4random()%256)/255.0 blue:(arc4random()%256)/255.0 alpha:1.0];
    tableView.backgroundColor = [UIColor clearColor];
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.showsVerticalScrollIndicator = NO;
    tableView.showsHorizontalScrollIndicator = NO;
    tableView.autoresizingMask = tableViewAutoresizing;
    tableView.clipsToBounds = NO == padUI;
    [self.view addSubview:tableView];
    
    if (UIUserInterfaceIdiomPhone == [[UIDevice currentDevice] userInterfaceIdiom] && [tableView respondsToSelector:@selector(panGestureRecognizer)])
    {
        UIPanGestureRecognizer *panner = [tableView panGestureRecognizer];
        [panner addTarget:self action:@selector(handleTableViewPan:)];
    }
    
    // We need a tappable area for the entire left side of the iPad screen.
    if (padUI)
    {
        UITapGestureRecognizer *aTapper = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePadDismissalAreaTap:)] autorelease];
        
        tappableDismissalAreaForPadUI = [[UIView alloc] init];
        [tappableDismissalAreaForPadUI addGestureRecognizer:aTapper];
        tappableDismissalAreaForPadUI.backgroundColor = [UIColor clearColor];
        //tappableDismissalAreaForPadUI.backgroundColor = [UIColor colorWithRed:(arc4random()%256)/255.0 green:(arc4random()%256)/255.0 blue:(arc4random()%256)/255.0 alpha:1.0];
        CGRect aFrame;
        aFrame.origin.x = 0.0;
        aFrame.origin.y = 0.0;
        aFrame.size.width = self.view.bounds.size.width - tableView.frame.size.width;
        aFrame.size.height = self.view.bounds.size.height;
        tappableDismissalAreaForPadUI.frame = aFrame;
        tappableDismissalAreaForPadUI.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.view addSubview:tappableDismissalAreaForPadUI];
    }
    
    CGRect inputBarFrame = CGRectZero;
    if (padUI)
    {
        inputBarFrame.size.width = self.view.bounds.size.width;
        inputBarFrame.size.height = 75.0;
        inputBarFrame.origin.y = self.view.bounds.size.height - 75.0;
    }
    else
    {
        inputBarFrame.size.width = self.view.bounds.size.width;
        inputBarFrame.size.height = 40.0;
        inputBarFrame.origin.y = self.view.bounds.size.height - 40.0;
    }
    
    inputBar = [[LIOInputBarView alloc] initWithFrame:inputBarFrame];
    inputBar.delegate = self;
    inputBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:inputBar];
    [inputBar setNeedsLayout];
    
    if (NO == padUI)
    {
        dismissalBar = [[LIODismissalBarView alloc] init];
        //dismissalBar.backgroundColor = [UIColor colorWithRed:(arc4random()%256)/255.0 green:(arc4random()%256)/255.0 blue:(arc4random()%256)/255.0 alpha:1.0];
        dismissalBar.backgroundColor = [UIColor clearColor];
        CGRect aFrame = dismissalBar.frame;
        aFrame.size.width = self.view.frame.size.width;
        aFrame.size.height = 35.0;
        aFrame.origin.y = inputBar.frame.origin.y - aFrame.size.height;
        dismissalBar.frame = aFrame;
        dismissalBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        dismissalBar.delegate = self;
        [self.view insertSubview:dismissalBar belowSubview:inputBar];

        aFrame = CGRectZero;
        aFrame.size.width = self.view.bounds.size.width;
        aFrame.size.height = LIOHeaderBarViewDefaultHeight;
        
        headerBar = [[LIOHeaderBarView alloc] initWithFrame:aFrame];
        //headerBar.backgroundColor = [UIColor colorWithRed:(arc4random()%256)/255.0 green:(arc4random()%256)/255.0 blue:(arc4random()%256)/255.0 alpha:1.0];
        headerBar.backgroundColor = [UIColor clearColor];
        headerBar.delegate = self;
        headerBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.view addSubview:headerBar];
        
        UITapGestureRecognizer *tapper = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleHeaderBarTap:)] autorelease];
        [headerBar addGestureRecognizer:tapper];
    }
    else
    {
        toasterView = [[LIOToasterView alloc] init];
        toasterView.delegate = self;
        toasterView.yOrigin = self.view.bounds.size.height - 60.0;
        CGRect aFrame = toasterView.frame;
        aFrame.origin.x = -500.0;
        toasterView.frame = aFrame;
        [self.view addSubview:toasterView];
    }
    
    UIImage *grayStretchableButtonImage = [[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableRecessedButtonGray"] stretchableImageWithLeftCapWidth:13 topCapHeight:13];
    UIImage *redStretchableButtonImage = [[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchableRecessedButtonRed"] stretchableImageWithLeftCapWidth:13 topCapHeight:13];
    
    aboutButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    [aboutButton setBackgroundImage:grayStretchableButtonImage forState:UIControlStateNormal];
    aboutButton.titleLabel.font = [UIFont boldSystemFontOfSize:10.0];
    aboutButton.titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    aboutButton.titleLabel.layer.shadowOpacity = 0.8;
    aboutButton.titleLabel.layer.shadowOffset = CGSizeMake(0.0, -1.0);
    [aboutButton setTitle:@"About LP Mobile" forState:UIControlStateNormal];
    [aboutButton addTarget:self action:@selector(aboutButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    CGRect aFrame = aboutButton.frame;
    aFrame.size.width = 92.0;
    aFrame.size.height = 32.0;
    aFrame.origin.x = 15.0;
    aFrame.origin.y = 16.0;
    aboutButton.frame = aFrame;
    aboutButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
    
    emailConvoButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
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
    
    reconnectionOverlay = [[UIView alloc] initWithFrame:self.view.bounds];
    reconnectionOverlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.66];
    reconnectionOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    reconnectionOverlay.hidden = YES;
    [self.view addSubview:reconnectionOverlay];
    
    UIView *reconnectionBezel = [[[UIView alloc] init] autorelease];
    reconnectionBezel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:1.0];
    reconnectionBezel.layer.cornerRadius = 6.0;
    reconnectionBezel.layer.shadowColor = [UIColor whiteColor].CGColor;
    reconnectionBezel.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    reconnectionBezel.layer.shadowOpacity = 0.75;
    reconnectionBezel.layer.shadowRadius = 4.0;
    aFrame = reconnectionBezel.frame;
    aFrame.size.height = 75.0;
    aFrame.size.width = 200.0;
    aFrame.origin.x = (self.view.bounds.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = (self.view.bounds.size.height / 2.0) - (aFrame.size.height / 2.0);
    reconnectionBezel.frame = aFrame;
    reconnectionBezel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [reconnectionOverlay addSubview:reconnectionBezel];
    
    UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
    aFrame = spinner.frame;
    aFrame.origin.x = (reconnectionBezel.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = 18.0;
    spinner.frame = aFrame;
    [spinner startAnimating];
    [reconnectionBezel addSubview:spinner];
    
    UILabel *label = [[[UILabel alloc] init] autorelease];
    label.font = [UIFont systemFontOfSize:16.0];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    label.text = @"Reconnecting...";
    [label sizeToFit];
    aFrame = label.frame;
    aFrame.origin.x = (reconnectionBezel.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = spinner.frame.origin.y + spinner.frame.size.height;
    label.frame = aFrame;
    [reconnectionBezel addSubview:label];
    
    dismissButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    [dismissButton setBackgroundImage:grayStretchableButtonImage forState:UIControlStateNormal];
    dismissButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    dismissButton.titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    dismissButton.titleLabel.layer.shadowOpacity = 0.8;
    dismissButton.titleLabel.layer.shadowOffset = CGSizeMake(0.0, -1.0);
    [dismissButton setTitle:@"Hide" forState:UIControlStateNormal];
    [dismissButton addTarget:self action:@selector(dismissButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    aFrame = dismissButton.frame;
    aFrame.size.width = 92.0;
    aFrame.size.height = 32.0;
    aFrame.origin.x = (self.view.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
    aFrame.origin.y = reconnectionBezel.frame.origin.y + reconnectionBezel.frame.size.height + 20.0;
    dismissButton.frame = aFrame;
    dismissButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [reconnectionOverlay addSubview:dismissButton];
    
    UITapGestureRecognizer *tapper = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleReconnectionOverlayTap:)] autorelease];
    [reconnectionOverlay addGestureRecognizer:tapper];
    
    //[self.view bringSubviewToFront:tableView];
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
    
    [tappableDismissalAreaForPadUI release];
    tappableDismissalAreaForPadUI = nil;
    
    [inputBar release];
    inputBar = nil;
    
    [headerBar release];
    headerBar = nil;
    
    [functionHeader release];
    functionHeader = nil;
    
    [vertGradient release];
    vertGradient = nil;
    
    [horizGradient release];
    horizGradient = nil;
    
    [reconnectionOverlay release];
    reconnectionOverlay = nil;
    
    [popover release];
    popover = nil;
    
    [aboutButton release];
    aboutButton = nil;
    
    [emailConvoButton release];
    emailConvoButton = nil;
    
    [dismissButton release];
    dismissButton = nil;
    
    [toasterView release];
    toasterView = nil;
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
    [vertGradient release];
    [horizGradient release];
    [reconnectionOverlay release];
    [popover release];
    [aboutButton release];
    [emailConvoButton release];
    [chatBubbleHeights release];
    [tappableDismissalAreaForPadUI release];
    [pendingNotificationString release];
    [toasterView release];
    
    // I... don't know if this is such a great idea, but.
    [[LIOBundleManager sharedBundleManager] pruneImageCache];
    
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (leavingMessage)
        return;
    
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    if (NO == [[UIApplication sharedApplication] isStatusBarHidden])
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    
    [self reloadMessages];
    
    NSIndexPath *lastRow = [NSIndexPath indexPathForRow:[messages count] - 1 inSection:0];
    [tableView scrollToRowAtIndexPath:lastRow atScrollPosition:UITableViewScrollPositionTop animated:NO];
    
    if (NO == padUI)
        [self scrollToBottomDelayed:YES];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidChangeStatusBarOrientation:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    
    if ([initialChatText length])
    {
        inputBar.inputField.text = initialChatText;
        
        pendingChatText = initialChatText;
        
        initialChatText = nil;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (leavingMessage)
        return;
    
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    double delayInSeconds = 0.6;
    if (NO == padUI) delayInSeconds = 0.1;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [inputBar.inputField becomeFirstResponder];
        [inputBar setNeedsLayout];
    });
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    aboutScreenWasPresentedViaInputBarAdArea = NO;
    
    [popover dismissPopoverAnimated:NO];
    [popover autorelease];
    popover = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [delegate altChatViewController:self shouldRotateToInterfaceOrientation:interfaceOrientation];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    /*
    if (popover)
    {
        [popover dismissPopoverAnimated:NO];
        [popover autorelease];
        popover = nil;
    }
    */
    
    vertGradient.frame = self.view.bounds;
    horizGradient.frame = self.view.bounds;
    
    [self rejiggerTableViewFrame];
    
    [self reloadMessages];
    
    if (NO == padUI)
        [self scrollToBottomDelayed:NO];
}

- (void)rejiggerTableViewFrame
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    // Make sure the table view is perfectly sized.
    CGRect tableFrame = tableView.frame;
    UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsLandscape(actualOrientation))
    {
        CGFloat origin = 32.0;
        if (keyboardHeight || padUI)
            origin = 0.0;
        
        tableFrame.origin.y = origin;
        tableFrame.size.height = self.view.bounds.size.height - keyboardHeight - dismissalBar.frame.size.height - inputBar.frame.size.height - origin;
    }
    else
    {
        CGFloat origin = 32.0;
        if (padUI)
            origin = 0.0;
        
        tableFrame.origin.y = origin;
        tableFrame.size.height = self.view.bounds.size.height - keyboardHeight - dismissalBar.frame.size.height - inputBar.frame.size.height - origin;
    }
    tableView.frame = tableFrame;
}

- (void)showReconnectionOverlay
{
    [self dismissModalViewControllerAnimated:NO];
    [self.view endEditing:YES];
    reconnectionOverlay.hidden = NO;
}

- (void)hideReconnectionOverlay
{
    reconnectionOverlay.hidden = YES;
}

- (void)performRevealAnimation
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    if (padUI)
    {
        background.alpha = 0.0;
        
        [UIView animateWithDuration:0.2
                              delay:0.45
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             background.alpha = 1.0;
                         }
                         completion:^(BOOL finished) {
                             background.alpha = 1.0;
                         }];
        
        tableView.alpha = 0.5;
        
        CATransform3D translate = CATransform3DMakeTranslation(tableView.frame.size.width / 2.0, -tableView.frame.size.height / 2.0, 0.0);
        CATransform3D rotate = CATransform3DMakeRotation(M_PI, 0.0, 1.0, 0.0);
        CATransform3D initialTransform = CATransform3DConcat(rotate, translate);
        initialTransform.m34 = 1.0 / 1000.0;
        
        tableView.layer.anchorPoint = CGPointMake(1.0, 0.0);
        tableView.layer.transform = initialTransform;
        
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             tableView.alpha = 1.0;
                             tableView.layer.transform = translate;
                         }
                         completion:^(BOOL finished) {
                             tableView.layer.transform = CATransform3DIdentity;
                             tableView.layer.anchorPoint = CGPointMake(0.5, 0.5);
                             [self scrollToBottomDelayed:YES];
                             [self rejiggerTableViewFrame];
                         }];
    }
    else
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
                         toasterView.alpha = 0.0;
                         
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

- (void)scrollToBottomDelayed:(BOOL)delayed
{
    NSUInteger myScrollId = arc4random();
    currentScrollId = myScrollId;
    
    if (delayed)
    {
        double delayInSeconds = 0.75;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(){
            if (myScrollId == currentScrollId)
            {
                NSIndexPath *lastRow = [NSIndexPath indexPathForRow:[messages count] inSection:0];
                [tableView scrollToRowAtIndexPath:lastRow atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }
        });
    }
    else
    {
        NSIndexPath *lastRow = [NSIndexPath indexPathForRow:[messages count] inSection:0];
        [tableView scrollToRowAtIndexPath:lastRow atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (void)reloadMessages
{
    [messages release];
    messages = [[dataSource altChatViewControllerChatMessages:self] retain];
    
    // Pre-calculate all bubble heights. D:
    [chatBubbleHeights removeAllObjects];
    for (int i=0; i<[messages count]; i++)
    {
        LIOChatBubbleView *tempView = [[LIOChatBubbleView alloc] init];
        
        LIOChatMessage *aMessage = [messages objectAtIndex:i];
        if (LIOChatMessageKindLocal == aMessage.kind)
        {
            tempView.formattingMode = LIOChatBubbleViewFormattingModeLocal;
            tempView.senderName = @"Me";
        }
        else
        {
            tempView.formattingMode = LIOChatBubbleViewFormattingModeRemote;
            tempView.senderName = aMessage.senderName;
        }
        
        [tempView populateMessageViewWithText:aMessage.text];
        
        NSNumber *aHeight = [NSNumber numberWithFloat:tempView.frame.size.height];
        [chatBubbleHeights addObject:aHeight];
        
        [tempView release];
    }
    
    [tableView reloadData];
}

- (NSString *)currentChatText
{
    return inputBar.inputField.text;
}

- (void)revealNotificationString:(NSString *)aString withAnimatedKeyboard:(BOOL)animated
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    if (padUI)
    {
        if (toasterView.isShown)
        {
            if (NO == toasterView.keyboardIconVisible)
            {
                [pendingNotificationString release];
                pendingNotificationString = [aString retain];
                
                [toasterView hideAnimated:YES];
            }
        }
        else
        {
            toasterView.keyboardIconVisible = animated;
            toasterView.text = aString;
            [toasterView showAnimated:YES permanently:animated];
        }
    }
    else
        [headerBar revealNotificationString:aString withAnimatedKeyboard:animated permanently:animated];
}

- (void)refreshExpandingFooter
{
    NSIndexPath *expandingFooterIndex = [NSIndexPath indexPathForRow:([messages count] + 1) inSection:0];
    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:expandingFooterIndex] withRowAnimation:UITableViewRowAnimationNone];
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
    if (nil == aCell)
    {
        aCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LIOAltChatViewControllerTableViewCellReuseId];
        aCell.selectionStyle = UITableViewCellSelectionStyleNone;
        [aCell autorelease];
    }
    
    [aCell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    UITapGestureRecognizer *tapper = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTappableDummyCellViewTap:)] autorelease];
    UIView *tappableDummyView = [[[UIView alloc] init] autorelease];
    tappableDummyView.backgroundColor = [UIColor clearColor];
    tappableDummyView.frame = aCell.contentView.bounds;
    tappableDummyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [tappableDummyView addGestureRecognizer:tapper];
    [aCell.contentView addSubview:tappableDummyView];
    
    LIOChatBubbleView *aBubble = [[[LIOChatBubbleView alloc] initWithFrame:CGRectZero] autorelease];
    aBubble.backgroundColor = [UIColor clearColor];
    aBubble.tag = LIOAltChatViewControllerTableViewCellBubbleViewTag;
    aBubble.delegate = self;
    aBubble.index = indexPath.row;
    [aCell.contentView addSubview:aBubble];
    
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
    aBubble.rawChatMessage = aMessage;
    
    if (LIOChatBubbleViewFormattingModeRemote == aBubble.formattingMode)
        aBubble.frame = CGRectMake(0.0, 0.0, 290.0, 0.0);
    else
        aBubble.frame = CGRectMake(tableView.bounds.size.width - 290.0, 0.0, 290.0, 0.0);
    
    [aBubble setNeedsLayout];
    [aBubble setNeedsDisplay];    
    
    return aCell;
}

#pragma mark -
#pragma mark UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    if (0 == indexPath.row)
        return 64.0;
    
    if ([messages count] + 1 == indexPath.row)
    {
        if (padUI)
        {
            // We want to show more bubbles on iPad. Thus, a smaller expanding footer vs. iPhone.
            CGFloat heightAccum = 0.0;
            heightAccum += [self tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:[messages count] inSection:0]];
            if ([messages count] >= 1)
                heightAccum += [self tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:([messages count] - 1) inSection:0]];
            if ([messages count] >= 2)
                heightAccum += [self tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:([messages count] - 2) inSection:0]];
            
            CGFloat result = tableView.bounds.size.height - heightAccum;
            if (result < 0.0) result = 7.0 - 10.0;
            return result;
        }
        else
        {
            CGFloat heightOfLastBubble = [self tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:[messages count] inSection:0]];
            CGFloat result = tableView.bounds.size.height - heightOfLastBubble - 10.0;
            if (result < 0.0) result = 7.0;
            return result;
        }
    }
    
    NSNumber *aHeight = [chatBubbleHeights objectAtIndex:(indexPath.row - 1)];
    CGFloat height = [aHeight floatValue];
    
    if (height < LIOChatBubbleViewMinTextHeight)
        height = LIOChatBubbleViewMinTextHeight;
    
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
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    LIOAboutViewController *aController = [[[LIOAboutViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    aController.delegate = self;
    
    if (padUI)
    {
        //aController.modalInPopover = YES;
        aController.contentSizeForViewInPopover = CGSizeMake(320.0, 460.0);
        
        popover = [[UIPopoverController alloc] initWithContentViewController:aController];
        popover.popoverContentSize = CGSizeMake(320.0, 460.0);
        popover.delegate = self;
        [popover presentPopoverFromRect:aboutButton.frame inView:functionHeader.contentView permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
    else
    {
        [self presentModalViewController:aController animated:YES];
    }
}

- (void)emailConvoButtonWasTapped
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
        
    LIOEmailHistoryViewController *aController = [[[LIOEmailHistoryViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    aController.delegate = self;
    
    if (padUI)
    {
        //aController.modalInPopover = YES;
        aController.contentSizeForViewInPopover = CGSizeMake(320.0, 240.0);
        
        popover = [[UIPopoverController alloc] initWithContentViewController:aController];
        popover.popoverContentSize = CGSizeMake(320.0, 240.0);
        popover.delegate = self;
        [popover presentPopoverFromRect:emailConvoButton.frame inView:functionHeader.contentView permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
    else
    {
        [self presentModalViewController:aController animated:YES];
    }
}

- (void)endSessionButtonWasTapped
{
    [delegate altChatViewControllerDidTapEndSessionButton:self];
}

#pragma mark -
#pragma mark Gesture handlers

- (void)handleReconnectionOverlayTap:(UITapGestureRecognizer *)aTapper
{
    [delegate altChatViewController:self wasDismissedWithPendingChatText:pendingChatText];
}

- (void)handleHeaderBarTap:(UITapGestureRecognizer *)aTapper
{
    [self headerBarViewPlusButtonWasTapped:headerBar];
}

- (void)handleTableViewPan:(UIPanGestureRecognizer *)aPanner
{
    if (NO == keyboardShowing)
        return;
    
    CGPoint touchLocation = [aPanner locationInView:inputBar];
    if (touchLocation.y > 0.0)
    {
        [self.view endEditing:YES];
        currentScrollId = 0;
        //[self reloadMessages];
    }
}

- (void)handleTappableDummyCellViewTap:(UITapGestureRecognizer *)aTapper
{
    [delegate altChatViewController:self wasDismissedWithPendingChatText:pendingChatText];
}

- (void)handlePadDismissalAreaTap:(UITapGestureRecognizer *)aTapper
{
    [delegate altChatViewController:self wasDismissedWithPendingChatText:pendingChatText];
}

#pragma mark -
#pragma mark Notification handlers

- (void)applicationDidChangeStatusBarOrientation:(NSNotification *)aNotification
{
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if ([[UIApplication sharedApplication] statusBarOrientation] != self.interfaceOrientation)
            LIOLog(@"Warning! The LookIO UI isn't in the same orientation as the host app. You may want to make use of the following LIOLookIOManagerDelegate method: lookIOManager:shouldRotateToInterfaceOrientation:");
    });
}

- (void)keyboardWillShow:(NSNotification *)aNotification
{
    if (keyboardShowing)
        return;
    
    keyboardShowing = YES;
    
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
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
    
    keyboardHeight = keyboardBounds.size.height;
    if (UIInterfaceOrientationIsLandscape(actualOrientation))
        keyboardHeight = keyboardBounds.size.width;
    
    CGRect inputBarFrame = inputBar.frame;
    inputBarFrame.origin.y -= keyboardHeight;
    
    toasterView.yOrigin = inputBarFrame.origin.y - toasterView.frame.size.height - 10.0;
    [toasterView setNeedsLayout];
    
    CGRect dismissalBarFrame = dismissalBar.frame;
    CGRect headerFrame = headerBar.frame;
    CGRect tableFrame = tableView.frame;
    if (NO == padUI)
    {
        dismissalBarFrame.origin.y -= keyboardHeight - 15.0; // 15.0 is the difference in dismissal bar height
        dismissalBarFrame.size.height = 20.0;
        
        if (UIInterfaceOrientationIsLandscape(actualOrientation))
            headerFrame.origin.y = -headerFrame.size.height;
        
        if (UIInterfaceOrientationIsLandscape(actualOrientation))
        {
            tableFrame.origin.y = 0.0;
            tableFrame.size.height = self.view.bounds.size.height - keyboardHeight - dismissalBarFrame.size.height - inputBarFrame.size.height;
        }
        else
        {
            tableFrame.origin.y = 32.0;
            tableFrame.size.height = self.view.bounds.size.height - keyboardHeight - dismissalBarFrame.size.height - inputBarFrame.size.height - 32.0;
        }
    }
    else
    {
        tableFrame.size.height -= keyboardHeight;
    }
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
        inputBar.frame = inputBarFrame;
        tableView.frame = tableFrame;
    
        if (NO == padUI)
        {
            dismissalBar.frame = dismissalBarFrame;
            headerBar.frame = headerFrame;
        }
    [UIView commitAnimations];

    [self reloadMessages];
    
    if (nil == popover)
        [self scrollToBottomDelayed:NO];
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
    if (NO == keyboardShowing)
        return;
    
    keyboardShowing = NO;
        
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
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
    
    keyboardHeight = keyboardBounds.size.height;
    if (UIInterfaceOrientationIsLandscape(actualOrientation))
        keyboardHeight = keyboardBounds.size.width;
    
    CGRect inputBarFrame = inputBar.frame;
    inputBarFrame.origin.y += keyboardHeight;
    
    toasterView.yOrigin = inputBarFrame.origin.y - toasterView.frame.size.height - 10.0;
    [toasterView setNeedsLayout];
    
    CGRect dismissalBarFrame = dismissalBar.frame;
    CGRect headerFrame = headerBar.frame;
    CGRect tableFrame = tableView.frame;
    if (NO == padUI)
    {
        dismissalBarFrame.origin.y += keyboardHeight - 15.0;
        dismissalBarFrame.size.height = 35.0;
        
        headerFrame.origin.y = 0.0;
        
        tableFrame.origin.y = 32.0;
        CGFloat newTableHeight = 0.0;
        if (UIInterfaceOrientationIsLandscape(actualOrientation))
        {
            newTableHeight = tableFrame.size.height + keyboardHeight - 15.0 - 32.0;
        }
        else
        {
            newTableHeight = tableFrame.size.height + keyboardHeight - 15.0;
        }
        
        tableFrame.size.height = newTableHeight;
    }
    else
    {
        tableFrame.size.height += keyboardHeight;
    }
    
    CGPoint previousOffset = tableView.contentOffset;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
        inputBar.frame = inputBarFrame;
    
        if (NO == padUI)
        {
            dismissalBar.frame = dismissalBarFrame;
            headerBar.frame = headerFrame;
        }
    [UIView commitAnimations];

    // Sweet Jesus, the order of the following things is SUPER IMPORTANT.
    keyboardHeight = 0.0;
    tableView.frame = tableFrame;
    [self refreshExpandingFooter];
    tableView.contentOffset = CGPointMake(previousOffset.x, previousOffset.y);
}

- (void)keyboardDidShow:(NSNotification *)aNotification
{
    if (aboutScreenWasPresentedViaInputBarAdArea && popover)
    {
        [popover presentPopoverFromRect:inputBar.notificationArea.frame inView:inputBar permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
        aboutScreenWasPresentedViaInputBarAdArea = NO;
    }
}

- (void)keyboardDidHide:(NSNotification *)aNotification
{
    if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom])
        [self refreshExpandingFooter];
    
//    if (aboutScreenWasPresentedViaInputBarAdArea)
//        [popover presentPopoverFromRect:inputBar.notificationArea.frame inView:inputBar permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}

#pragma mark -
#pragma mark LIOInputBarViewDelegate methods

- (void)inputBarView:(LIOInputBarView *)aView didChangeNumberOfLines:(NSInteger)numLinesDelta
{
    /*
    CGFloat deltaHeight = aView.singleLineHeight * numLinesDelta;
    
    CGRect aFrame = inputBar.frame;
    aFrame.origin.y -= deltaHeight;
    inputBar.frame = aFrame;
     */
}

- (void)inputBarView:(LIOInputBarView *)aView didChangeDesiredHeight:(CGFloat)desiredHeight
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    CGRect aFrame = inputBar.frame;
    aFrame.size.height = desiredHeight;
    aFrame.origin.y = self.view.bounds.size.height - keyboardHeight - aFrame.size.height;
    inputBar.frame = aFrame;
    
    if (NO == padUI)
    {
        CGRect aFrame = dismissalBar.frame;
        aFrame.origin.y = inputBar.frame.origin.y - aFrame.size.height;
        dismissalBar.frame = aFrame;
    }
    else
    {
        toasterView.yOrigin = inputBar.frame.origin.y - toasterView.frame.size.height - 10.0;
        [toasterView setNeedsLayout];
    }
    
    [self rejiggerTableViewFrame];
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
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
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
            
            if (padUI)
                aController.modalPresentationStyle = UIModalPresentationFormSheet;
            
            leavingMessage = YES;            
            
            [self presentModalViewController:aController animated:YES];
        }
    }
    
    [pendingChatText release];
    pendingChatText = nil;
    
    [self.view endEditing:YES];
    
    //[self reloadMessages];
}

- (void)inputBarViewDidTapAdArea:(LIOInputBarView *)aView
{
    // This only applies to iPad.
    
    aboutScreenWasPresentedViaInputBarAdArea = YES;
    
    LIOAboutViewController *aController = [[[LIOAboutViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    aController.delegate = self;
    //aController.modalInPopover = YES;
    aController.contentSizeForViewInPopover = CGSizeMake(320.0, 460.0);
    
    popover = [[UIPopoverController alloc] initWithContentViewController:aController];
    popover.delegate = self;
    [popover presentPopoverFromRect:inputBar.notificationArea.frame inView:inputBar permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}

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
    if (popover)
    {
        aboutScreenWasPresentedViaInputBarAdArea = NO;
        
        [popover dismissPopoverAnimated:NO];
        [popover autorelease];
        popover = nil;
    }
    else
        [self dismissModalViewControllerAnimated:YES];
}

- (void)aboutViewController:(LIOAboutViewController *)aController wasDismissedWithEmail:(NSString *)anEmail
{
    if ([anEmail length])
        [delegate altChatViewController:self didEnterBetaEmail:anEmail];
    
    if (popover)
    {
        aboutScreenWasPresentedViaInputBarAdArea = NO;
        
        [popover dismissPopoverAnimated:NO];
        [popover autorelease];
        popover = nil;
    }
    else
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
    if (popover)
    {
        [popover dismissPopoverAnimated:NO];
        [popover autorelease];
        popover = nil;
    }
    else
        [self dismissModalViewControllerAnimated:YES];
}

- (void)emailHistoryViewController:(LIOEmailHistoryViewController *)aController wasDismissedWithEmailAddress:(NSString *)anEmail
{
    if (popover)
    {
        [popover dismissPopoverAnimated:NO];
        [popover autorelease];
        popover = nil;
    }
    else
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

- (void)leaveMessageViewControllerWasCancelled:(LIOLeaveMessageViewController *)aController
{
    [self dismissModalViewControllerAnimated:NO];
    
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [delegate altChatViewControllerWantsSessionTermination:self];
    });
}

- (void)leaveMessageViewController:(LIOLeaveMessageViewController *)aController didSubmitEmailAddress:(NSString *)anEmail withMessage:(NSString *)aMessage
{
    [delegate altChatViewController:self didEnterLeaveMessageEmail:anEmail withMessage:aMessage];
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

#pragma mark -
#pragma mark Dynamic accessors

- (BOOL)isAgentTyping
{
    return agentTyping;
}

- (void)setAgentTyping:(BOOL)aBool
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    if (NO == agentTyping && aBool)
    {
        pendingNotificationStringIsTypingNotification = YES;
        [self revealNotificationString:@"Agent is typing..." withAnimatedKeyboard:YES];
    }
    else if (agentTyping && NO == aBool)
    {
        if (padUI)
            [toasterView hideAnimated:YES];
        else
            [self revealNotificationString:nil withAnimatedKeyboard:NO];
    }
    
    agentTyping = aBool;
}

#pragma mark -
#pragma mark LIOChatBubbleViewDelegate methods

- (void)chatBubbleViewWantsCopyMenu:(LIOChatBubbleView *)aView
{
    NSInteger index = aView.index;
    
    [self.view endEditing:YES];
    
    UITableViewCell *aCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    LIOChatBubbleView *newChatBubbleView = (LIOChatBubbleView *)[aCell viewWithTag:LIOAltChatViewControllerTableViewCellBubbleViewTag];
    
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [newChatBubbleView enterCopyModeAnimated:YES];
    });
}

#pragma mark -
#pragma mark LIOToasterViewDelegate methods

- (void)toasterViewDidFinishShowing:(LIOToasterView *)aView
{
    pendingNotificationStringIsTypingNotification = NO;
}

- (void)toasterViewDidFinishHiding:(LIOToasterView *)aView
{
    if ([pendingNotificationString length])
    {
        toasterView.keyboardIconVisible = pendingNotificationStringIsTypingNotification;
        toasterView.text = pendingNotificationString;
        [toasterView showAnimated:YES permanently:pendingNotificationStringIsTypingNotification];
        
        pendingNotificationStringIsTypingNotification = NO;
        [pendingNotificationString release];
        pendingNotificationString = nil;
        
    }
}

#pragma mark -
#pragma mark UIPopoverControllerDelegate methods

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [popover release];
    popover = nil;
}

@end