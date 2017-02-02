//
//  FileStoreTests.swift
//  Nextcloud
//
//  Created by Tobias Kräntzer on 02.02.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import XCTest
@testable import NextcloudCore

class FileStoreTests: TestCase {
    
    var store: FileStore?
    
    override func setUp() {
        super.setUp()
        
        guard
            let directory = self.directory
            else { XCTFail(); return }
        
        let store = FileStore(directory: directory)
        
        let expectation = self.expectation(description: "Open DB")
        store.open { (error) in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)
        
        self.store = store
    }
    
    func testManageAccounts() {
        guard
            let store = self.store
            else { XCTFail(); return }

        do {
            let url = URL(string: "https://example.com/api/")!
            let account: FileStore.Account = try store.addAccount(with: url)
            XCTAssertEqual(account.url, url)
            
            XCTAssertTrue(store.accounts.contains(account))
            
            try store.remove(account)
            XCTAssertFalse(store.accounts.contains(account))
            
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testUpdateStore() {
        guard
            let store = self.store
            else { XCTFail(); return }
        
        do {
            let url = URL(string: "https://example.com/api/")!
            let account: FileStore.Account = try store.addAccount(with: url)
            
            let updates = [
                Update(url: url.appendingPathComponent("foo/bar.baz"), isCollection: false, version: "123"),
                Update(url: url.appendingPathComponent("foo/a"), isCollection: true, version: "123"),
                Update(url: url.appendingPathComponent("foo/a/x"), isCollection: false, version: "123"),
                Update(url: url.appendingPathComponent("foo/b"), isCollection: false, version: "123"),
                Update(url: url.appendingPathComponent("foo"), isCollection: true, version: "123"),
                Update(url: url.appendingPathComponent("bar/c"), isCollection: false, version: "123")
            ]
            
            try store.update(account, with: updates)
            
            let resource = try store.resource(of: account, at: ["foo", "bar.baz"])
            XCTAssertNotNil(resource)
            XCTAssertEqual(resource?.path ?? [], ["foo", "bar.baz"])
            
            let content = try store.contents(of: account, at: ["foo"])
            XCTAssertEqual(content.count, 3)
            
        } catch {
            XCTFail("\(error)")
        }
        
    }
    
    struct Update: StoreUpdate {
        let url: URL
        let isCollection: Bool
        let version: String
    }
    
}
