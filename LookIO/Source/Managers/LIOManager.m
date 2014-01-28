//
//  LIOManager.m
//  LookIO
//
//  Created by Yaron Karasik on 12/5/13.
//
//

#import "LIOManager.h"

#import "LIOLogManager.h"
#import "LIOStatusManager.h"
#import "LIONetworkManager.h"
#import "LIOBundleManager.h"

#import "LIOContainerViewController.h"

#import "LIOVisit.h"
#import "LIOEngagement.h"

#import "LIODraggableButton.h"

#define LIOAlertViewNextStepDismissLookIOWindow 2001
#define LIOAlertViewNextStepShowPostChatSurvey  2002
#define LIOAlertViewNextStepEngagementDidEnd    2003
#define LIOAlertViewNextStepCancelReconnect     2004

#define LIOAlertViewReconnectPrompt             2005
#define LIOAlertViewReconnectSuccess            2006

typedef enum
{
    LIOLookIOWindowStateHidden = 0,
    LIOLookIOWindowStatePresenting,
    LIOLookIOWindowStateVisible,
    LIOLookIOWindowStateDismissing
} LIOLookIOWindowState;

typedef void (^LIOCompletionBlock)(void);

@interface LIOManager () <LIOVisitDelegate, LIOEngagementDelegate, LIODraggableButtonDelegate, LIOContainerViewControllerDelegate, UIAlertViewDelegate>

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

@end

@implementation LIOManager

#pragma mark -
#pragma mark Initialization Methods

static LIOManager *sharedLookIOManager = nil;

+ (LIOManager *) sharedLookIOManager
{
    if (nil == sharedLookIOManager)
        sharedLookIOManager = [[LIOManager alloc] init];
    
    return sharedLookIOManager;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        // Init network manager to set the default endpoints
        [LIONetworkManager networkManager];
    }
    
    return self;
}

- (void)performSetupWithDelegate:(id<LIOLookIOManagerDelegate>)aDelegate
{
    NSAssert([NSThread currentThread] == [NSThread mainThread], @"LookIO can only be used on the main thread!");

    self.delegate = aDelegate;

    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    [LIOStatusManager statusManager].badInitialization = nil == keyWindow;
    
    self.lookioWindow = [[UIWindow alloc] initWithFrame:keyWindow.frame];
    self.lookioWindow.hidden = YES;
    self.lookioWindow.windowLevel = 0.1;
    
    self.lookIOWindowState = LIOLookIOWindowStateHidden;
    
    self.controlButton = [[LIODraggableButton alloc] initWithFrame:CGRectZero];
    self.controlButton.delegate = self;
    [keyWindow addSubview:self.controlButton];
    [self.controlButton resetFrame];
    
    self.visit = [[LIOVisit alloc] init];
    self.visit.delegate = self;
    [self.visit launchVisit];
    
    LIOStatusManager *statusManager = [LIOStatusManager statusManager];
    statusManager.appForegrounded = YES;
    
    [self addNotificationHandlers];
    
    [self setupURLSchemes];
    
    [[LIOLogManager sharedLogManager] logWithSeverity: LIOLogManagerSeverityInfo format:@"Loaded."];
}

- (void)launchNewVisit
{
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
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void)applicationDidEnterBackground:(NSNotification *)aNotification
{
    [LIOStatusManager statusManager].appForegrounded = NO;
    
    if (UIBackgroundTaskInvalid == self.backgroundTaskId)
    {
        self.backgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskId];
            self.backgroundTaskId = UIBackgroundTaskInvalid;
        }];

        if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
        {
            [self.containerViewController dismissCurrentViewController];
        }

        self.backgroundedTime = [NSDate date];
        [self.visit sendContinuationReport];

        if (self.engagement)
        {
            NSMutableDictionary *backgroundedDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                     @"app_backgrounded", @"action",
                                                     nil];
            [self.engagement sendAdvisoryPacketWithDict:backgroundedDict retries:0];
        }
        
        // TODO Dismiss any active alert views
        
        switch (self.visit.visitState) {
            case LIOVisitStateChatActive:
                self.visit.visitState = LIOVisitStateChatActiveBackgrounded;
                break;
                
            case LIOVisitStateVisitInProgress:
                self.visit.visitState = LIOVisitStateAppBackgrounded;
                break;
                
            case LIOVisitStatePreChatSurvey:
                self.visit.visitState = LIOVisitStatePreChatSurveyBackgrounded;
                break;
                
            default:
                self.visit.visitState = LIOVisitStateChatActiveBackgrounded;
                break;
        }
        
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)aNotification
{
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];

    [LIOStatusManager statusManager].appForegrounded = YES;
    
    switch (self.visit.visitState) {
        case LIOVisitStateChatActiveBackgrounded:
            self.visit.visitState = LIOVisitStateChatActive;
            break;
            
        case LIOVisitStateAppBackgrounded:
            self.visit.visitState = LIOVisitStateVisitInProgress;
            break;
            
        case LIOVisitStatePreChatSurveyBackgrounded:
            self.visit.visitState = LIOVisitStatePreChatSurvey;
            break;
            
        default:
            self.visit.visitState = LIOVisitStateChatActive;
            break;
    }
    
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
            
            [self.containerViewController engagement:self.engagement didReceiveMessage:nil];
            
            if (LIOLookIOWindowStateHidden == self.lookIOWindowState)
            {
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

- (NSDictionary *)statusDictionary
{
    return [self.visit introDictionary];
}

- (void)visitSkillMappingDidChange:(LIOVisit *)visit
{
    
}

- (BOOL)enabled
{
    return self.visit.chatEnabled;
}

- (BOOL)chatInProgress
{
    return self.visit.chatInProgress;
}

- (void)setSkill:(NSString *)aRequiredSkill
{
    [self.visit setSkill:aRequiredSkill];
}

- (void)visitChatEnabledDidUpdate:(LIOVisit *)visit
{
    if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManager:didUpdateEnabledStatus:)])
        [self.delegate lookIOManager:self didUpdateEnabledStatus:[self.visit chatEnabled]];
}

- (void)visit:(LIOVisit *)visit controlButtonIsHiddenDidUpdate:(BOOL)isHidden
{
    if (isHidden)
        [self.controlButton hide:YES];
    else
        [self.controlButton show:YES];
}

- (void)controlButtonCharacteristsDidChange:(LIOVisit *)visit
{
    [self.controlButton updateButtonBranding];
}

- (void)visitWillRelaunch:(LIOVisit *)visit
{
    if (self.chatInProgress)
    {
        [self.engagement engagementNotFound];
    }

    [[LIONetworkManager networkManager] resetNetworkEndpoints];
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

#pragma mark -
#pragma mark DraggableButtonDelegate Methods

- (void)draggableButtonDidBeginDragging:(LIODraggableButton *)draggableButton
{
    
}

- (void)draggableButtonDidEndDragging:(LIODraggableButton *)draggableButton
{
    
}

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

    if (LIOAlertViewNextStepShowPostChatSurvey == alertView.tag)
    {
        self.visit.visitState = LIOVisitStatePostChatSurvey;
        
        if (LIOLookIOWindowStateVisible != self.lookIOWindowState)
        {
            [self presentLookIOWindow];            
        }
        [self.containerViewController presentPostchatSurveyForEngagement:self.engagement];
    }

    if (LIOAlertViewReconnectPrompt == alertView.tag)
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
                break;
        }
    }
    
    if (LIOAlertViewReconnectSuccess == alertView.tag)
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
        if (buttonIndex == 0)
            [self.engagement cancelReconnect];
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
    self.visit.visitState = LIOVisitStatePostChatSurvey;
}

- (void)containerViewcontrollerDidTapIntraAppLink:(NSURL *)link
{
    self.nextDismissalCompletionBlock = ^{
        [[UIApplication sharedApplication] openURL:link];
    };
    [self.containerViewController dismissCurrentViewController];
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
    
    for (UIWindow *window in [[UIApplication sharedApplication] windows])
        [window endEditing:YES];
 
    // Set up the window
    self.previousKeyWindow = [[UIApplication sharedApplication] keyWindow];
    self.mainWindow = self.previousKeyWindow;
    
    [self.lookioWindow makeKeyAndVisible];

    // Control Button
    if (!self.visit.controlButtonHidden)
    {
        [self.controlButton hide:YES];
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
}

- (void)dismissLookIOWindow
{
    self.lookIOWindowState = LIOLookIOWindowStateDismissing;
    
    self.lookioWindow.hidden = YES;
    [self.previousKeyWindow makeKeyAndVisible];
    self.previousKeyWindow = nil;
    
    if (!self.visit.controlButtonHidden)
    {
        [self.controlButton show:YES];
    }
    [self.controlButton resetUnreadMessages];
    
    switch (self.visit.visitState) {
        // If chat was opened but not started, we cancel the engagement
        case LIOVisitStateChatOpened:
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
            }
            else
            {
                [self.controlButton setSurveyMode];
                [self.controlButton presentMessage:@"Tap to complete survey"];
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
            [self.controlButton presentMessage:@"Tap to continue chat"];
            break;
            
        default:
            break;
    }
    
    self.lookIOWindowState = LIOLookIOWindowStateHidden;
    
    NSDictionary *chatUp = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"chat_down", @"action",
                            nil];
    [self.engagement sendAdvisoryPacketWithDict:chatUp retries:0];
    
    [self.visit refreshControlButtonVisibility];
    
    if (self.nextDismissalCompletionBlock)
    {
        self.nextDismissalCompletionBlock();
        self.nextDismissalCompletionBlock = nil;
    }
}

- (void)takeScreenshotAndSetBlurImageView {
    dispatch_async(dispatch_get_main_queue(), ^{
        LIOLog(@"Previous window is %@", self.previousKeyWindow);
        UIGraphicsBeginImageContext(self.previousKeyWindow.bounds.size);
        [self.previousKeyWindow.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [self.containerViewController setBlurImage:viewImage];
    });
}

- (void)updateBlurImageView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        LIOLog(@"Previous window is %@", self.previousKeyWindow);
        UIGraphicsBeginImageContext(self.previousKeyWindow.bounds.size);
        [self.previousKeyWindow.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [self.containerViewController updateBlurImage:viewImage];
    });
}

- (void)beginSession
{
    [self beginChat];
}

- (void)endChatAndShowAlert:(BOOL)showAlert
{
    // TODO End chat
}

- (void)beginChat
{
    if (LIOButtonModeLoading == self.controlButton.buttonMode)
    {
        [self showReconnectCancelAlert];
        return;
    }
    
    [self presentLookIOWindow];
    
    switch (self.visit.visitState) {
        case LIOVisitStateVisitInProgress:
            self.engagement = [[LIOEngagement alloc] initWithVisit:self.visit];
            self.engagement.delegate = self;
            self.visit.visitState = LIOVisitStateChatRequested;
            [self.engagement startEngagement];
            
            if (self.visit.surveysEnabled)
                [self.containerViewController presentLoadingViewController];
            else
            {
                [self.containerViewController presentChatForEngagement:self.engagement];
            }
            break;
            
        case LIOVisitStateChatStarted:
            [self.containerViewController presentChatForEngagement:self.engagement];
            break;
            
        case LIOVisitStateChatActive:
            [self.containerViewController presentChatForEngagement:self.engagement];
            break;
            
        case LIOVisitStatePreChatSurvey:
            [self.containerViewController presentPrechatSurveyForEngagement:self.engagement];
            break;
            
        default:
            break;
    }
}

- (void)showReconnectCancelAlert
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.ReconnectCancelAlertTitle")
                                                        message:LIOLocalizedString(@"LIOLookIOManager.ReconnectCancelAlertBody")
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.ReconnectCancelAlertButtonStop"), LIOLocalizedString(@"LIOLookIOManager.ReconnectCancelAlertButtonContinue"), nil];
    alertView.tag = LIOAlertViewNextStepCancelReconnect;
    [alertView show];
}

#pragma mark -
#pragma mark EngagementDelegate Methods

- (void)engagementDidConnect:(LIOEngagement *)engagement
{
    if (LIOVisitStateChatRequested == self.visit.visitState)
    {
        if (![self.visit surveysEnabled])
        {
            self.visit.visitState = LIOVisitStateChatOpened;            
        }
    }
    
    NSDictionary *chatUp = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"chat_up", @"action",
                            nil];
    [self.engagement sendAdvisoryPacketWithDict:chatUp retries:0];
}

- (void)engagementAgentIsReady:(LIOEngagement *)engagement
{
    if (LIOVisitStateChatActiveBackgrounded == self.visit.visitState)
    {
         if (UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
         {
             UILocalNotification *localNotification = [[UILocalNotification alloc] init];
             localNotification.soundName = @"LookIODing.caf";
             localNotification.alertBody = LIOLocalizedString(@"LIOLookIOManager.LocalNotificationReadyBody");
             localNotification.alertAction = LIOLocalizedString(@"LIOLookIOManager.LocalNotificationReadyButton");
             [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
 
             self.chatReceivedWhileAppBackgrounded = YES;
         }
    }
}

- (void)engagementDidStart:(LIOEngagement *)engagement
{
    if (LIOVisitStateChatStarted == self.visit.visitState)
    {
        if (UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
        {
            self.visit.visitState = LIOVisitStateChatActiveBackgrounded;
        }
        else
        {
            self.visit.visitState = LIOVisitStateChatActive;
            [self.containerViewController presentChatForEngagement:engagement];
        }
    }
    
    // If surveys are enabled, and no survey is available, an empty survey will be returned
    // In this case, chat should just be displayed as if it was opened normally
    if (self.visit.surveysEnabled && LIOVisitStateChatRequested == self.visit.visitState)
    {
        self.visit.visitState = LIOVisitStateChatOpened;
        [self.containerViewController presentChatForEngagement:engagement];
    }
}

- (void)engagementDidReceivePrechatSurvey:(LIOEngagement *)engagement
{
    // If surveys aren't enabled, ignore this survey
    if (!self.visit.surveysEnabled)
        return;
    
    if (LIOVisitStateChatRequested == self.visit.visitState)
    {
        self.visit.visitState = LIOVisitStatePreChatSurvey;
        [self.containerViewController presentPrechatSurveyForEngagement:engagement];
    }
}

- (void)engagementDidSubmitPrechatSurvey:(LIOEngagement *)engagement
{
    [self.controlButton setChatMode];
    
    if (LIOVisitStatePreChatSurvey == self.visit.visitState)
    {
        self.visit.visitState = LIOVisitStateChatStarted;
    }
}

- (void)engagementDidReceiveOfflineSurvey:(LIOEngagement *)engagement
{
    if (LIOVisitStateChatStarted == self.visit.visitState)
    {
        self.visit.visitState = LIOVisitStateOfflineSurvey;
        [self.containerViewController presentOfflineSurveyForEngagement:engagement];
    }
}

- (void)engagementDidEnd:(LIOEngagement *)engagement
{
    if (LIOVisitStatePostChatSurvey == self.visit.visitState)
        return;
    
    [self.engagement cleanUpEngagement];
    self.engagement = nil;
    
    self.visit.visitState = LIOVisitStateVisitInProgress;
    if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
        [self dismissLookIOWindow];
    
    [self.controlButton setChatMode];
    [self.controlButton resetUnreadMessages];
    [self.visit refreshControlButtonVisibility];
}

- (void)engagementDidDisconnect:(LIOEngagement *)engagement withAlert:(BOOL)withAlert
{
    // TODO ADd cases where an alert shouldn't be shown, like a prechat survey which was not completed and isn't visible
    
    // If chat is disconnected, let's show an alert view.
    
    NSInteger alertViewTag;
    
    // If a post chat survey is available and surveys are enabled, keep the engagement object and show the survey
    if (self.visit.surveysEnabled && self.engagement.postchatSurvey)
    {
        alertViewTag = LIOAlertViewNextStepShowPostChatSurvey;
    }
    else
    {
        // Otherwise, clear the engagement and dismiss the window after dismissing the alert
        
        alertViewTag = LIOAlertViewNextStepDismissLookIOWindow;
        
        [self.engagement cleanUpEngagement];
        self.engagement = nil;
        
        if ([LIOStatusManager statusManager].appForegrounded)
        {
            self.visit.visitState = LIOVisitStateVisitInProgress;
        }
        else
        {
            self.visit.visitState = LIOVisitStateAppBackgrounded;
        }
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertTitle")
                                                        message:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertBody")
                                                        delegate:self
                                               cancelButtonTitle:nil
                                               otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertButton"), nil];
    alertView.tag = alertViewTag;
    
    if (withAlert)
    {
        [alertView show];
    }
    else
    {
        [self alertView:alertView didDismissWithButtonIndex:0];
    }
    
    [self.controlButton setChatMode];
    [self.controlButton resetUnreadMessages];
    [self.visit refreshControlButtonVisibility];
}

- (void)engagementDidCancel:(LIOEngagement *)engagement
{
    [self.engagement cleanUpEngagement];
    self.engagement = nil;
    
    self.visit.visitState = LIOVisitStateVisitInProgress;
}

- (void)engagementDidFailToStart:(LIOEngagement *)engagement
{
    self.visit.visitState = LIOVisitStateVisitInProgress;
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.StartFailureAlertTitle")
                                                        message:LIOLocalizedString(@"LIOLookIOManager.StartFailureAlertBody")
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.StartFailureAlertButton"), nil];
    alertView.tag = LIOAlertViewNextStepDismissLookIOWindow;
    [alertView show];
}

- (void)engagement:(LIOEngagement *)engagement didSendMessage:(LIOChatMessage *)message
{
    // If chat was open and user sent a first message, visit states goes to started
    if (LIOVisitStateChatOpened == self.visit.visitState)
    {
        self.visit.visitState = LIOVisitStateChatStarted;
    }
}

- (void)engagement:(LIOEngagement *)engagement didReceiveMessage:(LIOChatMessage *)message
{
    if (LIOVisitStateChatActive == self.visit.visitState)
    {
        [self.containerViewController engagement:engagement didReceiveMessage:message];

        if (LIOLookIOWindowStateHidden == self.lookIOWindowState)
        {
            [self.controlButton reportUnreadMessage];
            if (self.visit.controlButtonHidden)
            {
                [self.containerViewController presentChatForEngagement:engagement];
            }
            else
            {
                [self.controlButton presentMessage:@"The agent has sent a message"];
            }
        }
    }
    
    if (LIOVisitStateChatActiveBackgrounded == self.visit.visitState)
    {
        
        if (UIApplicationStateActive != [[UIApplication sharedApplication] applicationState])
        {
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            localNotification.soundName = @"LookIODing.caf";
            localNotification.alertBody = LIOLocalizedString(@"LIOLookIOManager.LocalNotificationChatBody");
            localNotification.alertAction = LIOLocalizedString(@"LIOLookIOManager.LocalNotificationChatButton");
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
            
            self.chatReceivedWhileAppBackgrounded = YES;
        }
    }
}

- (void)engagement:(LIOEngagement *)engagement didReceiveNotification:(NSString *)notification
{
    [self.containerViewController engagement:engagement didReceiveNotification:notification];
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

- (void)engagementWantsReconnectionPrompt:(LIOEngagement *)engagement
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.ReconnectQuestionAlertTitle")
                                                        message:LIOLocalizedString(@"LIOLookIOManager.ReconnectQuestionAlertBody")
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.ReconnectQuestionAlertButtonClose"), LIOLocalizedString(@"LIOLookIOManager.ReconnectQuestionAlertButtonReconnect"), nil];
    alertView.tag = LIOAlertViewReconnectPrompt;

    if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
    {
        self.nextDismissalCompletionBlock = ^{
            [alertView show];
        };
        [self.containerViewController dismissCurrentViewController];
    }
    else
    {
        [alertView show];
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

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.ReconnectedAlertTitle")
                                                        message:LIOLocalizedString(@"LIOLookIOManager.ReconnectedAlertBody")
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.ReconnectedAlertButtonHide"), LIOLocalizedString(@"LIOLookIOManager.ReconnectedAlertButtonOpen"), nil];
    alertView.tag = LIOAlertViewReconnectSuccess;
    [alertView show];
}

- (void)engagementDidFailToReconnect:(LIOEngagement *)engagement
{
    [self.controlButton setChatMode];

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.ReconnectFailureAlertTitle")
                                                        message:LIOLocalizedString(@"LIOLookIOManager.ReconnectFailureAlertBody")
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.ReconnectFailureAlertButton"), nil];
    alertView.tag = LIOAlertViewNextStepEngagementDidEnd;
    [alertView show];
}

- (void)engagementDidDisconnectWhileInPostOrOfflineSurvey:(LIOEngagement *)engagement
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertTitle")
                                                        message:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertBody")
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:LIOLocalizedString(@"LIOLookIOManager.SessionEndedAlertButton"), nil];
    alertView.tag = LIOAlertViewNextStepDismissLookIOWindow;
    [alertView show];
}

- (void)engagementChatMessageStatusDidChange:(LIOEngagement *)engagement
{
    [self.containerViewController engagementChatMessageStatusDidChange:engagement];
}

#pragma mark -
#pragma mark Custom Branding Methods

- (id)brandingViewWithDimensions:(NSValue *)aValue
{
    CGSize aSize = [aValue CGSizeValue];
    if ([(NSObject *)self.delegate respondsToSelector:@selector(lookIOManager:brandingImageForDimensions:)])
    {
        id aView = [self.delegate lookIOManager:self brandingImageForDimensions:aSize];
        if (aView)
        {
            if ([aView isKindOfClass:[UIImage class]])
            {
                UIImage *anImage = (UIImage *)aView;
                return anImage;
            }
            else
            {
                [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"Expected a UIImage from \"brandingImageForDimensions\". Got: \"%@\". Falling back to default branding!", NSStringFromClass([aView class])];
            }
        }
    }
    
    return nil;
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
    [self.visit reportEvent:anEvent withData:nil];
}

- (void)reportEvent:(NSString *)anEvent withData:(id<NSObject>)someData
{
    [self.visit reportEvent:anEvent withData:someData];
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

@end