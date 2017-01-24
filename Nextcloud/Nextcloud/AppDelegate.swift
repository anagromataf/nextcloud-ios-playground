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

        service = Service()
        
        let screen = UIScreen.main
        window = UIWindow(frame: screen.bounds)
        window?.screen = screen
        applicationModule = ApplicationModule(window: window!, service: service!)
        applicationModule?.present()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.init(uptimeNanoseconds: 100000000)) {
            let account = Account(url: URL(string: "http://could.example.com")!, username: "Romeo")
            try! self.service?.accountManager.add(account)
        }
        
        return true
    }
    
}
