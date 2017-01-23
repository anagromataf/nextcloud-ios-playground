//
//  ApplicationModule.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 23.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import UIKit
import NextcloudUI

public class ApplicationModule: AccountListRouter {
    
    public let window: UIWindow
    
    let accountListModule: AccountListModule
    let fileBrowserModule: FileBrowserModule
    let mainModule: MainModule
    
    public init(window: UIWindow) {
        self.window = window
        
        accountListModule = AccountListModule()
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
    
    public func presentFolder() {
        
    }
    
}
