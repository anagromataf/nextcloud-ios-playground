//
//  Service.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 24.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import Foundation
import Dispatch

public class Service {
    
    public private(set) var accountManager: AccountManager
    
    private let store: FileStore
    
    public init(directory: URL) {
        self.store = FileStore(directory: directory)
        self.accountManager = AccountManager(store: store)
    }
    
    public func start(completion: ((Error?)->Void)?) {
        store.open(completion: completion)
    }
    
    class DummyResourceManager: ResourceManager {
        
        let account: Account
        init(account: Account) {
            self.account = account
        }
        
        struct D: Document {
            let account: Account
            let path: [String]
        }
        
        struct C: Directory {
            let account: Account
            let path: [String]
        }
        
        func resource(at path: [String]) throws -> Resource? {
            return C(account: account, path: path)
        }
        
        func content(at path: [String]) throws -> [Resource] {
            var contents = ["a", "b", "c", "d", "e"].map { (name) -> Resource in
                var path = path
                path.append(name)
                return C(account: account, path: path)
            }
            var path = path
            path.append("foo")
            contents.append(D(account: account, path: path))
            return contents
        }
    }
}
