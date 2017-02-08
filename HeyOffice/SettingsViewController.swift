//
//  SettingsViewController.swift
//  HeyOffice
//
//  Created by Colin Harris on 8/2/17.
//  Copyright © 2017 ThoughtWorks. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider

class SettingsViewController: UIViewController {
    
    var pool: AWSCognitoIdentityUserPool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pool = AWSCognitoIdentityUserPool(forKey: "UserPool")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logoutClicked() {
        print("logoutClicked")
        
        if let user = self.pool.currentUser() {
            user.signOut()
            user.getSession()
        }
    }
    
}
