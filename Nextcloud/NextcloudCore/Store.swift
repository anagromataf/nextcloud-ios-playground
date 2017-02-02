//
//  Store.swift
//  Nextcloud
//
//  Created by Tobias Kräntzer on 02.02.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import Foundation
import NextcloudAPI

protocol StoreAccount: Equatable, Hashable {
    var url: URL { get }
}

protocol Store {
    associatedtype Account: StoreAccount
    var accounts: [Account] { get }
    func addAccount(with url: URL) throws -> Account
    func remove(_ account: Account) throws -> Void
}

let StoreAccountKey = "StoreAccountKey"

extension Notification.Name {
    static let StoreDidAddAccount = Notification.Name(rawValue: "NextcloudCore.StoreDidAddAccount")
    static let StoreDidRemoveAccount = Notification.Name(rawValue: "NextcloudCore.StoreDidRemoveAccount")
}
