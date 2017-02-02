//
//  NextcloudAPI.swift
//  Nextcloud
//
//  Created by Tobias Kräntzer on 01.02.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import Foundation
import PureXML

public protocol NextcloudAPIDelegate: class {
    func nextcloudAPI(_ api: NextcloudAPI,
                      didReceive challenge: URLAuthenticationChallenge,
                      completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void
}

public class NextcloudAPI: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {

    public weak var delegate: NextcloudAPIDelegate?
    
    public let identifier: String
    
    private let operationQueue: OperationQueue
    private let queue: DispatchQueue
    
    private lazy var dataSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration, delegate: self, delegateQueue: self.operationQueue)
    }()
    
    public init(identifier: String) {
        self.identifier = identifier
        
        queue = DispatchQueue(label: "NextcloudAPI (\(identifier))")
        operationQueue = OperationQueue()
        operationQueue.underlyingQueue = queue
        
        super.init()
    }
    
    private var pendingPropertiesRequests: [URL:[([Resource]?, Error?) -> Void]] = [:]
    
    public func properties(of url: URL, completion: @escaping (([Resource]?, Error?) -> Void)) {
        queue.async {
            if var completionHandlers = self.pendingPropertiesRequests[url] {
                completionHandlers.append(completion)
            } else {
                let completionHandlers = [completion]
                self.pendingPropertiesRequests[url] = completionHandlers
                let request = NextcloudAPI.makePropFindRequest(for: url)
                let task = self.dataSession.dataTask(with: request) { [weak self] (data, response, error) in
                    guard
                        let this = self
                        else { return }
                    this.queue.async {
                        let handlers = this.pendingPropertiesRequests[url] ?? []
                        this.pendingPropertiesRequests[url] = nil
                        do {
                            guard
                                let data = data,
                                let httpResponse = response as? HTTPURLResponse
                                else { throw error ?? NextcloudAPIError.internalError }
                            switch httpResponse.statusCode {
                            case 207:
                                guard
                                    let document = PXDocument(data: data)
                                    else { throw NextcloudAPIError.internalError }
                                let result = try Resource.makeResources(with: document, baseURL: url)
                                for handler in handlers {
                                    handler(result, nil)
                                }
                            case let statusCode:
                                // TODO: Handle other staus codes correctly
                                throw NextcloudAPIError.invalidResponse(statusCode: statusCode)
                            }
                        } catch {
                            for handler in handlers {
                                handler(nil, error)
                            }
                        }
                    }
                }
                task.resume()
            }
        }
    }
    
    // MARK: - Requests
    
    static func makePropFindRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "PROPFIND"
        return request
    }

    // MARK: - URLSessionTaskDelegate
    
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        if let delegate = self.delegate {
            delegate.nextcloudAPI(self, didReceive: challenge, completionHandler: completionHandler)
        } else {
            completionHandler(.rejectProtectionSpace, nil)
        }
    }
    
}
