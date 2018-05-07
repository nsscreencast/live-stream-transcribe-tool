//
//  OrderListWindowController.swift
//  TranscribeTool
//
//  Created by Ben Scheirman on 5/4/18.
//  Copyright © 2018 NSScreencast. All rights reserved.
//

import AppKit

class OrderListWindowController : NSWindowController {
    
    @IBOutlet weak var loadOrdersButton: NSButton!
    @IBOutlet weak var loadingIndicator: NSProgressIndicator!
    
    @objc dynamic var isLoading: Bool = false
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        setButtonVisibility()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userDefaultsChanged(_:)),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
    }
    
    @objc
    private func userDefaultsChanged(_ notification: NSNotification) {
        setButtonVisibility()
    }
    
    private func setButtonVisibility() {
        loadOrdersButton.isEnabled = RevCredentials.current != nil
    }
}
