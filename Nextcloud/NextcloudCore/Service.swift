//
//  Service.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 24.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import Foundation
import Dispatch

public class Service {
    
    public private(set) var accountManager: AccountManager
    
    private let store: FileStore
    
    public init(directory: URL) {
        self.store = FileStore(directory: directory)
        self.accountManager = AccountManager(store: store)
    }
    
    public func start(completion: ((Error?)->Void)?) {
        store.open(completion: completion)
    }
}
