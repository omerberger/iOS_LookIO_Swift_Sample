//
//  LIOVisit.h
//  LookIO
//
//  Created by Yaron Karasik on 12/5/13.
//
//

#import <Foundation/Foundation.h>

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
- (int)visit:(LIOVisit *)visit engagementFunnelStateForFunnelState:(LIOFunnelState)funnelState;

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

- (void)disableControlButton;
- (void)undisableControlButton;
- (void)disableSurveys;
- (void)undisableSurveys;
- (void)useIconButton;
- (void)useTextButton;
- (void)useDefaultButton;

- (void)refreshControlButtonVisibility;

- (void)updateAndReportFunnelState;

- (BOOL)chatEnabled;
- (BOOL)chatInProgress;
- (BOOL)surveysEnabled;
- (BOOL)hideEmailChat;

- (void)launchVisit;
- (void)relaunchVisit;
- (void)stopVisit;
- (void)sendContinuationReport;

- (void)setSkill:(NSString *)skill;

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

@end
