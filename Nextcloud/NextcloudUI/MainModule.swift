//
//  MainModule.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 23.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import UIKit
import NextcloudCore

public class MainModule: UserInterfaceModule {
    
    public var resourceBrowserModule: UserInterfaceModule?
    public var resourceModule: UserInterfaceModule?
    
    public init() {
    }
    
    public func makeViewController() -> UIViewController {
        guard
            let resourceBrowserViewController = resourceBrowserModule?.makeViewController()
            else {
                return UIViewController()
        }

        let splitViewController = MainViewController()
        splitViewController.delegate = self
        splitViewController.presentsWithGesture = true
        splitViewController.viewControllers = [
            resourceBrowserViewController
        ]
        splitViewController.preferredDisplayMode = .allVisible
        
        return splitViewController
    }
    
}

protocol MainViewControllerDelegate: UISplitViewControllerDelegate {
    func splitViewController(_ svc: UISplitViewController, detailViewControllerFor resource: Resource) -> UIViewController?
}

class MainViewController: UISplitViewController {
    
}

extension MainModule: MainViewControllerDelegate {
    func splitViewController(_ svc: UISplitViewController, detailViewControllerFor resource: Resource) -> UIViewController? {
        var viewController: UIViewController? = nil
        if resource is Document {
            viewController = resourceModule?.makeViewController()
        }
        if let resourcePresenter = viewController as? ResourcePresenter {
            resourcePresenter.present(resource, animated: false)
        }
        return viewController
    }
    
    public func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        if let viewController = primaryViewController.separateSecondaryViewController(for: splitViewController) {
            viewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            let navigationController = UINavigationController(rootViewController: viewController)
            return navigationController
        } else {
            return nil
        }
    }
    
    public func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        guard
            let primaryResourcePresenter = primaryViewController as? ResourcePresenter,
            let secondaryResourcePresenter  = secondaryViewController as? ResourcePresenter,
            let resource = secondaryResourcePresenter.resource
        else {
            return true
        }
        
        primaryResourcePresenter.present(resource, animated: false)
        return true
    }
}

extension MainViewController: ResourcePresenter {
    
    public var resource: Resource? {
        guard
            let resourcePresenter = viewControllers.first as? ResourcePresenter
            else { return nil }
        
        return resourcePresenter.resource
    }
    
    public func present(_ resource: Resource, animated: Bool) {
        guard
            let delegate = self.delegate as? MainViewControllerDelegate,
            let resourcePresenter = viewControllers.first as? ResourcePresenter
            else { return }
        
        if isCollapsed == false, let detailViewController = delegate.splitViewController(self, detailViewControllerFor: resource) {
            let navigationController = UINavigationController(rootViewController: detailViewController)
            detailViewController.navigationItem.leftBarButtonItem = displayModeButtonItem
            showDetailViewController(navigationController, sender: nil)
        } else {
            resourcePresenter.present(resource, animated: animated)
        }
    }
}
