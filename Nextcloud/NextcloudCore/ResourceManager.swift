//
//  ResourceManager.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 24.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import Foundation

public protocol Resource {
    var account: Account { get }
    var path: [String] { get }
}

public struct File: Resource {
    public let account: Account
    public let path: [String]
    public init(account: Account, path: [String]) {
        self.account = account
        self.path = path
    }
}

public struct Folder: Resource {
    public let account: Account
    public let path: [String]
    public init(account: Account, path: [String]) {
        self.account = account
        self.path = path
    }
}

public protocol ResourceManager {
    func contents(of resource: Resource) throws -> [Resource]
}
