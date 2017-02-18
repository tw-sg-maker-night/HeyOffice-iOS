//
//  SettingsViewController.swift
//  HeyOffice
//
//  Created by Colin Harris on 8/2/17.
//  Copyright © 2017 ThoughtWorks. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider
import AWSDynamoDB

class SettingsViewController: UIViewController {
    
    var pool: AWSCognitoIdentityUserPool!
    var credentialsProvider: AWSCognitoCredentialsProvider!
    var dynamoDBObjectMapper: AWSDynamoDBObjectMapper!
    var dismissKeyboardGesture: UITapGestureRecognizer!
    
    var userDetails: UserDetails?
    @IBOutlet var nameField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pool = AWSCognitoIdentityUserPool(forKey: "UserPool")
        self.credentialsProvider = AWSServiceManager.default().defaultServiceConfiguration.credentialsProvider as! AWSCognitoCredentialsProvider
        self.dynamoDBObjectMapper = AWSDynamoDBObjectMapper(forKey: "UserDetails")
        
        self.dismissKeyboardGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.dismissKeyboard))
        self.dismissKeyboardGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(dismissKeyboardGesture)
    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        dynamoDBObjectMapper.load(UserDetails.self, hashKey: self.credentialsProvider.identityId!, rangeKey:nil)
            .continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
                if let error = task.error as? NSError {
                    print("The request failed. Error: \(error)")
                    self.userDetails = UserDetails()
                } else if let result = task.result as? UserDetails {
                    self.userDetails = result
                    DispatchQueue.main.async {
                        self.nameField.text = result.name
                    }
                }
                return nil
            })
    }
    
    @IBAction func logoutClicked() {
        print("logoutClicked")
        
        if let user = self.pool.currentUser() {
            user.signOut()
            user.getSession()
        }
    }
    
    @IBAction func updateClicked() {
        print("updateClicked")
        
        self.userDetails!.name = self.nameField.text
        
        self.dynamoDBObjectMapper.save(self.userDetails!).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as? NSError {
                print("The request failed. Error: \(error)")
            } else {
                print("Success!")
            }
            return nil
        })
    }
}
