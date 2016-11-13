//
//  Pin.swift
//  Virtual Tourist
//
//  Created by John Clema on 13/05/2016.
//  Copyright © 2016 JohnClema. All rights reserved.
//

import CoreData
import CoreLocation

class Pin: NSManagedObject {
    
    var isDownloading = false
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude!.doubleValue, longitude: self.longitude!.doubleValue)
    }

    // Insert code here to add functionality to your managed object subclass
    convenience init(location: CLLocationCoordinate2D, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: type(of: self).entityName(), in: context) {
            self.init(entity: ent, insertInto: context)
            self.creationDate = Date()
            self.latitude = location.latitude as NSNumber?
            self.longitude = location.longitude as NSNumber?
        } else {
            fatalError("Unable to find Entity Name")
        }
    }
    
    var humanReadableAge : String {
        get {
            let fmt = DateFormatter()
            fmt.timeStyle = .none
            fmt.dateStyle = .short
            fmt.doesRelativeDateFormatting = true
            fmt.locale = Locale.current
            
            return fmt.string(from: creationDate! as Date)
        }
    }
}
