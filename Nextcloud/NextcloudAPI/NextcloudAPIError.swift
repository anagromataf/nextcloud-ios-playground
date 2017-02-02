//
//  NextcloudAPIError.swift
//  Nextcloud
//
//  Created by Tobias Kräntzer on 02.02.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import Foundation

public enum NextcloudAPIError: Error {
    case internalError
    case invalidResponse(statusCode: Int)
}
