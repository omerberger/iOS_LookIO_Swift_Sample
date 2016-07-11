//
//  KIFTestScenario+Chat.m
//  LookIO Sample
//
//  Created by Joseph Toscano on 2/21/12.
//  Copyright (c) 2012 Look.IO. All rights reserved.
//

#import "KIFTestScenario+LIOChatNoAgents.h"
#import "KIFTestStep.h"

@implementation KIFTestScenario (LIOChatNoAgents)

+ (id)scenarioToChatWithNoAgentsPresent
{
    KIFTestScenario *aScenario = [KIFTestScenario scenarioWithDescription:@"Test that a user can chat and then leave a message."];
    
    [aScenario addStep:[KIFTestStep stepToWaitForTimeInterval:2.0 description:@"Give the app a few seconds to start up"]];
    
    // main UI is up
    [aScenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"TestField"]];
    
    // tab is up, tap it
    [aScenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"LIOTab"]];
    [aScenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"LIOTab"]];
    
    // chat UI is up, send test message
    [aScenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"LIOInputField"]];
    [aScenario addStep:[KIFTestStep stepToEnterText:@"KIF TEST KIF TEST" intoViewWithAccessibilityLabel:@"LIOInputField"]];
    [aScenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"LIOSendButton"]];
    
    // leave message UI is up, send message
    [aScenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"LIOLeaveMessageEmailField"]];
    [aScenario addStep:[KIFTestStep stepToEnterText:@"testguy@testytest.test" intoViewWithAccessibilityLabel:@"LIOLeaveMessageEmailField"]];
    [aScenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"LIOLeaveMessageSendButton"]];
    
    // see if we're back at the sample app main UI
    [aScenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"TestField"]];
    
    return aScenario;
}

@end