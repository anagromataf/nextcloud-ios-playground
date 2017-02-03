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
    
    public init() {
        self.accountManager = DummyAccountManager()
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
    
    class DummyAccountManager: AccountManager {
        
        let queue: DispatchQueue = DispatchQueue(label: "DummyAccountManager")
        
        var _accounts: [Account] = []
        
        func addAccount(with url: URL) throws -> Account {
            return try queue.sync {
                let account = Account(url: url)
                if _accounts.contains(account) {
                    throw AccountManagerError.alreadyExists
                } else {
                    _accounts.append(account)
                    DispatchQueue.main.async {
                        let center = NotificationCenter.default
                        center.post(name: Notification.Name.AccountManagerDidChange, object: self)
                    }
                    return account
                }
            }
        }
        
        func remove(_ account: Account) throws -> Void {
            queue.sync {
                if let index = _accounts.index(of: account) {
                    _accounts.remove(at: index)
                    DispatchQueue.main.async {
                        let center = NotificationCenter.default
                        center.post(name: Notification.Name.AccountManagerDidChange, object: self)
                    }
                }
            }
        }

        func accounts() throws -> [Account] {
            return queue.sync {
                return _accounts
            }
        }
        
        func resourceManager(for account: Account) -> ResourceManager {
            return DummyResourceManager(account: account)
        }
    }
}
