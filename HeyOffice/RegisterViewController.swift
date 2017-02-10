//
//  RegisterViewController.swift
//  HeyOffice
//
//  Created by Colin Harris on 9/2/17.
//  Copyright © 2017 ThoughtWorks. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider

class RegisterViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var emailField: UITextField!
    @IBOutlet var usernameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var messageLabel: UILabel!
    
    var pool: AWSCognitoIdentityUserPool?
    var user: AWSCognitoIdentityUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pool = AWSCognitoIdentityUserPool(forKey: "UserPool")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        messageLabel.text = ""
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("prepareForSegue")
        
        if let controller = segue.destination as? ConfirmRegistrationViewController {
            controller.user = user
        }
    }
    
    @IBAction func registerClicked() {
        print("registerClicked")
        var attributes = [AWSCognitoIdentityUserAttributeType]()
        
        let emailAttribute = AWSCognitoIdentityUserAttributeType(name: "email", value: emailField.text!)
        attributes.append(emailAttribute)
        
        self.pool?.signUp(usernameField.text!, password: passwordField.text!, userAttributes: attributes, validationData: nil)
            .continueWith(block: { (response: AWSTask<AWSCognitoIdentityUserPoolSignUpResponse>) -> Any? in
                
                DispatchQueue.main.async {
                    if let error = response.error as? NSError {
                        self.displayError(error)
                    } else {
                        self.user = response.result?.user
                        self.displaySuccess()
                    }
                }
                
            })
    }
    
    @IBAction func loginClicked() {
        print("loginClicked")
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    func displaySuccess() {
        print("displaySuccess")
        let alertController = UIAlertController(title: "Sign Up", message: "Success! A confirmation email has been sent.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) in
            self.performSegue(withIdentifier: "ConfirmRegistration", sender: self)
        })
        self.present(alertController, animated: true, completion: nil)
    }
    
    func displayError(_ error: NSError) {
        print("displayError")
        let type = error.userInfo["__type"]
        let message = error.userInfo["message"] as! String
        print("Type = \(type)")
        print("Message = \(message)")
        
        let alertController = UIAlertController(title: "Registration Failed", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("textFieldShouldReturn")
        if textField == self.emailField {
            self.usernameField.becomeFirstResponder()
        } else if textField == self.usernameField {
            self.passwordField.becomeFirstResponder()
        } else if textField == self.passwordField {
            self.registerClicked()
        }
        return true
    }
    
}