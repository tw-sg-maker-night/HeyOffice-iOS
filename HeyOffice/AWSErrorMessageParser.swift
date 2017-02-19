//
//  AWSErrorMessageParser.swift
//  HeyOffice
//
//  Created by Colin Harris on 19/2/17.
//  Copyright © 2017 ThoughtWorks. All rights reserved.
//

import Foundation

class AWSErrorMessageParser {
    
    class func parse(_ error: NSError) -> String {
        let message = error.userInfo["message"] as! String
        return message.components(separatedBy: ":").last!.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
    }
    
}
