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

#import "LIOContainerViewController.h"

#import "LIOVisit.h"
#import "LIOChat.h"

#import "LIODraggableButton.h"

@interface LIOManager () <LIOVisitDelegate, LIODraggableButtonDelegate, LIOContainerViewControllerDelegate>

@property (nonatomic, strong) UIWindow *lookioWindow;
@property (nonatomic, assign) UIWindow *previousKeyWindow;
@property (nonatomic, strong) LIOContainerViewController *containerViewController;

@property (nonatomic, strong) LIOVisit *visit;
@property (nonatomic, strong) LIOChat *chat;

@property (nonatomic, strong) LIODraggableButton *controlButton;
@property (nonatomic, assign) BOOL isRotationActuallyHappening;

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
    
    self.containerViewController = [[LIOContainerViewController alloc] init];
    self.containerViewController.delegate = self;
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
}

- (void)applicationDidChangeStatusBarOrientation:(NSNotification *)aNotification
{
    // After rotation, we should reset the control button frame

    double delayInSeconds = 0.2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.controlButton resetFrame];
        
        // If control button is visibler, let's reveal the control button after the rotation
        
        if (!self.visit.controlButtonHidden)
        {
            self.controlButton.hidden = NO;
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

#pragma mark Container View Controller Delegate Methods

- (void)containerViewControllerDidDismiss:(LIOContainerViewController *)containerViewController
{
    [self dismissLookIOWindow];
}

#pragma mark Chat Interaction Methods

- (void)presentLookIOWindow
{
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
}

- (void)dismissLookIOWindow
{
    self.lookioWindow.hidden = YES;
    [self.previousKeyWindow makeKeyAndVisible];
    self.previousKeyWindow = nil;
    
    if (!self.visit.controlButtonHidden)
    {
        [self.controlButton show:YES];
    }
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
}

@end
