//
//  ForgotPasswordViewController.swift
//  HeyOffice
//
//  Created by Colin Harris on 10/2/17.
//  Copyright © 2017 ThoughtWorks. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider

class ForgotPasswordViewController: UIViewController {
    
    @IBOutlet var emailField: UITextField!
    @IBOutlet var messageLabel: UILabel!
    
    var pool: AWSCognitoIdentityUserPool?
    var user: AWSCognitoIdentityUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pool = AWSCognitoIdentityUserPool(forKey: "UserPool")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.messageLabel.text = ""
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func forgotPasswordClicked() {
        print("forgotPasswordClicked")
        
        if self.emailField.text == nil || self.emailField.text == "" {
            self.messageLabel.text = "Email required"
            return
        }
        
        self.user = self.pool?.getUser(self.emailField.text!)
        self.user?.forgotPassword()
            .continueWith(block: { (task: AWSTask<AWSCognitoIdentityUserForgotPasswordResponse>) -> Any? in
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
        print("ForgotPasswordViewController.handleError")
        let message = error.userInfo["message"] as! String
        self.messageLabel.text = message
    }
    
    func handleSuccess() {
        print("ForgotPasswordViewController.handleSuccess")
        self.performSegue(withIdentifier: "ConfirmForgotPassword", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? ConfirmForgotPasswordViewController {
            controller.user = self.user
        }
    }
    
}
