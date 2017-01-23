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
