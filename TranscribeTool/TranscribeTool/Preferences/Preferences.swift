//
//  Preferences.swift
//  TranscribeTool
//
//  Created by Ben Scheirman on 5/7/18.
//  Copyright © 2018 NSScreencast. All rights reserved.
//

import Foundation
import SAMKeychain
import RevKit

@objcMembers
class Preferences : NSObject {
    static var current = Preferences()
    
    static var didChangeNotification: Notification.Name {
        return Notification.Name("PreferencesDidChangeNotification")
    }
    
    private struct Keys {
        static var sandboxRevService = "sandbox.rev.com"
        static var productionRevService = "production.rev.com"
        static var userKey = "userKey"
        static var clientKey = "clientKey"
        static var environmentKey = "environment"
    }

    @objc dynamic var environment: String {
        get {
            return defaults.string(forKey: Keys.environmentKey) ?? "Sandbox"
        }
        set {
            defaults.set(newValue, forKey: Keys.environmentKey)
            notifyChanged()
        }
    }
    
    @objc dynamic var sandboxUserKey: String? {
        get {
            return SAMKeychain.password(forService: Keys.sandboxRevService, account: Keys.userKey)
        }
        set {
            if let val = newValue {
                SAMKeychain.setPassword(val, forService: Keys.sandboxRevService, account: Keys.userKey)
            } else {
                SAMKeychain.deletePassword(forService: Keys.sandboxRevService, account: Keys.userKey)
            }
            notifyChanged()
        }
    }
    
    @objc dynamic var sandboxClientKey: String? {
        get {
            return SAMKeychain.password(forService: Keys.sandboxRevService, account: Keys.clientKey)
        }
        set {
            if let val = newValue {
                SAMKeychain.setPassword(val, forService: Keys.sandboxRevService, account: Keys.clientKey)
            } else {
                SAMKeychain.deletePassword(forService: Keys.sandboxRevService, account: Keys.clientKey)
            }
            notifyChanged()
        }
    }
    
    @objc dynamic var productionUserKey: String? {
        get {
            return SAMKeychain.password(forService: Keys.productionRevService, account: Keys.userKey)
        }
        set {
            if let val = newValue {
                SAMKeychain.setPassword(val, forService: Keys.productionRevService, account: Keys.userKey)
            } else {
                SAMKeychain.deletePassword(forService: Keys.productionRevService, account: Keys.userKey)
            }
            notifyChanged()
        }
    }
    
    @objc dynamic var productionClientKey: String? {
        get {
            return SAMKeychain.password(forService: Keys.productionRevService, account: Keys.clientKey)
        }
        set {
            if let val = newValue {
                SAMKeychain.setPassword(val, forService: Keys.productionRevService, account: Keys.clientKey)
            } else {
                SAMKeychain.deletePassword(forService: Keys.sandboxRevService, account: Keys.clientKey)
            }
            notifyChanged()
        }
    }
    
    private func notifyChanged() {
        NotificationCenter.default.post(name: Preferences.didChangeNotification, object: self)
    }
    
    private var defaults: UserDefaults {
        return UserDefaults.standard
    }
}

