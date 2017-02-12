//
//  String+HeyOffice.swift
//  HeyOffice
//
//  Created by Colin Harris on 10/2/17.
//  Copyright © 2017 ThoughtWorks. All rights reserved.
//

import Foundation

extension String {
    
    var parametersFromQueryString: [String: String] {
        return dictionaryBySplitting("&", keyValueSeparator: "=")
    }
    
    fileprivate func dictionaryBySplitting(_ elementSeparator: String, keyValueSeparator: String) -> [String: String] {
        
        var string = self
        if(hasPrefix(elementSeparator)) {
            string = String(characters.dropFirst(1))
        }
        
        var parameters = Dictionary<String, String>()
        
        let scanner = Scanner(string: string)
        
        var key: NSString?
        var value: NSString?
        
        while !scanner.isAtEnd {
            key = nil
            scanner.scanUpTo(keyValueSeparator, into: &key)
            scanner.scanString(keyValueSeparator, into: nil)
            
            value = nil
            scanner.scanUpTo(elementSeparator, into: &value)
            scanner.scanString(elementSeparator, into: nil)
            
            if let key = key as? String, let value = value as? String {
                parameters.updateValue(value, forKey: key)
            }
        }
        
        return parameters
    }

}
