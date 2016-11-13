//
//  Photo.swift
//  Virtual Tourist
//
//  Created by John Clema on 13/05/2016.
//  Copyright © 2016 JohnClema. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Photo: NSManagedObject {

    convenience init(data: NSData, pin: Pin, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: type(of: self).entityName(), in: context) {
            self.init(entity: ent, insertInto: context)
            self.data = data
            self.pin = pin
            self.creationDate = Date()  // Now
        } else {
            fatalError("Unable to find Entity Name")
        }
    }
    
    var image: UIImage? {
        if data != nil {
            return UIImage(data: self.data as! Data)
        }
        return nil
    }
}
