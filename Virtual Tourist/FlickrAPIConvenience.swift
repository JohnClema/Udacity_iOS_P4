//
//  FlickrAPIConvenience.swift
//  Virtual Tourist
//
//  Created by John Clema on 21/08/2016.
//  Copyright © 2016 JohnClema. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import CoreData

extension FlickrClient {
    
    var sharedStack: CoreDataStackManager {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.dataStack
    }
    
    func downloadPhotosForPin(_ pin: Pin, completionHandler: @escaping (_ success: Bool, _ errorString: String?) -> Void) {
        
        // see if we previously  received total number of pages for pin
        var pageNumber = 1
        
        if let numPages = pin.pageCount {
            var numPagesInt = numPages as Int
            // We might only access the first 4000 images returned by a search, so limit the results
            if numPagesInt > 190 {
                numPagesInt = 190
            }
            pageNumber = Int((arc4random_uniform(UInt32(numPagesInt)))) + 1
            print("Getting photos for page number \(pageNumber) in \(numPages) total pages")
        }
        // generate bounding box string from pin coordinate
        let bbox = self.bboxString(pin.coordinate)
        
        let parameters : [String: AnyObject] = [
            FlickrClient.URLKeys.APIKey: FlickrClient.Constants.APIKey as AnyObject,
            FlickrClient.URLKeys.Method : FlickrClient.Methods.Search as AnyObject,
            FlickrClient.URLKeys.Extras: FlickrClient.URLValues.URLMediumPhoto as AnyObject,
            FlickrClient.URLKeys.Format: FlickrClient.URLValues.JSONFormat as AnyObject,
            FlickrClient.URLKeys.NoJSONCallback: "1" as AnyObject,
            FlickrClient.URLKeys.BoundingBox: bbox as AnyObject,
            FlickrClient.URLKeys.Page: pageNumber as AnyObject,
            FlickrClient.URLKeys.PerPage: 21 as AnyObject,
            FlickrClient.URLKeys.Sort: randomSortKeyString() as AnyObject
        ]
        
        let task = taskForGETMethod(nil, parameters: parameters, parseJSON: true) { (JSONResult, error) in
            if let error = error {
                completionHandler(false, error.localizedDescription)
            } else {
                if let photosDictionary = (JSONResult as AnyObject).value(forKey: "photos") as? [String: AnyObject],
                    let photosArray = photosDictionary["photo"] as? [[String: AnyObject]],
                    let numPages = photosDictionary["pages"] as? Int {
                    
                    pin.pageCount = numPages as NSNumber?
                    
                    var itemCount = 0
                    if photosArray.isEmpty {
                        completionHandler(false, "Unable to download Photos")
                    }
                    for photoDictionary in photosArray {
                        let photoURLString = photoDictionary["url_m"] as! String
                        let photo = Photo(imageUrl: photoURLString, pin: pin, context: self.sharedContext)
                        self.sharedContext.insert(photo)
                        try! self.sharedContext.save()
                        self.downloadImageForPhoto(photo) { (success, errorString) in
                            if success {
                                debugPrint("success \(photo.creationDate)")
                                itemCount = itemCount + 1
                                if itemCount == photosArray.count {
                                    completionHandler(true, nil)
                                    
                                }
                                
                            } else {
                                completionHandler(false, "Unable to download Photos")
                            }
                        }
                    }
                } else {
                    completionHandler(false, "Unable to download Photos")
                }
            }
            
        }
        task.resume()
    }
    
    func downloadImageForPhoto(_ photo: Photo, completionHandler: @escaping (_ success: Bool, _ errorString: String?) -> Void) {
        
        
        
        let task = taskForGETMethod(photo.imageUrl!, parameters: nil, parseJSON: false) { (result, error) in
            if error != nil {
                completionHandler(false, "Photo download failed")
            } else {
                if let result = result {
                        let fileName = (photo.imageUrl! as NSString).lastPathComponent
                        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                        let fileURL = URL(string: path)?.appendingPathComponent(fileName)
                    
                    
                    
                        FileManager.default.createFile(atPath: fileURL!.path, contents: result as? Data, attributes: nil)
                        
                        photo.imagePath = fileURL?.path
                        self.sharedStack.save()
                        completionHandler(true, nil)
                } else {
                    completionHandler(false, "Photo download failed")
                }
            }
        }
        task.resume()
    }
    
    fileprivate func bboxString(_ coordinate: CLLocationCoordinate2D) -> String {
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        let minLon = max(longitude - FlickrClient.Constants.SearchBBoxHalfWidth, FlickrClient.Constants.SearchLonRange.0)
        let minLat = max(latitude - FlickrClient.Constants.SearchBBoxHalfHeight, FlickrClient.Constants.SearchLonRange.0)
        let maxLon = min(longitude + FlickrClient.Constants.SearchBBoxHalfWidth, FlickrClient.Constants.SearchLonRange.1)
        let maxLat = min(latitude + FlickrClient.Constants.SearchBBoxHalfHeight, FlickrClient.Constants.SearchLonRange.1)
        
        return "\(minLon),\(minLat),\(maxLon),\(maxLat)"
    }
    
    func randomSortKeyString() -> String {
        let possibleSorts = ["date-posted-desc", "date-posted-asc", "date-taken-desc", "date-taken-asc", "interstingness-desc", "interestingness-asc"]
        return possibleSorts[Int((arc4random_uniform(UInt32(possibleSorts.count))))]
    }
    
    var sharedContext: NSManagedObjectContext {
        return sharedStack.context
    }
    
}
