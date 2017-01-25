//
//  ResourceListViewController.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 24.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import UIKit
import Fountain

class ResourceListViewController: UITableViewController, ResourceListView {

    var presenter: ResourceListPresenter?
    var dataSource: FTDataSource?
    
    private var tableViewAdapter: FTTableViewAdapter?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableViewAdapter = FTTableViewAdapter(tableView: tableView)
        
        tableView.register(ResourceListCell.self, forCellReuseIdentifier: "ResourceListCell")
        tableViewAdapter?.forRowsMatching(nil, useCellWithReuseIdentifier: "ResourceListCell") {
            (view, item, indexPath, dataSource) in
            if  let cell = view as? ResourceListCell,
                let account = item as? ResourceListViewModel {
                cell.textLabel?.text = account.title
                cell.detailTextLabel?.text = account.subtitle
                cell.accessoryType = .disclosureIndicator
            }
        }
        
        tableViewAdapter?.delegate = self
        tableViewAdapter?.dataSource = dataSource
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presenter?.didSelect(itemAt: indexPath)
    }

}
