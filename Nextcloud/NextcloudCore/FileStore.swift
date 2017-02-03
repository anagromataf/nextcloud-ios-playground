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
    
    typealias Account = FileStoreAccount
    
    let account: Account
    let path: [String]
    let isCollection: Bool
    let dirty: Bool
    let version: String?
    
    static func ==(lhs: FileStoreResource, rhs: FileStoreResource) -> Bool {
        return lhs.account == rhs.account && lhs.path == rhs.path
    }
    
    var hashValue: Int {
        return account.hashValue ^ path.count
    }
}

class FileStoreChangeSet: StoreChangeSet {
    typealias Resource = FileStoreResource
    var insertedOrUpdated: [Resource] = []
    var deleted: [Resource] = []
}

class FileStore: Store {
    
    typealias Account = FileStoreAccount
    typealias Resource = FileStoreResource
    typealias ChangeSet = FileStoreChangeSet
    
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
                    let isCollection = row.get(FileStoreSchema.is_collection)
                    let dirty = row.get(FileStoreSchema.dirty)
                    let version = row.get(FileStoreSchema.version)
                    resource = Resource(account: account, path: path, isCollection: isCollection, dirty: dirty, version: version)
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
                    let isCollection = row.get(FileStoreSchema.is_collection)
                    let path = self.makePath(with: row.get(FileStoreSchema.href))
                    let dirty = row.get(FileStoreSchema.dirty)
                    let version = row.get(FileStoreSchema.version)
                    let resource = Resource(account: account, path: path, isCollection: isCollection, dirty: dirty, version: version)
                    result.append(resource)
                }
            }
            
            return result
        }
    }
    
    func update(resourceAt path: [String], of account: Account, with properties: ResourceProperties?) throws -> FileStoreChangeSet {
        return try update(resourceAt: path, of: account, with: properties, content: nil)
    }
    
    func update(resourceAt path: [String], of account: Account, with properties: ResourceProperties?, content: [String:ResourceProperties]?) throws -> FileStoreChangeSet {
        return try queue.sync {
            guard
                let db = self.db
                else { throw FileStoreError.notSetup }

            let changeSet = FileStoreChangeSet()
            
            try db.transaction {
                if let properties = properties {
                    
                    if try self.updateResource(at: path, of: account, with: properties, in: db, with: changeSet) {
                        
                        var parentPath = path
                        while parentPath.count > 0 {
                            parentPath.removeLast()
                            try self.invalidateCollection(at: parentPath, of: account, in: db, with: changeSet)
                        }
                        
                        if properties.isCollection == true {
                            if let content = content {
                                try self.updateCollection(at: path, of: account, with: content, in: db, with: changeSet)
                            }
                        } else {
                            try self.clearCollection(at: path, of: account, in: db, with: changeSet)
                        }
                    }
                } else {
                    try self.removeResource(at: path, of: account, in: db, with: changeSet)
                }
            }
            
            return changeSet
        }
    }

    private func invalidateCollection(at path: [String], of account: Account, in db: SQLite.Connection, with changeSet: FileStoreChangeSet) throws {
        
        let href = self.makeHRef(with: path)
        let depth = path.count
        
        let query = FileStoreSchema.resource.filter(FileStoreSchema.account_id == account.id && FileStoreSchema.href == href)
        
        if try db.run(query.update(FileStoreSchema.dirty <- true)) == 0 {
            let insert = FileStoreSchema.resource.insert(
                FileStoreSchema.account_id <- account.id,
                FileStoreSchema.href <- href,
                FileStoreSchema.depth <- depth,
                FileStoreSchema.version <- "",
                FileStoreSchema.is_collection <- true,
                FileStoreSchema.dirty <- true)
            _ = try db.run(insert)
        }
    }
    
    private func updateResource(at path: [String], of account: Account, with properties: ResourceProperties, dirty: Bool = false, in db: SQLite.Connection, with changeSet: FileStoreChangeSet) throws -> Bool {
        
        let href = makeHRef(with: path)
        let query = FileStoreSchema.resource
                        .filter(
                            FileStoreSchema.account_id == account.id
                            && FileStoreSchema.href == href
                            && FileStoreSchema.version == properties.version)
        if try db.pluck(query) != nil {
            return false
        } else {
            _ = try db.run(FileStoreSchema.resource.insert(
                or: .replace,
                FileStoreSchema.account_id <- account.id,
                FileStoreSchema.href <- href,
                FileStoreSchema.depth <- path.count,
                FileStoreSchema.version <- properties.version,
                FileStoreSchema.is_collection <- properties.isCollection,
                FileStoreSchema.dirty <- dirty))
            let resource = Resource(account: account, path: path, isCollection: properties.isCollection, dirty: dirty, version: properties.version)
            changeSet.insertedOrUpdated.append(resource)
            return true
        }
    }
    
    private func updateCollection(at path: [String], of account: Account, with content: [String:ResourceProperties], in db: SQLite.Connection, with changeSet: FileStoreChangeSet) throws {
        
        let href = self.makeHRef(with: path)
        let hrefPattern = path.count == 0 ? "/%" : "\(href)/%"
        
        let query = FileStoreSchema.resource
            .filter( FileStoreSchema.account_id == account.id && FileStoreSchema.href.like(hrefPattern) && FileStoreSchema.depth == path.count + 1)
            .order(FileStoreSchema.href.asc)
            .select(FileStoreSchema.href, FileStoreSchema.version)
        
        var names = content.keys.sorted()
        
        var insert: [String] = []
        var update: [String] = []
        
        for row in try db.prepare(query) {
            let path = self.makePath(with: row.get(FileStoreSchema.href))
            if let currentName = path.last {
                while names.count > 0 && names[0] < currentName {
                    insert.append(names[0])
                    names.removeFirst()
                }
                
                if names.count > 0 && currentName == names[0] {
                    let name = names[0]
                    names.removeFirst()
                    let version = row.get(FileStoreSchema.version)
                    if version != content[name]?.version {
                        update.append(name)
                    }
                } else {
                    _ = try self.removeResource(at: path, of: account, in: db, with: changeSet)
                }
            }
        }
        
        for name in insert {
            guard
                let properties = content[name]
                else { continue }

            var childPath = path
            childPath.append(name)
            
            _ = try self.updateResource(at: childPath, of: account, with: properties, dirty: properties.isCollection, in: db, with: changeSet)
        }
        
        for name in update {
            guard
                let properties = content[name]
                else { continue }
            
            var childPath = path
            childPath.append(name)
            
            _ = try self.updateResource(at: childPath, of: account, with: properties, dirty: properties.isCollection, in: db, with: changeSet)
            if properties.isCollection == false {
                _ = try self.clearCollection(at: childPath, of: account, in: db, with: changeSet)
            }
        }
        
    }
    
    private func clearCollection(at path: [String], of account: Account, in db: SQLite.Connection, with changeSet: FileStoreChangeSet) throws {
        let href = self.makeHRef(with: path)
        let hrefPattern = path.count == 0 ? "/%" : "\(href)/%"
        
        let query = FileStoreSchema.resource.filter(
            FileStoreSchema.account_id == account.id
                && FileStoreSchema.href.like(hrefPattern)
                && FileStoreSchema.depth == path.count + 1)
        
        _ = try db.run(query.delete())
    }
    
    private func removeResource(at path: [String], of account: Account, in db: SQLite.Connection, with changeSet: FileStoreChangeSet) throws {
        
        let href = self.makeHRef(with: path)
        let query = FileStoreSchema.resource.filter(FileStoreSchema.account_id == account.id && FileStoreSchema.href == href)

        if try db.run(query.delete()) > 0 {
            
            let hrefPattern = path.count == 0 ? "/%" : "\(href)/%"
            
            let query = FileStoreSchema.resource.filter(
                FileStoreSchema.account_id == account.id
                    && FileStoreSchema.href.like(hrefPattern)
                    && FileStoreSchema.depth == path.count + 1)
            
            let mightBeACollection = try db.run(query.delete()) > 0
            let resource = Resource(account: account, path: path, isCollection: mightBeACollection, dirty: false, version: nil)
            changeSet.deleted.append(resource)
        }
    }
    
    private func makeHRef(with path: [String]) -> String {
        return "/\(path.joined(separator: "/"))"
    }
    
    private func makePath(with href: String) -> [String] {
        let path: [String] = href.components(separatedBy: "/")
        return Array(path.dropFirst(1))
    }
}

class FileStoreSchema {
    
    static let account = Table("account")
    static let resource = Table("resource")
    
    static let id = Expression<Int64>("id")
    static let url = Expression<URL>("url")
    static let dirty = Expression<Bool>("dirty")
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
            t.column(FileStoreSchema.account_id, references: FileStoreSchema.account, FileStoreSchema.id)
            t.column(FileStoreSchema.href, primaryKey: true)
            t.column(FileStoreSchema.depth)
            t.column(FileStoreSchema.is_collection)
            t.column(FileStoreSchema.version)
            t.column(FileStoreSchema.dirty)
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
