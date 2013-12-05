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
    LIOFunnelStateClicked,
} LIOFunnelState;

@interface LIOVisit : NSObject

@property (nonatomic, assign) LIOFunnelState funnelState;

@property (nonatomic, assign) BOOL customButtonChatAvailable;
@property (nonatomic, assign) BOOL customButtonInvitationShown;

- (void)startVisit;
- (void)updateAndReportFunnelState;

@end
