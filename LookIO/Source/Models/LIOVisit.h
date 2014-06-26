//
//  LIOVisit.h
//  LookIO
//
//  Created by Yaron Karasik on 12/5/13.
//
//

#import <Foundation/Foundation.h>

// Models
#import "LIOAccountSkillStatus.h"

typedef enum
{
    LIOFunnelStateInitialized = 0,
    LIOFunnelStateVisit = 1,
    LIOFunnelStateHotlead = 2,
    LIOFunnelStateInvitation = 3,
    LIOFunnelStateClicked = 4,
} LIOFunnelState;

typedef enum
{
    LIOButtonVisibilityNever = 0,
    LIOButtonVisibilityAlways = 1,
    LIOButtonVisibilityInSession = 2
} LIOButtonVisibility;

typedef enum
{
    LIOVisitStateInitialized = 0,
    LIOVisitStateFailed,
    LIOVisitStateQueued,
    LIOVisitStateLaunching,
    LIOVisitStateVisitInProgress,
    LIOVisitStateChatRequested,
    LIOVisitStateChatOpened,
    LIOVisitStatePreChatSurvey,
    LIOVisitStateChatStarted,
    LIOVisitStateOfflineSurvey,
    LIOVisitStateChatActive,
    LIOVisitStatePostChatSurvey,
    LIOVisitStateEnding
} LIOVisitState;

@class LIOVisit;

@protocol LIOVisitDelegate <NSObject>

- (void)visitSkillMappingDidChange:(LIOVisit *)visit;
- (void)visit:(LIOVisit *)visit controlButtonIsHiddenDidUpdate:(BOOL)isHidden notifyDelegate:(BOOL)notifyDelegate;
- (void)controlButtonCharacteristsDidChange:(LIOVisit *)visit;
- (void)visitChatEnabledDidUpdate:(LIOVisit *)visit;
- (void)visitWillRelaunch:(LIOVisit *)visit;
- (void)visitReachabilityDidChange:(LIOVisit *)visit;
- (void)visit:(LIOVisit *)visit wantsToShowMessage:(NSString *)message;
- (void)visitDidLaunch:(LIOVisit *)visit;
- (void)visitReportDidLaunch:(LIOVisit *)visit;
- (int)visit:(LIOVisit *)visit engagementFunnelStateForFunnelState:(LIOFunnelState)funnelState;
- (void)visitHasIncomingCall:(LIOVisit *)visit;
- (void)visit:(LIOVisit *)visit didChangeEnabled:(BOOL)enabled forSkill:(NSString *)skill forAccount:(NSString *)account;
- (void)visit:(LIOVisit *)visit didChangeFunnelState:(LIOFunnelState)funnelState;
- (NSString *)visitCurrentEngagementAccount:(LIOVisit *)visit;
- (NSString *)visitCurrentEngagementSkill:(LIOVisit *)visit;
- (BOOL)doesCurrentEngagementExist:(LIOVisit *)visit;

@end

@interface LIOVisit : NSObject

@property (nonatomic, assign) id <LIOVisitDelegate> delegate;

@property (nonatomic, assign) LIOVisitState visitState;
@property (nonatomic, assign) BOOL controlButtonHidden;

@property (nonatomic, assign) BOOL developerDisabledChat;

@property (nonatomic, strong) NSNumber *lastKnownButtonVisibility;
@property (nonatomic, strong) NSNumber *lastKnownButtonType;
@property (nonatomic, assign) BOOL lastKnownButtonPopupChat;

@property (nonatomic, copy) NSString *lastKnownButtonTintColor;
@property (nonatomic, copy) NSString *lastKnownButtonTextColor;
@property (nonatomic, copy) NSString *lastKnownButtonText;

@property (nonatomic, strong) LIOAccountSkillStatus *requiredAccountSkill;
@property (nonatomic, strong) LIOAccountSkillStatus *defaultAccountSkill;

- (void)disableControlButton;
- (void)undisableControlButton;

- (void)disableSurveys;
- (void)undisableSurveys;
- (BOOL)surveysDisabled;

- (void)useIconButton;
- (void)useTextButton;
- (void)useDefaultButton;

- (void)refreshControlButtonVisibility;
- (void)updateEnabledForAllAccountsAndSkills;
- (void)updateAndReportFunnelState;

- (BOOL)chatEnabled;
- (BOOL)chatInProgress;
- (BOOL)isChatEnabledForSkill:(NSString *)skill;
- (BOOL)isChatEnabledForSkill:(NSString *)skill forAccount:(NSString *)account;
- (BOOL)hideEmailChat;
- (BOOL)maskCreditCards;

- (void)launchVisit;
- (void)relaunchVisit;
- (void)stopVisit;
- (void)sendContinuationReport;
- (void)sendContinuationReportAndResendAllUDEs;

- (void)setSkill:(NSString *)skill;
- (void)setSkill:(NSString *)skill withAccount:(NSString *)account;

- (void)setChatAvailable;
- (void)setChatUnavailable;
- (void)setInvitationShown;
- (void)setInvitationNotShown;

- (NSDictionary *)introDictionary;
- (NSString *)welcomeText;

// UDEs & Events
- (void)setUDE:(id)anObject forKey:(NSString *)aKey;
- (id)UDEForKey:(NSString *)aKey;
- (void)clearUDEs;
- (void)addUDEs:(NSDictionary *)aDictionary;
- (void)reportEvent:(NSString *)anEvent withData:(id<NSObject>)someData;

// Logging
- (void)stopLogUploading;

@end
