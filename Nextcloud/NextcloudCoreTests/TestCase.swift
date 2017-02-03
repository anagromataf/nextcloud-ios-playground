//
//  TestCase.swift
//  Nextcloud
//
//  Created by Tobias Kräntzer on 02.02.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import XCTest

class TestCase: XCTestCase {
    
    var directory: URL?
    
    override func setUp() {
        super.setUp()
        
        let temp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let directory = temp.appendingPathComponent(UUID().uuidString, isDirectory: true)
        
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [:]
            )
            self.directory = directory
        } catch {
            XCTFail("Could not create temporary directory '\(directory)': \(error)")
        }
        
    }
    
    override func tearDown() {
        
        if let directory = self.directory {
            let fileManager = FileManager.default
            
            do {
                try fileManager.removeItem(at: directory)
                self.directory = nil
            } catch {
                XCTFail("Could not remove temporary directory '\(directory)': \(error)")
            }
        }
        
        super.tearDown()
    }
}
