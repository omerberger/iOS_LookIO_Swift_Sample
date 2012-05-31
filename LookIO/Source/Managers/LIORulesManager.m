//
//  LIORulesManager.m
//  LookIO
//
//  Created by Joseph Toscano on 5/30/12.
//  Copyright (c) 2012 LookIO, Inc. All rights reserved.
//

#import "LIORulesManager.h"
#import "LIOTimerProxy.h"
#import "LIOLogManager.h"
#import "AsyncSocket.h"
#import "LIORuleViewVisible.h"

static LIORulesManager *sharedRulesManager = nil;

@implementation LIORulesManager

+ (LIORulesManager *)sharedRulesManager
{
    if (nil == sharedRulesManager)
        sharedRulesManager = [[LIORulesManager alloc] init];
    
    return sharedRulesManager;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        rules = [[NSMutableSet alloc] init];
        appInForegroundTimeInterval = -1;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillResignActive:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self clearAllRules];    
    [rules release];
    
    [super dealloc];
}

- (void)clearAllRules
{
    [rules removeAllObjects];
    
    appInForegroundTimeInterval = -1;
    [appInForegroundTimer stopTimer];
    [appInForegroundTimer release];
    appInForegroundTimer = nil;
}

/*
 "proactive_chat": {
     "static_triggers": [{"foreground_sec": "10"},
                         {"view_visible": {"view": "Cart",
                                           "duration_sec": "5"}}],
 "callback_socket": true} 
 */
- (void)parseNewRuleset:(NSDictionary *)aRuleset
{
    [self clearAllRules];
    
    NSArray *staticTriggers = [aRuleset objectForKey:@"static_triggers"];
    for (NSDictionary *aStaticTrigger in staticTriggers)
    {
        NSString *aRuleType = [[aStaticTrigger allKeys] objectAtIndex:0];
        
        if ([aRuleType isEqualToString:@"foreground_sec"])
        {
            NSNumber *foregroundSecs = [aStaticTrigger objectForKey:@"foreground_sec"];
            appInForegroundTimeInterval = [foregroundSecs floatValue];
            
            if (UIApplicationStateActive == [[UIApplication sharedApplication] applicationState])
            {
                appInForegroundTimer = [[LIOTimerProxy alloc] initWithTimeInterval:appInForegroundTimeInterval
                                                                            target:self
                                                                          selector:@selector(appInForegroundTimerDidFire)];
            }
        }
        else if ([aRuleType isEqualToString:@"view_visible"])
        {
            NSDictionary *params = [aStaticTrigger objectForKey:@"view_visible"];
            NSString *viewName = [params objectForKey:@"view"];
            NSNumber *durationNumber = [params objectForKey:@"duration_sec"];
            
            LIORuleViewVisible *newRule = [[[LIORuleViewVisible alloc] initWithLocationName:viewName duration:[durationNumber floatValue]] autorelease];
            [rules addObject:newRule];
        }
    }
}

- (void)appInForegroundTimerDidFire
{
    [appInForegroundTimer stopTimer];
    [appInForegroundTimer release];
    appInForegroundTimer = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:LIORulesManagerAppInForegroundRuleDidFireNotification object:self];
}

- (void)handleLocationChange:(NSString *)aLocationString
{
    // Check for rules that match this location string.
    for (id aRule in rules)
    {
        if ([aRule isMemberOfClass:[LIORuleViewVisible class]])
        {
            LIORuleViewVisible *ruleViewVisible = (LIORuleViewVisible *)aRule;
            if ([ruleViewVisible.locationName isEqualToString:aLocationString])
            {
                // Matched! Start the timer.
                // When the timer pops, we'll be notified via delegate method.
                [ruleViewVisible startTimer];
            }
            else
            {
                // For when the user switches AWAY from the target view.
                [ruleViewVisible stopTimer];
            }
        }
    }
}

#pragma mark -
#pragma mark Notification handlers

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
    if (appInForegroundTimeInterval && nil == appInForegroundTimer)
    {
        appInForegroundTimer = [[LIOTimerProxy alloc] initWithTimeInterval:appInForegroundTimeInterval
                                                                    target:self
                                                                  selector:@selector(appInForegroundTimerDidFire)];
    }
}

- (void)applicationWillResignActive:(NSNotification *)aNotification
{
    [appInForegroundTimer stopTimer];
    [appInForegroundTimer release];
    appInForegroundTimer = nil;
}

#pragma mark -
#pragma mark LIORuleViewVisibleDelegate methods

- (void)ruleViewVisibleTimerDidFire:(LIORuleViewVisible *)aRule
{
    [aRule stopTimer];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:aRule forKey:LIORulesManagerRuleKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:LIORulesManagerTimedRuleDidFireNotification
                                                        object:self
                                                      userInfo:userInfo];
}

@end