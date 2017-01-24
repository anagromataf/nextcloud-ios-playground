//
//  AccountListPresenter.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 23.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import Foundation
import Fountain

class AccountListPresenter {
    
    var router: AccountListRouter?
    
    weak var view: AccountListView? {
        didSet {
            view?.dataSource = dataSource
        }
    }
    
    private let dataSource: FTMutableArray
    
    init() {
        dataSource = FTMutableArray(array: [
            ListItem(title: "Foo", subtitle: "Bar"),
            ListItem(title: "Foo", subtitle: "Bar"),
            ListItem(title: "Foo", subtitle: "Bar"),
            ListItem(title: "Foo", subtitle: "Bar"),
            ListItem(title: "Foo", subtitle: "Bar")
            ])
    }
    
    func didSelect(itemAt indexPath: IndexPath) {
        router?.present("123")
    }
    
    private class ListItem: AccountListViewModel {
        let title: String?
        let subtitle: String?
        init(title: String?, subtitle: String?) {
            self.title = title
            self.subtitle = subtitle
        }
    }
}
