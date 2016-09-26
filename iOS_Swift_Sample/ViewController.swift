//
//  ViewController.swift
//  iOS_Swift_Sample
//
//  Created by Omer Berger on 6/17/16.
//  Copyright © 2016 Omer Berger. All rights reserved.
//

import UIKit

// MARK: - Lifecycle:

class ViewController: UIViewController ,LIOLookIOManagerDelegate{
    var customChatButton : UIButton = UIButton()
    let authenticatedUserId:NSString = "23"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        }
    

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        
         LIOLookIOManager.sharedLookIOManager().performSetupWithDelegate(nil)
        LIOLookIOManager.sharedLookIOManager().delegate = self
        
        //[[LIOLookIOManager sharedLookIOManager] reportEvent:kLPEventPageView withData:@"page_detail_abc"];
        
        // To report a sign up event:
        // [[LIOLookIOManager sharedLookIOManager] reportEvent:kLPEventSignUp];
        
        // To report an item that was added to the cart:
        //[[LIOLookIOManager sharedLookIOManager] reportEvent:kLPEventAddedToCart withData:@"product_name"];
        
        
        //        LIOLookIOManager.sharedLookIOManager().reportEvent("SomeEvent")
        //        LIOLookIOManager.sharedLookIOManager().reportEvent("SomeEvent",
        //        withData: ["SomeDataKey_1":"SomeDataValue_1", "SomeDataKey_2":"SomeDataValue_2"])
        }
    
    // MARK: - Lookio Delegate
    
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
 
        let alertController = UIAlertController(title: "Thanks!", message: "Thanks for chatting with us!", preferredStyle: UIAlertControllerStyle.Alert)

        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))

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
        
        return UInt32(kLPCollaborationComponentPhoto)
    }
    
    func lookIOManagerShouldUseCustomActionForChatNotAnswered(aManager: LIOLookIOManager!) -> Bool {
        
        print("Submit a flag if LIOShouldUseCustomActionForChatNotAnswered")
        return false
    }
    
    func lookIOManagerCustomActionForChatNotAnswered(aManager: LIOLookIOManager!) -> Void {
    
        let alert = UIAlertController(title: "No agents are available", message: "No agents are available. Please try again later.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))

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
//        
//        let ssoURLString : NSString = "https://www.example.com/ssoKeyGen?userId="+(self.authenticatedUserId as String);
//        
//        return NSURL(string: ssoURLString as String)
        

       // print("Submit a URL for LIOSingleSignOnKeyGenURL")
       // let ssoURLString : NSString =
        
        //NSString *ssoURLString = [NSString stringWithFormat:@"https://www.example.com/ssoKeyGen?userId=%@", self.authenticatedUserId];
        //return [NSURL URLWithString:ssoURLString];

        
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
