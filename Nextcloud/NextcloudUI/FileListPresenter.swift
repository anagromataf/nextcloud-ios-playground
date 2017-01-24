//
//  FileListPresenter.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 24.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import Foundation
import NextcloudCore

class FileListPresenter {
    
    var router: FileListRouter?
    
    weak var view: FileListView? {
        didSet {
            view?.dataSource = dataSource
        }
    }
    
    var resource: Resource? {
        didSet {
            guard
                let folderResource = resource as? Folder
                else {
                    dataSource = nil
                    return
            }
            
            let resourceManager = accountManager.resourceManager(for: folderResource.account)
            dataSource = FileListDataSource(resourceManager: resourceManager, resource: folderResource)
        }
    }
    
    private var dataSource: FileListDataSource? {
        didSet {
            view?.dataSource = dataSource
        }
    }
    
    let accountManager: AccountManager
    
    init(accountManager: AccountManager) {
        self.accountManager = accountManager
    }
    
    // MARK: - Actions
    
    func didSelect(itemAt indexPath: IndexPath) {
        guard
            let resource = dataSource?.resource(at: indexPath)
            else { return }
        router?.present(resource)
    }
    
}
