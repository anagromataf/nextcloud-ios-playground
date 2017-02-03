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

public protocol Directory: Resource {

}

public protocol Document: Resource {

}

public protocol ResourceManager {
    func resource(at path: [String]) throws -> Resource?
    func content(at path: [String]) throws -> [Resource]
}
