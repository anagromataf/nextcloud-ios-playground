//
//  ApplicationModule.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 23.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import UIKit
import NextcloudUI
import NextcloudCore

public class ApplicationModule: AccountListRouter, ResourceListRouter {
    
    public let window: UIWindow
    public let service: Service
    
    let accountListModule: AccountListModule
    let resourceListModule: ResourceListModule
    let resourceModule: ResourceModule
    let resourceBrowserModule: ResourceBrowserModule
    
    let mainModule: MainModule
    
    public init(window: UIWindow, service: Service) {
        self.window = window
        self.service = service
        
        accountListModule = AccountListModule(accountManager: service.accountManager)
        resourceListModule = ResourceListModule(accountManager: service.accountManager)
        resourceModule = ResourceModule()
        resourceBrowserModule = ResourceBrowserModule()
        mainModule = MainModule()
        
        resourceBrowserModule.accountListModule = accountListModule
        resourceBrowserModule.resourceListModule = resourceListModule
        resourceBrowserModule.resourceModule = resourceModule
        mainModule.resourceBrowserModule = resourceBrowserModule
        
        accountListModule.router = self
        resourceListModule.router = self
    }
    
    public func present() {
        window.backgroundColor = UIColor.white
        window.rootViewController = mainModule.makeViewController()
        window.makeKeyAndVisible()
    }
    
    // MARK: AccountListRouter, ResourceListRouter
    
    public func present(_ resource: Resource) {
        guard
            let resourcePresenter = window.rootViewController as? ResourcePresenter
            else { return }
        resourcePresenter.present(resource, animated: true)
    }
    
    public func presentNewAccount() {
        
        let title = "Add Account"
        let message = "Enter the url and username of your Nextcloud server"
        
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("https://could.example.com", comment: "")
            textField.keyboardType = .URL
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("Username", comment: "")
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }
        
        let addAction = UIAlertAction(title: NSLocalizedString("Add", comment: ""), style: .default) {
            action in
            guard
                let urlString = alert.textFields?.first?.text,
                let url = URL(string: urlString),
                let username = alert.textFields?.last?.text
                else {
                    return
            }
            
            let account = Account(url: url, username: username)
            let _ = try! self.service.accountManager.add(account)
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) {
            action in
        }

        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        if let viewControler = window.rootViewController?.presentedViewController {
            viewControler.present(alert, animated: true, completion: nil)
        } else {
            window.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
}
