//
//  ViewController.swift
//  iOS_Swift_Sample
//
//  Created by Omer Berger on 6/17/16.
//  Copyright © 2016 Omer Berger. All rights reserved.
//

import UIKit


/*
 ***   LookIO properties and methodes:  ***
 
 let isChatEnabledForSkill : Bool  =   LIOLookIOManager.sharedLookIOManager().isChatEnabledForSkill("mobile")
 let isChatEnabledForSkillforAccount : Bool  =   LIOLookIOManager.sharedLookIOManager().isChatEnabledForSkill("mobile", forAccount: "P74505730")
 LIOLookIOManager.sharedLookIOManager().beginChat()
 LIOLookIOManager.sharedLookIOManager().beginChatWithSkill("mobile")
 LIOLookIOManager.sharedLookIOManager().beginChatWithSkill("mobile", withAccount: "P74505730")
 LIOLookIOManager.sharedLookIOManager().endChatAndShowAlert(true)
 LIOLookIOManager.sharedLookIOManager().setChatDisabled(false)
 LIOLookIOManager.sharedLookIOManager().setChatAvailable()
 LIOLookIOManager.sharedLookIOManager().setChatUnavailable()
 LIOLookIOManager.sharedLookIOManager().setInvitationShown()
 LIOLookIOManager.sharedLookIOManager().setInvitationNotShown()
 LIOLookIOManager.sharedLookIOManager().setSkill("cat")
 LIOLookIOManager.sharedLookIOManager().setSkill("cat", withAccount: "P74505730")
 LIOLookIOManager.sharedLookIOManager().reportEvent("SomeEvent")
 LIOLookIOManager.sharedLookIOManager().reportEvent("SomeEvent",
 withData: ["SomeDataKey_1":"SomeDataValue_1", "SomeDataKey_2":"SomeDataValue_2"])
 LIOLookIOManager.sharedLookIOManager().addCustomVariables(["CustomVariableKey_1":"CustomVariable_1", "CustomVariableKey_2":"CustomVariable_2"])
 LIOLookIOManager.sharedLookIOManager().setCustomVariable(["CustomVariableKey_1":"CustomVariable_1", "CustomVariableKey_2":"CustomVariable_2"],forKey: "SomeKey")
 LIOLookIOManager.sharedLookIOManager().customVariableForKey("SomeKey")
 */


// MARK: - Lifecycle:


private var ObserverClassContext = 0

class ViewController: UIViewController ,LIOLookIOManagerDelegate{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    
    // MARK: - Lookio Delegate
    
    func lookIOManager(aManager: LIOLookIOManager!, onEvent eventName: String!, withParameters parameters: [NSObject : AnyObject]!) -> Void {
        
        print("LIOEventName : " + eventName)
    }
    
    func lookIOManager(aManager: LIOLookIOManager!, didUpdateEnabledStatus lookioIsEnabled: Bool) -> Void {
        
        print("LIOIsEnabled :" + lookioIsEnabled.description)
        
    }
    
    func lookioManager(manager: LIOLookIOManager!, didChangeEnabled enabled: Bool, forSkill skill: String!, forAccount account: String!) -> Void {
        
        print("LIOEnabled : " + enabled.description + ", skil : " + skill)
    }
    
    func lookIOManagerDidHideControlButton(aManager: LIOLookIOManager!) -> Void {
        
        print("LIODidHideControlButton")
        
    }
    
    func lookIOManagerDidShowControlButton(aManager: LIOLookIOManager!) -> Void {
        
        print("LIODidShowControlButton")
        
    }
    
    func lookIOManagerDidShowChat(aManager: LIOLookIOManager!) -> Void {
        
        print("LIODidShowChat")
        
    }
    
    func  lookIOManagerDidHideChat(aManager: LIOLookIOManager!) -> Void {
        
        print("LIODidHideChat")
        
    }
    
    func lookIOManagerDidEndChat(aManager: LIOLookIOManager!) -> Void {
        
        print("LIODidEndChat")
        
    }
    
    func lookIOManager(aManager: LIOLookIOManager!, didSendNotification notification: String!, withUnreadMessagesCount count: Int) -> Void {
        
        print("LIOdidSendNotification : " + notification + "UnreadCount : " + count.description)
    }
    
    func lookIOManager(aManager: LIOLookIOManager!, linkViewForURL aURL: NSURL!) -> AnyObject! {
        
        print("Submit a URL for LIOlinkViewForURL")
        return nil;
        
    }
    
    func lookIOManagerEnabledCollaborationComponents(aManager: LIOLookIOManager!) -> UInt32 {
        
        print("Submit Number of LIOEnabledCollaborationComponents")
        return 0
    }
    
    func lookIOManagerShouldUseCustomActionForChatNotAnswered(aManager: LIOLookIOManager!) -> Bool {
        
        print("Submit a flag if LIOShouldUseCustomActionForChatNotAnswered")
        return false
    }
    
    func lookIOManagerCustomActionForChatNotAnswered(aManager: LIOLookIOManager!) -> Void {
        
        print("LIOChatNotAnswered")
    }
    
    func lookIOManagerShouldCacheChatMessagesForReconnect(aManager: LIOLookIOManager!) -> Bool {
        
        print("Submit a flag if LIOShouldCacheChatMessagesForReconnect")
        return true
        
    }
    
    func lookIOManagerShouldReportCallDeflection(aManager: LIOLookIOManager!) -> Bool {
        
        print("Submit a flag if LIOShouldShouldReportCallDeflection")
        return true
        
    }
    
    func lookIOManagerSingleSignOnEnabled(aManager: LIOLookIOManager!) -> Bool {
        
        print("Submit a flag for LIOSingleSignOnEnabled")
        return false
        
    }
    
    func lookIOManagerSingleSignOnKeyGenURL(aManager: LIOLookIOManager!) -> NSURL! {
        
        print("Submit a URL for LIOSingleSignOnKeyGenURL")
        return nil
    }
    
    func lookIOManagerMainWindowForHostApp(aManager: LIOLookIOManager!) -> UIWindow! {
        
        print("Submit an NSWindow for LIOHostApp")
        return nil
    }
    
    func lookIOManager(aManager: LIOLookIOManager!, shouldRotateToInterfaceOrientation anOrientation: UIInterfaceOrientation) -> Bool {
        
        print("Submit a flag if LIOshouldRotateToInterfaceOrientation" + "Orientation : " + anOrientation.rawValue.description)
        return true
        
    }
    
    func lookIOManagerShouldAutorotate(aManager: LIOLookIOManager!) -> Bool {
        
        print("Submit a flag if LIOShouldAutorotate")
        return true
        
    }
    
    func lookIOManagerSupportedInterfaceOrientations(aManager: LIOLookIOManager!) -> Int {
        
        print("Submit a number for LIOSupportedInterfaceOrientations")
        return 0
    }
    
    func supportDeprecatedXcodeVersions() -> Bool {
        
        print("Submit a flag if support LIODeprecatedXcodeVersions")
        return false
    }
    
}
