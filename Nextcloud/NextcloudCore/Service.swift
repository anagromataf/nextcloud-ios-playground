//
//  Service.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 24.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import Foundation
import Dispatch

public protocol ServiceDelegate: class {
    func service(_ service: Service, needsPasswordFor account: Account, completionHandler: @escaping (String?) -> Void) -> Void
}

public class Service: ResourceManagerDelegate {
    
    public weak var delegate: ServiceDelegate?
    
    public let accountManager: AccountManager
    
    private let store: FileStore
    
    public init(directory: URL) {
        self.store = FileStore(directory: directory)
        self.accountManager = AccountManager(store: store)
        self.accountManager.delegate = self
    }
    
    public func start(completion: ((Error?)->Void)?) {
        store.open(completion: completion)
    }
    
    func passwordForResourceManager(_ manager: ResourceManager, with completionHandler: @escaping (String?) -> Void) {
        DispatchQueue.main.async {
            if let delegate = self.delegate {
                delegate.service(self, needsPasswordFor: manager.account, completionHandler: completionHandler)
            } else {
                completionHandler(nil)
            }
        }
    }
}
