//
//  AppDelegate.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 23.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import UIKit
import NextcloudCore
import NextcloudUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, ServiceDelegate {

    var window: UIWindow?
    var applicationModule: ApplicationModule?
    var service: Service?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        let fileManager = FileManager.default
        let directory = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.nextcloud.Nextcloud")!
        service = Service(directory: directory)
        service?.delegate = self
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
    
    // MARK: ServiceDelegate
    
    func service(_ service: Service, needsPasswordFor account: Account, completionHandler: @escaping (String?) -> Void) {
        guard
            let passwordPromt = window?.rootViewController as? PasswordPromt
            else {
                completionHandler(nil)
                return
        }
        
        passwordPromt.requestPassword(for: account, completion: completionHandler)
    }
    
}
