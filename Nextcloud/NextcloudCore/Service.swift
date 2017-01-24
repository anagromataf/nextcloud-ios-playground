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
    
    class DummyAccountManager: AccountManager {
        
        let queue: DispatchQueue = DispatchQueue(label: "DummyAccountManager")
        
        var _accounts: [Account] = []
        
        func add(_ account: Account) throws -> Account {
            return try queue.sync {
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
    }
}
