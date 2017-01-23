//
//  MainModule.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 23.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import UIKit

public class MainModule {
    
    public var fileBrowserModule: FileBrowserModule?
    
    public init() {
    }
    
    public func makeViewController() -> UIViewController {
        guard
            let fileBrowserViewController = fileBrowserModule?.makeViewController()
            else {
                return UIViewController()
        }

        let splitViewController = UISplitViewController()
        splitViewController.viewControllers = [
            fileBrowserViewController
        ]
        splitViewController.preferredDisplayMode = .allVisible
        
        return splitViewController
    }
    
}
