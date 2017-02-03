//
//  AccountListPresenter.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 23.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import Foundation
import Fountain
import NextcloudCore

class AccountListPresenter {
    
    var router: AccountListRouter?
    
    weak var view: AccountListView? {
        didSet {
            view?.dataSource = dataSource
        }
    }
    
    private let dataSource: AccountListDataSource
    
    let accountManager: AccountManager
    
    init(accountManager: AccountManager) {
        self.accountManager = accountManager
        dataSource = AccountListDataSource(accountManager: accountManager)
    }
    
    // MARK: - Actions
    
    func didSelect(itemAt indexPath: IndexPath) {
        do {
            guard
                let account = dataSource.account(at: indexPath),
                let resource = try accountManager.resourceManager(for: account).resource(at: [])
                else { return }
            
            router?.present(resource)
        } catch {
            NSLog("Faield to get resource: \(error)")
        }
    }
    
    func addAccount() {
        router?.presentNewAccount()
    }
}
