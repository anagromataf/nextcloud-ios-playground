//
//  ResourceBrowserModule.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 23.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import UIKit
import NextcloudCore

public class ResourceBrowserModule: NSObject, UserInterfaceModule {
    
    public var accountListModule: UserInterfaceModule?
    public var resourceListModule: UserInterfaceModule?
    public var resourceModule: UserInterfaceModule?
    
    public override init() {
    }
    
    public func makeViewController() -> UIViewController {
        guard
            let accountListViewController = accountListModule?.makeViewController()
            else {
                return UIViewController()
        }
        
        let navigationController = ResourceBrowserNavigationController(rootViewController: accountListViewController)
        navigationController.delegate = self
        return navigationController
    }
}

protocol ResourceBrowserNavigationControllerDelegate: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, viewControllerFor resource: Resource) -> UIViewController?
}

extension ResourceBrowserModule: ResourceBrowserNavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, viewControllerFor resource: Resource) -> UIViewController? {
        var viewController: UIViewController? = nil
        if resource.isCollection == true {
            viewController = resourceListModule?.makeViewController()
        } else {
            viewController = resourceModule?.makeViewController()
        }
        if let resourcePresenter = viewController as? ResourcePresenter {
            resourcePresenter.present(resource, animated: false)
        }
        return viewController
    }
}

extension ResourceBrowserNavigationController: ResourcePresenter {
    
    public var resource: Resource? {
        guard
            let resourcePresenter = topViewController as? ResourcePresenter
            else {
                return nil
        }
        return resourcePresenter.resource
    }
    
    public func present(_ resource: Resource, animated: Bool) {
        guard
            let delegate = self.delegate as? ResourceBrowserNavigationControllerDelegate,
            let viewController = delegate.navigationController(self, viewControllerFor: resource)
            else {
                return
        }
        pushViewController(viewController, animated: animated)
    }
}

class ResourceBrowserNavigationController: UINavigationController {
    override func separateSecondaryViewController(for splitViewController: UISplitViewController) -> UIViewController? {
        guard
            let resourcePresenter = topViewController as? ResourcePresenter,
            resourcePresenter.resource?.isCollection == false
            else { return nil }
        
        let viewController = topViewController
        popViewController(animated: false)
        return viewController
    }
}
