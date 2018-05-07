//
//  RevClient.swift
//  RevKit
//
//  Created by Ben Scheirman on 4/26/18.
//  Copyright © 2018 Fickle Bits, LLC. All rights reserved.
//

import Foundation

let RevKitErrorDomain = "RevKitErrorDomain"
struct RevKitErrorCodes {
    static let requestFailed = 1000
    static let unexpectedBehavior = 1001
}

public enum RevEnvironment : String {
    case sandbox
    case production
    
    var baseURL: URL {
        switch self {
        case .sandbox:
            return URL(string: "https://api-sandbox.rev.com/api/v1")!
        case .production:
            return URL(string: "https://www.rev.com/api/v1")!
        }
    }
}

public class RevClient {
    
    public enum Result<T> {
        case success(T)
        case failed(Error)
    }
    
    private let clientKey: String
    private let userKey: String
    private let environment: RevEnvironment
    
    private let sessionConfiguration = URLSessionConfiguration.default
    private lazy var session: URLSession = { [sessionConfiguration] in
       return URLSession(configuration: sessionConfiguration)
    }()
    
    public init(clientKey: String, userKey: String, environment: RevEnvironment) {
        self.clientKey = clientKey
        self.userKey = userKey
        self.environment = environment
    }
    
    public func uploadInput(from remoteURL: URL, filename: String? = nil, contentType: String, completion: @escaping (Result<String>) -> Void) {
        let url = environment.baseURL.appendingPathComponent("inputs")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addAuthorizationHeader(&request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let uploadedFilename = filename ?? remoteURL.lastPathComponent
        let body: [String: String] = [
            "filename": uploadedFilename,
            "content_type": contentType,
            "url": remoteURL.absoluteString
        ]
        let data = try! JSONSerialization.data(withJSONObject: body, options: [])
        request.httpBody = data
//        
//        print("Request info")
//        print("-------------------------------------------------------")
//        print("URL: \(request.url!.absoluteString)")
//        print("Method: \(request.httpMethod!)")
//        print("Request headers: \(request.allHTTPHeaderFields!)")
//        print("Body: \(String(data: data, encoding: .utf8)!)")
//        print(remoteURL.absoluteString)
//        print("-------------------------------------------------------")
//        
        let task = session.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print("ERROR: \(error!)")
                self.dispatchResult(result: .failed(error!), completion: completion)
                return
            }
            let http = response as! HTTPURLResponse
            switch http.statusCode {
            case 201:
                if let location = http.allHeaderFields["Location"] as? String {
                    self.dispatchResult(result: .success(location), completion: completion)
                } else {
                    assertionFailure("Location response header was not found")
                    let error = NSError(domain: RevKitErrorDomain, code: RevKitErrorCodes.unexpectedBehavior, userInfo: [
                        NSLocalizedFailureReasonErrorKey: "The server indicated success, but did not include the expected response.",
                        "Response": http,
                        "Body": data.flatMap { String(data: $0, encoding: .utf8) } ?? "<?>"
                        ])
                    self.dispatchResult(result: .failed(error), completion: completion)
                }
            default:
                print("Received HTTP \(http.statusCode)")
                let error = NSError(domain: RevKitErrorDomain, code: RevKitErrorCodes.requestFailed, userInfo: [
                    NSLocalizedFailureReasonErrorKey: "The request failed.",
                    "Response": http
                    ])
                self.dispatchResult(result: .failed(error), completion: completion)
            }
        }
        task.resume()
    }
    
    public func submitOrder<Params : OrderParams>(params: Params, completion: @escaping (Result<String>) -> Void) {
        let url = environment.baseURL.appendingPathComponent("orders")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addAuthorizationHeader(&request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try! encoder.encode(params)
        request.httpBody = data
        let task = session.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print("ERROR: \(error!)")
                self.dispatchResult(result: .failed(error!), completion: completion)
                return
            }
            let http = response as! HTTPURLResponse
            switch http.statusCode {
            case 201:
                if let location = http.allHeaderFields["Location"] as? String {
                    self.dispatchResult(result: .success(location), completion: completion)
                } else {
                    assertionFailure("Location response header was not found")
                    let error = NSError(domain: RevKitErrorDomain, code: RevKitErrorCodes.unexpectedBehavior, userInfo: [
                        NSLocalizedFailureReasonErrorKey: "The server indicated success, but did not include the expected response.",
                        "Response": http
                        ])
                    self.dispatchResult(result: .failed(error), completion: completion)
                }
            default:
                print("Received HTTP \(http.statusCode)")
                let error = NSError(domain: RevKitErrorDomain, code: RevKitErrorCodes.requestFailed, userInfo: [
                    NSLocalizedFailureReasonErrorKey: "The request failed.",
                    "Response": http
                    ])
                self.dispatchResult(result: .failed(error), completion: completion)
            }
        }
        task.resume()
    }
    
    public func getAllOrders(completion: @escaping (Result<PagedOrders>) -> Void) {
        let url = environment.baseURL.appendingPathComponent("orders")
        
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        addAuthorizationHeader(&request)
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error loading orders: \(error)")
                self.dispatchResult(result: .failed(error), completion: completion)
            } else {
                let http = response as! HTTPURLResponse
                switch http.statusCode {
                case 200:
                    print("Loaded orders...")
                    let body = String(data: data!, encoding: .utf8)!
                    
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    do {
                        let pagedOrders = try decoder.decode(PagedOrders.self, from: data!)
                        self.dispatchResult(result: .success(pagedOrders), completion: completion)
                    } catch let e {
                        print("Couldn't parse json: \(e)")
                        print("Response: \(body)")
                        self.dispatchResult(result: .failed(e), completion: completion)
                    }
                    
                default:
                    print("HTTP \(http.statusCode) from \(url)")
                    let body = String(data: data!, encoding: .utf8)!
                    print(body)
                    let error = NSError(domain: "TranscribeToolErrorDomain", code: 100, userInfo: [:])
                    self.dispatchResult(result: .failed(error), completion: completion)
                }
            }
        }
        print("HTTP GET \(url)")
        task.resume()
    }
    
    private func dispatchResult<T>(result: Result<T>, completion: @escaping (Result<T>) -> Void) {
        DispatchQueue.main.async {
            completion(result)
        }
    }
    
    private func addAuthorizationHeader(_ request: inout URLRequest) {
        request.setValue("Rev \(clientKey):\(userKey)", forHTTPHeaderField: "Authorization")
    }
    
    
}
