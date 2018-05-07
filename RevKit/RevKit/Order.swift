//
//  Order.swift
//  RevKit
//
//  Created by Ben Scheirman on 5/3/18.
//  Copyright © 2018 Fickle Bits, LLC. All rights reserved.
//

import Foundation

public struct Order : Decodable {
    public let orderNumber: String
    public let clientRef: String?
    public let price: Decimal
    public let status: String
    public let priority: String
    
    private enum CodingKeys : String, CodingKey {
        case orderNumber
        case clientRef
        case price
        case status
        case priority
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        orderNumber = try container.decode(String.self, forKey: .orderNumber)
        clientRef = try container.decodeIfPresent(String.self, forKey: .clientRef)
        price = try container.decode(Decimal.self, forKey: .price)
        status = try container.decode(String.self, forKey: .status)
        priority = try container.decode(String.self, forKey: .priority)
    }
}
