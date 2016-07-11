//
//  KIFTestScenario+Chat.m
//  LookIO Sample
//
//  Created by Joseph Toscano on 2/21/12.
//  Copyright (c) 2012 Look.IO. All rights reserved.
//

#import "KIFTestScenario+LIOChat.h"
#import "KIFTestStep.h"

@implementation KIFTestScenario (LIOChat)

+ (id)scenarioToChat
{
    KIFTestScenario *aScenario = [KIFTestScenario scenarioWithDescription:@"Test that a user can chat with agents present."];
    
    // main UI is up
    [aScenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"TestField"]];
    
    // tab is up, tap it
    [aScenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"LIOTab"]];
    [aScenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"LIOTab"]];
    
    // chat UI is up, send test message
    [aScenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"LIOInputField"]];
    [aScenario addStep:[KIFTestStep stepToEnterText:@"KIF TEST KIF TEST" intoViewWithAccessibilityLabel:@"LIOInputField"]];
    [aScenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"LIOSendButton"]];
    
    // wait a little bit
    [aScenario addStep:[KIFTestStep stepToWaitForTimeInterval:7.0 description:@"Pause for agent response #1"]];
    
    // send another message
    [aScenario addStep:[KIFTestStep stepToEnterText:@"KIF TEST KIF TEST" intoViewWithAccessibilityLabel:@"LIOInputField"]];
    [aScenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"LIOSendButton"]];
    
    // wait a little bit
    [aScenario addStep:[KIFTestStep stepToWaitForTimeInterval:7.0 description:@"Pause for agent response #2"]];
    
    // send another message
    [aScenario addStep:[KIFTestStep stepToEnterText:@"KIF TEST KIF TEST" intoViewWithAccessibilityLabel:@"LIOInputField"]];
    [aScenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"LIOSendButton"]];
    
    // end the session
    [aScenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"LIOSettingsButton"]];
    [aScenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"LIOSettingsActionSheet"]];
    
    return aScenario;
}

@end