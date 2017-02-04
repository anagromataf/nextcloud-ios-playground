//
//  ResourceManager.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 24.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import Foundation
import NextcloudAPI

public let InsertedOrUpdatedResourcesKey = "InsertedOrUpdatedResourcesKey"
public let DeletedResourcesKey = "DeletedResourcesKey"

public extension Notification.Name {
    static let ResourceManagerDidChange = Notification.Name(rawValue: "NextcloudCore.ResourceManagerDidChange")
}

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

protocol ResourceManagerDelegate: class {
    func passwordForResourceManager(_ manager: ResourceManager, with completionHandler: @escaping (String?)->Void) -> Void
}

public class ResourceManager: NextcloudAPIDelegate {

    weak var delegate: ResourceManagerDelegate?
    
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
        guard
            let storeResource = try store.resource(of: account.storeAccount, at: path)
            else { return [] }
        
        if storeResource.dirty {
            updateResource(at: path) { error in
                if error != nil {
                    NSLog("Failed to update resource: \(error)")
                }
            }
        }
        
        let content = try store.contents(of: account.storeAccount, at: path)
        return content.map { (storeResource) in
            return Resource(account: account, storeResource: storeResource)
        }
    }
    
    private func updateResource(at path: [String], completion: ((Error?) -> Void)?) {
        let url = account.url.appendingPathComponent(path.joined(separator: "/"))
        self.api.properties(of: url) { (results, error) in
            
            guard
                let results = results
                else { return }
            
            var properties: StoreResourceProperties? = nil
            var content: [String:StoreResourceProperties] = [:]

            for result in results {
                if let resultPath = result.url.pathComponents(relativeTo: self.account.url) {
                    let prop = FileStoreResourceProperties(isCollection: result.collection, version: result.version)
                    if resultPath == path {
                        properties = prop
                    } else if resultPath.starts(with: path)
                        && resultPath.count == path.count + 1 {
                        let name = resultPath[path.count]
                        content[name] = prop
                    }
                }
            }
            
            do {
                
                let changeSet = try self.store.update(resourceAt: path, of: self.account.storeAccount, with: properties, content: content)
                
                let insertedOrUpdated = changeSet.insertedOrUpdated.map { storeResource in
                     return Resource(account: self.account, storeResource: storeResource)
                }

                let deleted = changeSet.deleted.map { storeResource in
                    return Resource(account: self.account, storeResource: storeResource)
                }
                
                DispatchQueue.main.async {
                    let center = NotificationCenter.default
                    center.post(name: Notification.Name.ResourceManagerDidChange, object: self,
                                userInfo: [InsertedOrUpdatedResourcesKey: insertedOrUpdated,
                                           DeletedResourcesKey: deleted])
                }
                
            } catch {
                NSLog("Failed ot update store: \(error)")
            }
        }
    }
    
    // MARK: - NextcloudAPIDelegate
    
    public func nextcloudAPI(_ api: NextcloudAPI, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let delegate = self.delegate {
            delegate.passwordForResourceManager(self, with: { (password) in
                if let password = password {
                    completionHandler(.useCredential, URLCredential(user: self.account.username, password: password, persistence: .forSession))
                } else {
                    completionHandler(.cancelAuthenticationChallenge, nil)
                }
            })
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
