//
//  ResourceManager.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 24.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import Foundation
import NextcloudAPI

public struct Resource: Equatable, Hashable {
    
    public let account: Account
    
    let storeResource: FileStore.Resource
    init(account: Account, storeResource: FileStore.Resource) {
        self.account = account
        self.storeResource = storeResource
    }
    
    public var path: [String] {
        return storeResource.path
    }
    
    public var isCollection: Bool {
        return storeResource.isCollection
    }
    
    public static func ==(lhs: Resource, rhs: Resource) -> Bool {
        return lhs.storeResource == rhs.storeResource
    }
    
    public var hashValue: Int {
        return storeResource.hashValue
    }
}

public class ResourceManager: NextcloudAPIDelegate {

    let store: FileStore
    let account: Account
    let queue: DispatchQueue
    let api: NextcloudAPI
    
    init(store: FileStore, account: Account) {
        self.store = store
        self.account = account
        self.queue = DispatchQueue(label: "ResourceManager")
        self.api = NextcloudAPI(identifier: account.url.absoluteString)
        self.api.delegate = self
    }
    
    public func resource(at path: [String]) throws -> Resource? {
        guard
            let storeResource = try store.resource(of: account.storeAccount, at: path)
            else { return nil }
        
        if storeResource.dirty {
            updateResource(at: path) { error in
                if error != nil {
                    NSLog("Failed to update resource: \(error)")
                }
            }
        }
        
        return Resource(account: account, storeResource: storeResource)
    }
    
    public func content(at path: [String]) throws -> [Resource] {
        let content = try store.contents(of: account.storeAccount, at: path)
        return content.map { (storeResource) in
            return Resource(account: account, storeResource: storeResource)
        }
    }
    
    private func updateResource(at path: [String], completion: ((Error?) -> Void)?) {
        let url = account.url.appendingPathComponent(path.joined(separator: "/"))
        self.api.properties(of: url) { (result, error) in
            
        }
    }
    
    // MARK: - NextcloudAPIDelegate
    
    public func nextcloudAPI(_ api: NextcloudAPI, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
    }
}
