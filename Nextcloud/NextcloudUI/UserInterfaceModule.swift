//
//  UserInterfaceModule.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 23.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import Foundation

public protocol UserInterfaceModule {
    func makeViewController() -> UIViewController
}

public typealias Resource = String

public protocol ResourcePresenter {
    var resource: Resource? { get }
    func present(_ resource: Resource, animated: Bool) -> Void
}
