//
//  Resource.swift
//  Nextcloud
//
//  Created by Tobias Kräntzer on 02.02.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import Foundation
import PureXML

extension NextcloudAPI {
    public struct Resource {
        public let url: URL
        public let version: String
        public let collection: Bool
    }
}

extension NextcloudAPI.Resource {
    
    static func makeResources(with document: PXDocument, baseURL: URL) throws -> [NextcloudAPI.Resource] {
        guard
            document.root.qualifiedName == PXQName(name: "multistatus", namespace: "DAV:")
            else { throw NextcloudAPIError.internalError }
        
        var internalError: Error? = nil
        var result: [NextcloudAPI.Resource] = []
        
        document.root.enumerateElements { (element, stop) in
            do {
                let resource = try makeResource(with: element, baseURL: baseURL)
                result.append(resource)
            } catch {
                internalError = error
            }
        }
        
        if let error = internalError {
            throw error
        } else {
            return result
        }
    }
    
    static func makeResource(with element: PXElement, baseURL: URL) throws -> NextcloudAPI.Resource {
        
        let namespace = ["d":"DAV:"]
        
        guard
            let urlElement = element.nodes(forXPath: "./d:href", usingNamespaces: namespace).first as? PXElement,
            let urlString = urlElement.stringValue,
            let url = URL(string: urlString, relativeTo: baseURL)
            else { throw NextcloudAPIError.internalError }
        
        guard
            let etagElement = element.nodes(forXPath: "./d:propstat/d:prop/d:getetag", usingNamespaces: namespace).first as? PXElement,
            let etagString = etagElement.stringValue,
            let version = String(htmlEncodedString: etagString)
            else { throw NextcloudAPIError.internalError }
        
        let isCollection = element.nodes(forXPath: "./d:propstat/d:prop/d:resourcetype/d:collection", usingNamespaces: namespace).count > 0
        
        return NextcloudAPI.Resource(url: url, version: version, collection: isCollection)
    }
    
}
