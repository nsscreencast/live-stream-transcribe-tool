//
//  AppDelegate.swift
//  TranscribeTool
//
//  Created by Ben Scheirman on 5/4/18.
//  Copyright © 2018 NSScreencast. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {


    func applicationDidFinishLaunching(_ aNotification: Notification) {

        UserDefaults.standard.register(defaults: [
            "environment": "Sandbox"
        ])
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

