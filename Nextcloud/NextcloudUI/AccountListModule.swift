//
//  AccountListModule.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 23.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import UIKit

public protocol AccountListRouter: class {
    func present(_ resource: Resource) -> Void
}

public class AccountListModule: UserInterfaceModule {
    
    public weak var router: AccountListRouter?
    
    public init() {
    }
    
    public func makeViewController() -> UIViewController {
        let viewControler = AccountListViewController()
        let presenter = AccountListPresenter()
        presenter.view = viewControler
        presenter.router = router
        viewControler.presenter = presenter
        return viewControler
    }
    
}
