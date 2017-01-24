//
//  FileListModule.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 24.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import UIKit
import NextcloudCore

public protocol FileListRouter: class {
    func present(_ resource: Resource) -> Void
}

public class FileListModule: UserInterfaceModule {
    
    public weak var router: FileListRouter?
    
    public let accountManager: AccountManager
    public init(accountManager: AccountManager) {
        self.accountManager = accountManager
    }
    
    public func makeViewController() -> UIViewController {
        let viewControler = FileListViewController()
        let presenter = FileListPresenter(accountManager: accountManager)
        presenter.view = viewControler
        presenter.router = router
        viewControler.presenter = presenter
        return viewControler
    }
}
