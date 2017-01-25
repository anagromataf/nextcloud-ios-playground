//
//  ResourceListModule.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 24.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import UIKit
import NextcloudCore

public protocol ResourceListRouter: class {
    func present(_ resource: Resource) -> Void
}

public class ResourceListModule: UserInterfaceModule {
    
    public weak var router: ResourceListRouter?
    
    public let accountManager: AccountManager
    public init(accountManager: AccountManager) {
        self.accountManager = accountManager
    }
    
    public func makeViewController() -> UIViewController {
        let viewControler = ResourceListViewController()
        let presenter = ResourceListPresenter(accountManager: accountManager)
        presenter.view = viewControler
        presenter.router = router
        viewControler.presenter = presenter
        return viewControler
    }
}

extension ResourceListViewController: ResourcePresenter {
    
    public var resource: Resource? {
        return presenter?.resource
    }
    
    public func present(_ resource: Resource, animated: Bool) {
        presenter?.resource = resource
    }
}
