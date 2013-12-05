//
//  LIOManager.m
//  LookIO
//
//  Created by Yaron Karasik on 12/5/13.
//
//

#import "LIOManager.h"

#import "LIOLogManager.h"
#import "LIONetworkManager.h"

#import "LIOVisit.h"
#import "LIOChat.h"
#import "LIOAppStatus.h"

@interface LIOManager ()

@property (nonatomic, strong) UIWindow *lookioWindow;
@property (nonatomic, assign) BOOL initializationFailed;

@property (nonatomic, strong) LIOVisit *visit;
@property (nonatomic, strong) LIOChat *chat;
@property (nonatomic, strong) LIOAppStatus *appStatus;

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

    self.appStatus = [[LIOAppStatus alloc] init];
    self.appStatus.appForegrounded = YES;
    
    self.delegate = aDelegate;
    
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    self.initializationFailed = nil == keyWindow;
    
    self.lookioWindow = [[UIWindow alloc] initWithFrame:keyWindow.frame];
    self.lookioWindow.hidden = YES;
    self.lookioWindow.windowLevel = 0.1;
    
    self.visit = [[LIOVisit alloc] init];
    [self.visit startVisit];
    
    [[LIOLogManager sharedLogManager] logWithSeverity: LIOLogManagerSeverityInfo format:@"Loaded."];

}

#pragma mark Custom Button Methods

- (void)setChatAvailable
{
    self.visit.customButtonChatAvailable = YES;
    [self.visit updateAndReportFunnelState];
}

- (void)setChatUnavailable
{
    self.visit.customButtonChatAvailable = NO;
    [self.visit updateAndReportFunnelState];
}

- (void)setInvitationShown
{
    self.visit.customButtonInvitationShown = YES;
    [self.visit updateAndReportFunnelState];
}

- (void)setInvitationNotShown
{
    self.visit.customButtonInvitationShown = NO;
    [self.visit updateAndReportFunnelState];
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

#pragma mark Chat Interaction Methods

- (void)beginChat
{
    
}

@end
