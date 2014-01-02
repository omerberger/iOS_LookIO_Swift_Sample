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

typedef enum
{
    LIOLookIOWindowStateHidden = 0,
    LIOLookIOWindowStatePresenting,
    LIOLookIOWindowStateVisible,
    LIOLookIOWindowStateDismissing
} LIOLookIOWindowState;

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

@end

@implementation LIOManager

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
    
    self.containerViewController = [[LIOContainerViewController alloc] init];
    self.containerViewController.delegate = self;
    self.containerViewController.view.alpha = 0.0;
    self.lookioWindow.rootViewController = self.containerViewController;
    
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
    
    [[LIOLogManager sharedLogManager] logWithSeverity: LIOLogManagerSeverityInfo format:@"Loaded."];
}

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
    
    // TODO Dismiss any existing alertViews
    
    // TODO Created background task, monitor background time and send continue
    
    // TODO Send app_backgrounded advisory packet
    
    // TODO Dismiss chat if it's visible
    
    // TODO Rejigger windows if needed
}

- (void)applicationWillEnterForeground:(NSNotification *)aNotification
{
    [LIOStatusManager statusManager].appForegrounded = YES;
    
    // TODO End background task
    
    // TODO Check if 30 minutes have passed, if so, create a new visit
    // TODO If not, send continue report
    
    // TODO Send app_foregrounded advisory packet
    
    // TODO Check if a message was recieved while background and show chat if needed
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
    
    [self takeScreenshotAndSetBlurImageView];
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

#pragma mark Visit Interaction Methods

- (void)visitSkillMappingDidChange:(LIOVisit *)visit
{
    
}

- (BOOL)enabled
{
    return self.visit.chatEnabled;
}

- (void)chatEnabledDidUpdate:(LIOVisit *)visit
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

#pragma mark AlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (LIOAlertViewNextStepDismissLookIOWindow == alertView.tag)
    {
        [self dismissLookIOWindow];
    }
}

#pragma mark -
#pragma mark Container View Controller Delegate Methods

- (void)containerViewControllerDidDismiss:(LIOContainerViewController *)containerViewController
{
    [self dismissLookIOWindow];
}

#pragma mark Engagement Interaction Methods

- (void)presentLookIOWindow
{
    self.lookIOWindowState = LIOLookIOWindowStatePresenting;
    
    for (UIWindow *window in [[UIApplication sharedApplication] windows])
        [window endEditing:YES];
 
    self.previousKeyWindow = [[UIApplication sharedApplication] keyWindow];
    self.mainWindow = self.previousKeyWindow;
    
    [self.lookioWindow makeKeyAndVisible];

    if (!self.visit.controlButtonHidden)
    {
        [self.controlButton hide:YES];
    }
    
    [self takeScreenshotAndSetBlurImageView];
    
    self.lookIOWindowState = LIOLookIOWindowStateVisible;
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
    
    switch (self.visit.visitState) {
        case LIOVisitStateChatOpened:
            self.visit.visitState = LIOVisitStateVisitInProgress;
            [self.engagement cancelEngagement];
            break;
            
        default:
            break;
    }
    
    self.lookIOWindowState = LIOLookIOWindowStateHidden;
}

- (void)takeScreenshotAndSetBlurImageView {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Previous window is %@", self.previousKeyWindow);
        UIGraphicsBeginImageContext(self.previousKeyWindow.bounds.size);
        [self.previousKeyWindow.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [self.containerViewController setBlurImage:viewImage];
    });
}

- (void)beginChat
{
    [self presentLookIOWindow];
    
    switch (self.visit.visitState) {
        case LIOVisitStateVisitInProgress:
            self.engagement = [[LIOEngagement alloc] initWithVisit:self.visit];
            self.engagement.delegate = self;
            self.visit.visitState = LIOVisitStateChatRequested;
            [self.engagement startEngagement];
            break;
            
        case LIOVisitStateChatStarted:
            [self.containerViewController presentChatForEngagement:self.engagement];
            break;
            
        case LIOVisitStateChatActive:
            [self.containerViewController presentChatForEngagement:self.engagement];
            break;
            
        default:
            break;
    }
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
            [self.containerViewController presentChatForEngagement:self.engagement];
            
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
        }
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


- (void)engagementDidReceiveOfflineSurvey:(LIOEngagement *)engagement
{
    
}


- (void)engagementDidEnd:(LIOEngagement *)engagement
{
    self.engagement = nil;
    self.visit.visitState = LIOVisitStateVisitInProgress;
    if (LIOLookIOWindowStateVisible == self.lookIOWindowState)
        [self dismissLookIOWindow];
}

- (void)engagementDidCancel:(LIOEngagement *)engagement
{
    self.engagement = nil;
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
            [self beginChat];
        }
    }
    
    if (LIOVisitStateAppBackgrounded == self.visit.visitState)
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

#pragma mark Custom Branding Methods

- (BOOL)customBrandingAvailable
{
    return [(NSObject *)self.delegate respondsToSelector:@selector(lookIOManager:brandingImageForDimensions:)];
}

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

@end
