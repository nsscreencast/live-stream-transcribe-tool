//
//  OrderDetail.swift
//  RevKit
//
//  Created by Ben Scheirman on 5/8/18.
//  Copyright © 2018 NSScreencast. All rights reserved.
//

import Foundation

public struct OrderDetail : Decodable {
    public let orderNumber: String
    public let clientRef: String?
    public let price: Decimal
    public let status: String
    public let priority: String
    public let attachments: [Attachment]?
    public let comments: [Comment]?
}

public struct Link : Decodable {
    public let rel: String
    public let href: String
    public let contentType: String?
}

public struct Attachment : Decodable {
    public let kind: String
    public let name: String
    public let id: String
    public let links: [Link]
}

public struct Comment : Decodable {
    public let timestamp: Date
    public let by: String?
    public let text: String?
}
