//
//  NSManagedObject+Entity.swift
//  Virtual Tourist
//
//  Created by John Clema on 22/08/2016.
//  Copyright © 2016 JohnClema. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObject {
    
    class func entityName() -> String {
        return String(describing: self)
    }
    
}
