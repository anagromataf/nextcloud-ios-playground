//
//  FileListViewController.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 24.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import UIKit
import Fountain

class FileListViewController: UITableViewController, FileListView {

    var presenter: FileListPresenter?
    var dataSource: FTDataSource?
    
    private var tableViewAdapter: FTTableViewAdapter?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableViewAdapter = FTTableViewAdapter(tableView: tableView)
        
        tableView.register(FileListCell.self, forCellReuseIdentifier: "FileListCell")
        tableViewAdapter?.forRowsMatching(nil, useCellWithReuseIdentifier: "FileListCell") {
            (view, item, indexPath, dataSource) in
            if  let cell = view as? FileListCell,
                let account = item as? FileListViewModel {
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
