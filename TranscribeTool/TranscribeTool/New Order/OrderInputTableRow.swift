//
//  OrderInputTableRow.swift
//  TranscribeTool
//
//  Created by Ben Scheirman on 5/18/18.
//  Copyright © 2018 NSScreencast. All rights reserved.
//

import Foundation

@objcMembers class OrderInputTableRow: NSObject {
    
    var urn: String
    var filename: String
    
    init(urn: String, filename: String) {
        self.urn = urn
        self.filename = filename
    }
    
}
