//
//  LIOAltChatViewController.m
//  LookIO
//
//  Created by Joseph Toscano on 12/5/11.
//  Copyright (c) 2011 LivePerson, Inc. All rights reserved.
//

#import "LIOAltChatViewController.h"
#import "LIOLookIOManager.h"
#import "LIOChatBubbleView.h"
#import "LIOChatMessage.h"
#import <QuartzCore/QuartzCore.h>
#import "LIOInputBarView.h"
#import "LIOHeaderBarView.h"
#import "LIODismissalBarView.h"
#import "LIOEmailHistoryViewController.h"
#import "LIOLeaveMessageViewController.h"
#import "LIOBundleManager.h"
#import "LIOLogManager.h"
#import "TTTAttributedLabel.h"
#import "LIONotificationArea.h"
#import "LIOToasterView.h"
#import "LIOSurveyManager.h"
#import "LIOSurveyQuestion.h"
#import "LIOSurveyTemplate.h"
#import "LIOSurveyPickerEntry.h"
#import "LIOTimerProxy.h"
#import "LIOSurveyViewController.h"
#import "LIOMediaManager.h"
#import "LIOSurveyView.h"
#import "LIOImageBubbleView.h"

#define LIOAltChatViewControllerMaxHistoryLength   10
#define LIOAltChatViewControllerChatboxPadding     10.0
#define LIOAltChatViewControllerChatboxMinHeight   100.0
#define LIOAltChatViewControllerAttachmentRowHeight 135.0
#define LIOAltChatViewControllerAttachmentDisplayHeight      120.0
#define LIOAltChatViewControllerMaximumAttachmentDisplayWidth 150.0
#define LIOAltChatViewControllerMaximumAttachmentActualSize 800.0

#define LIOAltChatViewControllerTableViewCellReuseId       @"LIOAltChatViewControllerTableViewCellReuseId"
#define LIOAltChatViewControllerTableViewCellBubbleViewTag           1001
#define LIOAltChatViewControllerTableViewCellFailedMessageButtonTag  1002

#define LIOAltChatViewControllerPhotoSourceActionSheetTag            1003
#define LIOAltChatViewControllerAttachConfirmAlertViewTag            1004
#define LIOAltChatViewControllerResendMessageActionSheetTag          1005
#define LIOSurveyViewPrePadding 10.0

#define LIOAltChatViewControllerOfflineSurveyConfirmAlertViewTag     1006

#define LIOAltChatViewControllerLoadingViewTag                       1007

#define LIOSurveyViewPadding 10.0

#define LIOIpadPopoverTypeNone 0
#define LIOIpadPopoverTypeImagePicker 1
#define LIOIpadPopoverTypeSurvey 2

// LIOGradientLayer gets rid of implicit layer animations.
@interface LIOGradientLayer : CAGradientLayer
@end
@implementation LIOGradientLayer
+ (id<CAAction>)defaultActionForKey:(NSString *)key { return NULL; }
- (id<CAAction>)actionForKey:(NSString *)key { return NULL; }
@end

@interface LIOAltChatViewController ()
- (void)rejiggerTableViewFrame;
- (void)processSurvey;
@end

@implementation LIOAltChatViewController

@synthesize delegate, dataSource, initialChatText;
@dynamic agentTyping;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
        numPreviousMessagesToShowInScrollback = 1;
        chatBubbleHeights = [[NSMutableArray alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillResignActive:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
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
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
        if (![[UIApplication sharedApplication] isStatusBarHidden]) {
            tableViewFrame.origin.y += 20.0;
            tableViewFrame.size.height -= 20.0;
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
        tappableDismissalAreaForPadUI.accessibilityLabel = @"LIOAltChatViewController.tappableDismissalAreaForPadUI";
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
        dismissalBar.accessibilityLabel = @"LIOAltChatViewController.dismissalBar";
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
        [dismissalBar release];

        aFrame = CGRectZero;
        aFrame.size.width = self.view.bounds.size.width;
        aFrame.size.height = LIOHeaderBarViewDefaultHeight;
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
            if (![[UIApplication sharedApplication] isStatusBarHidden])
                aFrame.size.height += 20.0;
        
        headerBar = [[LIOHeaderBarView alloc] initWithFrame:aFrame];
        headerBar.accessibilityLabel = @"LIOAltChatViewController.headerBar";
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
    
    emailConvoButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    emailConvoButton.accessibilityLabel = @"LIOAltChatViewController.emailConvoButton";
    [emailConvoButton setBackgroundImage:grayStretchableButtonImage forState:UIControlStateNormal];
    emailConvoButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    emailConvoButton.titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    emailConvoButton.titleLabel.layer.shadowOpacity = 0.8;
    emailConvoButton.titleLabel.layer.shadowOffset = CGSizeMake(0.0, -1.0);
    emailConvoButton.titleLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
    emailConvoButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    emailConvoButton.titleLabel.minimumFontSize = 6.0;
    [emailConvoButton setTitle:LIOLocalizedString(@"LIOAltChatViewController.EmailChatButton") forState:UIControlStateNormal];
    emailConvoButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, 4.0, 0.0, 4.0);
    [emailConvoButton addTarget:self action:@selector(emailConvoButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    CGRect aFrame = emailConvoButton.frame;
    aFrame.size.width = 120.0;
    aFrame.size.height = 32.0;
    aFrame.origin.x = (tableView.bounds.size.width / 4.0) - (aFrame.size.width / 2.0);
        aFrame.origin.y = 10.0;
    emailConvoButton.frame = aFrame;
    if (NO == padUI)
        emailConvoButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

    UIButton *endSessionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    endSessionButton.accessibilityLabel = @"LIOAltChatViewController.endSessionButton";
    [endSessionButton setBackgroundImage:redStretchableButtonImage forState:UIControlStateNormal];
    endSessionButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    endSessionButton.titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    endSessionButton.titleLabel.layer.shadowOpacity = 0.8;
    endSessionButton.titleLabel.layer.shadowOffset = CGSizeMake(0.0, -1.0);
    endSessionButton.titleLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
    endSessionButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    endSessionButton.titleLabel.minimumFontSize = 9.0;
    [endSessionButton setTitle:LIOLocalizedString(@"LIOAltChatViewController.EndSessionButton") forState:UIControlStateNormal];
    endSessionButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, 4.0, 0.0, 4.0);
    [endSessionButton addTarget:self action:@selector(endSessionButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    aFrame = endSessionButton.frame;
    aFrame.size.width = 120.0;
    aFrame.size.height = 32.0;
    aFrame.origin.x = (tableView.bounds.size.width * 0.75) - (aFrame.size.width / 2.0);
        aFrame.origin.y = 10.0;
    endSessionButton.frame = aFrame;
    if (NO == padUI)
        endSessionButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
    functionHeaderChat = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    functionHeaderChat.selectionStyle = UITableViewCellSelectionStyleNone;

    // Fix for iOS 7.0 - allow Powered By Area to appear, otherwise it is clipped
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
        for (UIView *subview in functionHeaderChat.subviews)
            subview.clipsToBounds = NO;

    if (!padUI) {
        if (headerBar)
            if (headerBar.notificationArea)
                if (headerBar.notificationArea.hasCustomBranding)
                {
                    UILabel *poweredByLabel = [[[UILabel alloc] init] autorelease];
                    poweredByLabel.backgroundColor = [UIColor clearColor];
                    poweredByLabel.textColor = [UIColor whiteColor];
                    poweredByLabel.textAlignment = UITextAlignmentCenter;
                    poweredByLabel.text = [[LIOBundleManager sharedBundleManager] localizedStringWithKey:@"LIONotificationArea.PoweredBy"];
                    [poweredByLabel sizeToFit];
                    aFrame = poweredByLabel.frame;
                    aFrame.origin.x = 10.0;
                    aFrame.origin.y = -54.0;
                    aFrame.size.width = 320.0 - 20.0;
                    poweredByLabel.frame = aFrame;
                    poweredByLabel.font = [UIFont systemFontOfSize:13.0];
                    poweredByLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                    
                    UIImageView *logoView = [[[UIImageView alloc] initWithImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOLivePersonMobileLogo"]] autorelease];
                    aFrame = logoView.frame;
                    aFrame.origin.x = (320.0 / 2.0) - (aFrame.size.width / 2.0);
                    aFrame.origin.y = poweredByLabel.frame.origin.y + poweredByLabel.frame.size.height + 4.0;
                    logoView.frame = aFrame;
                    logoView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
                    
                    [functionHeaderChat.contentView addSubview:poweredByLabel];
                    [functionHeaderChat.contentView addSubview:logoView];
                }
    } else {
        if (inputBar)
            if (inputBar.notificationArea)
                if (inputBar.notificationArea.hasCustomBranding) {
                    {
                        UILabel *poweredByLabel = [[[UILabel alloc] init] autorelease];
                        poweredByLabel.backgroundColor = [UIColor clearColor];
                        poweredByLabel.textColor = [UIColor whiteColor];
                        poweredByLabel.textAlignment = UITextAlignmentCenter;
                        poweredByLabel.text = [[LIOBundleManager sharedBundleManager] localizedStringWithKey:@"LIONotificationArea.PoweredBy"];
                        [poweredByLabel sizeToFit];
                        aFrame = poweredByLabel.frame;
                        aFrame.origin.x = 10.0;
                        aFrame.origin.y = -54.0;
                        
                        // iOS 7.0 + iPad requires originating the powered by logo a bit higher
                        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
                            if (![[UIApplication sharedApplication] isStatusBarHidden])
                                aFrame.origin.y = -74.0;
                        
                        aFrame.size.width = 320.0 - 20.0;
                        poweredByLabel.frame = aFrame;
                        poweredByLabel.font = [UIFont systemFontOfSize:13.0];
                        poweredByLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                        
                        UIImageView *logoView = [[[UIImageView alloc] initWithImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOLivePersonMobileLogo"]] autorelease];
                        aFrame = logoView.frame;
                        aFrame.origin.x = (320.0 / 2.0) - (aFrame.size.width / 2.0);
                        aFrame.origin.y = poweredByLabel.frame.origin.y + poweredByLabel.frame.size.height + 4.0;
                        logoView.frame = aFrame;
                        logoView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
                        
                        [functionHeaderChat.contentView addSubview:poweredByLabel];
                        [functionHeaderChat.contentView addSubview:logoView];
                    }
                }
    }
    
    functionHeaderChat.backgroundColor = [UIColor clearColor];
    [functionHeaderChat.contentView addSubview:emailConvoButton];
    [functionHeaderChat.contentView addSubview:endSessionButton];
    
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
    label.text = LIOLocalizedString(@"LIOAltChatViewController.ReconnectionLabel");
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
    [dismissButton setTitle:LIOLocalizedString(@"LIOAltChatViewController.ReconnectionHideButton") forState:UIControlStateNormal];
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
    
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    if (padUI)
        numPreviousMessagesToShowInScrollback = 3;
    
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
    
    [functionHeaderChat release];
    functionHeaderChat = nil;
    
    [vertGradient release];
    vertGradient = nil;
    
    [horizGradient release];
    horizGradient = nil;
    
    [reconnectionOverlay release];
    reconnectionOverlay = nil;
    
    [popover release];
    popover = nil;
    
    [emailConvoButton release];
    emailConvoButton = nil;
    
    [dismissButton release];
    dismissButton = nil;
    
    toasterView.delegate = nil;
    [toasterView release];
    toasterView = nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    tableView.delegate = nil;
    tableView.dataSource = nil;
    [tableView release];
    
    toasterView.delegate = nil;
    [toasterView release];
    
    [alertView dismissWithClickedButtonIndex:-2742 animated:NO];
    [alertView autorelease];
    alertView = nil;
    
    [background release];
    [pendingChatText release];
    [initialChatText release];
    [chatMessages release];
    [headerBar release];
    [inputBar release];
    [functionHeaderChat release];
    [vertGradient release];
    [horizGradient release];
    [reconnectionOverlay release];
    [popover release];
    [emailConvoButton release];
    [chatBubbleHeights release];
    [tappableDismissalAreaForPadUI release];
    [pendingNotificationString release];
    [lastSentMessageText release];
    [dismissButton release];
    [pendingImageAttachment release];
    
    // I... don't know if this is such a great idea, but.
    [[LIOBundleManager sharedBundleManager] pruneImageCache];
    
    [super dealloc];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (leavingMessage)
        return;
    
    // If a survey is going to be shown, we want to hide the chat elements that are animating in.
    // They will be revealed after the survey is complete.

    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];

    // If surveys are enable, we don't show the chat UI until we either get the survey or an empty one indicating there is no
    // survey
    LIOSurveyManager* surveyManager = [LIOSurveyManager sharedSurveyManager];
    if (surveyManager.surveysEnabled && !surveyManager.receivedEmptyPreSurvey && !surveyManager.preSurveyCompleted) {
        // If we have a survey, and it's not completed, show it
        if (surveyManager.preChatTemplate) {
            if (padUI) {
                [self hideChatUIForSurvey:NO];
                double delayInSeconds = 0.5;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [self showSurveyViewForType:LIOSurveyManagerSurveyTypePre];
                });
            } else {
                [self showSurveyViewForType:LIOSurveyManagerSurveyTypePre];
            }
        } else {
            // Otherwise just hide the UI while waiting for a survey
            waitingForSurvey = YES;
            [self hideChatUIForSurvey:NO];
        }
    }
    
    if (NO == [[UIApplication sharedApplication] isStatusBarHidden])
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];

    [self reloadMessages];
    
    if ([chatMessages count])
    {
        NSIndexPath *lastRow = [NSIndexPath indexPathForRow:[chatMessages count] - 1 inSection:0];
        [tableView scrollToRowAtIndexPath:lastRow atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    
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
    
    // These don't exist on iOS < 5.0, so... we just use bare strings here.
    // Yes, this is a hack.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrame:)
                                                 name:@"UIKeyboardWillChangeFrameNotification"
                                               object:nil];

    /*
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidChangeFrame:)
                                                 name:@"UIKeyboardDidChangeFrameNotification"
                                               object:nil];
    */
}

-(void)hideChatUIForSurvey:(BOOL)animated {
    if (animated) {
        UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;

        [UIView animateWithDuration:0.3 animations:^{
            dismissalBar.alpha = 0.0;
            inputBar.alpha = 0.0;
            tableView.alpha = 0.0;
            
            CGRect headerFrame = headerBar.frame;
            if (UIInterfaceOrientationIsLandscape(actualOrientation))
                headerFrame.origin.y = -headerFrame.size.height;
            else
                headerFrame.origin.y = 0;
            headerBar.frame = headerFrame;
        }];        
    } else {
        UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;
        
        dismissalBar.hidden = YES;
        inputBar.hidden = YES;
        tableView.hidden = YES;
    
        CGRect headerFrame = headerBar.frame;
        if (UIInterfaceOrientationIsLandscape(actualOrientation))
            headerFrame.origin.y = -headerFrame.size.height;
        else
            headerFrame.origin.y = 0;
        headerBar.frame = headerFrame;
    }
}

-(void)showSurveyViewForType:(LIOSurveyManagerSurveyType)surveyType {
    [self.view endEditing:YES];
    [self hideChatUIForSurvey:YES];
    
    if (waitingForSurvey) {
        waitingForSurvey = NO;
        UIView* waitingForSurveyView = [self.view viewWithTag:LIOAltChatViewControllerLoadingViewTag];
        [UIView animateWithDuration:0.3 animations:^{
            waitingForSurveyView.alpha = 0.0;
        } completion:^(BOOL finished) {
            [waitingForSurveyView removeFromSuperview];
        }];
    }
    
    if (waitingForEngagementToStart) {
        waitingForEngagementToStart = NO;
        UIView* waitingForSurveyView = [self.view viewWithTag:LIOAltChatViewControllerLoadingViewTag];
        if (waitingForSurveyView) {
            [UIView animateWithDuration:0.3 animations:^{
                waitingForSurveyView.alpha = 0.0;
            } completion:^(BOOL finished) {
                [waitingForSurveyView removeFromSuperview];
            }];
        }
    }

    LIOSurveyManager* surveyManager = [LIOSurveyManager sharedSurveyManager];
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];

    surveyView = [[[LIOSurveyView alloc] initWithFrame:CGRectZero] autorelease];
    surveyView.currentSurveyType = surveyType;
    surveyView.currentSurvey = [surveyManager surveyTemplateForType:surveyType];
    surveyView.headerString = [surveyManager surveyHeaderForType:surveyType];
    int lastIndexCompleted = [surveyManager lastCompletedQuestionIndexForType:surveyType];
    if (lastIndexCompleted == -1)
        surveyView.currentQuestionIndex = lastIndexCompleted;
    else
        surveyView.currentQuestionIndex = lastIndexCompleted + 1;
    surveyView.delegate = self;
    
    if (!padUI) {
        surveyView.frame = self.view.bounds;
        [self.view insertSubview:surveyView belowSubview:headerBar];
        surveyView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    } else {
        UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;

        CGRect aRect = self.view.bounds;
        aRect.origin.x = UIInterfaceOrientationIsPortrait(actualOrientation) ? 768 : 1024;
        surveyView.frame = aRect;
        
        //surveyView.clipsToBounds = YES;
        surveyView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.view addSubview:surveyView];
        [UIView animateWithDuration:0.3 animations:^{
            CGRect aRect = surveyView.frame;
            aRect.origin.x = 0;
            surveyView.frame = aRect;
        }];
    }
    
    [surveyView setupViews];
    surveyInProgress = YES;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0)
        [self didRotateFromInterfaceOrientation:0];
}

- (void)showLoadingViewWithiPadDelay:(BOOL)shouldDelayiPad {
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];

    UIView* waitingForSurveyView = [[UIView alloc] initWithFrame:self.view.bounds];
    waitingForSurveyView.alpha = 0.0;
    waitingForSurveyView.tag = LIOAltChatViewControllerLoadingViewTag;
    waitingForSurveyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:waitingForSurveyView];
    [waitingForSurveyView release];
    
    UIView *bezelView = [[UIView alloc] initWithFrame:CGRectZero];
    bezelView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.66];
    bezelView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    bezelView.layer.cornerRadius = 6.0;
    [waitingForSurveyView addSubview:bezelView];
    [bezelView release];
    
    CGRect aFrame = bezelView.frame;
    aFrame.size.width = 200;
    aFrame.size.height = 130;
    aFrame.origin.x = waitingForSurveyView.bounds.size.width/2 - aFrame.size.width/2;
    aFrame.origin.y = waitingForSurveyView.bounds.size.height/2 - aFrame.size.height/2;
    bezelView.frame = aFrame;
    
    UIImageView *loadingImageView = [[UIImageView alloc] initWithFrame:waitingForSurveyView.bounds];
    loadingImageView.image = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOSpinningLoader"];
    loadingImageView.contentMode = UIViewContentModeCenter;
    [waitingForSurveyView addSubview:loadingImageView];
    [loadingImageView release];
    
    CABasicAnimation *loadingAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    loadingAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    loadingAnimation.toValue = [NSNumber numberWithFloat: 2*M_PI];
    loadingAnimation.duration = 1.0f;
    loadingAnimation.repeatCount = HUGE_VAL;
    [loadingImageView.layer addAnimation:loadingAnimation forKey:@"animation"];
    
    UILabel* loadingLabel = [[UILabel alloc] initWithFrame:waitingForSurveyView.bounds];
    loadingLabel.backgroundColor = [UIColor clearColor];
    loadingLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    loadingLabel.textColor = [UIColor whiteColor];
    loadingLabel.font = [UIFont boldSystemFontOfSize:16.0];
    loadingLabel.textAlignment = UITextAlignmentCenter;
    loadingLabel.text = LIOLocalizedString(@"LIOAltChatViewController.LoadingLabel");
    [waitingForSurveyView addSubview:loadingLabel];
    [loadingLabel release];
    
    UILabel* loadingSubLabel = [[UILabel alloc] initWithFrame:waitingForSurveyView.bounds];
    loadingSubLabel.backgroundColor = [UIColor clearColor];
    loadingSubLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    loadingSubLabel.textColor = [UIColor whiteColor];
    loadingSubLabel.font = [UIFont systemFontOfSize:14.0];
    loadingSubLabel.textAlignment = UITextAlignmentCenter;
    loadingSubLabel.text = LIOLocalizedString(@"LIOAltChatViewController.LoadingSubLabel");
    [waitingForSurveyView addSubview:loadingSubLabel];
    [loadingSubLabel release];
    
    UIButton* waitingForSurveyViewButton = [[UIButton alloc] initWithFrame:waitingForSurveyView.bounds];
    waitingForSurveyViewButton.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [waitingForSurveyView addSubview:waitingForSurveyViewButton];
    [waitingForSurveyViewButton addTarget:self action:@selector(waitingForSurveyButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    [waitingForSurveyViewButton release];
    
    aFrame = loadingImageView.frame;
    aFrame.origin.y = aFrame.origin.y - 25;
    loadingImageView.frame = aFrame;
    
    aFrame = loadingLabel.frame;
    aFrame.origin.y = aFrame.origin.y + 20;
    loadingLabel.frame = aFrame;
    
    aFrame = loadingSubLabel.frame;
    aFrame.origin.y = aFrame.origin.y + 40;
    loadingSubLabel.frame = aFrame;
    
    if (padUI && shouldDelayiPad) {
        [UIView animateWithDuration:0.3 delay:0.5 options:UIViewAnimationCurveLinear animations:^{
            waitingForSurveyView.alpha = 1.0;
        } completion:^(BOOL finished) {
        }];
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            waitingForSurveyView.alpha = 1.0;
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    // We might need to exit chat due to a canceled survey.
    if (NO == padUI && surveyWasCanceled)
    {
        [self performDismissalAnimation];
        return;
    }
    
    if (leavingMessage)
        return;
    
    if (waitingForSurvey) {
        [self showLoadingViewWithiPadDelay:YES];
    }
    
    double delayInSeconds = 0.6;
    if (NO == padUI) delayInSeconds = 0.1;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        if (!surveyInProgress && !waitingForSurvey) {
            BOOL result = [inputBar.inputField becomeFirstResponder];
            if (result != 1)
            {
                [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"The LPMobile UI is unable to bring up the keyboard. Please check to make sure that you aren't using any categories on the UITextView class which drastically modify its behavior."];
            }
        
            if ([initialChatText length])
            {
                inputBar.inputField.text = initialChatText;
                pendingChatText = initialChatText;
                initialChatText = nil;
            }
        
            [inputBar setNeedsLayout];
        }
    });
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0)
        [self willAnimateRotationToInterfaceOrientation:0 duration:0];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (alertView != nil) {
        [alertView dismissWithClickedButtonIndex:-2742 animated:NO];
        [alertView autorelease];
        alertView = nil;
    }
    
    if (actionSheet != nil) {
        [actionSheet dismissWithClickedButtonIndex:-1 animated:NO];
        [actionSheet autorelease];
        actionSheet = nil;
    }
    
    [popover dismissPopoverAnimated:NO];
    currentPopoverType = LIOIpadPopoverTypeNone;
    [popover autorelease];
    popover = nil;
}

// iOS >= 6.0
- (BOOL)shouldAutorotate
{
    return [delegate altChatViewControllerShouldAutorotate:self];
}

// iOS >= 6.0
- (NSUInteger)supportedInterfaceOrientations
{
    return [delegate altChatViewControllerSupportedInterfaceOrientations:self];
}

// I guess this is also called when the keyboard is hidden? o_O
- (void)viewWillLayoutSubviews
{
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [delegate altChatViewController:self shouldRotateToInterfaceOrientation:interfaceOrientation];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (surveyInProgress) {
        CGRect headerFrame = headerBar.frame;

        if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
            headerFrame.origin.y = - headerFrame.size.height;
        else
            headerFrame.origin.y = 0;
        
        headerBar.frame = headerFrame;
    }

}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    if (padUI && popover) {
        if (currentPopoverType == LIOIpadPopoverTypeImagePicker)
            [popover presentPopoverFromRect:inputBar.attachButton.bounds
                                     inView:inputBar.attachButton
                   permittedArrowDirections:UIPopoverArrowDirectionDown
                                   animated:YES];
    }
    
    vertGradient.frame = self.view.bounds;
    horizGradient.frame = self.view.bounds;
    
    [self rejiggerTableViewFrame];
    
    [self reloadMessages];
    
    if (NO == padUI)
        [self scrollToBottomDelayed:NO];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{    

    
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
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        if (![[UIApplication sharedApplication] isStatusBarHidden]) {
            if (UIInterfaceOrientationIsLandscape(actualOrientation && keyboardHeight > 0.0))
                tableFrame.origin.y = 0;
            else {
                tableFrame.origin.y += 20.0;
                tableFrame.size.height -= 20.0;
            }
        }
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

- (void)performRevealAnimationWithFadeIn:(BOOL)fadeIn
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    if (padUI)
    {
        if (fadeIn) {
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
        }
        
        if (!surveyInProgress)
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
                             if (!surveyInProgress)
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
        if (fadeIn) {
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
        }
        
        tableView.transform = CGAffineTransformMakeTranslation(0.0, -self.view.frame.size.height);
        headerBar.transform = CGAffineTransformMakeTranslation(0.0, -self.view.frame.size.height);
        inputBar.transform = CGAffineTransformMakeTranslation(0.0, self.view.frame.size.height);
        dismissalBar.transform = CGAffineTransformMakeTranslation(0.0, self.view.frame.size.height);
        
        CGFloat delay = fadeIn ? 0.1 : 0.0;
        
        [UIView animateWithDuration:0.3
                              delay:delay
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
                             
                             if (!surveyInProgress && !waitingForSurvey)
                                 [inputBar.inputField becomeFirstResponder];
                         }];
    }
}

- (void)performDismissalAnimation
{
    [delegate altChatViewControllerDidStartDismissalAnimation:self];
    isAnimatingDismissal = YES;
    
    background.alpha = 1.0;
        
    [UIView animateWithDuration:0.33
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         background.alpha = 0.0;
                         toasterView.alpha = 0.0;
                         
                         UIView* waitingForSurveyView = [self.view viewWithTag:LIOAltChatViewControllerLoadingViewTag];
                         if (waitingForSurveyView)
                             waitingForSurveyView.alpha = 0.0;
                         
                         // I don't know why, but iOS 6 broke this animation.
                         // Manually setting its frame doesn't work either. o_O
                         // Hence, we just fade it out instead of moving it.
                         //tableView.transform = CGAffineTransformMakeTranslation(0.0, -self.view.bounds.size.height);
                         //tableView.alpha = 0.0;
                         
                         headerBar.transform = CGAffineTransformMakeTranslation(0.0, -self.view.bounds.size.height);
                         inputBar.transform = CGAffineTransformMakeTranslation(0.0, self.view.bounds.size.height);
                         dismissalBar.transform = CGAffineTransformMakeTranslation(0.0, self.view.bounds.size.height);
                     }
                     completion:^(BOOL finished) {
                         double delayInSeconds = 0.1;
                         dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                         dispatch_after(popTime, dispatch_get_main_queue(), ^{
                             [delegate altChatViewControllerDidFinishDismissalAnimation:self];
                             isAnimatingDismissal = NO;
                         });
                     }];
    
    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         tableView.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                     }];
}

- (void)scrollToBottomDelayed:(BOOL)delayed
{
    NSUInteger myScrollId = arc4random();
    currentScrollId = myScrollId;
    
    if (delayed)
    {
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(){
            if (myScrollId == currentScrollId)
            {
                NSIndexPath *lastRow = [NSIndexPath indexPathForRow:[chatMessages count] inSection:0];
                [tableView scrollToRowAtIndexPath:lastRow atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }
        });
    }
    else
    {
        NSIndexPath *lastRow = [NSIndexPath indexPathForRow:[chatMessages count] inSection:0];
        [tableView scrollToRowAtIndexPath:lastRow atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (void)reloadMessages
{
    [chatMessages release];
    chatMessages = [[dataSource altChatViewControllerChatMessages:self] copy];
    
    // Pre-calculate all bubble heights. D:
    [chatBubbleHeights removeAllObjects];
    for (int i=0; i<[chatMessages count]; i++)
    {
        LIOChatMessage *aMessage = [chatMessages objectAtIndex:i];
        
        // Attachment? Fixed height.
        if ([aMessage.attachmentId length])
        {
            [chatBubbleHeights addObject:[NSNumber numberWithFloat:LIOAltChatViewControllerAttachmentRowHeight]];
        }
        else
        {
            LIOChatBubbleView *tempView = [[LIOChatBubbleView alloc] init];
            
            if (LIOChatMessageKindLocal == aMessage.kind)
            {
                tempView.formattingMode = LIOChatBubbleViewFormattingModeLocal;
                tempView.senderName = LIOLocalizedString(@"LIOAltChatViewController.LocalNameLabel");
            }
            else if (LIOChatMessageKindRemote == aMessage.kind)
            {
                tempView.formattingMode = LIOChatBubbleViewFormattingModeRemote;
                tempView.senderName = aMessage.senderName;
            }
            
            tempView.rawChatMessage = aMessage;
            [tempView populateMessageViewWithText:aMessage.text];
            [tempView layoutSubviews];
            
            NSNumber *aHeight = [NSNumber numberWithFloat:tempView.frame.size.height];
            [chatBubbleHeights addObject:aHeight];
            
            [tempView release];
        }
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
    
    if (surveyInProgress)
        return;
    
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
    NSIndexPath *expandingFooterIndex = [NSIndexPath indexPathForRow:([chatMessages count] + 1) inSection:0];
    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:expandingFooterIndex] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)forceLeaveMessageScreen
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    [[LIOLookIOManager sharedLookIOManager] setResetAfterNextForegrounding:YES];
    
    // Check to see if there is an offline survey template that could be used here
    LIOSurveyManager* surveyManager = [LIOSurveyManager sharedSurveyManager];
    if (surveyManager.offlineTemplate) {
        if (surveyInProgress)
            return;
        else
            [self showSurveyViewForType:LIOSurveyManagerSurveyTypeOffline];
    } else {
        NSString *pendingEmailAddress = [[LIOLookIOManager sharedLookIOManager] pendingEmailAddress];
        
        LIOLeaveMessageViewController *aController = [[[LIOLeaveMessageViewController alloc] initWithNibName:nil bundle:nil] autorelease];
        aController.delegate = self;
        
        if ([pendingEmailAddress length])
            aController.initialEmailAddress = pendingEmailAddress;
        
        aController.initialMessage = lastSentMessageText;
        
        if (padUI)
            aController.modalPresentationStyle = UIModalPresentationFormSheet;
        
        [self presentModalViewController:aController animated:YES];
    }
    
    leavingMessage = YES;
    
}

- (void)bailOnSecondaryViews
{    
    if (popover)
    {
        [popover dismissPopoverAnimated:NO];
        currentPopoverType = LIOIpadPopoverTypeNone;
        [popover release];
        popover = nil;
    }
    
    if (self.modalViewController)
    {
        [self.modalViewController.view endEditing:YES];
        [self dismissModalViewControllerAnimated:NO];
        [delegate altChatViewControllerWillPresentImagePicker:self];
    }
}

- (void)showPhotoSourceActionSheet
{
    BOOL padUI = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    
    NSString *cancelString = [[LIOBundleManager sharedBundleManager] localizedStringWithKey:@"LIOAltChatViewController.AttachSourceCancel"];
    NSString *cameraString = [[LIOBundleManager sharedBundleManager] localizedStringWithKey:@"LIOAltChatViewController.AttachSourceCamera"];
    NSString *libraryString = [[LIOBundleManager sharedBundleManager] localizedStringWithKey:@"LIOAltChatViewController.AttachSourceLibrary"];
    
    actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                    delegate:self
                                           cancelButtonTitle:cancelString
                                      destructiveButtonTitle:nil
                                           otherButtonTitles:cameraString, libraryString, nil];
    actionSheet.tag = LIOAltChatViewControllerPhotoSourceActionSheetTag;
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    
    if (padUI)
        [actionSheet showFromRect:inputBar.attachButton.bounds inView:inputBar.attachButton animated:YES];
    else
        [actionSheet showInView:self.view];
}

- (void)showPhotoLibraryPicker
{
    BOOL padUI = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    
    UIImagePickerController *ipc = [[[UIImagePickerController alloc] init] autorelease];
    ipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary | UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    ipc.allowsEditing = NO;
    ipc.delegate = self;
    
    if (padUI)
    {
        [self.view endEditing:YES];
        popover = [[UIPopoverController alloc] initWithContentViewController:ipc];
        popover.delegate = self;
        currentPopoverType = LIOIpadPopoverTypeImagePicker;
        [popover presentPopoverFromRect:inputBar.attachButton.bounds
                                 inView:inputBar.attachButton
               permittedArrowDirections:UIPopoverArrowDirectionDown
                               animated:YES];
    }
    else
    {
        [delegate altChatViewControllerWillPresentImagePicker:self];
        [self presentModalViewController:ipc animated:YES];
    }
}

- (void)showCamera
{
    BOOL padUI = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    
    UIImagePickerController *ipc = [[[UIImagePickerController alloc] init] autorelease];
    ipc.sourceType = UIImagePickerControllerSourceTypeCamera;
    ipc.allowsEditing = NO;
    ipc.delegate = self;
    
    if (padUI)
    {
        [self.view endEditing:YES];

        popover = [[UIPopoverController alloc] initWithContentViewController:ipc];
        popover.delegate = self;
        currentPopoverType = LIOIpadPopoverTypeImagePicker;
        [popover presentPopoverFromRect:inputBar.attachButton.bounds
                                 inView:inputBar.attachButton
               permittedArrowDirections:UIPopoverArrowDirectionDown
                               animated:YES];
    }
    else
    {
        [delegate altChatViewControllerWillPresentImagePicker:self];
        [self presentModalViewController:ipc animated:YES];
    }
}

- (void)showAttachmentUploadConfirmation
{
    NSString *bodyString = [[LIOBundleManager sharedBundleManager] localizedStringWithKey:@"LIOAltChatViewController.AttachConfirmationBody"];
    NSString *sendString = [[LIOBundleManager sharedBundleManager] localizedStringWithKey:@"LIOAltChatViewController.AttachConfirmationSend"];
    NSString *dontSendString = [[LIOBundleManager sharedBundleManager] localizedStringWithKey:@"LIOAltChatViewController.AttachConfirmationDontSend"];

    NSString *message = [bodyString stringByAppendingString:@"\n\n\n\n\n"];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
        message = bodyString;
    
    alertView = [[UIAlertView alloc] initWithTitle:nil
                                           message:message
                                                delegate:self
                                       cancelButtonTitle:nil
                                       otherButtonTitles:dontSendString, sendString, nil];
    alertView.tag = LIOAltChatViewControllerAttachConfirmAlertViewTag;
    
    CGSize expectedSize = [bodyString sizeWithFont:[UIFont systemFontOfSize:15.0] constrainedToSize:CGSizeMake(255, 9999) lineBreakMode:UILineBreakModeCharacterWrap];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:pendingImageAttachment];

    CGFloat imageHeight = 80.0;
    CGFloat imageWidth = imageHeight * (pendingImageAttachment.size.width / pendingImageAttachment.size.height);
    if (imageWidth > 260.0)
        imageWidth = 260.0;
    
    imageView.frame = CGRectMake(floor((284 - imageWidth)/2), expectedSize.height + 27.0, imageWidth, imageHeight);
    imageView.layer.cornerRadius = 2.0;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.layer.masksToBounds = YES;
    
    [alertView addSubview:imageView];
    [imageView autorelease];

    [alertView show];

}

#pragma mark -
#pragma mark UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [chatMessages count] + 2;
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
        return functionHeaderChat;
    
    if ([chatMessages count] + 1 == indexPath.row)
    {
        UITableViewCell *expandingFooter = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
        expandingFooter.selectionStyle = UITableViewCellSelectionStyleNone;
        expandingFooter.backgroundColor = [UIColor clearColor];
        return expandingFooter;
    }
     
    UITableViewCell *aCell = [tableView dequeueReusableCellWithIdentifier:LIOAltChatViewControllerTableViewCellReuseId];
    if (nil == aCell)
    {
        aCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LIOAltChatViewControllerTableViewCellReuseId];
        aCell.selectionStyle = UITableViewCellSelectionStyleNone;
        aCell.backgroundColor = [UIColor clearColor];
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

    LIOChatMessage *aMessage = [chatMessages objectAtIndex:(indexPath.row - 1)];
    
    // Attachment -- show as bare UIImageview for now.
    // TODO: Fold attachment display into LIOChatBubbleView.
    if ([aMessage.attachmentId length])
    {
        NSString *mimeType = [[LIOMediaManager sharedInstance] mimeTypeFromId:aMessage.attachmentId];
        if ([mimeType hasPrefix:@"image"])
        {
            NSData *imageData = [[LIOMediaManager sharedInstance] mediaDataWithId:aMessage.attachmentId];
            if (imageData)
            {
                UIImage *attachmentImage = [[[UIImage alloc] initWithData:imageData] autorelease];
                if (attachmentImage)
                {
                    LIOImageBubbleView *imageBubble = [[[LIOImageBubbleView alloc] init] autorelease];
                    imageBubble.contentMode = UIViewContentModeScaleAspectFill;
                    imageBubble.layer.masksToBounds = YES;
                    imageBubble.layer.cornerRadius = 3.0;
                    [imageBubble setImage:attachmentImage];

                    CGRect ibFrame;
                    if (attachmentImage.size.height > 0) {
                        ibFrame.size.width = LIOAltChatViewControllerAttachmentDisplayHeight*(attachmentImage.size.width/attachmentImage.size.height);
                        if (ibFrame.size.width > LIOAltChatViewControllerMaximumAttachmentDisplayWidth)
                            ibFrame.size.width = LIOAltChatViewControllerMaximumAttachmentDisplayWidth;
                        
                    }
                    else
                        ibFrame.size.width = LIOAltChatViewControllerAttachmentDisplayHeight;                    
                    ibFrame.size.height = LIOAltChatViewControllerAttachmentDisplayHeight;
                    
                    ibFrame.origin.x = tableView.bounds.size.width - ibFrame.size.width - 7.0;
                    ibFrame.origin.y = 5.0;
                    
                    imageBubble.frame = ibFrame;
                    [aCell.contentView addSubview:imageBubble];
                    
                    UIImage *stretchableShadow = stretchableShadow = [[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchablePhotoShadow"] stretchableImageWithLeftCapWidth:42 topCapHeight:62];
                    UIImageView* foregroundImage = [[[UIImageView alloc] initWithImage:stretchableShadow] autorelease];

                    ibFrame.origin.x =  - 3;
                    ibFrame.origin.y =  - 3;
                    ibFrame.size.width = ibFrame.size.width + 6.0;
                    ibFrame.size.height = ibFrame.size.height + 8.0;
                    foregroundImage.frame = ibFrame;
                    
                    [imageBubble addSubview:foregroundImage];
                    
                    if (LIOChatMessageKindLocal == aMessage.kind && aMessage.sendingFailed) {
                        UIButton* failedMessageButton = [[UIButton alloc] initWithFrame:CGRectMake(foregroundImage.frame.origin.x - 32.0, foregroundImage.frame.size.height/2 - 11.0 , 22, 22)];
                        UIImage* failedMessageButtonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOFailedMessageAlertIcon"];
                        [failedMessageButton setImage:failedMessageButtonImage forState:UIControlStateNormal];
                        [failedMessageButton addTarget:self action:@selector(failedMessageButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
                        failedMessageButton.tag = LIOAltChatViewControllerTableViewCellFailedMessageButtonTag;
                        [aCell.contentView addSubview:failedMessageButton];
                    }
                    
                    // Fix for iOS 7.0 - allow Bubbles to bounce
                    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
                        for (UIView *subview in aCell.subviews)
                            subview.clipsToBounds = NO;

                }
            }
        }
    }
    
    // No attachment
    else
    {
        LIOChatBubbleView *aBubble = [[[LIOChatBubbleView alloc] initWithFrame:CGRectZero] autorelease];
        aBubble.backgroundColor = [UIColor clearColor];
        aBubble.tag = LIOAltChatViewControllerTableViewCellBubbleViewTag;
        aBubble.delegate = self;
        aBubble.index = indexPath.row;
        
        if (LIOChatMessageKindLocal == aMessage.kind)
        {
            aBubble.formattingMode = LIOChatBubbleViewFormattingModeLocal;
            aBubble.senderName = LIOLocalizedString(@"LIOAltChatViewController.LocalNameLabel");
        }
        else if (LIOChatMessageKindRemote == aMessage.kind)
        {
            aBubble.formattingMode = LIOChatBubbleViewFormattingModeRemote;
            aBubble.senderName = aMessage.senderName;
        }

        [aCell.contentView addSubview:aBubble];
        
        aBubble.rawChatMessage = aMessage;
        [aBubble populateMessageViewWithText:aMessage.text];
        
        if (LIOChatBubbleViewFormattingModeRemote == aBubble.formattingMode)
            aBubble.frame = CGRectMake(0.0, 0.0, 290.0, 0.0);
        else if (LIOChatBubbleViewFormattingModeLocal == aBubble.formattingMode)
            aBubble.frame = CGRectMake(tableView.bounds.size.width - 290.0, 0.0, 290.0, 0.0);
        
        [aBubble setNeedsLayout];
        [aBubble setNeedsDisplay];
                
        if (LIOChatMessageKindLocal == aMessage.kind && aMessage.sendingFailed) {
            UIButton* failedMessageButton = [[UIButton alloc] initWithFrame:CGRectMake(tableView.bounds.size.width - 313.0, 20, 22, 22)];
            UIImage* failedMessageButtonImage = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOFailedMessageAlertIcon"];
            [failedMessageButton setImage:failedMessageButtonImage forState:UIControlStateNormal];
            [failedMessageButton addTarget:self action:@selector(failedMessageButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
            failedMessageButton.tag = LIOAltChatViewControllerTableViewCellFailedMessageButtonTag;
            [aCell.contentView addSubview:failedMessageButton];
        }

        // Fix for iOS 7.0 - allow Bubbles to bounce
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
            for (UIView *subview in aCell.subviews)
                subview.clipsToBounds = NO;
    }
    
    return aCell;
}

#pragma mark -
#pragma mark UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    int row = indexPath.row;
    
    if (0 > row)
        return 0.0;
    
    if (0 == row)
    {
        return 64.0;
    }
    
    if ([chatMessages count] + 1 == row)
    {
        CGFloat heightAccum = 0.0;
        for (int i=0; i<numPreviousMessagesToShowInScrollback; i++)
        {
            int aRow = [chatMessages count] - i;
            heightAccum += [self tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:aRow inSection:0]];
        }
        
        if (padUI)
        {
            CGFloat result = tableView.bounds.size.height - heightAccum;
            if (result < 0.0) {
                if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
                    result = 10;
                else
                    result = 7.0 - 10.0;
            }
            
            return result;
        }
        else
        {
            CGFloat result = tableView.bounds.size.height - heightAccum - 10.0;
            if (result < 0.0) {
                if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
                    result = 10;
                else
                    result = 7.0;
            }
        
            return result;
        }
    }
    
    NSNumber *aHeight = [chatBubbleHeights objectAtIndex:(row - 1)];
    CGFloat height = [aHeight floatValue];
    
    // Headers can be short. All else must be minimum height.
    CGFloat bottomPadding = 5.0;
    if (height < LIOChatBubbleViewMinTextHeight)
        height = LIOChatBubbleViewMinTextHeight;
    
    CGFloat returnValue = height + bottomPadding;
    
    return returnValue;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [chatMessages count] + 1)
        [delegate altChatViewController:self wasDismissedWithPendingChatText:pendingChatText];
}

#pragma mark -
#pragma mark UIControl actions

-(void)waitingForSurveyButtonWasTapped {
    [delegate altChatViewControllerWantsSessionTermination:self];
}

- (void)failedMessageButtonWasTapped:(UIButton*)aButton {
    CGPoint buttonPosition = [aButton convertPoint:CGPointZero toView:tableView];
    NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:buttonPosition];
    
    if (indexPath) {
        clickedFailedMessage = [chatMessages objectAtIndex:(indexPath.row - 1)];
        clickedFailedMessageIndex = indexPath.row;        
        
        BOOL padUI = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        
        NSString *titleString =  [[LIOBundleManager sharedBundleManager] localizedStringWithKey:@"LIOLookIOManager.ResendMessageQuestionTitle"];
        NSString *resendString = [[LIOBundleManager sharedBundleManager] localizedStringWithKey:@"LIOLookIOManager.ResendMessageQuestionSend"];
        NSString *cancelString = [[LIOBundleManager sharedBundleManager] localizedStringWithKey:@"LIOLookIOManager.ResendMessageQuestionCancel"];        
        
        if (padUI) {
            actionSheet = [[UIActionSheet alloc] initWithTitle:titleString
                                                      delegate:self
                                             cancelButtonTitle:cancelString
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:resendString, cancelString, nil];
            actionSheet.tag = LIOAltChatViewControllerResendMessageActionSheetTag;
            actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;

            [actionSheet showFromRect:aButton.bounds inView:aButton animated:YES];
        }
        else {
            actionSheet = [[UIActionSheet alloc] initWithTitle:titleString
                                                      delegate:self
                                             cancelButtonTitle:cancelString
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:resendString, nil];
            actionSheet.tag = LIOAltChatViewControllerResendMessageActionSheetTag;
            actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;

            [actionSheet showInView:self.view];
        }
    }
}

- (void)emailConvoButtonWasTapped
{
    if (chatMessages.count == 1) {
        alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOAltChatViewController.NoChatHistoryAlertTitle")
                                               message:LIOLocalizedString(@"LIOAltChatViewController.NoChatHistoryAlertBody")
                                              delegate:nil
                                     cancelButtonTitle:LIOLocalizedString(@"LIOAltChatViewController.NoChatHistoryAlertButton")
                                     otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
        
    LIOEmailHistoryViewController *aController = [[[LIOEmailHistoryViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    aController.delegate = self;
    
    if (padUI)
    {
        aController.contentSizeForViewInPopover = CGSizeMake(320.0, 240.0);
        
        popover = [[UIPopoverController alloc] initWithContentViewController:aController];
        popover.popoverContentSize = CGSizeMake(320.0, 240.0);
        popover.delegate = self;
        [popover presentPopoverFromRect:emailConvoButton.frame inView:functionHeaderChat.contentView permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
    else
    {
        [self.view endEditing:YES];
        
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self presentModalViewController:aController animated:YES];
        });
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
        aPanner.enabled = NO;
        [self.view endEditing:YES];
        currentScrollId = 0;
        //[self reloadMessages];
        
        int64_t delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            aPanner.enabled = YES;
        });
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

- (void)applicationWillResignActive:(NSNotification *)aNotification
{
}

- (void)applicationDidChangeStatusBarOrientation:(NSNotification *)aNotification
{
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if ([[UIApplication sharedApplication] statusBarOrientation] != self.interfaceOrientation)
        {
            [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"The LPMobile UI isn't in the same orientation as your host app's UI. You may want to make use of the following LIOLookIOManagerDelegate method: lookIOManager:shouldRotateToInterfaceOrientation:"];
        }
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
        else {
            if (surveyInProgress)
                headerFrame.origin.y = 0;
        }
        
        if (UIInterfaceOrientationIsLandscape(actualOrientation))
        {
            tableFrame.origin.y = 0.0;
            tableFrame.size.height = self.view.bounds.size.height - keyboardHeight - dismissalBarFrame.size.height - inputBarFrame.size.height;

        }
        else
        {
            tableFrame.origin.y = 32.0;
            tableFrame.size.height = self.view.bounds.size.height - keyboardHeight - dismissalBarFrame.size.height - inputBarFrame.size.height - 32.0;

            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
                if (![[UIApplication sharedApplication] isStatusBarHidden]) {
                    tableFrame.origin.y += 20.0;
                    tableFrame.size.height -= 20.0;
                }
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
        
        if (!surveyInProgress)
            headerFrame.origin.y = 0.0;
        
        tableFrame.origin.y = 32.0;
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
            if (![[UIApplication sharedApplication] isStatusBarHidden])
                tableFrame.origin.y += 20.0;
        
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
    //[self refreshExpandingFooter];
    tableView.contentOffset = previousOffset;
}

- (void)keyboardDidShow:(NSNotification *)aNotification
{
}

- (void)keyboardDidHide:(NSNotification *)aNotification
{
    [self refreshExpandingFooter];
}

- (void)keyboardWillChangeFrame:(NSNotification *)aNotification
{
    if (NO == keyboardShowing)
        return;
    
    UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    NSDictionary *userInfo = [aNotification userInfo];
    
    NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardBounds = [keyboardBoundsValue CGRectValue];
    
    keyboardHeight = keyboardBounds.size.height;
    if (UIInterfaceOrientationIsLandscape(actualOrientation))
        keyboardHeight = keyboardBounds.size.width;
    
    CGRect aFrame = inputBar.frame;
    aFrame.origin.y = self.view.bounds.size.height - keyboardHeight - aFrame.size.height;
    inputBar.frame = aFrame;
}

/*
- (void)keyboardDidChangeFrame:(NSNotification *)aNotification
{
}
*/

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
    if ([aString length])
    {
        [delegate altChatViewControllerTypingDidStop:self];
        [delegate altChatViewController:self didChatWithText:aString];
    }
    
    [pendingChatText release];
    pendingChatText = nil;
    
    previousTextLength = 0;
    
    [lastSentMessageText release];
    lastSentMessageText = [aString retain];
    
    [self.view endEditing:YES];
    
    //[self reloadMessages];
}

- (void)inputBarViewDidTapAdArea:(LIOInputBarView *)aView
{
}

- (void)inputBarViewDidStopPulseAnimation:(LIOInputBarView *)aView
{
}

- (void)inputBarViewDidTapAttachButton:(LIOInputBarView *)aView
{
    if (chatMessages.count <= 1) {
        alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOAltChatViewController.AttachStartChatAlertTitle")
                                                     message:LIOLocalizedString(@"LIOAltChatViewController.AttachStartChatAlertBody")
                                                    delegate:nil
                                           cancelButtonTitle:LIOLocalizedString(@"LIOAltChatViewController.AttachStartChatAlertButton")
                                           otherButtonTitles:nil];
        [alertView show];
    }
    else {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            [self showPhotoSourceActionSheet];
        else
            [self showPhotoLibraryPicker];
    }
}

#pragma mark -
#pragma mark LIOHeaderBarViewDelegate methods

- (void)headerBarViewPlusButtonWasTapped:(LIOHeaderBarView *)aView
{
    [tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    [self.view endEditing:YES];
}

#pragma mark -
#pragma mark LIOEmailHistoryViewControllerDelegate methods

- (void)emailHistoryViewController:(LIOEmailHistoryViewController *)aController wasDismissedWithEmailAddress:(NSString *)anEmail
{
    if (popover)
    {
        [popover dismissPopoverAnimated:NO];
        [popover autorelease];
        currentPopoverType = LIOIpadPopoverTypeNone;
        popover = nil;
    }
    else
    {
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self willAnimateRotationToInterfaceOrientation:0 duration:0];
        });
        
        [self dismissModalViewControllerAnimated:YES];
    }
    
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
        [self revealNotificationString:LIOLocalizedString(@"LIOAltChatViewController.AgentTypingNotification") withAnimatedKeyboard:YES];
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

- (void)chatBubbleView:(LIOChatBubbleView *)aView didTapIntraAppLinkWithURL:(NSURL *)aURL
{
    [[LIOLookIOManager sharedLookIOManager] beginTransitionWithIntraAppLinkURL:aURL];
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
    currentPopoverType = LIOIpadPopoverTypeNone;
    popover = nil;
}

#pragma mark -
#pragma mark LIOSurveyViewControllerDelegate methods

- (BOOL)surveyViewController:(LIOSurveyViewController *)aController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [delegate altChatViewController:self shouldRotateToInterfaceOrientation:interfaceOrientation];
}

- (void)surveyViewControllerDidCancel:(LIOSurveyViewController *)aController
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    surveyWasCanceled = YES;
    [self dismissModalViewControllerAnimated:YES];
    
    // viewDidAppear doesn't trigger on iPad, so we have to manually dismiss the chat here.
    if (padUI)
    {
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self performDismissalAnimation];
        });
    }
}

-(void)surveyViewDidCancel:(LIOSurveyView *)aView {
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];

    if (LIOSurveyManagerSurveyTypePre == aView.currentSurveyType) {
        
        [self.view endEditing:YES];
        
        if (padUI) {
            [UIView animateWithDuration:0.3 animations:^{
                CGRect aFrame = surveyView.frame;
                aFrame.origin.y = -aFrame.size.height;
                surveyView.frame = aFrame;
            } completion:^(BOOL finished) {
                [aView removeFromSuperview];
                
                LIOSurveyManager* surveyManager = [LIOSurveyManager sharedSurveyManager];
                NSDictionary* surveyDict = [surveyManager responseDictForSurveyType:aView.currentSurveyType];
                NSDictionary* questionsArray = [surveyDict objectForKey:@"questions"];
                if (!questionsArray || questionsArray.count == 0)
                    [delegate altChatViewControllerWantsSessionTermination:self];
                else
                    [delegate altChatViewController:self wasDismissedWithPendingChatText:pendingChatText];
            }];
        }
        else {
            [UIView animateWithDuration:0.5 animations:^{
                aView.alpha = 0.0;
                aView.transform = CGAffineTransformMakeTranslation(0.0, -self.view.bounds.size.height);
                
            } completion:^(BOOL finished) {
                [aView removeFromSuperview];

                LIOSurveyManager* surveyManager = [LIOSurveyManager sharedSurveyManager];
                NSDictionary* surveyDict = [surveyManager responseDictForSurveyType:aView.currentSurveyType];
                NSDictionary* questionsArray = [surveyDict objectForKey:@"questions"];
                if (!questionsArray || questionsArray.count == 0)
                    [delegate altChatViewControllerWantsSessionTermination:self];
                else
                    [delegate altChatViewController:self wasDismissedWithPendingChatText:pendingChatText];

            }];
        }
        surveyInProgress = NO;
    }
    
    if (LIOSurveyManagerSurveyTypeOffline == aView.currentSurveyType) {
        [self.view endEditing:YES];
        
        if (padUI) {
            [UIView animateWithDuration:0.3 animations:^{
                CGRect aFrame = surveyView.frame;
                aFrame.origin.y = -aFrame.size.height;
                surveyView.frame = aFrame;
            } completion:^(BOOL finished) {
                [aView removeFromSuperview];
                [delegate altChatViewControllerWantsSessionTermination:self];
            }];
        }
        else {
            [UIView animateWithDuration:0.5 animations:^{
                aView.alpha = 0.0;
                aView.transform = CGAffineTransformMakeTranslation(0.0, -self.view.bounds.size.height);
                
            } completion:^(BOOL finished) {
                [aView removeFromSuperview];
                [delegate altChatViewControllerWantsSessionTermination:self];
            }];
        }
        surveyInProgress = NO;
    }
    
    if (LIOSurveyManagerSurveyTypePost == aView.currentSurveyType) {
        [self.view endEditing:YES];
        
        if (padUI) {
            [UIView animateWithDuration:0.3 animations:^{
                CGRect aFrame = surveyView.frame;
                aFrame.origin.y = -aFrame.size.height;
                surveyView.frame = aFrame;
            } completion:^(BOOL finished) {
                [aView removeFromSuperview];
                [delegate altChatViewControllerWantsSessionTermination:self];
            }];
        }
        else {
            [UIView animateWithDuration:0.5 animations:^{
                aView.alpha = 0.0;
                aView.transform = CGAffineTransformMakeTranslation(0.0, -self.view.bounds.size.height);
                
            } completion:^(BOOL finished) {
                [aView removeFromSuperview];
                [delegate altChatViewControllerWantsSessionTermination:self];
            }];
        }
        surveyInProgress = NO;
    }
}

- (void)engagementDidStart {
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];

    if (waitingForEngagementToStart) {
        waitingForEngagementToStart = NO;
        
        UIView* waitingForSurveyView = [self.view viewWithTag:LIOAltChatViewControllerLoadingViewTag];
        if (waitingForSurveyView) {
            [UIView animateWithDuration:0.3 animations:^{
                waitingForSurveyView.alpha = 0.0;
            } completion:^(BOOL finished) {
                [waitingForSurveyView removeFromSuperview];
            }];
        }
        
        dismissalBar.alpha = 1.0;
        inputBar.alpha = 1.0;
        tableView.alpha = 1.0;
        dismissalBar.hidden = NO;
        inputBar.hidden = NO;
        tableView.hidden = NO;
        
        [self performRevealAnimationWithFadeIn:NO];
        if (padUI) {
            double delayInSeconds = 0.1;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self viewDidAppear:NO];
            });
        }
    }
}


- (void)noSurveyRecieved {
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];

    if (waitingForSurvey) {
        waitingForSurvey = NO;
        [LIOSurveyManager sharedSurveyManager].receivedEmptyPreSurvey = YES;
        
        UIView* waitingForSurveyView = [self.view viewWithTag:LIOAltChatViewControllerLoadingViewTag];
        [UIView animateWithDuration:0.3 animations:^{
            waitingForSurveyView.alpha = 0.0;
        } completion:^(BOOL finished) {
            [waitingForSurveyView removeFromSuperview];
        }];
        
        dismissalBar.alpha = 1.0;
        inputBar.alpha = 1.0;
        tableView.alpha = 1.0;
        dismissalBar.hidden = NO;
        inputBar.hidden = NO;
        tableView.hidden = NO;
        
        [self performRevealAnimationWithFadeIn:NO];
        if (padUI) {
            double delayInSeconds = 0.1;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self viewDidAppear:NO];
            });
        }
    }
}

-(void)surveyViewDidFinish:(LIOSurveyView *)aView {
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    LIOSurveyManager* surveyManager = [LIOSurveyManager sharedSurveyManager];
    
    surveyInProgress = NO;
    
    NSDictionary* surveyDict = [surveyManager responseDictForSurveyType:aView.currentSurveyType];
    
    if (LIOSurveyManagerSurveyTypePost == aView.currentSurveyType) {
        [delegate altChatViewController:self didFinishPostSurveyWithResponses:surveyDict];
        NSString *titleString = [[LIOBundleManager sharedBundleManager] localizedStringWithKey:@"LIOSurveyView.SubmitOfflineSurveyAlertTitle"];
        NSString *bodyString = [[LIOBundleManager sharedBundleManager] localizedStringWithKey:@"LIOSurveyView.SubmitOfflineSurveyAlertBody"];
        NSString *buttonString = [[LIOBundleManager sharedBundleManager] localizedStringWithKey:@"LIOSurveyView.SubmitOfflineSurveyAlertButton"];
        
        alertView = [[UIAlertView alloc] initWithTitle:titleString
                                               message:bodyString
                                              delegate:self
                                     cancelButtonTitle:nil
                                     otherButtonTitles:buttonString, nil];
        alertView.tag = LIOAltChatViewControllerOfflineSurveyConfirmAlertViewTag;
        [alertView show];
        
        if (surveyView) {
            [surveyView endEditing:YES];
            
            if (padUI) {
                [UIView animateWithDuration:0.3 animations:^{
                    CGRect aFrame = surveyView.frame;
                    aFrame.origin.y = -aFrame.size.height;
                    surveyView.frame = aFrame;
                } completion:^(BOOL finished) {
                    [surveyView removeFromSuperview];
                    surveyView = nil;
                }];
            } else {
                [UIView animateWithDuration:0.3 animations:^{
                    surveyView.alpha = 0.0;
                    surveyView.transform = CGAffineTransformMakeTranslation(0.0, -self.view.bounds.size.height/2);
                    
                } completion:^(BOOL finished) {
                    [surveyView removeFromSuperview];
                    surveyView = nil;
                }];
            }
        }
    }
    
    if (LIOSurveyManagerSurveyTypeOffline == aView.currentSurveyType) {
        [delegate altChatViewController:self didFinishOfflineSurveyWithResponses:surveyDict];

        NSString *titleString = [[LIOBundleManager sharedBundleManager] localizedStringWithKey:@"LIOSurveyView.SubmitOfflineSurveyAlertTitle"];
        NSString *bodyString = [[LIOBundleManager sharedBundleManager] localizedStringWithKey:@"LIOSurveyView.SubmitOfflineSurveyAlertBody"];
        NSString *buttonString = [[LIOBundleManager sharedBundleManager] localizedStringWithKey:@"LIOSurveyView.SubmitOfflineSurveyAlertButton"];
        
        alertView = [[UIAlertView alloc] initWithTitle:titleString
                                               message:bodyString
                                              delegate:self
                                     cancelButtonTitle:nil
                                     otherButtonTitles:buttonString, nil];
        alertView.tag = LIOAltChatViewControllerOfflineSurveyConfirmAlertViewTag;
        [alertView show];
        
        if (surveyView) {
            [surveyView endEditing:YES];

            if (padUI) {
                [UIView animateWithDuration:0.3 animations:^{
                    CGRect aFrame = surveyView.frame;
                    aFrame.origin.y = -aFrame.size.height;
                    surveyView.frame = aFrame;
                } completion:^(BOOL finished) {
                    [surveyView removeFromSuperview];
                    surveyView = nil;
                }];
            } else {
                [UIView animateWithDuration:0.3 animations:^{
                    surveyView.alpha = 0.0;
                    surveyView.transform = CGAffineTransformMakeTranslation(0.0, -self.view.bounds.size.height/2);
                
                } completion:^(BOOL finished) {
                    [surveyView removeFromSuperview];
                    surveyView = nil;
                }];
            }
        }
    }
    
    if (LIOSurveyManagerSurveyTypePre == aView.currentSurveyType) {
        surveyManager.preSurveyCompleted = YES;
        [delegate altChatViewController:self didFinishPreSurveyWithResponses:surveyDict];
        
        [self reloadMessages];
        
        dismissalBar.alpha = 0.0;
        dismissalBar.hidden = NO;
        inputBar.alpha = 0.0;
        inputBar.hidden = NO;
        tableView.alpha = 0.0;
        tableView.hidden = NO;
        
        waitingForEngagementToStart = YES;

        if (padUI) {
            [UIView animateWithDuration:0.3 animations:^{
                CGRect aFrame = surveyView.frame;
                aFrame.origin.y = -aFrame.size.height;
                surveyView.frame = aFrame;
            } completion:^(BOOL finished) {
                if (!surveyInProgress) {
                    [surveyView removeFromSuperview];
                    surveyView = nil;
                    
                    // Show loading view only if we haven't received the engagement start yet
                    if (waitingForEngagementToStart)
                        [self showLoadingViewWithiPadDelay:NO];
                }
            }];
            
            /*
            if (!surveyInProgress && !isAnimatingDismissal) {
                dismissalBar.alpha = 1.0;
                inputBar.alpha = 1.0;
                tableView.alpha = 1.0;
            
                [self performRevealAnimationWithFadeIn:NO];
            
                double delayInSeconds = 0.1;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [self viewDidAppear:NO];
                });
            }
             */
        }
        else {
            [UIView animateWithDuration:0.3 animations:^{
                aView.alpha = 0.0;
                aView.transform = CGAffineTransformMakeTranslation(0.0, -self.view.bounds.size.height/2);
                
            } completion:^(BOOL finished) {
                /*
                if (!surveyInProgress && !isAnimatingDismissal) {
                    
                    dismissalBar.alpha = 1.0;
                    inputBar.alpha = 1.0;
                    tableView.alpha = 1.0;
                    [self performRevealAnimationWithFadeIn:NO];
                }
                 */
                if (waitingForEngagementToStart)
                    [self showLoadingViewWithiPadDelay:NO];

                [aView removeFromSuperview];
            }];
        }
        
    }
}

#pragma mark - UIActionSheetDelegate methods -

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (LIOAltChatViewControllerPhotoSourceActionSheetTag == actionSheet.tag)
    {
        if (0 == buttonIndex) // take photo/video
            [self showCamera];
        else if (1 == buttonIndex) // choose existing
            [self showPhotoLibraryPicker];
    }
    
    if (LIOAltChatViewControllerResendMessageActionSheetTag == actionSheet.tag)
    {
        if (0 == buttonIndex) {
            [delegate altChatViewController:self didResendChatMessage:clickedFailedMessage];
        }
    }
}

#pragma mark - UIImagePickerControllerDelegate methods -

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    if (padUI) {
        [popover dismissPopoverAnimated:YES];
        currentPopoverType = LIOIpadPopoverTypeNone;
    }
    else {
        [delegate altChatViewControllerWillDismissImagePicker:self];
        [self dismissModalViewControllerAnimated:YES];
    }
    
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (image)
    {
        CGSize resizedImageSize;
        CGFloat targetSize = LIOAltChatViewControllerMaximumAttachmentActualSize / [[UIScreen mainScreen] scale];
        if (image.size.height >= image.size.width) {
            resizedImageSize.height = targetSize;
            resizedImageSize.width = targetSize*(image.size.width/image.size.height);
        } else {
            resizedImageSize.width = targetSize;
            resizedImageSize.height = targetSize*(image.size.height/image.size.width);
        }
        pendingImageAttachment = [[[LIOMediaManager sharedInstance] scaleImage:image toSize:resizedImageSize] retain];
        [self showAttachmentUploadConfirmation];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    if (padUI)
    {
        [popover dismissPopoverAnimated:YES];
        currentPopoverType = LIOIpadPopoverTypeNone;
    }
    else
    {
        [delegate altChatViewControllerWillDismissImagePicker:self];
        [self dismissModalViewControllerAnimated:YES];
    }
}

#pragma mark - UIAlertViewDelegate methods -

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (LIOAltChatViewControllerAttachConfirmAlertViewTag == alertView.tag)
    {
        if (buttonIndex == 1) // yes
        {
            if (pendingImageAttachment)
            {
                NSString *attachmentId = [[LIOMediaManager sharedInstance] commitImageMedia:pendingImageAttachment];
                [delegate altChatViewController:self didChatWithAttachmentId:attachmentId];
                [pendingImageAttachment release];
                pendingImageAttachment = nil;
            }
        }
        else
        {
            [pendingImageAttachment release];
            pendingImageAttachment = nil;
        }
    }
    
    if (LIOAltChatViewControllerOfflineSurveyConfirmAlertViewTag == alertView.tag) {
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [delegate altChatViewControllerWantsSessionTermination:self];
        });
    }
}

@end