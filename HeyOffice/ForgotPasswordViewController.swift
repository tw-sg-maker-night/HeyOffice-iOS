//
//  ForgotPasswordViewController.swift
//  HeyOffice
//
//  Created by Colin Harris on 10/2/17.
//  Copyright © 2017 ThoughtWorks. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider
import PKHUD

class ForgotPasswordViewController: UIViewController {
    
    @IBOutlet var emailField: UITextField!
    @IBOutlet var messageLabel: UILabel!
    
    var pool: AWSCognitoIdentityUserPool?
    var user: AWSCognitoIdentityUser?
    var dismissKeyboardGesture: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pool = AWSCognitoIdentityUserPool(forKey: "UserPool")
        
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
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func valid() -> Bool {
        self.messageLabel.text = ""
        
        if self.emailField.text == nil || self.emailField.text == "" {
            self.messageLabel.text = "Email required"
            return false
        }
        
        return true
    }
    
    @IBAction func forgotPasswordClicked() {
        print("forgotPasswordClicked")
        if !valid() {
            return
        }
        HUD.show(.progress)        
        self.user = self.pool?.getUser(self.emailField.text!)
        self.user?.forgotPassword()
            .continueWith(block: { (task: AWSTask<AWSCognitoIdentityUserForgotPasswordResponse>) -> Any? in
                DispatchQueue.main.async {
                    if let error = task.error as NSError? {
                        self.handleError(error)
                    } else {
                        self.handleSuccess()
                    }
                }
                return nil
            })
    }
    
    func handleError(_ error: NSError) {
        print("ForgotPasswordViewController.handleError")
        self.messageLabel.text = AWSErrorMessageParser.parse(error)
        HUD.flash(.error, delay: 0.5)
    }
    
    func handleSuccess() {
        print("ForgotPasswordViewController.handleSuccess")
        HUD.flash(.success, delay: 0.5) { _ in
            self.performSegue(withIdentifier: "ConfirmForgotPassword", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? ConfirmForgotPasswordViewController {
            controller.user = self.user
        }
    }
    
}
