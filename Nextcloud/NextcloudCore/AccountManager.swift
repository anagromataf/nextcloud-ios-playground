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
    
    public func addAccount(with url: URL) throws -> Account {
        let storeAccount = try store.addAccount(with: url)
        let account = Account(storeAccount: storeAccount)
        
        let center = NotificationCenter.default
        center.post(name: Notification.Name.AccountManagerDidChange, object: self)
        
        return account
    }
    
    public func remove(_ account: Account) throws {
        try store.remove(account.storeAccount)
        let center = NotificationCenter.default
        center.post(name: Notification.Name.AccountManagerDidChange, object: self)
    }
    
    private let resourceManagers: NSMapTable<Account, ResourceManager> = NSMapTable<Account, ResourceManager>.strongToWeakObjects()
    
    public func resourceManager(for account: Account) -> ResourceManager {
        return queue.sync  {
            if let manager = resourceManagers.object(forKey: account) {
                return manager
            } else {
                let manager = ResourceManager(store: store, account: account)
                resourceManagers.setObject(manager, forKey: account)
                return manager
            }
        }
    }
}
