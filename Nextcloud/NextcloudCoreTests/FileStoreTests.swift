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
    
    func testManageAccounts() {
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
    
}
