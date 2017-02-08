//
//  LoginViewController.swift
//  HeyOffice
//
//  Created by Colin Harris on 8/2/17.
//  Copyright © 2017 ThoughtWorks. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider

class LoginViewController: UIViewController, AWSCognitoIdentityPasswordAuthentication, UITextFieldDelegate {
    
    @IBOutlet var usernameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var messageLabel: UILabel!
    
    var passwordAuthenticationCompletion: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.messageLabel.text = ""
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getDetails(_ authenticationInput: AWSCognitoIdentityPasswordAuthenticationInput, passwordAuthenticationCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>) {
        print("LoginViewController.getDetails")
        
        
        self.passwordAuthenticationCompletion = passwordAuthenticationCompletionSource;
        DispatchQueue.main.async {
            if self.usernameField.text == nil {
               self.usernameField.text = authenticationInput.lastKnownUsername
            }
        }
    }
    
    func didCompleteStepWithError(_ error: Error?) {
        print("LoginViewController.didCompleteStepWithError")
        if let error = error as? NSError {
            print("Error = \(error.localizedDescription)")
            print("UserInfo.__type = \(error.userInfo["__type"])")
            print("UserInfo.message = \(error.userInfo["message"])")
            DispatchQueue.main.async {
                self.messageLabel.text = error.userInfo["message"] as! String?
            }
        }
    }
    
    @IBAction func loginClicked() {
        print("loginClicked")
        print("username = \(self.usernameField.text)")
        print("password = \(self.passwordField.text)")
        
        self.messageLabel.text = ""
        
        let result = AWSCognitoIdentityPasswordAuthenticationDetails(username: self.usernameField.text!, password: self.passwordField.text!)
        self.passwordAuthenticationCompletion?.set(result: result)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("textFieldShouldReturn")
        if textField == self.usernameField {
            self.passwordField.becomeFirstResponder()
        } else if textField == self.passwordField {
            self.loginClicked()
        }
        
        return true
    }
    
}

