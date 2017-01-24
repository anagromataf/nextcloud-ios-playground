//
//  FileBrowserModule.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 23.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import UIKit
import NextcloudCore

public class FileBrowserModule: UserInterfaceModule {
    
    public var accountListModule: UserInterfaceModule?
    
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

extension UINavigationController: ResourcePresenter {
    
    public var resource: Resource? {
        return nil
    }
    
    public func present(_ resource: Resource, animated: Bool) {
        let viewController = UIViewController()
        viewController.view.backgroundColor = UIColor.cyan
        pushViewController(viewController, animated: animated)
    }
}
