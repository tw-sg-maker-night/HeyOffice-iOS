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
import OAuthSwift

class SettingsViewController: UIViewController {
    
    var pool: AWSCognitoIdentityUserPool!
    var credentialsProvider: AWSCognitoCredentialsProvider!
    var dynamoDBObjectMapper: AWSDynamoDBObjectMapper!
    var dismissKeyboardGesture: UITapGestureRecognizer!
    var oauthswift: OAuth2Swift!
    
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

        oauthswift = OAuth2Swift(
            consumerKey:    UberConsumerKey,
            consumerSecret: UberConsumerSecret,
            authorizeUrl:   UberAuthorizeUrl,
            accessTokenUrl: UberAccessTokenUrl,
            responseType:   "code"
        )

    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.messageLabel.text = ""
        disableNameField()
        self.credentialsProvider.getIdentityId().continueWith(block: { (task: AWSTask<NSString>) -> Any? in
            if let error = task.error as? NSError {
                DispatchQueue.main.async {
                    self.messageLabel.text = AWSErrorMessageParser.parse(error)
                }
            } else {
                self.loadUserDetails(identityId: task.result! as String)
            }
            return nil
        })
    }
    
    func loadUserDetails(identityId: String) {
        dynamoDBObjectMapper.load(UserDetails.self, hashKey: identityId, rangeKey:nil)
            .continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
                DispatchQueue.main.async {
                    if let error = task.error as? NSError {
                        self.nameField.placeholder = "Error"
                        self.messageLabel.text = AWSErrorMessageParser.parse(error)
                        return
                    }
                    
                    if let result = task.result as? UserDetails {
                        self.userDetails = result
                    } else {
                        self.userDetails = UserDetails()
                        self.userDetails?.userId = self.credentialsProvider.identityId
                    }
                    self.enableNameField()
                }
                return nil
            })
    }
    
    func disableNameField() {
        self.nameField.text = ""
        self.nameField.placeholder = "Loading..."
        self.nameField.isEnabled = false
    }
    
    func enableNameField() {
        self.nameField.text = self.userDetails?.name
        self.nameField.placeholder = "Name"
        self.nameField.isEnabled = true
    }
    
    @IBAction func logoutClicked() {
        print("logoutClicked")
        if let tabController = self.tabBarController as? TabBarController {
            tabController.signOut()
        }
    }
    
    func valid() -> Bool {
        self.messageLabel.text = ""
        
        if self.nameField!.text == nil || self.nameField!.text == "" {
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
        
        self.userDetails!.name = self.nameField.text
        
        self.saveUserDetail()
    }
    
    @IBAction
    func signInToUber() {
        print("starting oauth to uber")
        let _ = oauthswift.authorize(
            withCallbackURL: URL(string: "heyoffice://authenticate_uber/uber")!,
            scope: "profile",
            state: "UBER",
            success: { credential, response, parameters in
                self.userDetails!.uberOAuthToken = credential.oauthToken
                self.userDetails!.uberOAuthRefreshToken = credential.oauthRefreshToken
                
                self.saveUserDetail()
            },
            failure: { error in
                print(error.localizedDescription)
            }
        )
    }
    
    func saveUserDetail() {
        DispatchQueue.main.async {
            HUD.show(.progress)
        }
        
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
