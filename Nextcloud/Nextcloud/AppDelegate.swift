//
//  AppDelegate.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 23.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import UIKit
import NextcloudCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var applicationModule: ApplicationModule?
    var service: Service?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        let fileManager = FileManager.default
        let directory = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.nextcloud.Nextcloud")!
        service = Service(directory: directory)
        service?.start { (error) in
            DispatchQueue.main.async {
                if error != nil {
                    NSLog("Failed to setup service: \(error)")
                } else {
                    let screen = UIScreen.main
                    self.window = UIWindow(frame: screen.bounds)
                    self.window?.screen = screen
                    self.applicationModule = ApplicationModule(window: self.window!, service: self.service!)
                    self.applicationModule?.present()
                }
            }
        }
        
        let screen = UIScreen.main
        self.window = UIWindow(frame: screen.bounds)
        self.window?.screen = screen
        
        return true
    }
    
}
