//
//  ConfirmForgotPasswordViewController.swift
//  HeyOffice
//
//  Created by Colin Harris on 10/2/17.
//  Copyright © 2017 ThoughtWorks. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider
import PKHUD

class ConfirmForgotPasswordViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var codeField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var messageLabel: UILabel!
    
    var user: AWSCognitoIdentityUser?
    var initialCodeValue: String?
    var dismissKeyboardGesture: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.messageLabel.text = ""
        
        self.dismissKeyboardGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.dismissKeyboard))
        self.dismissKeyboardGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(dismissKeyboardGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.codeField?.text = self.initialCodeValue
    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func valid() -> Bool {
        self.messageLabel.text = ""
        
        if self.codeField.text == nil || self.codeField.text == "" {
            self.messageLabel.text = "Confirmation code required"
            return false
        }
        
        if self.passwordField.text == nil || self.passwordField.text == "" {
            self.messageLabel.text = "New password required"
            return false
        }
        
        return true
    }
    
    @IBAction func updatePasswordClicked() {
        print("updatePasswordClicked")
        if !valid() {
            return
        }
        HUD.show(.progress)
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
        self.messageLabel.text = AWSErrorMessageParser.parse(error)
        HUD.flash(.error, delay: 0.5)
    }
    
    func handleSuccess() {
        HUD.flash(.success, delay: 0.5) { flag in
            let _ = self.navigationController?.popToRootViewController(animated: true)
        }
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
