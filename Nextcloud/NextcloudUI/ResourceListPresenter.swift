//
//  ResourceListPresenter.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 24.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import Foundation
import NextcloudCore

class ResourceListPresenter {
    
    var router: ResourceListRouter?
    
    weak var view: ResourceListView? {
        didSet {
            view?.dataSource = dataSource
        }
    }
    
    var resource: Resource? {
        didSet {
            guard
                let collection = resource as? Directory
                else {
                    dataSource = nil
                    return
            }
            
            let resourceManager = accountManager.resourceManager(for: collection.account)
            dataSource = ResourceListDataSource(resourceManager: resourceManager, resource: collection)
        }
    }
    
    private var dataSource: ResourceListDataSource? {
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
