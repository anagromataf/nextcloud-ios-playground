//
//  ResourceModule.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 25.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import UIKit
import NextcloudCore

public class ResourceModule: UserInterfaceModule {

    public init() {
    }
    
    public func makeViewController() -> UIViewController {
        let viewController = ResourceViewController()
        return viewController
    }
    
}

class ResourceViewController: UIViewController, ResourcePresenter {
    
    private(set) var resource: Resource?
    
    func present(_ resource: Resource, animated: Bool) {
        self.resource = resource
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.lightGray
    }
}
