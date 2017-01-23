//
//  FileBrowserModule.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 23.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import UIKit

public class FileBrowserModule {
    
    public var accountListModule: AccountListModule?
    
    public init() {
    }
    
    public func makeViewController() -> UIViewController {
        guard
            let accountListViewController = accountListModule?.makeViewController()
            else {
                return UIViewController()
        }
        
        return UINavigationController(rootViewController: accountListViewController)
    }
}
