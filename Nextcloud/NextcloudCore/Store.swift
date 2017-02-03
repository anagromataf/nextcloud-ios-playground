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
    associatedtype Account: StoreAccount
    var account: Account { get }
    var path: [String] { get }
    var isCollection: Bool { get }
    var dirty: Bool { get }
    var version: String? { get }
}

protocol ResourceProperties {
    var isCollection: Bool { get }
    var version: String { get }
}

protocol StoreChangeSet {
    associatedtype Resource: StoreResource
    var insertedOrUpdated: [Resource] { get }
    var deleted: [Resource] { get }
}

protocol Store {
    associatedtype Account: StoreAccount
    var accounts: [Account] { get }
    func addAccount(with url: URL) throws -> Account
    func remove(_ account: Account) throws -> Void
    
    associatedtype Resource: StoreResource
    func resource(of account: Account, at path: [String]) throws -> Resource?
    func contents(of account: Account, at path: [String]) throws -> [Resource]
    
    associatedtype ChangeSet: StoreChangeSet
    func update(resourceAt path: [String], of account: Account, with properties: ResourceProperties?) throws -> ChangeSet
    func update(resourceAt path: [String], of account: Account, with properties: ResourceProperties?, content: [String:ResourceProperties]?) throws -> ChangeSet
}
