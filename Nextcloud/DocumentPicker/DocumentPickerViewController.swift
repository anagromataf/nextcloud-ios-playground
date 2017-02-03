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
    
    var accountListModule: AccountListModule!
    var resourceListModule: ResourceListModule!
    var resourceModule: ResourceModule!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        
        let fileManager = FileManager.default
        let directory = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.nextcloud.Nextcloud")!
        service = Service(directory: directory)

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        service.start { [weak self] (error) in
            DispatchQueue.main.async {
                guard let this = self else { return }
                if error != nil {
                    NSLog("Failed to setup service: \(error)")
                } else {
                    this.accountListModule = AccountListModule(accountManager: this.service.accountManager)
                    this.resourceListModule = ResourceListModule(accountManager: this.service.accountManager)
                    this.resourceModule = ResourceModule()
                    
                    this.accountListModule.router = this
                    this.resourceListModule.router = this
                    
                    this.rootViewController = this.accountListModule.makeViewController()
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForPresentation(in mode: UIDocumentPickerMode) {
        
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
            let navigationController = self.navigationController,
            let viewController = makeViewController(for: resource)
            else {
                return
        }
        navigationController.pushViewController(viewController, animated: animated)
    }
    
    private func makeViewController(for resource: Resource) -> UIViewController? {
        var viewController: UIViewController? = nil
        if resource.isCollection == true {
            viewController = resourceListModule.makeViewController()
        } else {
            viewController = resourceModule.makeViewController()
        }
        if let resourcePresenter = viewController as? ResourcePresenter {
            resourcePresenter.present(resource, animated: false)
        }
        return viewController
    }
}
