//
//  OrderParams.swift
//  RevKit
//
//  Created by Ben Scheirman on 5/2/18.
//  Copyright © 2018 Fickle Bits, LLC. All rights reserved.
//

import Foundation

public protocol OrderParams : Encodable {
    var clientRef: String? { get set }
    var verbatim: Bool { get set }
    var timestamps: Bool { get set }
}

public struct Input : Encodable {
    let uri: String
    
    public init(uri: String) {
        self.uri = uri
    }
}

public struct CaptionOrderParams : OrderParams {
    public var clientRef: String? = nil
    public var verbatim: Bool = false
    public var timestamps: Bool = true
    public var captionOptions: CaptionOptions
    
    public init(captionOptions: CaptionOptions) {
        self.captionOptions = captionOptions
    }
    
    public struct CaptionOptions: Encodable {
        public let inputs: [Input]
        public var outputFileFormats: [String]
        
        public init(inputs: [Input], outputFileFormats: [String]) {
            self.inputs = inputs
            self.outputFileFormats = outputFileFormats
        }
    }
}

