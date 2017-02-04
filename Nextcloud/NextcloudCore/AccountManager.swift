//
//  AccountManager.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 24.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import Foundation

public enum AccountManagerError: Error {
    case alreadyExists
}

public class Account: Equatable, Hashable {
    
    let storeAccount: FileStore.Account
    init(storeAccount: FileStore.Account) {
        self.storeAccount = storeAccount
    }
    
    public var url: URL {
        return storeAccount.url
    }
    
    public var username: String {
        return storeAccount.username
    }
    
    public static func ==(lhs: Account, rhs: Account) -> Bool {
        return lhs.storeAccount == rhs.storeAccount
    }
    
    public var hashValue: Int {
        return storeAccount.hashValue
    }
}

public extension Notification.Name {
    static let AccountManagerDidChange = Notification.Name(rawValue: "AccountManagerDidChange")
}

public class AccountManager {

    weak var delegate: ResourceManagerDelegate?
    
    let queue: DispatchQueue
    let store: FileStore
    init(store: FileStore) {
        self.store = store
        self.queue = DispatchQueue(label: "AccountManager")
    }
    
    public var accounts: [Account] {
        return store.accounts.map { (storeAccount) in
            return Account(storeAccount: storeAccount)
        }
    }
    
    public func addAccount(with url: URL, username: String) throws -> Account {
        let storeAccount = try store.addAccount(with: url, username: username)
        let account = Account(storeAccount: storeAccount)
        
        let center = NotificationCenter.default
        center.post(name: Notification.Name.AccountManagerDidChange, object: self)
        
        return account
    }
    
    public func remove(_ account: Account) throws {
        try queue.sync {
            resourceManagers[account] = nil
            try store.remove(account.storeAccount)
        }
        let center = NotificationCenter.default
        center.post(name: Notification.Name.AccountManagerDidChange, object: self)
    }
    
    private var resourceManagers: [Account:ResourceManager] = [:]
    
    public func resourceManager(for account: Account) -> ResourceManager {
        return queue.sync  {
            if let manager = resourceManagers[account] {
                return manager
            } else {
                let manager = ResourceManager(store: store, account: account)
                manager.delegate = self.delegate
                resourceManagers[account] = manager
                return manager
            }
        }
    }
}
