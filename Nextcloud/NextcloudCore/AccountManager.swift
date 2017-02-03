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

public struct Account: Equatable, Hashable {
    
    public let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    public static func ==(lhs: Account, rhs: Account) -> Bool {
        return lhs.url == rhs.url
    }
    
    public var hashValue: Int {
        return url.hashValue
    }
}

public extension Notification.Name {
    static let AccountManagerDidChange = Notification.Name(rawValue: "AccountManagerDidChange")
}

public protocol AccountManager {
    
    func addAccount(with url: URL) throws -> Account
    func remove(_ account: Account) throws -> Void
    func accounts() throws -> [Account]
    
    func resourceManager(for account: Account) -> ResourceManager
}
