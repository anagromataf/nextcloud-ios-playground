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

public class ApplicationModule: AccountListRouter {
    
    public let window: UIWindow
    public let service: Service
    
    let accountListModule: AccountListModule
    let fileBrowserModule: FileBrowserModule
    let mainModule: MainModule
    
    public init(window: UIWindow, service: Service) {
        self.window = window
        self.service = service
        
        accountListModule = AccountListModule(accountManager: service.accountManager)
        fileBrowserModule = FileBrowserModule()
        mainModule = MainModule()
        
        fileBrowserModule.accountListModule = accountListModule
        mainModule.fileBrowserModule = fileBrowserModule
        
        accountListModule.router = self
    }
    
    public func present() {
        window.backgroundColor = UIColor.white
        window.rootViewController = mainModule.makeViewController()
        window.makeKeyAndVisible()
    }
    
    // MARK: AccountListRouter
    
    public func present(_ resource: Resource) {
        guard
            let resourcePresenter = window.rootViewController as? ResourcePresenter
            else { return }
        resourcePresenter.present("123", animated: true)
    }
    
}
