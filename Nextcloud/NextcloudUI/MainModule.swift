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
    
    public init() {
    }
    
    public func makeViewController() -> UIViewController {
        guard
            let resourceBrowserViewController = resourceBrowserModule?.makeViewController()
            else {
                return UIViewController()
        }

        let splitViewController = UISplitViewController()
        splitViewController.viewControllers = [
            resourceBrowserViewController
        ]
        splitViewController.preferredDisplayMode = .allVisible
        
        return splitViewController
    }
    
}

extension UISplitViewController: ResourcePresenter {
    
    public var resource: Resource? {
        guard
            let resourcePresenter = viewControllers.first as? ResourcePresenter
            else { return nil }
        
        return resourcePresenter.resource
    }
    
    public func present(_ resource: Resource, animated: Bool) {
        guard
            let resourcePresenter = viewControllers.first as? ResourcePresenter
            else { return }
        
        resourcePresenter.present(resource, animated: animated)
    }
    
}
 
