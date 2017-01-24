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
    public let username: String
    public init(url: URL, username: String) {
        self.url = url
        self.username = username
    }
    public static func ==(lhs: Account, rhs: Account) -> Bool {
        return lhs.url == rhs.url && lhs.username == rhs.username
    }
    public var hashValue: Int {
        return url.hashValue + username.hashValue
    }
}

public extension Notification.Name {
    static let AccountManagerDidChange = Notification.Name(rawValue: "AccountManagerDidChange")
}

public protocol AccountManager {
    func add(_ account: Account) throws -> Account
    func remove(_ account: Account) throws -> Void
    func accounts() throws -> [Account]
}
