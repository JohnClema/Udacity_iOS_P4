//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by John Clema on 13/05/2016.
//  Copyright © 2016 JohnClema. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Photo {

    @NSManaged var creationDate: Date?
    @NSManaged var data: NSData?
    @NSManaged var imageUrl: String?
    @NSManaged var imagePath: String?
    @NSManaged var pin: Pin?

}
