//
//  RevClient.swift
//  RevKit
//
//  Created by Ben Scheirman on 4/26/18.
//  Copyright © 2018 Fickle Bits, LLC. All rights reserved.
//

import Foundation

public struct RevKitError {
    
    struct Codes {
        static let requestFailed = 1000
        static let unexpectedBehavior = 1001
        static let notFound = 1002
        static let serverError = 1003
    }
    
    struct Response : Decodable {
        let code: Int
        let message: String
        
        var error: NSError {
            return NSError(domain: RevKitError.domain,
                           code: code,
                           userInfo: [
                            NSLocalizedFailureReasonErrorKey: message
                    ])
        }
    }

    static var domain: String = "RevKitErrorDomain"
    
    static func requestFailed(url: URL, message: String) -> NSError {
        return NSError(domain: domain, code: Codes.requestFailed,
                       userInfo: [
                        NSURLErrorFailingURLErrorKey: url,
                        NSLocalizedFailureReasonErrorKey: "The request was invalid.",
                        NSLocalizedDescriptionKey: message
            ])
    }
    
    static func resourceNotFound(url: URL) -> NSError {
        return NSError(domain: domain, code: Codes.notFound,
                       userInfo: [
                        NSURLErrorFailingURLErrorKey: url,
                        NSLocalizedFailureReasonErrorKey: "The resource was not found.",
                        NSLocalizedDescriptionKey: "Could not find the requested item.",
                        NSLocalizedRecoverySuggestionErrorKey: "Try refreshing your data."
            ])
    }
    
    static func serverError(url: URL) -> NSError {
        return NSError(domain: domain, code: Codes.serverError,
                       userInfo: [
                        NSURLErrorFailingURLErrorKey: url,
                        NSLocalizedFailureReasonErrorKey: "The server encountered an error.",
                        NSLocalizedDescriptionKey: "Server Error",
                        NSLocalizedRecoverySuggestionErrorKey: "Try your request again later."
            ])
    }
    
    static func unexpectedError(failureReason: String? = nil) -> NSError {
        return NSError(domain: domain, code: Codes.serverError,
                       userInfo: [
                        NSLocalizedDescriptionKey: "An unexpected error occurred",
                        NSLocalizedFailureReasonErrorKey: failureReason ?? "(no reason given)"
            ])
    }
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

public class RevClient : NSObject {
    
    public enum Result<T> {
        case success(T)
        case failed(Error)
    }
    
    private let clientKey: String
    private let userKey: String
    private let environment: RevEnvironment
    
    struct UploadStatus {
        var progress: Progress
        var response: HTTPURLResponse? = nil
        var responseData: Data
        var completion: (Result<String>) -> Void
        
        init(progress: Progress, completion: @escaping (Result<String>) -> Void) {
            self.progress = progress
            self.completion = completion
            responseData = Data()
        }
    }
    
    private var uploadStatus: UploadStatus?
    
    private let sessionConfiguration = URLSessionConfiguration.default
    private lazy var session: URLSession = { [sessionConfiguration] in
       return URLSession(configuration: sessionConfiguration)
    }()
    
    public init(clientKey: String, userKey: String, environment: RevEnvironment) {
        self.clientKey = clientKey
        self.userKey = userKey
        self.environment = environment
        super.init()
    }
    
    public func uploadInput(from remoteURL: URL, filename: String? = nil, contentType: String? = nil, completion: @escaping (Result<String>) -> Void) {
        let url = environment.baseURL.appendingPathComponent("inputs")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addAuthorizationHeader(&request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let uploadedFilename = filename ?? remoteURL.lastPathComponent
        var body: [String: String] = [
            "filename": uploadedFilename,
            "url": remoteURL.absoluteString
        ]
        if let contentType = contentType {
            body["content_type"] = contentType
        }
        
        let data = try! JSONSerialization.data(withJSONObject: body, options: [])
        request.httpBody = data
        
        execute(request: request, httpSuccess: { (http, data) -> Result<String> in
            return self.extractHTTPLocation(http: http)
        }, completion: completion)
    }
    
    public func uploadInput(file fileURL: URL, contentType: String? = nil, progress: Progress, completion: @escaping (Result<String>) -> Void) -> URLSessionUploadTask {
        guard uploadStatus == nil else {
            fatalError("There is already a progress in use. To upload multiple files simultaneously, use separate instances of RevClient.")
        }
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        var request = URLRequest(url: environment.baseURL.appendingPathComponent("inputs"))
        addAuthorizationHeader(&request)
        let filename = fileURL.lastPathComponent
        request.httpMethod = "POST"
        request.setValue("attachment; filename=\"\(filename)\"", forHTTPHeaderField: "Content-Disposition")
        request.setValue(contentType ?? "video/mp4", forHTTPHeaderField: "Content-Type")
        
        let task = session.uploadTask(with: request, fromFile: fileURL)
        uploadStatus = UploadStatus(progress: progress, completion: completion)
        task.resume()
        return task
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
        
        execute(request: request, httpSuccess: { (http, data) -> Result<String> in
            return self.extractHTTPLocation(http: http)
        }, completion: completion)
    }
    
    public func getAllOrders(completion: @escaping (Result<PagedOrders>) -> Void) {
        let url = environment.baseURL.appendingPathComponent("orders")
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        addAuthorizationHeader(&request)
        executeJSONRequest(request: request, completion: completion)
    }
    
    public func getOrderDetail(orderNum: String, completion: @escaping (Result<OrderDetail>) -> Void) {
        let url = environment.baseURL.appendingPathComponent("orders/\(orderNum)")
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        addAuthorizationHeader(&request)
        executeJSONRequest(request: request, completion: completion)
    }
    
    private func executeJSONRequest<T : Decodable>(request: URLRequest, completion: @escaping (Result<T>) -> Void) {
        execute(request: request, httpSuccess: { (http, data) -> Result<T> in
            
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale.current
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                                     //"2018-05-03T21:12:43.483Z"
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .custom({ d in
                let container = try d.singleValueContainer()
                let stringValue = try container.decode(String.self)
                print("date string: \(stringValue)")
                return dateFormatter.date(from: stringValue)!
            })
            do {
                let body = String(data: data, encoding: .utf8) ?? "<no body>"
                print("Response: \n\n\n\(body)\n\n\n")
                let parsedObject = try decoder.decode(T.self, from: data)
                return .success(parsedObject)
            } catch let e {
                let body = String(data: data, encoding: .utf8) ?? "<no body>"
                print("Couldn't parse json: \(e)")
                print("Response: \(body)")
                return .failed(e)
            }
        }, completion: completion)
    }
    
    private func execute<T>(request: URLRequest, httpSuccess: @escaping (HTTPURLResponse, Data) -> Result<T>, completion: @escaping (Result<T>) -> Void) {
        let task = session.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print("ERROR: \(error!)")
                self.dispatchResult(result: .failed(error!), completion: completion)
                return
            }
            let http = response as! HTTPURLResponse
            switch http.statusCode {
            case 200...201:
                let result = httpSuccess(http, data!)
                self.dispatchResult(result: result, completion: completion)
            case 400:
                let error = self.extractAPIError(http: http, data: data!)
                self.dispatchResult(result: .failed(error), completion: completion)
            case 404:
                let error = RevKitError.resourceNotFound(url: request.url!)
                self.dispatchResult(result: .failed(error), completion: completion)
            default:
                print("HTTP \(http.statusCode) from \(request.url!)")
                let body = String(data: data!, encoding: .utf8)!
                print(body)
                let error = RevKitError.unexpectedError()
                self.dispatchResult(result: .failed(error), completion: completion)
            }
        }
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
    
    private func extractHTTPLocation(http: HTTPURLResponse) -> Result<String> {
        guard let location = http.allHeaderFields["Location"] as? String else {
            assertionFailure("Location response header was not found")
            let error = RevKitError.unexpectedError(failureReason: "The server indicated success, but did not include the expected response.")
            return .failed(error)
        }
        return .success(location)
    }
    
    private func extractAPIError(http: HTTPURLResponse, data: Data) -> Error {
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(RevKitError.Response.self, from: data)
            return response.error
        } catch {
            return RevKitError.unexpectedError()
        }
    }
}

extension RevClient : URLSessionDataDelegate {
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let uploadStatus = uploadStatus else { fatalError() }
        guard let response = uploadStatus.response else { return }
        
        let result: Result<String>
        if let error = error {
            result = .failed(error)
        } else if response.statusCode == 201 {
            if let location = response.allHeaderFields["Location"] as? String {
                result = .success(location)
            } else {
                let error = RevKitError.unexpectedError()
                result = .failed(error)
            }
        } else {
            let bodyString = String(data: uploadStatus.responseData, encoding: .utf8) ?? "<no response>"
            let error = RevKitError.requestFailed(url: task.currentRequest!.url!, message: bodyString)
            result = .failed(error)
        }
        
        uploadStatus.completion(result)
        self.uploadStatus = nil
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        print("HTTP Response \(httpResponse.statusCode)   Headers: %@", httpResponse.allHeaderFields)
        uploadStatus?.response = httpResponse
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        uploadStatus?.responseData.append(data)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let progress = uploadStatus?.progress else { return }
        progress.completedUnitCount = totalBytesSent
        progress.totalUnitCount = totalBytesExpectedToSend
        print("Progress: \(progress.fractionCompleted)")
    }
}
