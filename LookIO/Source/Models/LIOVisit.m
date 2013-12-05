//
//  LIOVisit.m
//  LookIO
//
//  Created by Yaron Karasik on 12/5/13.
//
//

#import "LIOVisit.h"
#import "LIOLogManager.h"

@implementation LIOVisit

- (id)init {
    self = [super init];
    if (self) {
        self.funnelState = LIOFunnelStateInitialized;
        LIOLog(@"<FUNNEL STATE> Initialized");
        
        self.customButtonChatAvailable = NO;
        self.customButtonInvitationShown = NO;

    }
    return self;
}

- (void)startVisit
{
    
}


@end
