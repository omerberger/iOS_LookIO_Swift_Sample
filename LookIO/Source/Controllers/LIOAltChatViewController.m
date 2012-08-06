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
#import "LIOAboutViewController.h"
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
#import "LIOSurveyPickerView.h"
#import "LIOSurveyValidationView.h"
#import "LIOAnimatedCogView.h"
#import "LIOTimerProxy.h"
#import "LIOSurveyViewController.h"

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
- (void)processSurvey;
@end

@implementation LIOAltChatViewController

@synthesize delegate, dataSource, initialChatText, currentMode, currentSurveyType, currentSurveyQuestionIndex;
@dynamic agentTyping;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
        previousSurveyQuestionBubbleGenerated = -1;
        numPreviousMessagesToShowInScrollback = 1;
        currentSurveyQuestionIndex = -1;
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
    
    functionHeaderChat = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    functionHeaderChat.selectionStyle = UITableViewCellSelectionStyleNone;
    [functionHeaderChat.contentView addSubview:aboutButton];
    [functionHeaderChat.contentView addSubview:emailConvoButton];
    [functionHeaderChat.contentView addSubview:endSessionButton];
    
    leaveSurveyButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    [leaveSurveyButton setBackgroundImage:grayStretchableButtonImage forState:UIControlStateNormal];
    leaveSurveyButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    leaveSurveyButton.titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    leaveSurveyButton.titleLabel.layer.shadowOpacity = 0.8;
    leaveSurveyButton.titleLabel.layer.shadowOffset = CGSizeMake(0.0, -1.0);
    [leaveSurveyButton setTitle:@"Exit Chat" forState:UIControlStateNormal];
    [leaveSurveyButton addTarget:self action:@selector(leaveSurveyButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    aFrame = leaveSurveyButton.frame;
    aFrame.size.width = tableView.bounds.size.width - 60.0;
    aFrame.size.height = 32.0;
    aFrame.origin.x = 30.0;
    aFrame.origin.y = 16.0;
    leaveSurveyButton.frame = aFrame;
    leaveSurveyButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    functionHeaderSurvey = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    functionHeaderSurvey.selectionStyle = UITableViewCellSelectionStyleNone;
    [functionHeaderSurvey.contentView addSubview:leaveSurveyButton];
    
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
    
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    if (NO == padUI)
    {
        if (LIOAltChatViewControllerModeSurvey == currentMode)
            numPreviousMessagesToShowInScrollback = 2;
        else
            numPreviousMessagesToShowInScrollback = 1;    
    }
    else
        numPreviousMessagesToShowInScrollback = 3;    
    
    if (LIOAltChatViewControllerModeSurvey == currentMode)
    {
        LIOSurveyManager *surveyManager = [LIOSurveyManager sharedSurveyManager];
        LIOSurveyTemplate *aSurvey = nil;
        NSString *aSurveyHeader = nil;
        if (LIOSurveyManagerSurveyTypePre == currentSurveyType)
        {
            aSurvey = surveyManager.preChatTemplate;
            aSurveyHeader = surveyManager.preChatHeader;
        }
        else if (LIOSurveyManagerSurveyTypePost == currentSurveyType)
        {
            aSurvey = surveyManager.postChatTemplate;
            aSurveyHeader = surveyManager.postChatHeader;
        }
        
        if (aSurvey)
        {
            [surveyMessages release];
            surveyMessages = [[NSMutableArray alloc] init];
            
            LIOChatMessage *headerMessage = [LIOChatMessage chatMessage];
            headerMessage.kind = LIOChatMessageKindHeader;
            headerMessage.date = [NSDate date];
            headerMessage.text = aSurveyHeader;
            [surveyMessages addObject:headerMessage];
            
            if (-1 == currentSurveyQuestionIndex)
                currentSurveyQuestionIndex = 0;
            
            // Might need to restore old questions and answers.
            if (currentSurveyQuestionIndex > 0)
            {
                for (int i=0; i<currentSurveyQuestionIndex; i++)
                {
                    LIOSurveyQuestion *currentQuestion = [aSurvey.questions objectAtIndex:i];
                    
                    LIOChatMessage *newChatMessage = [LIOChatMessage chatMessage];
                    newChatMessage.kind = LIOChatMessageKindRemote;
                    newChatMessage.date = [NSDate date];
                    newChatMessage.text = currentQuestion.label;
                    newChatMessage.sequence = i + 1;
                    [surveyMessages addObject:newChatMessage];
                    
                    id aResponse = [surveyManager answerObjectForSurveyType:currentSurveyType withQuestionIndex:i];
                    if ([aResponse isKindOfClass:[NSArray class]])
                    {
                        NSArray *indexArrayResponse = (NSArray *)aResponse;
                        
                        NSMutableString *result = [NSMutableString string];
                        for (NSNumber *anIndexNumber in indexArrayResponse)
                        {
                            int anIndex = [anIndexNumber intValue];
                            LIOSurveyPickerEntry *anEntry = [currentQuestion.pickerEntries objectAtIndex:anIndex];
                            [result appendFormat:@"%@\n", anEntry.label];
                        }
                        
                        LIOChatMessage *newChatMessage = [LIOChatMessage chatMessage];
                        newChatMessage.date = [NSDate date];
                        newChatMessage.kind = LIOChatMessageKindLocal;
                        newChatMessage.text = result;
                        [surveyMessages addObject:newChatMessage];
                    }
                    else if ([aResponse isKindOfClass:[NSString class]])
                    {
                        LIOChatMessage *newChatMessage = [LIOChatMessage chatMessage];
                        newChatMessage.date = [NSDate date];
                        newChatMessage.kind = LIOChatMessageKindLocal;
                        newChatMessage.text = (NSString *)aResponse;
                        [surveyMessages addObject:newChatMessage];
                    }
                }
                
                [self processSurvey];
                
                if (NO == padUI)
                {
                    numPreviousMessagesToShowInScrollback = 1;
                    [self refreshExpandingFooter];
                    [self scrollToBottomDelayed:YES];
                }
            }
            else
            {
                [self processSurvey];
            }
        }
        else
        {
            currentMode = LIOAltChatViewControllerModeChat;
        }
    }
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
    
    [functionHeaderSurvey release];
    functionHeaderSurvey = nil;
    
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
    
    [leaveSurveyButton release];
    leaveSurveyButton = nil;
    
    [dismissButton release];
    dismissButton = nil;
    
    [toasterView release];
    toasterView = nil;
    
    [validationView release];
    validationView = nil;
    
    currentMessages = nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    tableView.delegate = nil;
    tableView.dataSource = nil;
    [tableView release];
    
    [surveyOutroTimer stopTimer];
    [surveyOutroTimer release];
    
    [background release];
    [pendingChatText release];
    [initialChatText release];
    [chatMessages release];
    [surveyMessages release];
    [headerBar release];
    [inputBar release];
    [functionHeaderChat release];
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
    [currentSurveyValidationErrorString release];
    [validationView release];
    [functionHeaderSurvey release];
    [leaveSurveyButton release];
    
    // I... don't know if this is such a great idea, but.
    [[LIOBundleManager sharedBundleManager] pruneImageCache];
    
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (leavingMessage)
        return;
    
    // If a survey is going to be shown, we want to hide the chat elements that are animating in.
    // They will be revealed after the survey is complete.
    LIOSurveyManager *surveyManager = [LIOSurveyManager sharedSurveyManager];
    if (surveyManager.preChatTemplate)
    {
        dismissalBar.alpha = 0.0;
        inputBar.alpha = 0.0;
        tableView.alpha = 0.0;
        headerBar.alpha = 0.0;
    }
    
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    if (NO == [[UIApplication sharedApplication] isStatusBarHidden])
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    
    [self reloadMessages];
    
    if ([currentMessages count])
    {
        NSIndexPath *lastRow = [NSIndexPath indexPathForRow:[currentMessages count] - 1 inSection:0];
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
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // We might need to exit chat due to a canceled survey.
    if (surveyWasCanceled)
    {
        [self performDismissalAnimation];
        return;
    }
    
    // We might need to show the survey modal.
    LIOSurveyManager *surveyManager = [LIOSurveyManager sharedSurveyManager];
    if (surveyManager.preChatTemplate)
    {
        int lastIndexCompleted = surveyManager.lastCompletedQuestionIndexPre;
        int finalIndex = [surveyManager.preChatTemplate.questions count] - 1;
        if (lastIndexCompleted < finalIndex)
        {
            LIOSurveyViewController *surveyController = [[[LIOSurveyViewController alloc] initWithNibName:nil bundle:nil] autorelease];
            surveyController.delegate = self;
            surveyController.headerString = surveyManager.preChatHeader;
            surveyController.currentQuestionIndex = lastIndexCompleted;
            surveyController.currentSurvey = surveyManager.preChatTemplate;
            [self presentModalViewController:surveyController animated:YES];
            
            return;
        }
    }
    
    if (leavingMessage)
        return;
    
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    double delayInSeconds = 0.6;
    if (NO == padUI) delayInSeconds = 0.1;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        if (NO == pickerIsBeingUsed)
            [inputBar.inputField becomeFirstResponder];
        
        if ([initialChatText length])
        {
            inputBar.inputField.text = initialChatText;
            pendingChatText = initialChatText;
            initialChatText = nil;
        }
        
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
        
    vertGradient.frame = self.view.bounds;
    horizGradient.frame = self.view.bounds;
    
    [self rejiggerTableViewFrame];
    
    [self reloadMessages];
    
    if (NO == padUI)
        [self scrollToBottomDelayed:NO];
    
    if (surveyPicker)
    {
        CGRect aFrame = surveyPicker.frame;
        aFrame.origin.x = 0.0;
        aFrame.size.width = self.view.bounds.size.width;
        surveyPicker.frame = aFrame;
        
        [surveyPicker layoutSubviews];
        
        aFrame = surveyPicker.frame;
        aFrame.origin.y = self.view.bounds.size.height - aFrame.size.height;
        surveyPicker.frame = aFrame;
    }
    
    if (validationView)
    {
        CGFloat yOrigin = surveyPicker.frame.origin.y - validationView.frame.size.height;
        if (nil == surveyPicker)
            yOrigin = inputBar.frame.origin.y - validationView.frame.size.height;
        
        CGRect aFrame = validationView.frame;
        aFrame.size.width = self.view.bounds.size.width;
        aFrame.origin.y = yOrigin;
        validationView.frame = aFrame;
        
        [validationView layoutSubviews];
    }
}

- (void)surveyOutroTimerDidFire
{
    [surveyOutroTimer stopTimer];
    [surveyOutroTimer release];
    surveyOutroTimer = nil;
    
    currentMode = LIOAltChatViewControllerModeChat;
    [self reloadMessages];
    [self scrollToBottomDelayed:YES];
    
    inputBar.inputField.keyboardType = UIKeyboardTypeDefault;
    [inputBar stopPulseAnimation];
    inputBar.inputField.userInteractionEnabled = YES;
    [inputBar.inputField becomeFirstResponder];    
}

- (void)processSurvey
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    LIOSurveyManager *surveyManager = [LIOSurveyManager sharedSurveyManager];
    LIOSurveyTemplate *surveyTemplate;
    if (LIOSurveyManagerSurveyTypePre == currentSurveyType)
        surveyTemplate = surveyManager.preChatTemplate;
    else
        surveyTemplate = surveyManager.postChatTemplate;
    
    if (currentSurveyQuestionIndex >= [surveyTemplate.questions count])
    {        
        // Collect responses for submission.
        NSMutableDictionary *responses = [NSMutableDictionary dictionary];
        for (int i=0; i<[surveyTemplate.questions count]; i++)
        {
            LIOSurveyQuestion *aQuestion = (LIOSurveyQuestion *)[surveyTemplate.questions objectAtIndex:i];
            id aResponse = [[LIOSurveyManager sharedSurveyManager] answerObjectForSurveyType:currentSurveyType withQuestionIndex:i];
            if (aResponse != nil)
                [responses setObject:aResponse forKey:[NSString stringWithFormat:@"%d", aQuestion.questionId]];
        }
        NSDictionary *surveyDict = [NSDictionary dictionaryWithObjectsAndKeys:surveyTemplate.surveyId, @"id", responses, @"responses", nil];
        [delegate altChatViewController:self didFinishSurveyWithResponses:surveyDict];
        
        pickerIsBeingUsed = NO;
        
        [surveyPicker removeFromSuperview];
        [surveyPicker release];
        surveyPicker = nil;
        
        [validationView removeFromSuperview];
        [validationView release];
        validationView = nil;
        
        if (padUI)
            numPreviousMessagesToShowInScrollback = 3;
        else
            numPreviousMessagesToShowInScrollback = 1;
        
        LIOChatMessage *surveyOutro = [LIOChatMessage chatMessage];
        surveyOutro.kind = LIOChatMessageKindSurveyOutro;
        surveyOutro.date = [NSDate date];
        surveyOutro.text = @"lollerchutes";
        [surveyMessages addObject:surveyOutro];
        [self reloadMessages];
        [self scrollToBottomDelayed:YES];
        
        [self revealNotificationString:@"Please wait while we find someone to help you..." withAnimatedKeyboard:NO];
        
        surveyOutroTimer = [[LIOTimerProxy alloc] initWithTimeInterval:5.0 target:self selector:@selector(surveyOutroTimerDidFire)];
        
        return;
    }
    
    // Do we have a valid response for the current question?
    id aResponse = [surveyManager answerObjectForSurveyType:currentSurveyType withQuestionIndex:currentSurveyQuestionIndex];
    if (nil == aResponse)
    {
        LIOSurveyQuestion *currentQuestion = [surveyTemplate.questions objectAtIndex:currentSurveyQuestionIndex];
        
        if (previousSurveyQuestionBubbleGenerated != currentSurveyQuestionIndex)
        {
            LIOChatMessage *newChatMessage = [LIOChatMessage chatMessage];
            newChatMessage.kind = LIOChatMessageKindRemote;
            newChatMessage.date = [NSDate date];
            newChatMessage.text = currentQuestion.label;
            newChatMessage.sequence = currentSurveyQuestionIndex + 1;
            [surveyMessages addObject:newChatMessage];
        }
        
        previousSurveyQuestionBubbleGenerated = currentSurveyQuestionIndex;
        
        [self reloadMessages];
        
        [surveyPicker removeFromSuperview];
        [surveyPicker release];
        surveyPicker = nil;
        
        [validationView removeFromSuperview];
        [validationView release];
        validationView = nil;
        
        // We need either the keyboard, or a picker.
        if (LIOSurveyQuestionDisplayTypeText == currentQuestion.displayType)
        {
            pickerIsBeingUsed = NO;
            
            /*
            if (LIOSurveyQuestionValidationTypeEmail == currentQuestion.validationType)
                inputBar.inputField.keyboardType = UIKeyboardTypeEmailAddress;
            else if (LIOSurveyQuestionValidationTypeNumeric == currentQuestion.validationType)
                inputBar.inputField.keyboardType = UIKeyboardTypeNumberPad;
            else
                inputBar.inputField.keyboardType = UIKeyboardTypeDefault;
            */
            
            inputBar.inputField.userInteractionEnabled = YES;
            //[inputBar.inputField resignFirstResponder];
            [inputBar.inputField becomeFirstResponder];
        }
        else
        {
            pickerIsBeingUsed = YES;
            
            inputBar.inputField.userInteractionEnabled = NO;
            [self.view endEditing:YES];
            
            surveyPicker = [[LIOSurveyPickerView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, 0.0)];
            surveyPicker.surveyQuestion = currentQuestion;
            surveyPicker.delegate = self;
            
            if (LIOSurveyQuestionDisplayTypePicker == currentQuestion.displayType)
                surveyPicker.currentMode = LIOSurveyPickerViewModeSingle;
            else if (LIOSurveyQuestionDisplayTypeMultiselect == currentQuestion.displayType)
                surveyPicker.currentMode = LIOSurveyPickerViewModeMulti;

            [self.view addSubview:surveyPicker];
            [surveyPicker layoutSubviews];
            
            CGRect aFrame = surveyPicker.frame;
            aFrame.origin.y = self.view.bounds.size.height - aFrame.size.height;
            surveyPicker.frame = aFrame;
            
            [surveyPicker showAnimated];
        }
        
        if ([currentSurveyValidationErrorString length])
        {
            [inputBar startPulseAnimation];
            
            validationView = [[LIOSurveyValidationView alloc] init];
            validationView.delegate = self;
            validationView.label.text = currentSurveyValidationErrorString;
            [validationView layoutSubviews];
            
            CGFloat yOrigin = surveyPicker.frame.origin.y - validationView.frame.size.height;
            if (nil == surveyPicker)
                yOrigin = inputBar.frame.origin.y - validationView.frame.size.height;
            
            CGRect aFrame = validationView.frame;
            aFrame.origin.x = 0.0;
            aFrame.origin.y = yOrigin;
            aFrame.size.width = self.view.bounds.size.width;
            validationView.frame = aFrame;
            [self.view insertSubview:validationView belowSubview:inputBar];
            
            [currentSurveyValidationErrorString release];
            currentSurveyValidationErrorString = nil;
            
            [validationView showAnimated];
        }
        else
        {
            [inputBar stopPulseAnimation];
        }
    }
}

- (void)processSurveyResponse:(id)aResponse
{
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    
    NSString *stringResponse = nil;
    NSArray *indexArrayResponse = nil;
    if ([aResponse isKindOfClass:[NSString class]])
        stringResponse = (NSString *)aResponse;
    else if ([aResponse isKindOfClass:[NSArray class]])
        indexArrayResponse = (NSArray *)aResponse;
    else
    {
        LIOLog(@"what: %@", NSStringFromClass([aResponse class]));
        return;
    }
    
    LIOSurveyManager *surveyManager = [LIOSurveyManager sharedSurveyManager];
    LIOSurveyTemplate *surveyTemplate;
    if (LIOSurveyManagerSurveyTypePre == currentSurveyType)
        surveyTemplate = surveyManager.preChatTemplate;
    else
        surveyTemplate = surveyManager.postChatTemplate;
    
    LIOSurveyQuestion *currentQuestion = [surveyTemplate.questions objectAtIndex:currentSurveyQuestionIndex];
    
    if (stringResponse)
    {
        if (0 == [stringResponse length])
        {
            // An empty response is okay for optional questions.
            if (NO == currentQuestion.mandatory)
            {
                if (LIOSurveyManagerSurveyTypePre == currentSurveyType) surveyManager.lastCompletedQuestionIndexPre = currentSurveyQuestionIndex; else surveyManager.lastCompletedQuestionIndexPost = currentSurveyQuestionIndex;
                currentSurveyQuestionIndex++;
            }
            else
            {
                [currentSurveyValidationErrorString release];
                currentSurveyValidationErrorString = [[NSString alloc] initWithString:@"Please enter a response for this question."];
            }
        }
        else
        {
            BOOL validated = NO;
            
            [currentSurveyValidationErrorString release];
            currentSurveyValidationErrorString = nil;
            
            if (LIOSurveyQuestionValidationTypeAlphanumeric == currentQuestion.validationType)
            {
                // Kinda weird. This is just a passthrough, I guess.
                validated = YES;
            }
            else if (LIOSurveyQuestionValidationTypeEmail == currentQuestion.validationType)
            {
                // Cheap e-mail validation: does the string contain one @ symbol?
                NSRegularExpression *emailRegex = [NSRegularExpression regularExpressionWithPattern:@"@" options:0 error:nil];
                if (1 == [emailRegex numberOfMatchesInString:stringResponse options:0 range:NSMakeRange(0, [stringResponse length])])
                    validated = YES;
                else
                    currentSurveyValidationErrorString = [[NSString alloc] initWithString:@"Please enter a valid e-mail address."];
            }
            else if (LIOSurveyQuestionValidationTypeNumeric == currentQuestion.validationType)
            {
                // TODO: Make this better. Currently just looks for any digit and says OK! THAT'S NUMERIC! if there is one.
                NSRegularExpression *numericRegex = [NSRegularExpression regularExpressionWithPattern:@"\\d+" options:0 error:nil];
                NSArray *matches = [numericRegex matchesInString:stringResponse options:0 range:NSMakeRange(0, [stringResponse length])];
                if ([matches count])
                    validated = YES;
                else
                    currentSurveyValidationErrorString = [[NSString alloc] initWithString:@"Please enter a valid number."];
            }
            else if ([currentQuestion.validationRegexp length])
            {
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:currentQuestion.validationRegexp options:0 error:nil];
                NSArray *matches = [regex matchesInString:stringResponse options:0 range:NSMakeRange(0, [stringResponse length])];
                if ([matches count])
                    validated = YES;
                else
                    currentSurveyValidationErrorString = [[NSString alloc] initWithString:@"Please check your input and try again."];
            }
            
            if (validated)
            {
                if (LIOSurveyManagerSurveyTypePre == currentSurveyType) surveyManager.lastCompletedQuestionIndexPre = currentSurveyQuestionIndex; else surveyManager.lastCompletedQuestionIndexPost = currentSurveyQuestionIndex;
                
                [surveyManager registerAnswerObject:stringResponse forSurveyType:currentSurveyType withQuestionIndex:currentSurveyQuestionIndex];
                currentSurveyQuestionIndex++;
                
                LIOChatMessage *newChatMessage = [LIOChatMessage chatMessage];
                newChatMessage.date = [NSDate date];
                newChatMessage.kind = LIOChatMessageKindLocal;
                newChatMessage.text = aResponse;
                [surveyMessages addObject:newChatMessage];
                
                if (NO == padUI && 1 == currentSurveyQuestionIndex)
                {
                    int prev = numPreviousMessagesToShowInScrollback;
                    [self reloadMessages];
                    numPreviousMessagesToShowInScrollback = 1;
                    [self refreshExpandingFooter];
                    [self scrollToBottomDelayed:NO];
                    numPreviousMessagesToShowInScrollback = prev;
                }
            }
            
            /*
            else if (NO == currentQuestion.mandatory)
            {
                [currentSurveyValidationErrorString release];
                currentSurveyValidationErrorString = nil;
                currentSurveyQuestionIndex++;
            }
            */
        }
    }
    else if (indexArrayResponse)
    {
        if (currentQuestion.mandatory && 0 == [indexArrayResponse count])
        {
            [currentSurveyValidationErrorString release];
            currentSurveyValidationErrorString = [[NSString alloc] initWithString:@"Please enter a response for this question."];
        }
        else
        {
            [surveyManager registerAnswerObject:indexArrayResponse forSurveyType:currentSurveyType withQuestionIndex:currentSurveyQuestionIndex];
            
            NSMutableString *result = [NSMutableString string];
            for (NSNumber *anIndexNumber in indexArrayResponse)
            {
                int anIndex = [anIndexNumber intValue];
                LIOSurveyPickerEntry *anEntry = [currentQuestion.pickerEntries objectAtIndex:anIndex];
                [result appendFormat:@"%@\n", anEntry.label];
            }
            
            LIOChatMessage *newChatMessage = [LIOChatMessage chatMessage];
            newChatMessage.date = [NSDate date];
            newChatMessage.kind = LIOChatMessageKindLocal;
            newChatMessage.text = result;
            [surveyMessages addObject:newChatMessage];
            
            if (LIOSurveyManagerSurveyTypePre == currentSurveyType) surveyManager.lastCompletedQuestionIndexPre = currentSurveyQuestionIndex; else surveyManager.lastCompletedQuestionIndexPost = currentSurveyQuestionIndex;
            
            currentSurveyQuestionIndex++;
            
            if (1 == currentSurveyQuestionIndex)
            {
                int prev = numPreviousMessagesToShowInScrollback;
                [self reloadMessages];
                numPreviousMessagesToShowInScrollback = 1;
                [self refreshExpandingFooter];
                [self scrollToBottomDelayed:NO];
                numPreviousMessagesToShowInScrollback = prev;
            }
        }
    }
        
    // After the first question, we want to only show one bubble at a time on iPhone.
    if (currentSurveyQuestionIndex > 0 && UIUserInterfaceIdiomPhone == [[UIDevice currentDevice] userInterfaceIdiom])
    {
        [self scrollToBottomDelayed:NO];
        numPreviousMessagesToShowInScrollback = 1;
    }
    
    [self processSurvey];
    [self scrollToBottomDelayed:YES];
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
    
    [validationView removeFromSuperview];
    [surveyPicker removeFromSuperview];
    
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
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(){
            if (myScrollId == currentScrollId)
            {
                NSIndexPath *lastRow = [NSIndexPath indexPathForRow:[currentMessages count] inSection:0];
                [tableView scrollToRowAtIndexPath:lastRow atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }
        });
    }
    else
    {
        NSIndexPath *lastRow = [NSIndexPath indexPathForRow:[currentMessages count] inSection:0];
        [tableView scrollToRowAtIndexPath:lastRow atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (void)reloadMessages
{
    [chatMessages release];
    chatMessages = [[dataSource altChatViewControllerChatMessages:self] copy];
    
    if (LIOAltChatViewControllerModeChat == currentMode)
        currentMessages = chatMessages;
    else
        currentMessages = surveyMessages;
    
    // Pre-calculate all bubble heights. D:
    [chatBubbleHeights removeAllObjects];
    for (int i=0; i<[currentMessages count]; i++)
    {
        LIOChatBubbleView *tempView = [[LIOChatBubbleView alloc] init];
        
        LIOChatMessage *aMessage = [currentMessages objectAtIndex:i];
        if (LIOChatMessageKindLocal == aMessage.kind)
        {
            tempView.formattingMode = LIOChatBubbleViewFormattingModeLocal;
            
            if (currentMode != LIOAltChatViewControllerModeSurvey)
                tempView.senderName = @"Me";
        }
        else if (LIOChatMessageKindRemote == aMessage.kind)
        {
            tempView.formattingMode = LIOChatBubbleViewFormattingModeRemote;
            tempView.senderName = aMessage.senderName;
        }
        else if (LIOChatMessageKindHeader == aMessage.kind)
        {
            tempView.formattingMode = LIOChatBubbleViewFormattingModeHeader;
        }
        
        if (LIOAltChatViewControllerModeSurvey == currentMode)
            tempView.bubbleStyle = LIOChatBubbleViewBubbleStyleSurvey;
        
        [tempView populateMessageViewWithText:aMessage.text];
        [tempView layoutSubviews];
        
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
    NSIndexPath *expandingFooterIndex = [NSIndexPath indexPathForRow:([currentMessages count] + 1) inSection:0];
    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:expandingFooterIndex] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark -
#pragma mark UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [currentMessages count] + 2;
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
    {
        if (currentMode == LIOAltChatViewControllerModeChat)
            return functionHeaderChat;
        else if (currentMode == LIOAltChatViewControllerModeSurvey)
            return functionHeaderSurvey;
    }
    
    if ([currentMessages count] + 1 == indexPath.row)
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
    
    // ... this kinda defeats the purpose of reusable cells.
    // OH WELL
    LIOChatBubbleView *aBubble = [[[LIOChatBubbleView alloc] initWithFrame:CGRectZero] autorelease];
    aBubble.backgroundColor = [UIColor clearColor];
    aBubble.tag = LIOAltChatViewControllerTableViewCellBubbleViewTag;
    aBubble.delegate = self;
    aBubble.index = indexPath.row;
    
    LIOChatMessage *aMessage = [currentMessages objectAtIndex:(indexPath.row - 1)];
    if (LIOChatMessageKindLocal == aMessage.kind)
    {
        aBubble.formattingMode = LIOChatBubbleViewFormattingModeLocal;
        
        if (currentMode != LIOAltChatViewControllerModeSurvey)
            aBubble.senderName = @"Me";
    }
    else if (LIOChatMessageKindRemote == aMessage.kind)
    {
        aBubble.formattingMode = LIOChatBubbleViewFormattingModeRemote;
        aBubble.senderName = aMessage.senderName;
    }
    else if (LIOChatMessageKindHeader == aMessage.kind)
    {
        aBubble.formattingMode = LIOChatBubbleViewFormattingModeHeader;
    }
    
    if (LIOChatMessageKindSurveyOutro == aMessage.kind)
    {
        // Survey outro only has an animated cog/signal doodad in it. No bubble.
        LIOAnimatedCogView *cogView = [[[LIOAnimatedCogView alloc] init] autorelease];
        [cogView layoutSubviews];
        CGRect aFrame = cogView.frame;
        aFrame.origin.y = 30.0;
        aFrame.origin.x = (aCell.contentView.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
        cogView.frame = aFrame;
        [aCell.contentView addSubview:cogView];
        
        [cogView fadeIn];
    }
    else
        [aCell.contentView addSubview:aBubble];
    
    if (LIOAltChatViewControllerModeSurvey == currentMode)
        aBubble.bubbleStyle = LIOChatBubbleViewBubbleStyleSurvey;
    
    aBubble.rawChatMessage = aMessage;
    [aBubble populateMessageViewWithText:aMessage.text];
    
    if (LIOChatBubbleViewFormattingModeRemote == aBubble.formattingMode)
        aBubble.frame = CGRectMake(0.0, 0.0, 290.0, 0.0);
    else if (LIOChatBubbleViewFormattingModeLocal == aBubble.formattingMode)
        aBubble.frame = CGRectMake(tableView.bounds.size.width - 290.0, 0.0, 290.0, 0.0);
    else if (LIOChatBubbleViewFormattingModeHeader == aBubble.formattingMode)
        aBubble.frame = CGRectMake(0.0, 0.0, aCell.contentView.bounds.size.width, 0.0);
    
    [aBubble setNeedsLayout];
    [aBubble setNeedsDisplay];
    
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
        return 64.0;
    
    if ([currentMessages count] + 1 == row)
    {
        CGFloat heightAccum = 0.0;
        for (int i=0; i<numPreviousMessagesToShowInScrollback; i++)
        {
            int aRow = [currentMessages count] - i;
            heightAccum += [self tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:aRow inSection:0]];
        }
        
        if (padUI)
        {
            CGFloat result = tableView.bounds.size.height - heightAccum;
            if (result < 0.0) result = 7.0 - 10.0;
            return result;
        }
        else
        {
            CGFloat result = tableView.bounds.size.height - heightAccum - 10.0;
            if (result < 0.0) result = 7.0;
            return result;
        }
    }
    
    NSNumber *aHeight = [chatBubbleHeights objectAtIndex:(row - 1)];
    CGFloat height = [aHeight floatValue];
    
    // Headers can be short. All else must be minimum height.
    CGFloat bottomPadding = 0.0;
    LIOChatMessage *currentMessage = [currentMessages objectAtIndex:(row - 1)];
    if (LIOChatMessageKindHeader != currentMessage.kind)
    {
        bottomPadding = 5.0;
        if (height < LIOChatBubbleViewMinTextHeight)
            height = LIOChatBubbleViewMinTextHeight;
    }
    
    return height + bottomPadding;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [currentMessages count] + 1)
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
        [popover presentPopoverFromRect:aboutButton.frame inView:functionHeaderChat.contentView permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
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
        [popover presentPopoverFromRect:emailConvoButton.frame inView:functionHeaderChat.contentView permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
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

- (void)leaveSurveyButtonWasTapped
{
    [self.view endEditing:YES];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Exit Chat?"
                                                        message:@"Would you like to exit this chat?"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Don't Exit", @"Exit", nil];
    [alertView show];
    [alertView autorelease];
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
    
    if (validationView)
    {
        [validationView removeFromSuperview];
        [validationView release];
        validationView = nil;
    }

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
    
    if (validationView)
    {
        [validationView removeFromSuperview];
        [validationView release];
        validationView = nil;
    }    

    // Sweet Jesus, the order of the following things is SUPER IMPORTANT.
    keyboardHeight = 0.0;
    tableView.frame = tableFrame;
    //[self refreshExpandingFooter];
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
    [self refreshExpandingFooter];
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
    
    if (LIOAltChatViewControllerModeSurvey == currentMode)
    {
        [self processSurveyResponse:aString];
        return;
    }
    
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

- (void)inputBarViewDidStopPulseAnimation:(LIOInputBarView *)aView
{
    [validationView hideAnimated];
}

#pragma mark -
#pragma mark LIOHeaderBarViewDelegate methods

- (void)headerBarViewPlusButtonWasTapped:(LIOHeaderBarView *)aView
{
    [tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
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
    popover = nil;
}

#pragma mark -
#pragma mark LIOSurveyPickerViewDelegate methods

- (void)surveyPickerView:(LIOSurveyPickerView *)aView didSelectIndices:(NSArray *)anArrayOfIndices
{
    [pendingSurveyResponse release];
    pendingSurveyResponse = [anArrayOfIndices retain];
    
    [surveyPicker hideAnimated];
    [validationView hideAnimated];
}

- (void)surveyPickerViewDidFinishDismissalAnimation:(LIOSurveyPickerView *)aView
{
    [self processSurveyResponse:[pendingSurveyResponse autorelease]];
    pendingSurveyResponse = nil;
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (1 == buttonIndex)
        [delegate altChatViewControllerWantsToLeaveSurvey:self];
}

#pragma mark -
#pragma mark LIOSurveyValidationViewDelegate methods

- (void)surveyValidationViewDidFinishDismissalAnimation:(LIOSurveyValidationView *)aView
{
    [validationView removeFromSuperview];
    [validationView release];
    validationView = nil;
}

#pragma mark -
#pragma mark LIOSurveyViewControllerDelegate methods

- (BOOL)surveyViewController:(LIOSurveyViewController *)aController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [delegate altChatViewController:self shouldRotateToInterfaceOrientation:interfaceOrientation];
}

- (void)surveyViewControllerDidCancel:(LIOSurveyViewController *)aController
{
    surveyWasCanceled = YES;
    [self dismissModalViewControllerAnimated:YES];
}

- (void)surveyViewControllerDidFinishSurvey:(LIOSurveyViewController *)aController
{
    // Collect responses for submission.
    NSMutableDictionary *finalDict = [NSMutableDictionary dictionary];
    for (int i=0; i<[aController.currentSurvey.questions count]; i++)
    {
        LIOSurveyQuestion *aQuestion = (LIOSurveyQuestion *)[aController.currentSurvey.questions objectAtIndex:i];
        id aResponse = [[LIOSurveyManager sharedSurveyManager] answerObjectForSurveyType:LIOSurveyManagerSurveyTypePre withQuestionIndex:i];
        if (aResponse != nil)
            [finalDict setObject:aResponse forKey:[NSString stringWithFormat:@"%d", aQuestion.questionId]];
    }
    NSMutableDictionary *surveyDict = [NSMutableDictionary dictionary];
    [surveyDict setObject:aController.currentSurvey.surveyId forKey:@"id"];
    [surveyDict setObject:finalDict forKey:@"responses"];
    [delegate altChatViewController:self didFinishSurveyWithResponses:surveyDict];
    
    dismissalBar.alpha = 1.0;
    inputBar.alpha = 1.0;
    tableView.alpha = 1.0;
    headerBar.alpha = 1.0;
    
    [self dismissModalViewControllerAnimated:YES];
}

@end