//
//  RegisterViewController.swift
//  HeyOffice
//
//  Created by Colin Harris on 9/2/17.
//  Copyright © 2017 ThoughtWorks. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider
import PKHUD

class RegisterViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
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
        
        messageLabel.text = ""
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("prepareForSegue")
        
        if let controller = segue.destination as? ConfirmRegistrationViewController {
            controller.user = user
        }
    }
    
    func validate() -> Bool {
        messageLabel.text = ""
        
        if emailField.text == nil || emailField.text == "" {
            messageLabel.text = "Email address required"
            return false
        }
        
        if passwordField.text == nil || passwordField.text == "" {
            messageLabel.text = "Password required"
            return false
        }
        
        if !isValidEmail(email: emailField.text!) {
            messageLabel.text = "Email address not valid"
            return false
        }
        
        return true
    }
    
    func isValidEmail(email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
    
    @IBAction func registerClicked() {
        print("registerClicked")
        if !validate() {
            return
        }
        
        HUD.show(.progress)
        var attributes = [AWSCognitoIdentityUserAttributeType]()
        
        let emailAttribute = AWSCognitoIdentityUserAttributeType(name: "email", value: emailField.text!)
        attributes.append(emailAttribute)
        
        let username = emailField.text!.components(separatedBy: "@")[0]
        
        self.pool?.signUp(username, password: passwordField.text!, userAttributes: attributes, validationData: nil)
            .continueWith(block: { (response: AWSTask<AWSCognitoIdentityUserPoolSignUpResponse>) -> Any? in
                
                DispatchQueue.main.async {
                    if let error = response.error as NSError? {
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
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    func displaySuccess() {
        print("displaySuccess")
        HUD.flash(
            .labeledSuccess(title: "Success", subtitle: "A confirmation email has been sent."),
            onView: self.view,
            delay: 1.0) { _ in
            self.performSegue(withIdentifier: "ConfirmRegistration", sender: self)
        }
    }
    
    func displayError(_ error: NSError) {
        print("displayError")
        HUD.flash(.error, delay: 0.5)
        self.messageLabel.text = AWSErrorMessageParser.parse(error)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("textFieldShouldReturn")
        if textField == self.emailField {
            self.passwordField.becomeFirstResponder()
        } else if textField == self.passwordField {
            self.registerClicked()
        }
        return true
    }
    
}
