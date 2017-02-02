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

protocol StoreResource: Equatable, Hashable {
    var path: [String] { get }
    var isCollection: Bool { get }
}

protocol StoreUpdate {
    var url: URL { get }
    var isCollection: Bool { get }
    var version: String { get }
}

protocol Store {
    associatedtype Account: StoreAccount
    var accounts: [Account] { get }
    func addAccount(with url: URL) throws -> Account
    func remove(_ account: Account) throws -> Void
    
    associatedtype Resource: StoreResource
    func resource(of account: Account, at path: [String]) throws -> Resource?
    func contents(of account: Account, at path: [String]) throws -> [Resource]
    
    func update(_ account: Account, with update: [StoreUpdate]) throws -> Void
}

let StoreAccountKey = "StoreAccountKey"
let StoreResourcesKey = "StoreResourcesKey"

extension Notification.Name {
    static let StoreDidAddAccount = Notification.Name(rawValue: "NextcloudCore.StoreDidAddAccount")
    static let StoreDidRemoveAccount = Notification.Name(rawValue: "NextcloudCore.StoreDidRemoveAccount")
    static let StoreDidUpdateResources = Notification.Name(rawValue: "NextcloudCore.StoreDidUpdateResources")
}
