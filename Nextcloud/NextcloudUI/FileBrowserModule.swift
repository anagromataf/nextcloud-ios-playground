//
//  FileBrowserModule.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 23.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import UIKit
import NextcloudCore

public class FileBrowserModule: NSObject, UserInterfaceModule {
    
    public var accountListModule: UserInterfaceModule?
    public var fileListModule: UserInterfaceModule?
    
    public override init() {
    }
    
    public func makeViewController() -> UIViewController {
        guard
            let accountListViewController = accountListModule?.makeViewController()
            else {
                return UIViewController()
        }
        
        let navigationController = UINavigationController(rootViewController: accountListViewController)
        navigationController.delegate = self
        return navigationController
    }
}

protocol UINavigationControllerDelegateFileList: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, viewControllerFor resource: Resource) -> UIViewController?
}

extension FileBrowserModule: UINavigationControllerDelegateFileList {
    func navigationController(_ navigationController: UINavigationController, viewControllerFor resource: Resource) -> UIViewController? {
        guard
            let viewController = fileListModule?.makeViewController(),
            let resourcePresenter = viewController as? ResourcePresenter
        else {
            return nil
        }
        resourcePresenter.present(resource, animated: false)
        return viewController
    }
}

extension UINavigationController: ResourcePresenter {
    
    public var resource: Resource? {
        return nil
    }
    
    public func present(_ resource: Resource, animated: Bool) {
        guard
            let delegate = self.delegate as? UINavigationControllerDelegateFileList,
            let viewController = delegate.navigationController(self, viewControllerFor: resource)
            else {
                return
        }
        pushViewController(viewController, animated: animated)
    }
}
