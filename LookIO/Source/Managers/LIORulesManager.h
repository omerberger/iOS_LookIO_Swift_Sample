//
//  LIORulesManager.h
//  LookIO
//
//  Created by Joseph Toscano on 5/30/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define LIORulesManagerTimedRuleDidFireNotification             @"LIORulesManagerTimedRuleDidFireNotification"
#define LIORulesManagerAppInForegroundRuleDidFireNotification   @"LIORulesManagerAppInForegroundRuleDidFireNotification"

#define LIORulesManagerRuleKey  @"LIORulesManagerRuleKey"

@class LIORulesManager, LIOTimerProxy, AsyncSocket_LIO;

@protocol LIORuleViewVisibleDelegate;

@interface LIORulesManager : NSObject <LIORuleViewVisibleDelegate>
{
    NSTimeInterval appInForegroundTimeInterval;
    LIOTimerProxy *appInForegroundTimer;
    NSMutableSet *rules;
}

+ (LIORulesManager *)sharedRulesManager;
- (void)clearAllRules;
- (void)parseNewRuleset:(NSDictionary *)aRuleset;
- (void)handleLocationChange:(NSString *)aLocationString;

@end