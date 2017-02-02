//
//  FileStore.swift
//  Nextcloud
//
//  Created by Tobias Kräntzer on 02.02.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import Foundation

struct FileStoreAccount: StoreAccount {
    
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    static func ==(lhs: FileStoreAccount, rhs: FileStoreAccount) -> Bool {
        return lhs.url == rhs.url
    }
    
    var hashValue: Int {
        return url.hashValue
    }
}

class FileStore: Store {
    
    typealias Account = FileStoreAccount
    
    private let queue: DispatchQueue = DispatchQueue(label: "FileStore")
    
    let directory: URL
    init(directory: URL) {
        self.directory = directory
    }
    
    func open(completion: ((Error?) -> Void)?) {
        queue.async {
            
        }
    }
    
    func close() {
        queue.sync {
            
        }
    }
    
    // Store
    
    var accounts: [Account] {
        return []
    }
    
    func addAccount(with url: URL) throws -> Account {
        return FileStoreAccount(url: url)
    }
    
    func remove(_ account: Account) throws {
        
    }
}

