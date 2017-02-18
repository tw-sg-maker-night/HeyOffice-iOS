//
//  ConfirmRegistrationViewController.swift
//  HeyOffice
//
//  Created by Colin Harris on 9/2/17.
//  Copyright © 2017 ThoughtWorks. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider

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
    
    @IBAction func confirmClicked() {
        print("confirmClicked")
        
        self.user.confirmSignUp(self.codeField!.text!, forceAliasCreation: true)
            .continueWith { (task: AWSTask<AWSCognitoIdentityUserConfirmSignUpResponse>) -> Any? in
                if let error = task.error as? NSError {
                    DispatchQueue.main.async {
                        self.displayError(error)
                    }
                } else {
                    DispatchQueue.main.async {
                        let _ = self.navigationController?.popToRootViewController(animated: true)
                    }
                }
                return nil
            }
    }
    
    func displayError(_ error: NSError) {
        let message = error.userInfo["message"] as! String
        let alertController = UIAlertController(title: "Confirm Code", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
}
