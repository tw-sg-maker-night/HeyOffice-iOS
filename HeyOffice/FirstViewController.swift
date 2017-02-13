//
//  FirstViewController.swift
//  HeyOffice
//
//  Created by Colin Harris on 2/2/17.
//  Copyright © 2017 ThoughtWorks. All rights reserved.
//

import UIKit
import AWSLex

class FirstViewController: UIViewController, AWSLexVoiceButtonDelegate {

    @IBOutlet weak var voiceButton: AWSLexVoiceButton!
    @IBOutlet weak var outputLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.voiceButton.delegate = self
        self.outputLabel.text = ""
    }

    func voiceButton(_ button: AWSLexVoiceButton, on response: AWSLexVoiceButtonResponse) {
        DispatchQueue.main.async(execute: {
            print("on text output \(response.outputText)")
            self.outputLabel.text = response.outputText
        })
    }
    
    public func voiceButton(_ button: AWSLexVoiceButton, onError error: Error) {
        print("error \(error)")
    }

}

