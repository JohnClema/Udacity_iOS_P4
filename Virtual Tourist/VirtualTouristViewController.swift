//
//  VirtualTouristViewController.swift
//  Virtual Tourist
//
//  Created by John Clema on 13/11/16.
//  Copyright © 2016 JohnClema. All rights reserved.
//

import CoreData
import UIKit

class VirtualTouristViewController: UIViewController {
    
    let photosFinishedDownloadingNotification = "PhotosFinishedDownloadNotification"

    var sharedStack: CoreDataStackManager {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.dataStack
    }
    
    var sharedContext: NSManagedObjectContext {
        return sharedStack.context
    }
}
