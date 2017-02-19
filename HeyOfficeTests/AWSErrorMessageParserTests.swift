//
//  AWSErrorMessageParserTests.swift
//  HeyOffice
//
//  Created by Colin Harris on 19/2/17.
//  Copyright © 2017 ThoughtWorks. All rights reserved.
//

import XCTest
@testable import HeyOffice

class AWSErrorMessageParserTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testPasswordLengthError() {
        let error = NSError(domain: "", code: 0, userInfo: [
            "__type": "InvalidParameterException",
            "message": "Password did not conform with policy: Password not long enough"
        ])
        let result = AWSErrorMessageParser.parse(error)
        print("Result = \(result)")
        XCTAssert(result == "Password not long enough")
    }
    
}
