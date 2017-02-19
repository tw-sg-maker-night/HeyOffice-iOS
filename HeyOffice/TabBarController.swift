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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkIfLoggedIn()
    }
    
    func signOut() {
        user?.signOut()
        showVoiceCommandTab()
        checkIfLoggedIn()
    }
    
    func checkIfLoggedIn() {
        user?.getSession().continueWith(block: { (task: AWSTask<AWSCognitoIdentityUserSession>) -> Any? in
            if let error = task.error {
                print("Error \(error.localizedDescription)")
                return nil
            }
            self.presentedViewController?.dismiss(animated: true, completion: nil)
            return nil
        })
    }
    
    func showVoiceCommandTab() {
        self.selectedIndex = 0
    }
}
