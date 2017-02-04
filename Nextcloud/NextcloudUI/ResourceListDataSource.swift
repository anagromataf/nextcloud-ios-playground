//
//  ResourceListDataSource.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 24.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import Foundation
import Fountain
import NextcloudCore

class ResourceListDataSource: NSObject, FTDataSource {
    
    let resourceManager: ResourceManager
    let resource: Resource
    
    init(resourceManager: ResourceManager, resource: Resource) {
        self.resourceManager = resourceManager
        self.resource = resource
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(resourceManagerDidChange(_:)),
                                               name: Notification.Name.ResourceManagerDidChange,
                                               object: resourceManager)
        reload()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func resourceManagerDidChange(_ notification: Notification) {
        DispatchQueue.main.async {
            
            if let insertedOrUpdate = notification.userInfo?[InsertedOrUpdatedResourcesKey] as? [Resource] {
                for resource in insertedOrUpdate {
                    if self.resource.path.starts(with: resource.path)  {
                        self.reload()
                        return
                    }
                }
            }
            
            if let deleted = notification.userInfo?[DeletedResourcesKey] as? [Resource] {
                for resource in deleted {
                    if self.resource.path.starts(with: resource.path)  {
                        self.reload()
                        return
                    }
                }
            }
        }
    }
 
    private var resources: [Resource] = []
    
    private func reload() {
        do {
            let resources = try resourceManager.content(at: resource.path)
            for observer in _observers.allObjects {
                observer.dataSourceWillReset?(self)
            }
            self.resources = resources
            for observer in _observers.allObjects {
                observer.dataSourceDidReset?(self)
            }
        } catch {
            NSLog("Failed to get resources: \(error)")
        }
    }
    
    func resource(at indexPath: IndexPath) -> Resource? {
        if indexPath.section == 0 {
            return resources[indexPath.item]
        } else {
            return nil
        }
    }
    
    // MARK: - FTDataSource
    
    func numberOfSections() -> UInt {
        return 1
    }
    
    func numberOfItems(inSection section: UInt) -> UInt {
        return UInt(resources.count)
    }
    
    func sectionItem(forSection section: UInt) -> Any! {
        return nil
    }
    
    func item(at indexPath: IndexPath!) -> Any! {
        if indexPath.section == 0 {
            let resource = resources[indexPath.item]
            return ViewModel(resource: resource)
        } else {
            return nil
        }
    }
    
    private let _observers: NSHashTable = NSHashTable<FTDataSourceObserver>.weakObjects()
    
    func observers() -> [Any]! {
        return _observers.allObjects
    }
    
    func addObserver(_ observer: FTDataSourceObserver!) {
        if _observers.contains(observer) == false {
            _observers.add(observer)
        }
    }
    
    public func removeObserver(_ observer: FTDataSourceObserver!) {
        _observers.remove(observer)
    }
    
    class ViewModel: ResourceListViewModel {
        
        var title: String? {
            return resource.path.last
        }
        
        var subtitle: String? {
            return resource.path.joined(separator: "/")
        }
        
        let resource: Resource
        
        init(resource: Resource) {
            self.resource = resource
        }
    }
    
}
