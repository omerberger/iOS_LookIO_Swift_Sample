//
//  TestController.m
//  LookIO Sample
//
//  Created by Joseph Toscano on 2/21/12.
//  Copyright (c) 2012 Look.IO. All rights reserved.
//

#import "LIOTestController.h"
#import "KIFTestScenario+LIOChatNoAgents.h"

@implementation LIOTestController

- (void)initializeScenarios
{
    [self addScenario:[KIFTestScenario scenarioToChatWithNoAgentsPresent]];
    //[self addScenario:[KIFTestScenario scenarioToChat]];
}

@end