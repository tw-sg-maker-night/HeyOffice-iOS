//
//  ConfirmRegistrationViewController.swift
//  HeyOffice
//
//  Created by Colin Harris on 9/2/17.
//  Copyright © 2017 ThoughtWorks. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider
import PKHUD

class ConfirmRegistrationViewController: UIViewController, UITextFieldDelegate {
    
    var user: AWSCognitoIdentityUser!
    var initialCodeValue: String?
    var dismissKeyboardGesture: UITapGestureRecognizer!
    
    @IBOutlet var emailField: UITextField?
    @IBOutlet var codeField: UITextField?
    @IBOutlet var messageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dismissKeyboardGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.dismissKeyboard))
        self.dismissKeyboardGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(dismissKeyboardGesture)
    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.codeField?.text = self.initialCodeValue
        self.emailField?.text = self.user.username
        self.messageLabel.text = ""
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.codeField?.text = self.initialCodeValue
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func valid() -> Bool {
        if self.codeField?.text == nil || self.codeField?.text == "" {
            self.messageLabel.text = "Confirmation code required"
            return false
        }
        
        if self.emailField?.text == nil || self.emailField?.text == "" {
            self.messageLabel.text = "Email required"
            return false
        }
        
        return true
    }
    
    @IBAction func confirmClicked() {
        print("confirmClicked")
        if !valid() {
            return
        }
        HUD.show(.progress)
        self.user.confirmSignUp(self.codeField!.text!, forceAliasCreation: true)
            .continueWith { (task: AWSTask<AWSCognitoIdentityUserConfirmSignUpResponse>) -> Any? in
                if let error = task.error as? NSError {
                    DispatchQueue.main.async {
                        HUD.flash(.error, delay: 0.5)
                        self.messageLabel.text = AWSErrorMessageParser.parse(error)
                    }
                } else {
                    DispatchQueue.main.async {
                        HUD.flash(.success, delay: 0.5)
                        if let loginController = self.navigationController?.viewControllers.first as? LoginViewController {
                            loginController.usernameField.text = self.emailField?.text
                        }
                        let _ = self.navigationController?.popToRootViewController(animated: true)
                    }
                }
                return nil
            }
    }
    
}
