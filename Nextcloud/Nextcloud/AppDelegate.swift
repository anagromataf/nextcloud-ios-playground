//
//  AppDelegate.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 23.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var applicationModule: ApplicationModule?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        let screen = UIScreen.main
        window = UIWindow(frame: screen.bounds)
        window?.screen = screen
        applicationModule = ApplicationModule(window: window!)
        applicationModule?.present()
        
        return true
    }
    
}
