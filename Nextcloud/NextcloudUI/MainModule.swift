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
        if resource.isCollection == false {
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

extension MainViewController: PasswordPromt {
    
    public func requestPassword(for account: Account, completion: @escaping (String?) -> Void) {
        
        let title = "Login"
        let message = "Password for '\(account.username)' at '\(account.url.absoluteString)'"
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("Password", comment: "")
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            textField.isSecureTextEntry = true
        }
        
        let loginAction = UIAlertAction(title: NSLocalizedString("Login", comment: ""), style: .default) {
            action in
            let password = alert.textFields?.last?.text
            completion(password)
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) {
            action in
            
            completion(nil)
        }
        
        alert.addAction(loginAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
}
