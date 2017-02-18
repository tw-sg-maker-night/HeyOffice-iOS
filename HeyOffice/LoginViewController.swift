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
    @IBOutlet var baselineConstraint: NSLayoutConstraint!
    
    var passwordAuthenticationCompletion: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>?
    var dismissKeyboardGesture: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dismissKeyboardGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.dismissKeyboard))
        self.dismissKeyboardGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(dismissKeyboardGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        print("keyboardWillShow")
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            self.baselineConstraint.constant = keyboardSize.size.height
            let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
            UIView.animate(withDuration: duration, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        print("keyboardWillHide")
        if let _ = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            self.baselineConstraint.constant = 20
            let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
            UIView.animate(withDuration: duration, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.messageLabel.text = ""
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func getDetails(_ authenticationInput: AWSCognitoIdentityPasswordAuthenticationInput, passwordAuthenticationCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>) {
        print("LoginViewController.getDetails")
        
        self.passwordAuthenticationCompletion = passwordAuthenticationCompletionSource;
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
        } else {
            DispatchQueue.main.async {
                self.usernameField.text = nil
                self.dismiss(animated: true, completion: nil)
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
    
    @IBAction func registerClicked() {
        print("registerClicked")
        self.performSegue(withIdentifier: "Register", sender: self)
    }
    
    @IBAction func forgotPasswordClicked() {
        print("forgotPasswordClicked")
        self.performSegue(withIdentifier: "ForgotPassword", sender: self)
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

