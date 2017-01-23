//
//  AccountListModule.swift
//  Nextcloud
//
//  Created by Tobias Kraentzer on 23.01.17.
//  Copyright © 2017 Nextcloud. All rights reserved.
//

import UIKit

public class AccountListModule: UserInterfaceModule {
    
    public init() {
    }
    
    public func makeViewController() -> UIViewController {
        let viewControler = UIViewController()
        viewControler.view.backgroundColor = UIColor.green
        return viewControler
    }
    
}
