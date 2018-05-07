//
//  RevCredentials.swift
//  TranscribeTool
//
//  Created by Ben Scheirman on 5/4/18.
//  Copyright © 2018 NSScreencast. All rights reserved.
//

import Foundation

struct RevCredentials {
    let userKey: String
    let clientKey: String
    
    static var current: RevCredentials? {
        let defaults = UserDefaults.standard
        guard
            let userKey = defaults.string(forKey: "sandboxUserKey"),
            !userKey.isEmpty,
            let clientKey = defaults.string(forKey: "sandboxClientKey"),
            !clientKey.isEmpty
            else {
                return nil
        }
        return RevCredentials(userKey: userKey, clientKey: clientKey)
    }
}

