//
//  TabBarController.swift
//  HeyOffice
//
//  Created by Colin Harris on 8/2/17.
//  Copyright © 2017 ThoughtWorks. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider

class TabBarController: UITabBarController {
    
    var pool: AWSCognitoIdentityUserPool?
    var user: AWSCognitoIdentityUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pool = AWSCognitoIdentityUserPool(forKey: "UserPool")
        if self.user == nil {
            self.user = self.pool?.currentUser()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("TabBarController.viewWillAppear")
        print("checking user is logged in...")
        print("Is signed in = \(self.user?.isSignedIn)")
        self.user?.getSession().continueWith(block: { (task: AWSTask<AWSCognitoIdentityUserSession>) -> Any? in
            print("TabBarController.getSession task completed")
            
            if let error = task.error {
                print("Error \(error.localizedDescription)")
            } else {
                print("No error")
            }
            
            return nil
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
}
