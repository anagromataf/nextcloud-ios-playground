//
//  FileListView.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 24.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import UIKit
import Fountain

protocol FileListViewModel : class {
    var title: String? { get }
    var subtitle: String? { get }
}

protocol FileListView : class {
    var dataSource: FTDataSource? { get set }
}
