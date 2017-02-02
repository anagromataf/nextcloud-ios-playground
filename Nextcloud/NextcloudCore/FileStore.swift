//
//  FileStore.swift
//  Nextcloud
//
//  Created by Tobias Kräntzer on 02.02.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import Foundation
import SQLite

enum FileStoreError: Error {
    case notSetup
    case internalError
}

struct FileStoreAccount: StoreAccount {
    
    let id: Int64
    let url: URL
    
    init(id: Int64, url: URL) {
        self.id = id
        self.url = url
    }
    
    static func ==(lhs: FileStoreAccount, rhs: FileStoreAccount) -> Bool {
        return lhs.id == rhs.id
    }
    
    var hashValue: Int {
        return id.hashValue
    }
}

struct FileStoreResource: StoreResource {
    
    let id: Int64
    let path: [String]
    let isCollection: Bool
    
    static func ==(lhs: FileStoreResource, rhs: FileStoreResource) -> Bool {
        return lhs.id == rhs.id
    }
    
    var hashValue: Int {
        return id.hashValue
    }
}

class FileStore: Store {
    
    typealias Account = FileStoreAccount
    typealias Resource = FileStoreResource
    
    private let queue: DispatchQueue = DispatchQueue(label: "FileStore")
    
    let directory: URL
    init(directory: URL) {
        self.directory = directory
    }
    
    private var db: SQLite.Connection?
    
    // MARK: - Open & Close
    
    func open(completion: ((Error?) -> Void)?) {
        queue.async {
            do {
                try self.open()
                completion?(nil)
            } catch {
                completion?(error)
            }
        }
    }
    
    func close() {
        queue.sync {
            self.db = nil
        }
    }
    
    private func open() throws {
        let setup = FileStoreSchema(directory: directory)
        db = try setup.create()
    }
    
    // Store
    
    var accounts: [Account] {
        return queue.sync {
            do {
                return try self.fetchAccounts()
            } catch {
                NSLog("Failed to fetch accounts: \(error)")
                return []
            }
        }
    }
    
    private func fetchAccounts() throws -> [Account] {
        guard
            let db = self.db
            else { throw FileStoreError.notSetup }
        var result: [Account] = []
        try db.transaction {
            let query = FileStoreSchema.account.select([
                    FileStoreSchema.id,
                    FileStoreSchema.url
                ])
            for row in try db.prepare(query) {
                let account = try self.makeAcocunt(with: row)
                result.append(account)
            }
        }
        return result
    }
    
    private func makeAcocunt(with row: SQLite.Row) throws -> Account {
        let id = row.get(FileStoreSchema.id)
        let url = row.get(FileStoreSchema.url)
        return Account(id: id, url: url)
    }
    
    func addAccount(with url: URL) throws -> Account {
        return try queue.sync {
            guard
                let db = self.db
                else { throw FileStoreError.notSetup }
            
            var account: Account? = nil
            try db.transaction {
                let standardizedURL = url.standardized
                let insert = FileStoreSchema.account.insert(FileStoreSchema.url <- standardizedURL)
                let id = try db.run(insert)
                account = Account(id: id, url: standardizedURL)
            }
            
            guard
                let result = account
                else { throw FileStoreError.internalError }
            
            DispatchQueue.main.async {
                let center = NotificationCenter.default
                center.post(name: Notification.Name.StoreDidAddAccount,
                            object: self,
                            userInfo: [StoreAccountKey: result])
            }
            
            return result
        }
    }
    
    func remove(_ account: Account) throws {
        try queue.sync {
            guard
                let db = self.db
                else { throw FileStoreError.notSetup }
            
            try db.transaction {
                let delete = FileStoreSchema.account.filter(FileStoreSchema.id == account.id).delete()
                try db.run(delete)
            }
            
            DispatchQueue.main.async {
                let center = NotificationCenter.default
                center.post(name: Notification.Name.StoreDidRemoveAccount,
                            object: self,
                            userInfo: [StoreAccountKey: account])
            }
        }
    }
    
    func resource(of account: Account, at path: [String]) throws -> Resource? {
        return try queue.sync {
            guard
                let db = self.db
                else { throw FileStoreError.notSetup }
            
            var resource: Resource? = nil
            
            try db.transaction {
                
                let href = self.makeHRef(with: path)
                
                let query = FileStoreSchema.resource.filter(
                    FileStoreSchema.account_id == account.id &&
                    FileStoreSchema.href == href)
                
                if let row = try db.pluck(query) {
                    let id = row.get(FileStoreSchema.id)
                    let isCollection = row.get(FileStoreSchema.is_collection)
                    resource = Resource(id: id, path: path, isCollection: isCollection)
                }
            }
            return resource
        }
    }
    
    func contents(of account: FileStoreAccount, at path: [String]) throws -> [FileStoreResource] {
        return try queue.sync {
            guard
                let db = self.db
                else { throw FileStoreError.notSetup }
            
            var result: [Resource] = []
            
            try db.transaction {
                
                let href = self.makeHRef(with: path)
                let hrefPattern = path.count == 0 ? "/%" : "\(href)/%"
                
                let query = FileStoreSchema.resource.filter(
                    FileStoreSchema.account_id == account.id
                    && FileStoreSchema.href.like(hrefPattern)
                    && FileStoreSchema.depth == path.count + 1)
                
                for row in try db.prepare(query) {
                    let id = row.get(FileStoreSchema.id)
                    let isCollection = row.get(FileStoreSchema.is_collection)
                    let path = self.makePath(with: row.get(FileStoreSchema.href))
                    let resource = Resource(id: id, path: path, isCollection: isCollection)
                    result.append(resource)
                }
            }
            
            return result
        }
    }

    func update(_ account: Account, with updates: [StoreUpdate]) throws {
        try queue.sync {
            guard
                let db = self.db
                else { throw FileStoreError.notSetup }
            
            var result: [Resource] = []
            
            try db.transaction {
                for update in updates {
                    
                    guard
                        let path = update.url.pathComponents(relativeTo: account.url)
                        else { throw FileStoreError.internalError }
                    
                    let depth = path.count
                    let href = self.makeHRef(with: path)
                    
                    let id = try db.run(FileStoreSchema.resource.insert(
                        or: .replace,
                        FileStoreSchema.account_id <- account.id,
                        FileStoreSchema.href <- href,
                        FileStoreSchema.depth <- depth,
                        FileStoreSchema.version <- update.version,
                        FileStoreSchema.is_collection <- update.isCollection))
                    
                    let resource = Resource(id: id, path: path, isCollection: update.isCollection)
                    result.append(resource)
                }
            }
            
            DispatchQueue.main.async {
                let center = NotificationCenter.default
                center.post(name: Notification.Name.StoreDidRemoveAccount,
                            object: self,
                            userInfo: [StoreAccountKey: account,
                                       StoreResourcesKey: result])
            }
        }
    }
    
    private func makeHRef(with path: [String]) -> String {
        return "/\(path.joined(separator: "/"))"
    }
    
    private func makePath(with href: String) -> [String] {
        let path: [String] = href.components(separatedBy: "/")
        return Array(path.dropFirst(0))
    }
}

class FileStoreSchema {
    
    static let account = Table("account")
    static let resource = Table("resource")
    
    static let id = Expression<Int64>("id")
    static let url = Expression<URL>("url")
    static let href = Expression<String>("href")
    static let depth = Expression<Int>("depth")
    static let version = Expression<String>("version")
    static let is_collection = Expression<Bool>("is_collection")
    static let account_id = Expression<Int64>("account_id")
    
    
    let directory: URL
    required init(directory: URL) {
        self.directory = directory
    }
    
    func create() throws -> SQLite.Connection {
        let db = try createDatabase()
        
        switch readCurrentVersion() {
        case 0:
            try setup(db)
            try writeCurrentVersion(1)
        default:
            break
        }
        
        return db
    }
    
    // MARK: Database
    
    private func createDatabase() throws -> SQLite.Connection {
        let db = try Connection(databaseLocation.path)
        
        db.busyTimeout = 5
        db.busyHandler({ tries in
            if tries >= 3 {
                return false
            }
            return true
        })
        
        return db
    }
    
    private func setup(_ db: SQLite.Connection) throws {
        try db.run(FileStoreSchema.account.create { t in
            t.column(FileStoreSchema.id, primaryKey: true)
            t.column(FileStoreSchema.url, unique: true)
        })
        try db.run(FileStoreSchema.account.createIndex(FileStoreSchema.url))
        try db.run(FileStoreSchema.resource.create { t in
            t.column(FileStoreSchema.id, primaryKey: true)
            t.column(FileStoreSchema.account_id, references: FileStoreSchema.account, FileStoreSchema.id)
            t.column(FileStoreSchema.href)
            t.column(FileStoreSchema.depth)
            t.column(FileStoreSchema.is_collection)
            t.column(FileStoreSchema.version)
            t.unique([FileStoreSchema.account_id, FileStoreSchema.href])
            t.foreignKey(FileStoreSchema.account_id, references: FileStoreSchema.account, FileStoreSchema.id, update: .noAction, delete: .cascade)
        })
        try db.run(FileStoreSchema.resource.createIndex(FileStoreSchema.href))
        try db.run(FileStoreSchema.resource.createIndex(FileStoreSchema.depth))
    }
    
    private var databaseLocation: URL {
        return directory.appendingPathComponent("db.sqlite", isDirectory: false)
    }
    
    // MARK: Version
    
    var version: Int {
        return readCurrentVersion()
    }
    
    private func readCurrentVersion() -> Int {
        let url = directory.appendingPathComponent("version.txt")
        do {
            let versionText = try String(contentsOf: url)
            guard let version = Int(versionText) else { return 0 }
            return version
        } catch {
            return 0
        }
    }
    
    private func writeCurrentVersion(_ version: Int) throws {
        let url = directory.appendingPathComponent("version.txt")
        let versionData = String(version).data(using: .utf8)
        try versionData?.write(to: url)
    }
}

extension URL: Value {
    public static var declaredDatatype: String {
        return String.declaredDatatype
    }
    public static func fromDatatypeValue(_ datatypeValue: String) -> URL {
        return URL(string: datatypeValue)!
    }
    public var datatypeValue: String {
        return self.absoluteString
    }
}
