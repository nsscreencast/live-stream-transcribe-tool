//
//  RevCredentials.swift
//  TranscribeTool
//
//  Created by Ben Scheirman on 5/4/18.
//  Copyright © 2018 NSScreencast. All rights reserved.
//

import Foundation
import RevKit

struct RevCredentials {
    let userKey: String
    let clientKey: String
    let environment: RevEnvironment
    
    static var current: RevCredentials? {
        let prefs = Preferences.current
        
        var savedUserKey: String?
        var savedClientKey: String?
        var env: RevEnvironment?
        
        switch prefs.environment {
            
        case "Sandbox":
            savedUserKey = prefs.sandboxUserKey
            savedClientKey = prefs.sandboxClientKey
            env = .sandbox
            
        case "Production":
            savedUserKey = prefs.productionUserKey
            savedClientKey = prefs.productionClientKey
            env = .production
            
        default: fatalError()
            
        }
        
        guard
            let userKey = savedUserKey,
            let clientKey = savedClientKey,
            let environment = env
            else {
                return nil
        }
        
        return RevCredentials(userKey: userKey, clientKey: clientKey, environment: environment)
    }
}

extension RevClient {
    convenience init(credentials: RevCredentials) {
        self.init(clientKey: credentials.clientKey,
                  userKey: credentials.userKey,
                  environment: credentials.environment)
    }
}

