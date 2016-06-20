//
//  ViewController.swift
//  iOS_Swift_Sample
//
//  Created by Omer Berger on 6/17/16.
//  Copyright © 2016 Omer Berger. All rights reserved.
//

import UIKit

class ViewController: UIViewController ,LIOLookIOManagerDelegate{

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

// MARK: - Lookio Delegate
 
    func lookIOManager(aManager: LIOLookIOManager!, onEvent eventName: String!, withParameters parameters: [NSObject : AnyObject]!) {
        
    }

    func lookIOManager(aManager: LIOLookIOManager!, didUpdateEnabledStatus lookioIsEnabled: Bool) {
        
        
    }
    
    func lookioManager(manager: LIOLookIOManager!, didChangeEnabled enabled: Bool, forSkill skill: String!, forAccount account: String!) {
        
        
    }
    
    func lookIOManagerDidHideControlButton(aManager: LIOLookIOManager!) {
        
        
    }
    
    func lookIOManagerDidShowControlButton(aManager: LIOLookIOManager!) {
        
        
    }
    
    func lookIOManagerDidShowChat(aManager: LIOLookIOManager!) {
        
        
    }
    
    func  lookIOManagerDidHideChat(aManager: LIOLookIOManager!) {
        
        
    }
    
    func lookIOManagerDidEndChat(aManager: LIOLookIOManager!) {
        
        
    }
    
    func lookIOManager(aManager: LIOLookIOManager!, didSendNotification notification: String!, withUnreadMessagesCount count: Int) {
        
        
    }
    
    func lookIOManager(aManager: LIOLookIOManager!, linkViewForURL aURL: NSURL!) -> AnyObject! {
        
        return nil;
        
    }
    
    func lookIOManagerEnabledCollaborationComponents(aManager: LIOLookIOManager!) -> UInt32 {
        
        return 0
    }
    
    func lookIOManagerShouldUseCustomActionForChatNotAnswered(aManager: LIOLookIOManager!) -> Bool {
        
        return false
    }
    
    func lookIOManagerCustomActionForChatNotAnswered(aManager: LIOLookIOManager!) {
        
        
    }
    
    func lookIOManagerShouldCacheChatMessagesForReconnect(aManager: LIOLookIOManager!) -> Bool {
        
        return true
        
    }
    
    func lookIOManagerShouldReportCallDeflection(aManager: LIOLookIOManager!) -> Bool {
        
        return true
        
    }
    
    func lookIOManagerSingleSignOnEnabled(aManager: LIOLookIOManager!) -> Bool {
        
        return false
        
    }
    
    func lookIOManagerSingleSignOnKeyGenURL(aManager: LIOLookIOManager!) -> NSURL! {
        
        return nil
    }
    
    func lookIOManagerMainWindowForHostApp(aManager: LIOLookIOManager!) -> UIWindow! {
        
        return nil
    }
    
    func lookIOManager(aManager: LIOLookIOManager!, shouldRotateToInterfaceOrientation anOrientation: UIInterfaceOrientation) -> Bool {
        
        return true
        
    }
    
    func lookIOManagerShouldAutorotate(aManager: LIOLookIOManager!) -> Bool {
        return true
        
    }
    
    func lookIOManagerSupportedInterfaceOrientations(aManager: LIOLookIOManager!) -> Int {
        
        return 0
    }
    
    func supportDeprecatedXcodeVersions() -> Bool {
        
        return false
    }



}

