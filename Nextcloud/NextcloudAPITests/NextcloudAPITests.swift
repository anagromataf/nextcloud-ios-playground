//
//  NextcloudAPITests.swift
//  NextcloudAPITests
//
//  Created by Tobias Kräntzer on 01.02.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import XCTest
@testable import NextcloudAPI

class NextcloudAPITests: XCTestCase, NextcloudAPIDelegate {
    
    func testAPI() {
        
        let api = NextcloudAPI(identifier: "123")
        api.delegate = self
        
        let expectation = self.expectation(description: "Response")
        api.properties(of: URL(string: "https://cloud.example.org/webdav/")!) { (resources, error) in
            
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    // MARK: - NextcloudAPIDelegate
    
    func nextcloudAPI(_ api: NextcloudAPI, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.host == "cloud.example.org" {
            completionHandler(.useCredential, URLCredential(user: "username", password: "password", persistence: .forSession))
        } else {
            completionHandler(.rejectProtectionSpace, nil)
        }
    }
    
}
