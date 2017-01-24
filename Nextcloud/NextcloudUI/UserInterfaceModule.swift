//
//  UserInterfaceModule.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 23.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import Foundation
import NextcloudCore

public protocol UserInterfaceModule {
    func makeViewController() -> UIViewController
}

public protocol ResourcePresenter {
    var resource: Resource? { get }
    func isResource(_ resource: Resource) -> Bool
    func present(_ resource: Resource, animated: Bool) -> Void
}

extension ResourcePresenter {
    public func isResource(_ resource: Resource) -> Bool {
        guard
            let this = self.resource
            else { return false }
        return this.account == resource.account && this.path == resource.path
    }
}
