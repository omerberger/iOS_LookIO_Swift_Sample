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
    LIOFunnelStateVisit,
    LIOFunnelStateHotlead,
    LIOFunnelStateInvitation,
    LIOFunnelStateClicked
} LIOFunnelState;

typedef enum
{
    LIOButtonVisibilityNever = 0,
    LIOButtonVisibilityAlways = 1,
    LIOButtonVisibilityInSession = 3
} LIOButtonVisibility;

typedef enum
{
    LIOVisitStateInitialized = 0,
    LIOVisitStateFailed,
    LIOVisitStateQueued,
    LIOVisitStateLaunching,
    LIOVisitStateVisitInProgress,
    LIOVisitStateAppBackgrounded,
    LIOVisitStateChatRequested,
    LIOVisitStateChatOpened,
    LIOVisitStatePreChatSurvey,
    LIOVisitStatePreChatSurveyBackgrounded,
    LIOVisitStateChatStarted,
    LIOVisitStateOfflineSurvey,
    LIOVisitStateChatActive,
    LIOVisitStateChatActiveBackgrounded,
    LIOVisitStatePostChatSurvey
} LIOVisitState;

@class LIOVisit;

@protocol LIOVisitDelegate <NSObject>

- (void)visitSkillMappingDidChange:(LIOVisit *)visit;
- (void)visit:(LIOVisit *)visit controlButtonIsHiddenDidUpdate:(BOOL)isHidden;
- (void)controlButtonCharacteristsDidChange:(LIOVisit *)visit;
- (void)chatEnabledDidUpdate:(LIOVisit *)visit;

@end

@interface LIOVisit : NSObject

@property (nonatomic, assign) id <LIOVisitDelegate> delegate;

@property (nonatomic, assign) LIOVisitState visitState;
@property (nonatomic, assign) BOOL controlButtonHidden;

@property (nonatomic, copy) NSString *lastKnownButtonTintColor;
@property (nonatomic, copy) NSString *lastKnownButtonTextColor;

- (void)refreshControlButtonVisibility;

- (BOOL)chatEnabled;
- (BOOL)chatInProgress;
- (BOOL)surveysEnabled;
- (BOOL)hideEmailChat;

- (void)launchVisit;
- (void)sendContinuationReport;

- (void)setChatAvailable;
- (void)setChatUnavailable;
- (void)setInvitationShown;
- (void)setInvitationNotShown;

- (NSDictionary *)introDictionary;
- (NSString *)welcomeText;

@end
