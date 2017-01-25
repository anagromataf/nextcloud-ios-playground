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
        if resource is Folder {
            viewController = resourceListModule?.makeViewController()
        } else if resource is File {
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
            let delegate = self.delegate as? ResourceBrowserNavigationControllerDelegate
            else {
                return
        }
        
        var viewControllers = self.viewControllers
        var newViewControllers: [UIViewController] = []

        if viewControllers.count > 0 {
            // The root view controller is alwasy the account list and should always be to root
            let rootViewController = viewControllers.removeFirst()
            newViewControllers.append(rootViewController)
        }

        for resource in path(for: resource) {
            let viewController = viewControllers.count > 0 ? viewControllers.removeFirst() : nil
            if let resourcePresenter = viewController as? ResourcePresenter, resourcePresenter.isResource(resource) == true {
                newViewControllers.append(viewController!)
            } else {
                viewControllers.removeAll()
                if let viewController = delegate.navigationController(self, viewControllerFor: resource) {
                    newViewControllers.append(viewController)
                } else {
                    return
                }
            }
        }
        
        setViewControllers(newViewControllers, animated: animated)
    }

    private func path(for resource: Resource) -> [Resource] {
        var result: [Resource] = []
        var currentPath: [String] = []
        result.append(Folder(account: resource.account, path: currentPath))
        for name in resource.path {
            currentPath.append(name)
            if currentPath != resource.path {
                result.append(Folder(account: resource.account, path: currentPath))
            } else {
                result.append(resource)
            }
        }
        return result
    }
}

class ResourceBrowserNavigationController: UINavigationController {
    override func separateSecondaryViewController(for splitViewController: UISplitViewController) -> UIViewController? {
        guard
            let resourcePresenter = topViewController as? ResourcePresenter,
            resourcePresenter.resource is File
            else { return nil }
        
        let viewController = topViewController
        popViewController(animated: false)
        return viewController
    }
}
