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
    func present(_ resource: Resource, animated: Bool) -> Void
}
