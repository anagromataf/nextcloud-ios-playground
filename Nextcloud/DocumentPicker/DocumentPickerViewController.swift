//
//  DocumentPickerViewController.swift
//  DocumentPicker
//
//  Created by Tobias Kraentzer on 25.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import UIKit
import NextcloudCore
import NextcloudUI

class DocumentPickerViewController: UIDocumentPickerExtensionViewController, AccountListRouter, ResourceListRouter {

    let service: Service
    
    let accountListModule: AccountListModule
    let resourceListModule: ResourceListModule
    let resourceModule: ResourceModule
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        service = Service()
        
        let _ = try? service.accountManager.addAccount(with: URL(string: "https://cloud.example.com")!)
        
        accountListModule = AccountListModule(accountManager: service.accountManager)
        resourceListModule = ResourceListModule(accountManager: service.accountManager)
        resourceModule = ResourceModule()
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        accountListModule.router = self
        resourceListModule.router = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForPresentation(in mode: UIDocumentPickerMode) {
        rootViewController = accountListModule.makeViewController()
    }
    
    // MARK: Root View Controller
    
    var rootViewController: UIViewController? {
        didSet {
            if let viewController = rootViewController {
                addChildViewController(viewController)
                viewController.view.frame = view.bounds
                viewController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
                viewController.view.translatesAutoresizingMaskIntoConstraints = true
                view.addSubview(viewController.view)
                viewController.didMove(toParentViewController: self)
            }
        }
    }
    
    // MARK: AccountListRouter, ResourceListRouter
    
    func present(_ resource: Resource) {
        present(resource, animated: true)
    }
    
    func presentNewAccount() {}
}

extension DocumentPickerViewController: ResourcePresenter {
    
    public var resource: Resource? {
        guard
            let navigationController = self.navigationController,
            let resourcePresenter = navigationController.topViewController as? ResourcePresenter
            else {
                return nil
        }
        return resourcePresenter.resource
    }
    
    public func present(_ resource: Resource, animated: Bool) {
        guard
            let navigationController = self.navigationController
            else {
                return
        }
        
        var viewControllers = navigationController.viewControllers
        var newViewControllers: [UIViewController] = []
        
        if viewControllers.count > 0 {
            // The root view controller is alwasy the account list and should always be to root
            let rootViewController = viewControllers.removeFirst()
            newViewControllers.append(rootViewController)
        }
        
        for resource in resource.resourceChain {
            let viewController = viewControllers.count > 0 ? viewControllers.removeFirst() : nil
            if let resourcePresenter = viewController as? ResourcePresenter, resourcePresenter.isResource(resource) == true {
                newViewControllers.append(viewController!)
            } else {
                viewControllers.removeAll()
                if let viewController = makeViewController(for: resource) {
                    newViewControllers.append(viewController)
                } else {
                    return
                }
            }
        }
        
        navigationController.setViewControllers(newViewControllers, animated: animated)
    }
    
    private func makeViewController(for resource: Resource) -> UIViewController? {
        var viewController: UIViewController? = nil
        if resource is Folder {
            viewController = resourceListModule.makeViewController()
        } else if resource is File {
            viewController = resourceModule.makeViewController()
        }
        if let resourcePresenter = viewController as? ResourcePresenter {
            resourcePresenter.present(resource, animated: false)
        }
        return viewController
    }
}
