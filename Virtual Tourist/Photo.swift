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

    convenience init(imageUrl: String, pin: Pin, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: type(of: self).entityName(), in: context) {
            self.init(entity: ent, insertInto: context)
            self.imageUrl = imageUrl
            self.pin = pin
            self.creationDate = Date()  // Now
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
    
    var image: UIImage? {
        if imagePath != nil {
            let imageData = NSData(contentsOf: getFileURL())
            return UIImage(data: imageData! as Data)
        }
        return nil
    }
    
    func getFileURL() -> URL {
        let fileName = (imagePath! as NSString).lastPathComponent
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(fileName)
        return fileURL
    }
    
    // Make sure the current image is deleted from teh file system when a Photo is deleted
    override func prepareForDeletion() {
        if (imagePath == nil) {
            return
        }
        let fileURL = getFileURL()
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
            } catch let error as NSError {
                print(error.userInfo) // fail silent
            }
        }
    }
}
