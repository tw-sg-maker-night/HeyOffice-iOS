//
//  NewPasswordViewController.swift
//  HeyOffice
//
//  Created by Colin Harris on 10/2/17.
//  Copyright © 2017 ThoughtWorks. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider

class NewPasswordViewController: UIViewController, AWSCognitoIdentityNewPasswordRequired {
    
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var messageLabel: UILabel!
    
    var passwordRequiredCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityNewPasswordRequiredDetails>?
    var dismissKeyboardGesture: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dismissKeyboardGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.dismissKeyboard))
        self.dismissKeyboardGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(dismissKeyboardGesture)
    }
    
    @objc
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
    
    func getNewPasswordDetails(_ newPasswordRequiredInput: AWSCognitoIdentityNewPasswordRequiredInput,
                               newPasswordRequiredCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityNewPasswordRequiredDetails>) {
        print("getNewPasswordDetails")
        self.passwordRequiredCompletionSource = newPasswordRequiredCompletionSource
    }
    
    func didCompleteNewPasswordStepWithError(_ error: Error?) {
        print("didCompleteNewPasswordStepWithError")
        DispatchQueue.main.async {
            if let error = error as NSError? {
                let message = error.userInfo["message"] as! String
                let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func submitPasswordClicked() {
        print("submitPasswordClicked")
        let details = AWSCognitoIdentityNewPasswordRequiredDetails(
            proposedPassword: passwordField.text!,
            userAttributes: [String: String]()
        )
        self.passwordRequiredCompletionSource!.set(result: details)
    }
    
}
