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
import PKHUD

class SettingsViewController: UIViewController {
    
    var pool: AWSCognitoIdentityUserPool!
    var credentialsProvider: AWSCognitoCredentialsProvider!
    var dynamoDBObjectMapper: AWSDynamoDBObjectMapper!
    var dismissKeyboardGesture: UITapGestureRecognizer!
    
    var userDetails: UserDetails?
    @IBOutlet var nameField: UITextField!
    @IBOutlet var messageLabel: UILabel!
    
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
        self.messageLabel.text = ""
        
        HUD.show(.progress)
        dynamoDBObjectMapper.load(UserDetails.self, hashKey: self.credentialsProvider.identityId!, rangeKey:nil)
            .continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
                if let error = task.error as? NSError {
                    print("The request failed. Error: \(error)")
                    self.userDetails = UserDetails()
                    DispatchQueue.main.async {
                        HUD.flash(.error, delay: 0.5)
                    }
                } else if let result = task.result as? UserDetails {
                    self.userDetails = result
                    DispatchQueue.main.async {
                        self.nameField.text = result.name
                        HUD.hide()
                    }
                }
                return nil
            })
    }
    
    @IBAction func logoutClicked() {
        print("logoutClicked")
        if let tabController = self.parent as? TabBarController {
            tabController.signOut()
        }
    }
    
    func valid() -> Bool {
        self.messageLabel.text = ""
        
        if self.userDetails!.name == nil || self.userDetails!.name == "" {
            self.messageLabel.text = "Name required"
            return false
        }
        
        return true
    }
    
    @IBAction func updateClicked() {
        print("updateClicked")
        if !valid() {
            return
        }
        
        HUD.show(.progress)
        self.userDetails!.name = self.nameField.text
        
        self.dynamoDBObjectMapper.save(self.userDetails!).continueWith(block: { (task: AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as? NSError {
                DispatchQueue.main.async {
                    HUD.flash(.error, delay: 0.5)
                    self.messageLabel.text = AWSErrorMessageParser.parse(error)
                }
            } else {
                DispatchQueue.main.async {
                    HUD.flash(.success, delay: 0.5)
                }
            }
            return nil
        })
    }
}
