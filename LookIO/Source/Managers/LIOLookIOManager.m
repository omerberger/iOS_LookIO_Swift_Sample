//
//  LIOLookIOManager.m
//  LookIO
//
//  Created by Yaron Karasik on 12/5/13.
//
//

#import "LIOLookIOManager.h"

// Managers
#import "LIOLogManager.h"
#import "LIOStatusManager.h"
#import "LIONetworkManager.h"
#import "LIOBundleManager.h"
#import "LIOMediaManager.h"

// Models
#import "LIOVisit.h"
#import "LIOEngagement.h"

// View Controllers
#import "LIOContainerViewController.h"

// Views
#import "LIODraggableButton.h"

#define LIOAlertViewNextStepDismissLookIOWindow        2001
#define LIOAlertViewNextStepShowPostChatSurvey         2002
#define LIOAlertViewNextStepEngagementDidEnd           2003
#define LIOAlertViewNextStepCancelReconnect            2004
#define LIOAlertViewNextStepEndEngagement              2005
#define LIOAlertViewNextStepShowPostChatSurveyQuestion 2006

#define LIOAlertViewRegularReconnectPrompt      2010
#define LIOAlertViewRegularReconnectSuccess     2011
#define LIOAlertViewCrashReconnectPrompt        2012
#define LIOAlertViewScreenshotPermission        2013

typedef enum
{
    LIOLookIOWindowStateHidden = 0,
    LIOLookIOWindowStatePresenting,
    LIOLookIOWindowStateVisible,
    LIOLookIOWindowStateDismissing
} LIOLookIOWindowState;

// Event constants.
NSString *const kLPEventConversion  = @"LPEventConversion";
NSString *const kLPEventPageView    = @"LPEventPageView";
NSString *const kLPEventSignUp      = @"LPEventSignUp";
NSString *const kLPEventSignIn      = @"LPEventSignIn";
NSString *const kLPEventAddedToCart = @"LPEventAddedToCart";

// Reported event constants
NSString *const LPDevEventVisitStart           = @"visitStart";
NSString *const LPDevEventColdLead             = @"coldLead";
NSString *const LPDevEventHotLead              = @"hotLead";
NSString *const LPDevEventInvitationShown      = @"invitationShow";
NSString *const LPDevEventEnabledChange        = @"enabledChange";
NSString *const LPDevEventWindowShow           = @"windowShow";
NSString *const LPDevEventWindowHide           = @"windowHide";
NSString *const LPDevEventChatWindowShow       = @"chatWindowShow";
NSString *const LPDevEventChatWindowHide       = @"chatWindowHide";
NSString *const LPDevEventInvitationAccepted   = @"invitationAccept";
NSString *const LPDevEventChatInteractive      = @"chatInteractive";
NSString *const LPDevEventPrechatSurveyShow    = @"prechatSurveyShow";
NSString *const LPDevEventPrechatSurveySubmit  = @"prechatSurveySubmit";
NSString *const LPDevEventPrechatSurveyCancel  = @"prechatSurveyCancel";
NSString *const LPDevEventPostchatSurveyShow   = @"postchatSurveyShow";
NSString *const LPDevEventPostchatSurveySubmit = @"postchatSurveySubmit";
NSString *const LPDevEventOfflineSurveyShow    = @"offlineSurveyShow";
NSString *const LPDevEventOfflineSurveySubmit  = @"offlineSurveySubmit";
NSString *const LPDevEventChatEnd              = @"chatEnd";
NSString *const LPDevEventAgentMessage         = @"agentMessage";
NSString *const LPDevEventVisitorMessage       = @"visitorMessage";
NSString *const LPDevEventVisitorPhoto         = @"visitorPhoto";

typedef void (^LIOCompletionBlock)(void);

@interface LIOLookIOManager () <LIOVisitDelegate, LIOEngagementDelegate, LIODraggableButtonDelegate, LIOContainerViewControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, assign) BOOL didPerformSetup;

@property (nonatomic, strong) UIWindow *lookioWindow;
@property (nonatomic, assign) UIWindow *previousKeyWindow;
@property (nonatomic, assign) LIOLookIOWindowState lookIOWindowState;

@property (nonatomic, strong) LIOContainerViewController *containerViewController;

@property (nonatomic, strong) LIOVisit *visit;
@property (nonatomic, strong) LIOEngagement *engagement;
@property (nonatomic, assign) BOOL chatReceivedWhileAppBackgrounded;

@property (nonatomic, strong) LIODraggableButton *controlButton;
@property (nonatomic, assign) BOOL isRotationActuallyHappening;

@property (nonatomic, strong) UIAlertView *alertView;

@property (nonatomic, strong) NSDate *backgroundedTime;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskId;

@property (nonatomic, copy) LIOCompletionBlock nextDismissalCompletionBlock;

@property (nonatomic, strong) NSMutableArray *urlSchemes;

@property (nonatomic, strong) LIOEngagement *disconnectedEngagement;

@property (nonatomic, strong) UIImageView *cursorView;
@property (nonatomic, strong) UIImageView *clickView;

@property (nonatomic, strong) NSArray *supportedOrientations;

@property (nonatomic, strong) NSTimer *bringButtonToFrontTimer;

@property (nonatomic, copy) NSString *bundleDownloadEngagementSkill;
@property (nonatomic, copy) NSString *bundleDownloadEngagementAccount;


@end

@implementation LIOLookIOManager

#pragma mark -
#pragma mark Initialization Methods

static LIOLookIOManager *sharedLookIOManager = nil;

+ (LIOLookIOManager *) sharedLookIOManager
{
    if (nil == sharedLookIOManager)
        sharedLookIOManager = [[LIOLookIOManager alloc] init];
    
    return sharedLookIOManager;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        // Init network manager to set the default endpoints
        [LIONetworkManager networkManager];
        
        // Set did perform setup to NO, so that
        self.didPerformSetup = NO;
    }
    
    return self;
}

- (void)performSetupWithDelegate:(id<LIOLookIOManagerDelegate>)aDelegate
{
    NSAssert([NSThread currentThread] == [NSThread mainThread], @"LookIO can only be used on the main thread!");
    
    if (self.didPerformSetup) {
        [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"performSetupWithDelegate: has been called more than once in your application. Please call this method only once per application run. Any call except the first will be ignored."];
        return;
    }
    self.didPerformSetup = YES;

    self.delegate = aDelegate;

    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    [LIOStatusManager statusManager].badInitialization = nil == keyWindow;

    if ([LIOStatusManager statusManager].badInitialization)
    {
        [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"Could not find host app's key window! Behavior from this point on is undefined. Make sure to run performSetupWithDelegate in your app delegate’s application:didFinishLaunchingWithOptions: method, after the method makeKeyAndVisible is called on the application’s main window."];
    }
    
    self.lookioWindow = [[UIWindow alloc] initWithFrame:keyWindow.frame];
    self.lookioWindow.hidden = YES;
    self.lookioWindow.windowLevel = 0.1;
    
    self.bringButtonToFrontTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                    target:self
                                                                  selector:@selector(bringButtonToFrontTimerDidFire:)
                                                                  userInfo:nil
                                                                   repeats:YES];
    
    self.lookIOWindowState = LIOLookIOWindowStateHidden;
    
    self.controlButton = [[LIODraggableButton alloc] initWithFrame:CGRectZero];
    self.controlButton.delegate = self;
    [keyWindow addSubview:self.controlButton];
    [self.controlButton resetFrame];
    
    self.engagement = nil;
    self.disconnectedEngagement = nil;
    
    self.visit = [[LIOVisit alloc] init];
    self.visit.delegate = self;
    [self.visit setupCallCenter];
    [self.visit launchVisit];
    
    LIOStatusManager *statusManager = [LIOStatusManager statusManager];
    statusManager.appForegrounded = YES;
    
    [self addNotificationHandlers];
    
    [self setupURLSchemes];
    
    // Setup Screenshare Elements
    
    self.cursorView = [[UIImageView alloc] initWithImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIODefaultTouch"]];
    self.cursorView.frame = CGRectMake(-self.cursorView.frame.size.width, -self.cursorView.frame.size.height, self.cursorView.frame.size.width, self.cursorView.frame.size.height);
    self.cursorView.hidden = YES;
    [keyWindow addSubview:self.cursorView];
    
    self.clickView = [[UIImageView alloc] initWithImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOClickIndicator"]];
    self.clickView.frame = CGRectMake(-self.clickView.frame.size.width, -self.clickView.frame.size.height, self.clickView.frame.size.width, self.clickView.frame.size.height);
    self.clickView.hidden = YES;
    [keyWindow addSubview:self.clickView];
    
    self.bundleDownloadEngagementAccount = nil;
    self.bundleDownloadEngagementSkill = nil;
    
    // Setup list of plist based backup orientations
    
    // Try to get supported orientation information from plist.
    NSArray *plistOrientations = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedInterfaceOrientations"];
    if (plistOrientations)
    {
        NSMutableArray *orientationNumbers = [NSMutableArray array];
        
        if ([plistOrientations containsObject:@"UIInterfaceOrientationPortrait"])
            [orientationNumbers addObject:[NSNumber numberWithInteger:UIInterfaceOrientationPortrait]];
        
        if ([plistOrientations containsObject:@"UIInterfaceOrientationPortraitUpsideDown"])
            [orientationNumbers addObject:[NSNumber numberWithInteger:UIInterfaceOrientationPortraitUpsideDown]];
        
        if ([plistOrientations containsObject:@"UIInterfaceOrientationLandscapeLeft"])
            [orientationNumbers addObject:[NSNumber numberWithInteger:UIInterfaceOrientationLandscapeLeft]];
        
        if ([plistOrientations containsObject:@"UIInterfaceOrientationLandscapeRight"])
            [orientationNumbers addObject:[NSNumber numberWithInteger:UIInterfaceOrientationLandscapeRight]];
        
        self.supportedOrientations = orientationNumbers;
    }
    else
    {
        self.supportedOrientations = [[NSArray alloc] init];
    }
    
    [[LIOLogManager sharedLogManager] logWithSeverity: LIOLogManagerSeverityInfo format:@"Loaded."];
}

- (void)bringButtonToFrontTimerDidFire:(NSTimer *)aTimer
{
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (keyWindow != self.lookioWindow)
    {
        if (self.controlButton)
            [keyWindow bringSubviewToFront:self.controlButton];
    }
}

- (void)launchNewVisit
{
    [self.visit relaunchVisit];
    return;
    
    // End existing chats if they exist
    
    if (self.engagement)
    {
        [self.engagement endEngagement];
    }
    
    [self.visit stopVisit];
    self.visit.delegate = nil;
    self.visit = nil;
    
    [[LIONetworkManager networkManager] resetNetworkEndpoints];
    
    self.visit = [[LIOVisit alloc] init];
    self.visit.delegate = self;
    [self.visit launchVisit];
}

- (void)checkAndReconnectDisconnectedEngagement
{
    LIOEngagement *engagement = [LIOEngagement loadExistingEngagement];
    
    if (engagement == nil)
    {
        [[LIOMediaManager sharedInstance] purgeAllMedia];
        return;
    }
    
    LIOLog(@"Found a saved engagement id! Trying to reconnect...");
    self.disconnectedEngagement = engagement;
    
    
    self.alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.ReconnectQuestionAlertTitle")
                                                message:LIOLocalizedString(@"LIOLookIOManager.ReconnectQuestionAlertBody")
                                               delegate:self
                                      cancelButtonTitle:nil
                                      otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.ReconnectQuestionAlertButtonClose"), LIOLocalizedString(@"LIOLookIOManager.ReconnectQuestionAlertButtonReconnect"), nil];
    self.alertView.tag = LIOAlertViewCrashReconnectPrompt;
    [self.alertView show];
}

#pragma mark -
#pragma mark Override methods

- (void)disableSurveys
{
    [self.visit disableSurveys];
}

- (void)undisableSurveys
{
    [self.visit undisableSurveys];
}

- (void)useIconButton
{
    [self.visit useIconButton];
    self.controlButton.buttonKind = [self.visit.lastKnownButtonType integerValue];
    [self.controlButton updateBaseValues];
    [self.controlButton updateButtonBranding];
}

- (void)useTextButton
{
    [self.visit useTextButton];
    self.controlButton.buttonKind = [self.visit.lastKnownButtonType integerValue];
    [self.controlButton updateBaseValues];
    [self.controlButton updateButtonBranding];
}

- (void)useDefaultButton
{
    [self.visit useDefaultButton];
    self.controlButton.buttonKind = [self.visit.lastKnownButtonType integerValue];
    [self.controlButton updateBaseValues];
    [self.controlButton updateButtonBranding];
}

- (void)disableControlButton
{
    if (self.visit == nil)
        LIOLog(@"No visit yet to disable");
    
    [self.visit disableControlButton];
}

- (void)undisableControlButton
{
    if (self.visit == nil)
        LIOLog(@"No visit yet to disable");

    [self.visit undisableControlButton];
}

- (NSMutableDictionary *)currentBrandingDictionary
{
    NSData *buffer = [NSKeyedArchiver archivedDataWithRootObject:[LIOBrandingManager brandingManager].lastKnownBrandingDictionary];
    return (NSMutableDictionary *)[NSKeyedUnarchiver unarchiveObjectWithData: buffer];
}

- (void)overrideBrandingDictionary:(NSDictionary *)dictionary
{
    [LIOBrandingManager brandingManager].overrideBrandingDictionary = dictionary;
    [self.controlButton updateBaseValues];
    [self.controlButton updateButtonBranding];
}

- (void)removeBrandingOverride
{
    [LIOBrandingManager brandingManager].overrideBrandingDictionary = nil;
    [self.controlButton updateBaseValues];
    [self.controlButton updateButtonBranding];
}

#pragma mark -
#pragma mark Notification handlers

- (void)addNotificationHandlers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillChangeStatusBarOrientation:)
                                                 name:UIApplicationWillChangeStatusBarOrientationNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidChangeStatusBarOrientation:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(bundleDownloadDidFinish:)
                                                 name:LIOBundleManagerBundleDownloadDidFinishNotification
                                               object:nil];

    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void)applicationDidEnterBackground:(NSNotification *)aNotification
{
    [LIOStatusManager statusManager].appForegrounded = NO;
    
    [self dismissExistingAlertView];
    
    if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
    {
        [self.containerViewController dismissImmediatelyForBackgrounding];
    }
    
    if (UIBackgroundTaskInvalid == self.backgroundTaskId)
    {
        self.backgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskId];
            self.backgroundTaskId = UIBackgroundTaskInvalid;
        }];

        self.backgroundedTime = [NSDate date];
        [self.visit sendContinuationReport];

        if (self.engagement)
        {
            NSMutableDictionary *backgroundedDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                     @"app_backgrounded", @"action",
                                                     nil];
            [self.engagement sendAdvisoryPacketWithDict:backgroundedDict retries:0];
        }
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)aNotification
{
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];

    [LIOStatusManager statusManager].appForegrounded = YES;
    
    if (UIBackgroundTaskInvalid != self.backgroundTaskId)
    {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskId];
        self.backgroundTaskId = UIBackgroundTaskInvalid;
        
        if ([self.backgroundedTime timeIntervalSinceNow] <= -1800.0)
        {
            [self.visit relaunchVisit];
        }
        else
        {
            [self.visit sendContinuationReport];
        }
    }
    
    if (self.engagement)
    {
    
        NSMutableDictionary *foregroundedDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                 @"app_foregrounded", @"action",
                                                 nil];
        
        [self.engagement sendAdvisoryPacketWithDict:foregroundedDict retries:0];
        
        if (self.chatReceivedWhileAppBackgrounded)
        {
            self.chatReceivedWhileAppBackgrounded = NO;
            if (LIOLookIOWindowStateHidden == self.lookIOWindowState)
            {
                // Don't popup chat if an alertview is visible because chat ended while in background
                if (!self.alertView)
                    [self beginChat];
            }
        }
    }
}

- (void)applicationWillChangeStatusBarOrientation:(NSNotification *)aNotification
{
    self.isRotationActuallyHappening = YES;
    
    // If control button is visible, let's temporarily hide it
    if (!self.visit.controlButtonHidden)
    {
        [self.controlButton hide:NO];
        self.controlButton.hidden = YES;
    }
    
    // If the lookIO window is visible, let's update the blur image
    if (self.lookIOWindowState == LIOLookIOWindowStateVisible)
    {
        [self updateBlurImageView];
    }
}

- (void)applicationDidChangeStatusBarOrientation:(NSNotification *)aNotification
{
    // After rotation, we should reset the control button frame

    double delayInSeconds = 0.2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.controlButton resetFrame];
        
        // If control button is visible, and lookIO window is hidden, let's reveal the control button after the rotation
        
        if (!self.visit.controlButtonHidden)
        {
            self.controlButton.hidden = NO;
            if (self.lookIOWindowState == LIOLookIOWindowStateHidden)
                [self.controlButton show:YES];
        }
    });
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    UIInterfaceOrientation actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (UIInterfaceOrientationPortrait == actualInterfaceOrientation)
    {
    }
    else if (UIInterfaceOrientationLandscapeLeft == actualInterfaceOrientation)
    {
        transform = CGAffineTransformRotate(transform, -90.0 / 180.0 * M_PI);
    }
    else if (UIInterfaceOrientationPortraitUpsideDown == actualInterfaceOrientation)
    {
        transform = CGAffineTransformRotate(transform, -180.0 / 180.0 * M_PI);
    }
    else // Landscape, home button right
    {
        transform = CGAffineTransformRotate(transform, -270.0 / 180.0 * M_PI);
    }
    
    self.clickView.transform = transform;
    self.cursorView.transform = transform;
}

#pragma mark -
#pragma mark Custom Button Methods

- (void)setChatAvailable
{
    [self.visit setChatAvailable];
}

- (void)setChatUnavailable
{
    [self.visit setChatUnavailable];
}

- (void)setInvitationShown
{
    [self.visit setInvitationShown];
}

- (void)setInvitationNotShown
{
    [self.visit setInvitationNotShown];
}

#pragma mark -
#pragma mark Server usage methods

- (void)setProductionMode
{
    [[LIONetworkManager networkManager] setProductionMode];
}

- (void)setStagingMode
{
    [[LIONetworkManager networkManager] setStagingMode];
}

- (void)setQAMode
{
    [[LIONetworkManager networkManager] setQAMode];
}

#pragma mark -
#pragma mark Visit Interaction Methods

- (void)reportDeveloperEvent:(NSString *)event
{
    if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManager:onEvent:withParameters:)])
        [self.delegate lookIOManager:self onEvent:event withParameters:nil];
}

- (void)reportDeveloperEvent:(NSString *)event withParams:(NSDictionary *)params
{
    if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManager:onEvent:withParameters:)])
        [self.delegate lookIOManager:self onEvent:event withParameters:params];
}

- (NSDictionary *)statusDictionary
{
    return [self.visit introDictionary];
}

- (void)visitSkillMappingDidChange:(LIOVisit *)visit
{
    
}

- (BOOL)enabled
{
    if (self.visit == nil) return NO;
    
    return self.visit.chatEnabled;
}

- (BOOL)isChatEnabledForSkill:(NSString *)skill
{
    if (self.visit == nil) return NO;
    
    return [self.visit isChatEnabledForSkill:skill];
}

- (BOOL)isChatEnabledForSkill:(NSString *)skill forAccount:(NSString *)account
{
    if (self.visit == nil) return NO;

    return [self.visit isChatEnabledForSkill:skill forAccount:account];
}

- (void)setChatDisabled:(BOOL)disabled
{
    self.visit.developerDisabledChat = disabled;
    [self.visit updateEnabledForAllAccountsAndSkills];

    [self visitChatEnabledDidUpdate:self.visit];
    [self.visit refreshControlButtonVisibility];
    [self.visit updateAndReportFunnelState];
}

- (BOOL)chatInProgress
{
    return self.visit.chatInProgress;
}

- (void)setSkill:(NSString *)aRequiredSkill
{
    [self.visit setSkill:aRequiredSkill];
}

- (void)setSkill:(NSString *)skill withAccount:(NSString *)account
{
    [self.visit setSkill:skill withAccount:account];
}


- (void)visitChatEnabledDidUpdate:(LIOVisit *)visit
{
    if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManager:didUpdateEnabledStatus:)])
        [self.delegate lookIOManager:self didUpdateEnabledStatus:[self.visit chatEnabled]];
}

- (void)visit:(LIOVisit *)visit didChangeEnabled:(BOOL)enabled forSkill:(NSString *)skill forAccount:(NSString *)account
{
    if ([(NSObject *)self.delegate respondsToSelector:@selector(lookioManager:didChangeEnabled:forSkill:forAccount:)])
        [self.delegate lookioManager:self didChangeEnabled:enabled forSkill:skill forAccount:account];
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:account, @"account", skill, @"skill", [NSNumber numberWithBool:enabled], @"enabled", nil];
    [self reportDeveloperEvent:LPDevEventEnabledChange withParams:params];
}

- (void)visit:(LIOVisit *)visit controlButtonIsHiddenDidUpdate:(BOOL)isHidden notifyDelegate:(BOOL)notifyDelegate
{
    if (isHidden)
    {
        [self.controlButton hide:YES];
        
        if (notifyDelegate)
        {
            if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManagerDidHideControlButton:)])
                [self.delegate lookIOManagerDidHideControlButton:self];
        }
    }
    else
    {
        if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
            return;
        
        [self.controlButton show:YES];
        
        if (notifyDelegate)
        {
            if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManagerDidShowControlButton:)])
                [self.delegate lookIOManagerDidShowControlButton:self];
        }
    }
}

- (void)controlButtonCharacteristsDidChange:(LIOVisit *)visit
{
    [self.controlButton updateButtonBranding];
}

- (void)visitReportDidLaunch:(LIOVisit *)visit
{
    [self reportDeveloperEvent:LPDevEventVisitStart];
}

- (void)visitDidLaunch:(LIOVisit *)visit
{
    self.controlButton.buttonTitle = self.visit.lastKnownButtonText;
    self.controlButton.buttonKind = [self.visit.lastKnownButtonType integerValue];
    [self.controlButton updateBaseValues];
    
    // Check and reconnect a disconnected engagement, only if it's disconnected
    if (LIOVisitStateVisitInProgress == self.visit.visitState) {
        if ([self engagementShouldCacheChatMessages:nil])
            [self checkAndReconnectDisconnectedEngagement];
        else
            [[LIOMediaManager sharedInstance] purgeAllMedia];
    }
}

- (void)visitWillRelaunch:(LIOVisit *)visit
{
    [[LIONetworkManager networkManager] resetOnlyVisitEndpoints];
}

- (void)visitReachabilityDidChange:(LIOVisit *)visit
{
    if (self.engagement)
    {
        [self.engagement reachabilityDidChange];
    }
}

- (void)visit:(LIOVisit *)visit wantsToShowMessage:(NSString *)message
{
    if (!self.visit.controlButtonHidden)
    {
        [self.controlButton presentMessage:message];
    }
}

- (int)visit:(LIOVisit *)visit engagementFunnelStateForFunnelState:(LIOFunnelState)funnelState
{
    if (funnelState < LIOFunnelStateClicked)
        return funnelState;
    
    if (self.engagement == nil)
        return funnelState;

    if (self.engagement.isConnected == YES)
        return 6;

    if (self.visit.visitState == LIOVisitStateChatActive)
        return 5;
    
    return funnelState;
}

- (void)visitHasIncomingCall:(LIOVisit *)visit
{
    // If an incoming call starts, let's dismiss any alert view and the LookIOWindow
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissExistingAlertView];
        
        if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
        {
            [self.containerViewController dismissImmediatelyForBackgrounding];
        }
    });
}

- (void)visit:(LIOVisit *)visit didChangeFunnelState:(LIOFunnelState)funnelState
{
    switch (funnelState) {
        case LIOFunnelStateVisit:
            [self reportDeveloperEvent:LPDevEventColdLead];
            break;
            
        case LIOFunnelStateHotlead:
            [self reportDeveloperEvent:LPDevEventHotLead];
            break;
            
        case LIOFunnelStateInvitation:
            [self reportDeveloperEvent:LPDevEventInvitationShown];
            break;
            
        case LIOFunnelStateClicked:
            [self reportDeveloperEvent:LPDevEventInvitationAccepted];
            break;
            
        default:
            break;
    }
}

- (BOOL)doesCurrentEngagementExist:(LIOVisit *)visit
{
    return (self.engagement != nil);
}

- (NSString *)visitCurrentEngagementAccount:(LIOVisit *)visit
{
    if (self.engagement)
        return self.engagement.engagementAccount;
    
    return nil;
}

- (NSString *)visitCurrentEngagementSkill:(LIOVisit *)visit
{
    if (self.engagement)
        return self.engagement.engagementSkill;
    
    return nil;
}

- (BOOL)visitShouldReportCallDeflection:(LIOVisit *)visit {
    BOOL shouldReport = YES;
    
    if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManagerShouldReportCallDeflection:)])
        shouldReport = [self.delegate lookIOManagerShouldReportCallDeflection:self];
    
    return shouldReport;
}

#pragma mark -
#pragma mark DraggableButtonDelegate Methods

- (void)draggableButtonWasTapped:(LIODraggableButton *)draggableButton
{
    [self beginChat];
}

#pragma mark -
#pragma mark AlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (LIOAlertViewNextStepDismissLookIOWindow == alertView.tag)
    {
        if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
        {
            [self.containerViewController dismissCurrentViewController];
        }
    }
    
    if (LIOAlertViewNextStepShowPostChatSurveyQuestion == alertView.tag)
    {
        switch (buttonIndex) {
            case 0:
                [self cleanUpEngagementAfterEnd];
                if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
                {
                    [self.containerViewController dismissCurrentViewController];
                }
                break;
                
            case 1:
                self.visit.visitState = LIOVisitStatePostChatSurvey;
                [self.visit refreshControlButtonVisibility];
                
                // Report event
                if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
                {
                    [self reportDeveloperEvent:LPDevEventChatWindowHide];
                }
                if (LIOLookIOWindowStateVisible != self.lookIOWindowState)
                {
                    [self presentLookIOWindow];
                }
                
                // Report event
                [self reportDeveloperEvent:LPDevEventPostchatSurveyShow];
                [self.containerViewController presentPostchatSurveyForEngagement:self.engagement];

                break;
                
            default:
                [self cleanUpEngagementAfterEnd];
                if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
                {
                    [self.containerViewController dismissCurrentViewController];
                }
                break;
        }
    }

    if (LIOAlertViewNextStepShowPostChatSurvey == alertView.tag)
    {
        self.visit.visitState = LIOVisitStatePostChatSurvey;
        [self.visit refreshControlButtonVisibility];

        // Report event
        if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
        {
            [self reportDeveloperEvent:LPDevEventChatWindowHide];
        }
        if (LIOLookIOWindowStateVisible != self.lookIOWindowState)
        {
            [self presentLookIOWindow];            
        }

        // Report event
        [self reportDeveloperEvent:LPDevEventPostchatSurveyShow];
        [self.containerViewController presentPostchatSurveyForEngagement:self.engagement];
    }

    if (LIOAlertViewRegularReconnectPrompt == alertView.tag)
    {
        switch (buttonIndex) {
            case 0:
                [self.engagement declineEngagementReconnect];
                [self engagementDidDisconnect:self.engagement withAlert:NO];
                break;
                
            case 1:
                [self.controlButton setLoadingMode];
                [self.engagement acceptEngagementReconnect];
                break;
                
            default:
                [self.controlButton setLoadingMode];
                [self.engagement acceptEngagementReconnect];
                break;
        }
    }
    
    if (LIOAlertViewRegularReconnectSuccess == alertView.tag)
    {
        switch (buttonIndex) {
            case 0:
                if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
                {
                    [self.containerViewController dismissCurrentViewController];
                }
                break;
                
            case 1:
                if (LIOLookIOWindowStateVisible != self.lookIOWindowState)
                {
                    if (self.engagement == nil)
                        break;
                    
                    [self presentLookIOWindow];
                    switch (self.visit.visitState) {
                        case LIOVisitStatePreChatSurvey:
                            [self.containerViewController presentPrechatSurveyForEngagement:self.engagement];
                            break;
                            
                        case LIOVisitStateOfflineSurvey:
                            [self.containerViewController presentOfflineSurveyForEngagement:self.engagement];
                            break;
                            
                        case LIOVisitStatePostChatSurvey:
                            [self.containerViewController presentPostchatSurveyForEngagement:self.engagement];
                            break;
                            
                        default:
                            [self.containerViewController presentChatForEngagement:self.engagement];
                            break;
                    }
                }
                break;
                
            default:
                break;
        }
    }
    
    if (LIOAlertViewNextStepEngagementDidEnd == alertView.tag)
    {
        [self engagementDidEnd:self.engagement];
    }
    
    if (LIOAlertViewNextStepCancelReconnect == alertView.tag)
    {
        if (buttonIndex == 0) {
            if (self.engagement)
                [self.engagement cancelReconnect];
            else
                [self engagementDidEnd:self.engagement];
        }
    }
    
    if (LIOAlertViewNextStepEndEngagement == alertView.tag)
    {
        if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
        {
            LIOEngagement *engagement = self.engagement;
            self.nextDismissalCompletionBlock = ^{
                [engagement endEngagement];
            };
            [self.containerViewController dismissCurrentViewController];
        }
        else
        {
            if (self.engagement)
                [self.engagement endEngagement];
        }
    }
    
    if (LIOAlertViewCrashReconnectPrompt == alertView.tag)
    {
        switch (buttonIndex) {
            case 0:
                self.disconnectedEngagement = nil;
                break;

            case 1:
                self.engagement = self.disconnectedEngagement;
                self.disconnectedEngagement = nil;
                self.engagement.delegate = self;

                self.visit.visitState = LIOVisitStateChatActive;
                [self.controlButton setLoadingMode];

                [self.engagement attemptReconnectionWithVisit:self.visit];
                break;

                // In case alert view is dimissed by user or by other alert
            default:
                self.disconnectedEngagement = nil;
                break;
        }
    }
    
    if (LIOAlertViewScreenshotPermission == alertView.tag)
    {
        switch (buttonIndex) {
            case 0:
                [self.engagement sendPermissionPacketWithDict:@{@"permission" : @"revoked", @"asset" : @"screenshare"}
                                                      retries:0];
                break;
            case 1:
                [self.engagement sendPermissionPacketWithDict:@{@"permission" : @"granted", @"asset" : @"screenshare"}
                                                      retries:0];
                
                // TODO: Advacned screenshare stuff
                // screenshotsAllowed = YES;
                // statusBarUnderlay.hidden = NO;
                // if (NO == [[UIApplication sharedApplication] isStatusBarHidden])
                //    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
                // screenSharingStartedDate = [[NSDate date] retain];
                if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
                {
                    [self.containerViewController dismissCurrentViewController];
                }
                [self.engagement startScreenshare];
                break;

            // In case alert view is dimissed by user or by other alert
            default:
                [self.engagement sendPermissionPacketWithDict:@{@"permission" : @"revoked", @"asset" : @"screenshare"}
                                                      retries:0];
                break;
        }
    }
    
    // Clear alertview tag so that it will not called again when dismissed (Happens in iOS 8 Beta 5)
    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
        alertView.tag = 0;
}

- (void)dismissExistingAlertView
{
    if (self.alertView)
    {
        if (LIOLookIOWindowStateHidden == self.lookIOWindowState && (LIOAlertViewNextStepShowPostChatSurvey == self.alertView.tag || LIOAlertViewCrashReconnectPrompt == self.alertView.tag || LIOAlertViewNextStepShowPostChatSurveyQuestion == self.alertView.tag))
        {
            // Special case - if chat ended and supposed to show a post chat survey,
            // window is hidden, don't dismiss the alert view so that the post chat
            // survey can still be shown.
        }
        else
        {
            [self.alertView dismissWithClickedButtonIndex:-1 animated:NO];
            self.alertView = nil;
        }
    }
    if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
    {
        [self.containerViewController dismissExistingAlertView];
    }
}

- (void)dismissExistingAlertViewIgnoringTag:(NSInteger)tag {
    if (self.alertView)
    {
        if (LIOLookIOWindowStateHidden == self.lookIOWindowState && (LIOAlertViewNextStepShowPostChatSurvey == self.alertView.tag || LIOAlertViewCrashReconnectPrompt == self.alertView.tag || LIOAlertViewRegularReconnectSuccess == self.alertView.tag || LIOAlertViewNextStepShowPostChatSurveyQuestion == self.alertView.tag))
        {
            // Special case - if chat ended and supposed to show a post chat survey,
            // window is hidden, don't dismiss the alert view so that the post chat
            // survey can still be shown.
        }
        else
        {
            if (self.alertView.tag != tag) {
                [self.alertView dismissWithClickedButtonIndex:-1 animated:NO];
                self.alertView = nil;
            }
        }
    }
    if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
    {
        [self.containerViewController dismissExistingAlertView];
    }
}

#pragma mark -
#pragma mark Container View Controller Delegate Methods

- (void)containerViewControllerDidDismiss:(LIOContainerViewController *)containerViewController
{
    [self dismissLookIOWindow];
}

- (void)containerViewControllerDidPresentPostChatSurvey:(LIOContainerViewController *)containerViewController
{
    // Report event
    if (self.lookIOWindowState == LIOLookIOWindowStateVisible)
        [self reportDeveloperEvent:LPDevEventChatWindowHide];
    
    [self reportDeveloperEvent:LPDevEventPostchatSurveyShow];
    
    self.visit.visitState = LIOVisitStatePostChatSurvey;
    [self.visit refreshControlButtonVisibility];
}

- (void)containerViewControllerDidTapIntraAppLink:(NSURL *)link
{
    self.nextDismissalCompletionBlock = ^{
        [[UIApplication sharedApplication] openURL:link];
    };
    [self.containerViewController dismissCurrentViewController];
}

- (void)containerViewControllerWantsWindowBackgroundColor:(UIColor *)color
{
    self.lookioWindow.backgroundColor = color;
}

- (BOOL)containerViewControllerShowControlButtonForWebView:(LIOContainerViewController *)containerViewController
{
    NSInteger visibilityValue = [self.visit.lastKnownButtonVisibility integerValue];
    switch (visibilityValue) {
        case 0:
            return NO;
            break;
            
        case 1:
            return YES;
            break;
            
        case 2:
            return YES;
            break;
            
        default:
            break;
    }
    return NO;
}

- (NSString *)containerViewControllerButtonTitleForWebView:(LIOContainerViewController *)containerViewController
{
    return self.visit.lastKnownButtonText;
}

- (NSInteger)containerViewControllerButtonKindForWebView:(LIOContainerViewController *)containerViewController
{
    return [self.visit.lastKnownButtonType integerValue];
}

#pragma mark -
#pragma mark Engagement Interaction Methods

- (void)presentLookIOWindow
{
    self.lookIOWindowState = LIOLookIOWindowStatePresenting;
    
    if (self.containerViewController == nil)
    {
        self.containerViewController = [[LIOContainerViewController alloc] init];
        self.containerViewController.delegate = self;
        self.containerViewController.view.alpha = 0.0;
        self.lookioWindow.rootViewController = self.containerViewController;
    }
    
    [self.containerViewController startPresentationAnimation];
    
    for (UIWindow *window in [[UIApplication sharedApplication] windows])
        [window endEditing:YES];
 
    // Set up the window
    if (self.previousKeyWindow == nil)
    {
        if (self.mainWindow)
        {
            self.previousKeyWindow = self.mainWindow;
        
            LIOLog(@"Got key window from mainWindow.");
        }
        else if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManagerMainWindowForHostApp:)])
        {
            self.previousKeyWindow = [self.delegate lookIOManagerMainWindowForHostApp:self];
            self.mainWindow = self.previousKeyWindow;
        
            LIOLog(@"Got host app's key window from delegate: 0x%08X", (unsigned int)self.previousKeyWindow);
        }
        else if ([[[UIApplication sharedApplication] keyWindow] isKindOfClass:[UIWindow class]])
        {
            self.previousKeyWindow = [[UIApplication sharedApplication] keyWindow];
            self.mainWindow = self.previousKeyWindow;
        
            LIOLog(@"Got host app's key window from UIApplication: 0x%08X", (unsigned int)self.previousKeyWindow);
        }
        else
        {
            [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"Could not find host app's key window! Behavior from this point on is undefined."];
        }
    }
    
    self.lookioWindow.backgroundColor = [UIColor clearColor];
    [self.lookioWindow makeKeyAndVisible];
    
    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        self.lookioWindow.frame = [UIScreen mainScreen].bounds;
        self.containerViewController.view.frame = self.lookioWindow.bounds;
    }
    
    // Control Button
    if (!self.visit.controlButtonHidden)
    {
        [self.controlButton hide:YES];
        if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManagerDidHideControlButton:)])
            [self.delegate lookIOManagerDidHideControlButton:self];
    }
    [self.controlButton resetUnreadMessages];
    
    // Blur View
    [self takeScreenshotAndSetBlurImageView];
    
    // LookIOWindow State
    self.lookIOWindowState = LIOLookIOWindowStateVisible;
    
    // Report chat up action
    if (self.engagement)
    {
        NSDictionary *chatUp = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"chat_up", @"action",
                            nil];
        [self.engagement sendAdvisoryPacketWithDict:chatUp retries:0];
    }
    
    if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManagerDidShowChat:)])
        [self.delegate lookIOManagerDidShowChat:self];
    
    [self reportDeveloperEvent:LPDevEventWindowShow];

}

- (void)dismissLookIOWindow
{
    // If not visible, don't dismiss
    if (LIOLookIOWindowStateVisible != self.lookIOWindowState)
        return;
    
    self.lookIOWindowState = LIOLookIOWindowStateDismissing;
    
    self.lookioWindow.hidden = YES;
    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
    {
        [self.previousKeyWindow makeKeyAndVisible];
        self.previousKeyWindow = nil;
    } else {
        // This fixes a bug with UIWindow and modal view controllers on iOS 5.0
        [self.previousKeyWindow makeKeyWindow];
        self.previousKeyWindow.hidden = NO;
        self.previousKeyWindow = nil;
    }
    
    if (!self.visit.controlButtonHidden)
    {
        [self.controlButton show:YES];
        if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManagerDidShowControlButton:)])
            [self.delegate lookIOManagerDidShowControlButton:self];
    }
    [self.controlButton resetUnreadMessages];
    
    switch (self.visit.visitState) {
        // If chat was opened but not started, we cancel the engagement
        case LIOVisitStateChatOpened:
            [self reportDeveloperEvent:LPDevEventChatWindowHide];
            self.visit.visitState = LIOVisitStateVisitInProgress;
            [self.engagement cancelEngagement];
            break;
            
        case LIOVisitStateChatRequested:
            self.visit.visitState = LIOVisitStateVisitInProgress;
            [self.engagement cancelEngagement];
            break;

            
        case LIOVisitStatePreChatSurvey:
            // If prechat survey is open and no questions were answered, cancel the engagement
            if (![self.engagement.prechatSurvey anyQuestionsAnswered])
            {
                self.visit.visitState = LIOVisitStateVisitInProgress;
                [self.engagement cancelEngagement];
                
                [self reportDeveloperEvent:LPDevEventPrechatSurveyCancel];
            }
            else
            {
                [self.controlButton setSurveyMode];
                [self.controlButton presentMessage:LIOLocalizedString(@"LIOControlButtonView.CompleteSurveyPopupMessage")];
            }
            break;

        // If we just sumbitted an offline survey, end the engagement
        case LIOVisitStateOfflineSurvey:
            self.visit.visitState = LIOVisitStateVisitInProgress;
            [self.engagement endEngagement];
            break;
            
        case LIOVisitStatePostChatSurvey:
            self.visit.visitState = LIOVisitStateVisitInProgress;
            [self.engagement endEngagement];
            break;
            
        case LIOVisitStateChatActive:
            [self reportDeveloperEvent:LPDevEventChatWindowHide];
            [self.controlButton presentMessage:LIOLocalizedString(@"LIOControlButtonView.ChatContinuePopupMessage")];
            break;
            
        case LIOVisitStateChatStarted:
            [self.controlButton presentMessage:LIOLocalizedString(@"LIOControlButtonView.ChatContinuePopupMessage")];
            break;
            
        default:
            break;
    }
    
    self.lookIOWindowState = LIOLookIOWindowStateHidden;
    
    // Only send chat_down if the engagement is still active at this point
    if (self.engagement) {
        NSDictionary *chatUp = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"chat_down", @"action",
                            nil];
        [self.engagement sendAdvisoryPacketWithDict:chatUp retries:0];
    }
    
    [self.visit refreshControlButtonVisibility];
    
    if (self.nextDismissalCompletionBlock)
    {
        self.nextDismissalCompletionBlock();
        self.nextDismissalCompletionBlock = nil;
    }
    
    // If the engagement is over/cancelled, let's get rid of the container view controller to save memory
    if (LIOVisitStateVisitInProgress == self.visit.visitState)
    {
        [self.containerViewController removeTimers];
        self.containerViewController = nil;
        self.lookioWindow.rootViewController = nil;
    }
    
    if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManagerDidHideChat:)])
        [self.delegate lookIOManagerDidHideChat:self];
    
    [self reportDeveloperEvent:LPDevEventWindowHide];
}

- (void)takeScreenshotAndSetBlurImageView {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;
        [self.containerViewController setBlurImage:[self captureScreenFromPreviousOnly:YES]];

        self.containerViewController.blurImageView.transform = CGAffineTransformIdentity;

        if (!LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
        {            
            switch (actualOrientation) {
                case UIInterfaceOrientationPortrait:
                    self.containerViewController.blurImageView.transform = CGAffineTransformIdentity;
                    break;
                    
                case UIInterfaceOrientationLandscapeLeft:
                    self.containerViewController.blurImageView.transform = CGAffineTransformMakeRotation(M_PI/2);
                    break;
                    
                case UIInterfaceOrientationLandscapeRight:
                    self.containerViewController.blurImageView.transform = CGAffineTransformMakeRotation(-M_PI/2);
                    break;
                    
                case UIInterfaceOrientationPortraitUpsideDown:
                    self.containerViewController.blurImageView.transform = CGAffineTransformMakeRotation(M_PI);
                    break;
                    
                default:
                    break;
            }
        }
        self.containerViewController.blurImageView.frame = self.containerViewController.view.bounds;
    });
}

- (void)updateBlurImageView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIInterfaceOrientation actualOrientation = [UIApplication sharedApplication].statusBarOrientation;
        [self.containerViewController setBlurImage:[self captureScreenFromPreviousOnly:YES]];

        self.containerViewController.blurImageView.transform = CGAffineTransformIdentity;
        
        if (!LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
        {
            switch (actualOrientation) {
                case UIInterfaceOrientationPortrait:
                    self.containerViewController.blurImageView.transform = CGAffineTransformIdentity;
                    break;
                    
                case UIInterfaceOrientationLandscapeLeft:
                    self.containerViewController.blurImageView.transform = CGAffineTransformMakeRotation(M_PI/2);
                    break;
                    
                case UIInterfaceOrientationLandscapeRight:
                    self.containerViewController.blurImageView.transform = CGAffineTransformMakeRotation(-M_PI/2);
                    break;
                    
                case UIInterfaceOrientationPortraitUpsideDown:
                    self.containerViewController.blurImageView.transform = CGAffineTransformMakeRotation(M_PI);
                    break;
                    
                default:
                    break;
            }
        }
        
        self.containerViewController.blurImageView.frame = self.containerViewController.view.bounds;
    });
}

- (UIImage *)captureScreenFromPreviousOnly:(BOOL)previousOnly
{
    // CAUTION: Called on a non-main thread!
//    statusBarUnderlayBlackout.hidden = NO;
    
    BOOL shouldBlur = [[LIOBrandingManager brandingManager] booleanValueForField:@"active" element:LIOBrandingElementChatBackgroundBlur];
    
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];
    BOOL isiPad3 = NO;
    if (padUI && [[LIOStatusManager deviceType] hasPrefix:@"iPad3,"])
    {
        isiPad3 = YES;
        shouldBlur = NO;
    }

    if (!shouldBlur)
        return nil;
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    UIGraphicsBeginImageContextWithOptions(screenSize, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    NSArray *windows = nil;
    if (previousOnly) {
        if (self.previousKeyWindow) {
            windows = @[self.previousKeyWindow];
        }
    }
    else
    {
        windows = [[UIApplication sharedApplication] windows];
    }    
    
    // Iterate over every window from back to front
    for (UIWindow *window in windows)
    {
        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen])
        {
            // -renderInContext: renders in the coordinate space of the layer,
            // so we must first apply the layer's geometry to the graphics context
            CGContextSaveGState(context);
            
            // Center the context around the window's anchor point
            CGContextTranslateCTM(context, [window center].x, [window center].y);
            // Apply the window's transform about the anchor point
            CGContextConcatCTM(context, [window transform]);
            // Offset by the portion of the bounds left of and above the anchor point
            CGContextTranslateCTM(context,
                                  -[window bounds].size.width * [[window layer] anchorPoint].x,
                                  -[window bounds].size.height * [[window layer] anchorPoint].y);
              
            // Render the layer hierarchy to the current context
            [[window layer] renderInContext:context];
            
            // Restore the context
            CGContextRestoreGState(context);
        }
    }
    
    // Retrieve the screenshot image
    UIImage *screenshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // CAUTION: Called on a non-main thread!
//    statusBarUnderlayBlackout.hidden = YES;
    
    return screenshotImage;
}

- (void)beginSession
{
    [self beginChat];
}

- (void)endChatAndShowAlert:(BOOL)showAlert
{
    if (![self chatInProgress])
        return;
    
    if (showAlert)
    {
        [self dismissExistingAlertView];
        self.alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertTitle")
                                                          message:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertBody")
                                                         delegate:self
                                                cancelButtonTitle:nil                                              otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertButton"), nil];
        self.alertView.tag = LIOAlertViewNextStepEndEngagement;
        [self.alertView show];
    }
    else
    {
        if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
        {
            LIOEngagement *engagement = self.engagement;
            self.nextDismissalCompletionBlock = ^{
                [engagement endEngagement];
            };
            [self.containerViewController dismissCurrentViewController];
        }
        else
        {
            if (self.engagement)
                [self.engagement endEngagement];
        }
    }

}

- (void)beginChat
{
    // If a required account skill is set, we will use that for chat
    if (self.visit)
    {
        if (self.visit.requiredAccountSkill)
        {
            [self beginChatWithSkill:self.visit.requiredAccountSkill.skill withAccount:self.visit.requiredAccountSkill.account];
            return;
        }
        
        if (self.visit.defaultAccountSkill)
        {
            [self beginChatWithSkill:self.visit.defaultAccountSkill.skill withAccount:self.visit.defaultAccountSkill.account];
            return;
        }
    }
   
    // Otherwise start a chat without any parameters
    [self beginChatWithSkill:nil withAccount:nil];
}

- (void)beginChatWithSkill:(NSString *)skill
{
    // If a default account exists, we will use that for
    if (self.visit)
    {
        if (self.visit.defaultAccountSkill)
        {
            [self beginChatWithSkill:skill withAccount:self.visit.defaultAccountSkill.account];
            return;
        }
    }
    
    [self beginChatWithSkill:skill withAccount:nil];
}

- (void)beginChatWithSkill:(NSString *)skill withAccount:(NSString *)account
{
    if (LIOButtonModeLoading == self.controlButton.buttonMode)
    {
        [self showReconnectCancelAlert];
        return;
    }
    
    if (LIOVisitStateFailed == self.visit.visitState || LIOVisitStateQueued == self.visit.visitState || LIOVisitStateInitialized == self.visit.visitState || LIOVisitStateLaunching == self.visit.visitState)
    {
        [self presentEngagementDidFailToStartAlert];
        return;
    }
    
    if (self.containerViewController != nil)
        [self.containerViewController updateStatusBarInset];
    [self presentLookIOWindow];
    
    if ([LIOBundleManager sharedBundleManager].isDownloadingBundle)
    {
        self.bundleDownloadEngagementSkill = skill;
        self.bundleDownloadEngagementAccount = account;
        
        [self.containerViewController presentLoadingViewControllerWithQueueingMessage:NO];
        return;
    }
    
    [self presentContainerViewControllerForCurrentStateWithSkill:skill withAccount:account];
}


- (void)presentContainerViewControllerForCurrentStateWithSkill:(NSString *)skill withAccount:(NSString *)account
{
    switch (self.visit.visitState) {
        case LIOVisitStateVisitInProgress:
            if (self.engagement)
            {
                [self.engagement cleanUpEngagement];
                self.engagement = nil;
            }
            self.engagement = [[LIOEngagement alloc] initWithVisit:self.visit skill:skill account:account];
            self.engagement.delegate = self;
            self.visit.visitState = LIOVisitStateChatRequested;
            [self.engagement startEngagement];
            [self.visit updateEnabledForAllAccountsAndSkills];
            
            [self.containerViewController presentLoadingViewControllerWithQueueingMessage:NO];
            break;
            
        case LIOVisitStateChatStarted:
            [self.containerViewController presentLoadingViewControllerWithQueueingMessage:YES];
            break;
            
        case LIOVisitStateChatActive:
            [self reportDeveloperEvent:LPDevEventChatWindowShow];
            [self.containerViewController presentChatForEngagement:self.engagement];
            break;
            
        case LIOVisitStatePreChatSurvey:
            [self.containerViewController presentPrechatSurveyForEngagement:self.engagement];
            break;
            
        default:
            break;
    }
}

- (void)bundleDownloadDidFinish:(NSNotification *)notification
{
    // If the bundle finished downloading when the window is visible, we should start the chat with the last used account and skill, or default if those
    // do not exist for some reason
    if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
    {
        if (self.bundleDownloadEngagementSkill && self.bundleDownloadEngagementAccount)
        {
            [self presentContainerViewControllerForCurrentStateWithSkill:self.bundleDownloadEngagementSkill withAccount:self.bundleDownloadEngagementAccount];
            
            self.bundleDownloadEngagementAccount = nil;
            self.bundleDownloadEngagementSkill = nil;
        }
        else
        {
            if (self.visit.defaultAccountSkill)
                [self presentContainerViewControllerForCurrentStateWithSkill:self.visit.defaultAccountSkill.skill withAccount:self.visit.defaultAccountSkill.account];
        }
    }
}

- (void)showReconnectCancelAlert
{
    [self dismissExistingAlertView];
    self.alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.ReconnectCancelAlertTitle")
                                                        message:LIOLocalizedString(@"LIOLookIOManager.ReconnectCancelAlertBody")
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.ReconnectCancelAlertButtonStop"), LIOLocalizedString(@"LIOLookIOManager.ReconnectCancelAlertButtonContinue"), nil];
    self.alertView.tag = LIOAlertViewNextStepCancelReconnect;
    [self.alertView show];
}

#pragma mark -
#pragma mark EngagementDelegate Methods

- (void)engagementDidConnect:(LIOEngagement *)engagement
{
    NSDictionary *chatUp = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"chat_up", @"action",
                            nil];
    [self.engagement sendAdvisoryPacketWithDict:chatUp retries:0];
}

- (void)engagementAgentIsReady:(LIOEngagement *)engagement
{
    if (![[LIOStatusManager statusManager] appForegrounded])
    {
         if (UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
         {
             if ([self canShowLocalNotification]) {
                 UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                 localNotification.soundName = @"LookIODing.caf";
                 localNotification.alertBody = LIOLocalizedString(@"LIOLookIOManager.LocalNotificationReadyBody");
                 localNotification.alertAction = LIOLocalizedString(@"LIOLookIOManager.LocalNotificationReadyButton");
                 [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
             }
             self.chatReceivedWhileAppBackgrounded = YES;
         }
    }
}

- (void)engagementHasNoPrechatSurvey:(LIOEngagement *)engagement
{
    // If surveys are enabled, and no survey is available, an empty survey will be returned
    // In this case, chat should just be displayed as if it was opened normally
    if (LIOVisitStateChatRequested == self.visit.visitState)
    {
        if (self.lookIOWindowState == LIOLookIOWindowStateVisible)
            [self reportDeveloperEvent:LPDevEventChatWindowShow];

        self.visit.visitState = LIOVisitStateChatOpened;
        [self.containerViewController presentChatForEngagement:engagement];
    }
}

// Called when "connected" message is sent
- (void)engagementDidStart:(LIOEngagement *)engagement
{
    // Report event
    if (!engagement.didReportChatInteractive)
    {
        engagement.didReportChatInteractive = YES;
        [self reportDeveloperEvent:LPDevEventChatInteractive];
    }
    
    if (LIOVisitStateChatStarted == self.visit.visitState || LIOVisitStateChatOpened == self.visit.visitState)
    {
        self.visit.visitState = LIOVisitStateChatActive;
        
        if (UIApplicationStateActive == [[UIApplication sharedApplication] applicationState])
        {
            if (self.lookIOWindowState == LIOLookIOWindowStateVisible)
            {
                [self reportDeveloperEvent:LPDevEventChatWindowShow];
                [self.containerViewController presentChatForEngagement:engagement];
            }
        }
    }
}

- (void)engagementDidQueue:(LIOEngagement *)engagement
{
    if (LIOVisitStateChatOpened == self.visit.visitState)
    {
        self.visit.visitState = LIOVisitStateChatStarted;
    }
}

- (void)engagementDidReceivePrechatSurvey:(LIOEngagement *)engagement
{
    if (LIOVisitStateChatRequested == self.visit.visitState)
    {
        [self reportDeveloperEvent:LPDevEventPrechatSurveyShow];
        
        self.visit.visitState = LIOVisitStatePreChatSurvey;
        [self.containerViewController presentPrechatSurveyForEngagement:engagement];
    }
}

- (void)engagementDidSubmitPrechatSurvey:(LIOEngagement *)engagement
{
    // Report event
    [self reportDeveloperEvent:LPDevEventPrechatSurveySubmit];
    
    [self.controlButton setChatMode];
    
    if (LIOVisitStatePreChatSurvey == self.visit.visitState)
    {
        self.visit.visitState = LIOVisitStateChatStarted;
    }
}

- (void)engagementDidSubmitOfflineSurvey:(LIOEngagement *)engagement
{
    [self reportDeveloperEvent:LPDevEventOfflineSurveySubmit];
}

- (void)engagementDidSubmitPostchatSurvey:(LIOEngagement *)engagement
{
    [self reportDeveloperEvent:LPDevEventPostchatSurveySubmit];
}

- (void)engagementDidReceiveOfflineSurvey:(LIOEngagement *)engagement
{
    if (LIOVisitStateChatStarted == self.visit.visitState || LIOVisitStateChatActive == self.visit.visitState || LIOVisitStateChatOpened == self.visit.visitState)
    {
        // Let's check if the developer has defined a custom action to use
        BOOL callChatNotAnsweredAfterDismissal = NO;
        if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManagerShouldUseCustomActionForChatNotAnswered:)])
            if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManagerCustomActionForChatNotAnswered:)])
                callChatNotAnsweredAfterDismissal = [self.delegate lookIOManagerShouldUseCustomActionForChatNotAnswered:self];
        
        if (callChatNotAnsweredAfterDismissal)
        {
            // First let's end the engagement
            if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
            {
                id delegate = self.delegate;
                LIOEngagement *engagement = self.engagement;
                self.nextDismissalCompletionBlock = ^{
                    [engagement endEngagement];
                    [delegate lookIOManagerCustomActionForChatNotAnswered:[LIOLookIOManager sharedLookIOManager]];
                };
                [self.containerViewController dismissCurrentViewController];
            }
            else
            {
                if (self.engagement)
                    [self.engagement endEngagement];
                [self.delegate lookIOManagerCustomActionForChatNotAnswered:self];
            }
        }
        else
        {
            [self reportDeveloperEvent:LPDevEventOfflineSurveyShow];
            
            self.visit.visitState = LIOVisitStateOfflineSurvey;
            [self.containerViewController presentOfflineSurveyForEngagement:engagement];
            [self.visit refreshControlButtonVisibility];
            
            // Show chat UI if hidden
            if (LIOLookIOWindowStateVisible != self.lookIOWindowState)
            {
                [self presentLookIOWindow];
            }
        }
    }
}

- (void)engagementDidEnd:(LIOEngagement *)engagement
{
    if (LIOVisitStatePostChatSurvey == self.visit.visitState)
        return;
    
    // Report event
    [self reportDeveloperEvent:LPDevEventChatEnd];
    
    [self.engagement cleanUpEngagement];
    self.engagement = nil;
    [self.containerViewController dismissCurrentNotification];
    
    if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManagerDidEndChat:)])
        [self.delegate lookIOManagerDidEndChat:self];
    
    self.visit.visitState = LIOVisitStateVisitInProgress;
    if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
    {
        [self.containerViewController dismissCurrentViewController];
    }
    
    [self visitChatEnabledDidUpdate:self.visit];
    [self.visit updateEnabledForAllAccountsAndSkills];
    [self.controlButton setChatMode];
    [self.controlButton resetUnreadMessages];
    [self.visit refreshControlButtonVisibility];
}

- (void)engagementDidDisconnect:(LIOEngagement *)engagement withAlert:(BOOL)withAlert
{
    // TODO: Add cases where an alert shouldn't be shown, like a prechat survey which was not completed and isn't visible
    
    // If chat is disconnected, let's show an alert view.
    
    NSInteger alertViewTag;
    
    // If a post chat survey is available and surveys are enabled, keep the engagement object and show the survey
    if (self.engagement.postchatSurvey)
    {
         if (self.visit.lastKnownButtonPopupChat == NO && self.lookIOWindowState != LIOLookIOWindowStateVisible)
             alertViewTag = LIOAlertViewNextStepShowPostChatSurveyQuestion;
        else
            alertViewTag = LIOAlertViewNextStepShowPostChatSurvey;
    }
    else
    {
        // Otherwise, clear the engagement and dismiss the window after dismissing the alert
        
        alertViewTag = LIOAlertViewNextStepDismissLookIOWindow;
        [self cleanUpEngagementAfterEnd];
    }
    
    [self dismissExistingAlertView];
    
    // If there is a post chat survey, and pop up chat is disabled,
    // ask the user if he wants to see it. Otherwise, just notify that the session has ended.
    if (LIOAlertViewNextStepShowPostChatSurveyQuestion == alertViewTag) {
        self.alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.SessionEndedPostChatAlertTitle")
                                                    message:LIOLocalizedString(@"LIOLookIOManager.SessionEndedPostChatAlertBody")
                                                   delegate:self
                                          cancelButtonTitle:LIOLocalizedString(@"LIOLookIOManager.SessionEndedPostChatAlertButtonCancel")
                                          otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.SessionEndedPostChatAlertButtonAccept"), nil];
    }
    else
    {
        self.alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertTitle")
                                                    message:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertBody")
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertButton"), nil];
    }
    self.alertView.tag = alertViewTag;
    
    if (withAlert)
    {
        [self.alertView show];
    }
    else
    {
        [self alertView:self.alertView didDismissWithButtonIndex:0];
    }
    
    [self.controlButton setChatMode];
    [self.controlButton resetUnreadMessages];
    [self.visit refreshControlButtonVisibility];
}

- (void)cleanUpEngagementAfterEnd {
    // Report event
    [self reportDeveloperEvent:LPDevEventChatEnd];
    [self reportDeveloperEvent:LPDevEventChatWindowHide];
    
    [self.engagement cleanUpEngagement];
    self.engagement = nil;
    [self.containerViewController dismissCurrentNotification];
    
    [self visitChatEnabledDidUpdate:self.visit];
    [self.visit updateEnabledForAllAccountsAndSkills];
    
    if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManagerDidEndChat:)])
        [self.delegate lookIOManagerDidEndChat:self];
    
    self.visit.visitState = LIOVisitStateVisitInProgress;
}

- (void)engagementDidCancel:(LIOEngagement *)engagement
{
    [self.engagement cleanUpEngagement];
    self.engagement = nil;
    [self.containerViewController dismissCurrentNotification];
    
    [self visitChatEnabledDidUpdate:self.visit];
    [self.visit updateEnabledForAllAccountsAndSkills];

    self.visit.visitState = LIOVisitStateVisitInProgress;
}

- (void)engagementDidFailToStart:(LIOEngagement *)engagement
{
    self.visit.visitState = LIOVisitStateVisitInProgress;

    [self dismissExistingAlertView];
    self.alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.StartFailureAlertTitle")
                                                        message:LIOLocalizedString(@"LIOLookIOManager.StartFailureAlertBody")
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.StartFailureAlertButton"), nil];
    self.alertView.tag = LIOAlertViewNextStepDismissLookIOWindow;
    [self.alertView show];
}

- (void)presentEngagementDidFailToStartAlert
{
    [self dismissExistingAlertView];
    self.alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.StartFailureAlertTitle")
                                                message:LIOLocalizedString(@"LIOLookIOManager.StartFailureAlertBody")
                                               delegate:nil
                                      cancelButtonTitle:nil                                      otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.StartFailureAlertButton"), nil];
    [self.alertView show];
    
}

- (void)engagement:(LIOEngagement *)engagement didSendMessage:(LIOChatMessage *)message
{
    // Report dev event
    switch (message.kind) {
        case LIOChatMessageKindLocal:
            [self reportDeveloperEvent:LPDevEventVisitorMessage];
            break;
            
        case LIOChatMessageKindLocalImage:
            [self reportDeveloperEvent:LPDevEventVisitorPhoto];
            break;
            
        default:
            break;
    }
    
    // If chat was open and user sent a first message, visit states goes to started
    if (LIOVisitStateChatOpened == self.visit.visitState)
    {
        self.visit.visitState = LIOVisitStateChatStarted;
        
        if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
        {
            [self reportDeveloperEvent:LPDevEventChatWindowHide];
            [self.containerViewController presentLoadingViewControllerWithQueueingMessage:YES];
        }
    }
}

- (void)engagement:(LIOEngagement *)engagement didReceiveMessage:(LIOChatMessage *)message
{
    // Report dev event
    [self reportDeveloperEvent:LPDevEventAgentMessage];
    
    if (LIOVisitStateChatActive == self.visit.visitState)
    {
        [self.containerViewController engagement:engagement didReceiveMessage:message];
        
        if (LIOLookIOWindowStateHidden == self.lookIOWindowState)
        {
            if (self.visit.lastKnownButtonPopupChat)
            {
                [self presentLookIOWindow];
                [self.containerViewController presentChatForEngagement:engagement];
                [self reportDeveloperEvent:LPDevEventChatWindowShow];
            }
            else
            {
                if (!self.visit.controlButtonHidden)
                {
                    [self.controlButton reportUnreadMessage];
                    [self.controlButton presentMessage:LIOLocalizedString(@"LIOLookIOManager.LocalNotificationChatBody")];
                }
                // If the button is hidden, let's send this information through a delegate method
                else
                {
                    [self.controlButton reportUnreadMessage];
                    if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManager:didSendNotification:withUnreadMessagesCount:)])
                    {
                        [self.delegate lookIOManager:self didSendNotification:LIOLocalizedString(@"LIOLookIOManager.LocalNotificationChatBody") withUnreadMessagesCount:self.controlButton.numberOfUnreadMessages];
                    }
                }
            }
        }
    }

    if (![[LIOStatusManager statusManager] appForegrounded])
    {
        if (UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
        {
            if ([self canShowLocalNotification]) {
                UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                localNotification.soundName = @"LookIODing.caf";
                localNotification.alertBody = LIOLocalizedString(@"LIOLookIOManager.LocalNotificationChatBody");
                localNotification.alertAction = LIOLocalizedString(@"LIOLookIOManager.LocalNotificationChatButton");
                [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
            }
            self.chatReceivedWhileAppBackgrounded = YES;
        }
    }
}

- (BOOL)canShowLocalNotification
{
    BOOL shouldShowNotification = YES;
    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
    {
        UIUserNotificationSettings *settings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        if (!(settings.types & UIUserNotificationTypeAlert))
            shouldShowNotification = NO;
    }
    return shouldShowNotification;
}

- (void)engagement:(LIOEngagement *)engagement didReceiveNotification:(NSString *)notification
{
    [self.containerViewController engagement:engagement didReceiveNotification:notification];
    if (LIOLookIOWindowStateVisible != self.lookIOWindowState)
    {
        if (!self.visit.controlButtonHidden)
        {
            [self.controlButton presentMessage:notification];
        }
        // If the button is hidden, let's send this information through a delegate method
        else
        {
            if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManager:didSendNotification:withUnreadMessagesCount:)])
            {
                [self.delegate lookIOManager:self didSendNotification:notification withUnreadMessagesCount:self.controlButton.numberOfUnreadMessages];
            }
        }
    }
}

- (void)engagement:(LIOEngagement *)engagement agentDidUpdateTypingStatus:(BOOL)isTyping;
{
    [self.containerViewController engagement:engagement agentIsTyping:isTyping];
}

- (BOOL)engagementShouldShowSendPhotoKeyboardItem:(LIOEngagement *)engagement
{
    UInt32 result = kLPCollaborationComponentNone;
    if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManagerEnabledCollaborationComponents:)])
        result = [self.delegate lookIOManagerEnabledCollaborationComponents:self];
    
    if (kLPCollaborationComponentPhoto == result)
        return YES;

    return NO;
}

- (void)engagementRequestedToResendAllUDEs:(LIOEngagement *)engagement
{
    if (self.visit)
    {
        [self.visit sendContinuationReportAndResendAllUDEs];
    }
}

- (BOOL)engagementShouldCacheChatMessages:(LIOEngagement *)engagement
{
    BOOL shouldCache = NO;
    if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManagerShouldCacheChatMessagesForReconnect:)])
        shouldCache = [self.delegate lookIOManagerShouldCacheChatMessagesForReconnect:self];

    return shouldCache;
}

- (void)engagementWantsReconnectionPrompt:(LIOEngagement *)engagement
{
    [self dismissExistingAlertView];
    self.alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.ReconnectQuestionAlertTitle")
                                                        message:LIOLocalizedString(@"LIOLookIOManager.ReconnectQuestionAlertBody")
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.ReconnectQuestionAlertButtonClose"), LIOLocalizedString(@"LIOLookIOManager.ReconnectQuestionAlertButtonReconnect"), nil];
    self.alertView.tag = LIOAlertViewRegularReconnectPrompt;

    UIAlertView *alertViewToShow = self.alertView;
    
    if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
    {
        self.nextDismissalCompletionBlock = ^{
            [alertViewToShow show];
        };
        [self.containerViewController dismissCurrentViewController];
    }
    else
    {
        [self.alertView show];
    }
}

- (void)engagementDidReconnect:(LIOEngagement *)engagement
{

    if (self.visit.visitState == LIOVisitStatePreChatSurvey)
    {
        [self.controlButton setSurveyMode];
    }
    else
    {
        [self.controlButton setChatMode];
    }

    // In case the reconnect prompt alertview is still present, we shouldn't call it's default functionality
    // This issue appeared in iOS 8 because of changes to the way the alertview works
    [self dismissExistingAlertViewIgnoringTag:LIOAlertViewRegularReconnectPrompt];
    
    self.alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.ReconnectedAlertTitle")
                                                        message:LIOLocalizedString(@"LIOLookIOManager.ReconnectedAlertBody")
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.ReconnectedAlertButtonHide"), LIOLocalizedString(@"LIOLookIOManager.ReconnectedAlertButtonOpen"), nil];
    self.alertView.tag = LIOAlertViewRegularReconnectSuccess;
    [self.alertView show];
}

- (void)engagementDidFailToReconnect:(LIOEngagement *)engagement
{
    [self.controlButton setChatMode];

    [self dismissExistingAlertView];
    self.alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.ReconnectFailureAlertTitle")
                                                        message:LIOLocalizedString(@"LIOLookIOManager.ReconnectFailureAlertBody")
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.ReconnectFailureAlertButton"), nil];
    self.alertView.tag = LIOAlertViewNextStepEngagementDidEnd;
    [self.alertView show];
}

- (void)engagementDidDisconnectWhileInPostOrOfflineSurvey:(LIOEngagement *)engagement
{
    [self dismissExistingAlertView];
    self.alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertTitle")
                                                        message:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertBody")
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertButton"), nil];
    self.alertView.tag = LIOAlertViewNextStepDismissLookIOWindow;
    [self.alertView show];
}

- (void)engagementChatMessageStatusDidChange:(LIOEngagement *)engagement
{
    [self.containerViewController engagementChatMessageStatusDidChange:engagement];
}



- (void)engagementWantsScreenshare:(LIOEngagement *)engagement
{
    if (![[LIOStatusManager statusManager] appForegrounded])
    {
        
        if (UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
        {
            if ([self canShowLocalNotification]) {
                UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                localNotification.soundName = @"LookIODing.caf";
                localNotification.alertBody = LIOLocalizedString(@"LIOLookIOManager.LocalNotificationScreenshareBody");
                localNotification.alertAction = LIOLocalizedString(@"LIOLookIOManager.LocalNotificationScreenshareButton");
                [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
            }
        }
    }
    
    [self dismissExistingAlertView];
    self.alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.ScreenshareAlertTitle")
                                                message:LIOLocalizedString(@"LIOLookIOManager.ScreenshareAlertBody")
                                               delegate:self
                                      cancelButtonTitle:nil
                                      otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.ScreenshareAlertButtonDisallow"), LIOLocalizedString(@"LIOLookIOManager.ScreenshareAlertButtonAllow"), nil];
    self.alertView.tag = LIOAlertViewScreenshotPermission;
    [self.alertView show];
}

- (UIImage *)engagementWantsScreenshot:(LIOEngagement *)engagement
{
    if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
        return nil;
    
    if (UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
        return nil;

    return [self captureScreenFromPreviousOnly:NO];
}

- (void)engagement:(LIOEngagement *)engagement screenshareCursorMoveToPoint:(CGPoint)point
{
    self.cursorView.hidden = NO;
    
    CGRect aFrame = self.cursorView.frame;
    UIInterfaceOrientation actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (actualInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
        
        aFrame.origin.x = point.y;
        aFrame.origin.y = applicationFrame.size.height - point.x - aFrame.size.height;
    } else if (actualInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
        
        aFrame.origin.x = applicationFrame.size.width - point.y - aFrame.size.width/2;
        aFrame.origin.y = point.x;
    } else
    {
        aFrame.origin.x = point.x;
        aFrame.origin.y = point.y;
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        self.cursorView.frame = aFrame;
    }];
}

- (void)engagement:(LIOEngagement *)engagement wantsCursor:(BOOL)cursor
{
    if (cursor)
    {
        self.cursorView.hidden = NO;
        self.clickView.hidden = NO;

        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        
        CGRect aFrame = CGRectZero;
        aFrame.size.width = self.cursorView.image.size.width * 8.0;
        aFrame.size.height = self.cursorView.image.size.height * 8.0;
        aFrame.origin.x = (keyWindow.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
        aFrame.origin.y = (keyWindow.frame.size.height / 2.0) - (aFrame.size.height / 2.0);
        self.cursorView.frame = aFrame;
        self.cursorView.alpha = 0.0;
        
        aFrame.size.width = self.cursorView.image.size.width;
        aFrame.size.height = self.cursorView.image.size.height;
        aFrame.origin.x = (keyWindow.frame.size.width / 2.0) - (aFrame.size.width / 2.0);
        aFrame.origin.y = (keyWindow.frame.size.height / 2.0) - (aFrame.size.height / 2.0);
        
        [UIView animateWithDuration:0.25 animations:^{
            self.cursorView.frame = aFrame;
            self.cursorView.alpha = 1.0;
        }];
    }
    else
    {
        self.cursorView.hidden = YES;
        self.clickView.hidden = YES;
    }
}

- (void)engagement:(LIOEngagement *)engagement screenshareDidClickAtPoint:(CGPoint)point
{
    CGRect aFrame = CGRectZero;
    aFrame.size.width = self.clickView.image.size.width;
    aFrame.size.height = self.clickView.image.size.height;
    self.clickView.bounds = aFrame;
    self.clickView.alpha = 0.0;
    
    self.clickView.center = CGPointMake(point.x, point.y);
    
    aFrame = CGRectZero;
    aFrame.size.width = self.clickView.image.size.width * 3.0;
    aFrame.size.height = self.clickView.image.size.height * 3.0;
    
    
    CGRect correctFrame = [self clickViewFrameForPoint:point];
    aFrame.origin.x = correctFrame.origin.x;
    aFrame.origin.y = correctFrame.origin.y;
    
    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut)
                     animations:^{
                         self.clickView.frame = aFrame;
                         self.clickView.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.1
                                               delay:0.2
                                             options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseIn)
                                          animations:^{
                                              self.clickView.alpha = 0.0;
                                          }
                                          completion:nil];
                     }];
}

- (CGRect)clickViewFrameForPoint:(CGPoint)point
{
    CGRect aFrame = self.clickView.frame;
    UIInterfaceOrientation actualInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (actualInterfaceOrientation == UIInterfaceOrientationLandscapeLeft)
    {
        CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
        
        aFrame.origin.x = point.y - aFrame.size.width*1.5;
        aFrame.origin.y = applicationFrame.size.height - point.x - aFrame.size.height*1.5;
    } else if (actualInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
        aFrame.origin.x = applicationFrame.size.width - point.y - aFrame.size.width*1;
        aFrame.origin.y = point.x - aFrame.size.height*1.5;
    } else
    {
        aFrame.origin.x = point.x - aFrame.size.width*1.5;
        aFrame.origin.y = point.y - aFrame.size.height*1.5;
    }
    return aFrame;
}

- (BOOL)engagementShouldUseSSO:(LIOEngagement *)engagement
{
    BOOL shouldUseSSO = NO;
    if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManagerSingleSignOnEnabled:)])
        shouldUseSSO = [self.delegate lookIOManagerSingleSignOnEnabled:self];
    
    return shouldUseSSO;
}

- (NSURL *)engagementSSOKeyGenURL:(LIOEngagement *)engagement
{
    NSURL *SSOKeyGenURL = nil;
    if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManagerSingleSignOnKeyGenURL:)])
        SSOKeyGenURL = [self.delegate lookIOManagerSingleSignOnKeyGenURL:self];
    
    return SSOKeyGenURL;
}

#pragma mark -
#pragma mark Custom Variables

- (void)setCustomVariable:(id)anObject forKey:(NSString *)aKey
{
    [self.visit setUDE:anObject forKey:aKey];
}

- (id)customVariableForKey:(NSString *)aKey
{
    return [self.visit UDEForKey:aKey];
}

- (void)addCustomVariables:(NSDictionary *)aDictionary
{
    [self.visit addUDEs:aDictionary];
}

- (void)clearCustomVariables
{
    [self.visit clearUDEs];
}

#pragma mark -
#pragma mark Event Reporting

- (void)reportEvent:(NSString *)anEvent
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.visit reportEvent:anEvent withData:nil];
    });
}

- (void)reportEvent:(NSString *)anEvent withData:(id<NSObject>)someData
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.visit reportEvent:anEvent withData:someData];
    });
}

#pragma mark -
#pragma mark Helper Methods

- (BOOL)isIntraLink:(NSURL *)aURL
{
    return [self.urlSchemes containsObject:[[aURL scheme] lowercaseString]];
}

- (void)setupURLSchemes
{
    self.urlSchemes = [[NSMutableArray alloc] init];
    NSArray *cfBundleURLTypes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
    if ([cfBundleURLTypes isKindOfClass:[NSArray class]])
    {
        for (NSDictionary *aURLType in cfBundleURLTypes)
        {
            if ([aURLType isKindOfClass:[NSDictionary class]])
            {
                NSArray *cfBundleURLSchemes = [aURLType objectForKey:@"CFBundleURLSchemes"];
                if ([cfBundleURLSchemes isKindOfClass:[NSArray class]])
                {
                    for (NSString *aScheme in cfBundleURLSchemes)
                    {
                        if (NO == [self.urlSchemes containsObject:aScheme])
                            [self.urlSchemes addObject:[aScheme lowercaseString]];
                    }
                }
            }
        }
    }
}

- (id)linkViewForURL:(NSURL *)aURL
{
    if (NO == [self.urlSchemes containsObject:[[aURL scheme] lowercaseString]])
        return nil;
    
    if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManager:linkViewForURL:)])
        return [self.delegate lookIOManager:self linkViewForURL:aURL];
    
    return nil;
}

- (BOOL)supportDeprecatedXcodeVersions
{
    BOOL supportDeprecatedXcodeVersions = NO;
    if ([(NSObject *)self.delegate respondsToSelector:@selector(supportDeprecatedXcodeVersions)])
        supportDeprecatedXcodeVersions = [self.delegate supportDeprecatedXcodeVersions];
        
    return supportDeprecatedXcodeVersions;
}

#pragma mark -
#pragma mark Autorotation Methods

- (BOOL)containerViewController:(LIOContainerViewController *)containerViewController shouldRotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation
{
    UIWindow *hostAppWindow = [[UIApplication sharedApplication] keyWindow];
    if (self.previousKeyWindow && self.previousKeyWindow != hostAppWindow)
        hostAppWindow = self.previousKeyWindow;
    
    // Ask delegate.
    if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManager:shouldRotateToInterfaceOrientation:)])
        return [self.delegate lookIOManager:self shouldRotateToInterfaceOrientation:anOrientation];
    
    // Ask root view controller.
    if (hostAppWindow.rootViewController)
        return [hostAppWindow.rootViewController shouldAutorotateToInterfaceOrientation:anOrientation];
    
    // Fall back on plist settings.
    [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"Using .plist keys to determine rotation behavior. This may not be accurate. You may want to make use of the following LIOLookIOManagerDelegate method: lookIOManager:shouldRotateToInterfaceOrientation:"];

    return [self.supportedOrientations containsObject:[NSNumber numberWithInteger:anOrientation]];
}

-(BOOL)containerViewControllerShouldAutorotate:(LIOContainerViewController *)containerViewController
{
    UIWindow *hostAppWindow = [[UIApplication sharedApplication] keyWindow];
    if (self.previousKeyWindow && self.previousKeyWindow != hostAppWindow)
        hostAppWindow = self.previousKeyWindow;
    
    // Ask delegate.
    if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManagerShouldAutorotate:)])
        return [self.delegate lookIOManagerShouldAutorotate:self];
    
    // Ask root view controller.
    if (hostAppWindow.rootViewController)
        return [hostAppWindow.rootViewController shouldAutorotate];
    
    return NO;
}

- (NSInteger)containerViewControllerSupportedInterfaceOrientations:(LIOContainerViewController *)containerViewController
{
    UIWindow *hostAppWindow = [[UIApplication sharedApplication] keyWindow];
    if (self.previousKeyWindow && self.previousKeyWindow != hostAppWindow)
        hostAppWindow = self.previousKeyWindow;
    
    // Ask delegate.
    if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManagerSupportedInterfaceOrientations:)])
        return [self.delegate lookIOManagerSupportedInterfaceOrientations:self];
    
    // Ask root view controller.
    if (hostAppWindow.rootViewController)
        return [hostAppWindow.rootViewController supportedInterfaceOrientations];
    
    // UIInterfaceOrientationMaskPortrait is 2 as of 10/18/12.
    return 2;
}

@end