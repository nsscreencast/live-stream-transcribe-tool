//
//  OrderTableRow.swift
//  TranscribeTool
//
//  Created by Ben Scheirman on 5/18/18.
//  Copyright © 2018 NSScreencast. All rights reserved.
//

import Foundation
import RevKit

@objcMembers class OrderTableRow: NSObject {
    
    var orderNumber: String
    var clientRef: String
    var price: Double
    var status: String
    var priority: String
    
    init(order: Order) {
        self.orderNumber = order.orderNumber
        self.clientRef = order.clientRef ?? ""
        self.price = Double(truncating: order.price as NSNumber)
        self.status = order.status
        self.priority = order.priority
    }
    
}
