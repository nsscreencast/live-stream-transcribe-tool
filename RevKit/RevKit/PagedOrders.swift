//
//  PagedResponse.swift
//  RevKit
//
//  Created by Ben Scheirman on 5/3/18.
//  Copyright © 2018 Fickle Bits, LLC. All rights reserved.
//

import Foundation

public struct PagedOrders : Decodable {
    public let totalCount: Int
    public let resultsPerPage: Int
    public let page: Int
    public let orders: [Order]
}
