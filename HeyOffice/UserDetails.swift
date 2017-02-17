//
//  UserDetails.swift
//  HeyOffice
//
//  Created by Colin Harris on 17/2/17.
//  Copyright © 2017 ThoughtWorks. All rights reserved.
//

import Foundation
import AWSDynamoDB

class UserDetails: AWSDynamoDBObjectModel, AWSDynamoDBModeling  {
    var userId:String?
    var name:String?
    
    class func dynamoDBTableName() -> String {
        return "HeyOfficeUsers"
    }
    
    class func hashKeyAttribute() -> String {
        return "userId"
    }
}
