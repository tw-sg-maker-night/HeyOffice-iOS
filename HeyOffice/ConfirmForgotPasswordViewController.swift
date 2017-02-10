//
//  ConfirmForgotPasswordViewController.swift
//  HeyOffice
//
//  Created by Colin Harris on 10/2/17.
//  Copyright © 2017 ThoughtWorks. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider

class ConfirmForgotPasswordViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var codeField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var messageLabel: UILabel!
    
    var user: AWSCognitoIdentityUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.messageLabel.text = ""
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func validate() -> Bool {
        self.messageLabel.text = ""
        
        if self.codeField.text == nil || self.codeField.text == "" {
            self.messageLabel.text = "Code required"
            return false
        }
        
        if self.passwordField.text == nil || self.passwordField.text == "" {
            self.messageLabel.text = "Password required"
            return false
        }
        
        return true
    }
    
    @IBAction func updatePasswordClicked() {
        print("updatePasswordClicked")
        if !validate() {
            return
        }
        
        self.user?.confirmForgotPassword(self.codeField.text!, password: self.passwordField.text!)
            .continueWith(block: { (task: AWSTask<AWSCognitoIdentityUserConfirmForgotPasswordResponse>) -> Any? in
                DispatchQueue.main.async {
                    if let error = task.error as? NSError {
                        self.handleError(error)
                    } else {
                        self.handleSuccess()
                    }
                }
                return nil
            })
    }
    
    func handleError(_ error: NSError) {
        let message = error.userInfo["message"] as! String
        self.messageLabel.text = message
    }
    
    func handleSuccess() {
        let _ = self.navigationController?.popToRootViewController(animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("textFieldShouldReturn")
        if textField == self.codeField {
            self.passwordField.becomeFirstResponder()
        } else if textField == self.passwordField {
            self.updatePasswordClicked()
        }
        return true
    }
    
}
