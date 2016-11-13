//
//  ImageCache.swift
//  Virtual Tourist
//
//  Created by John Clema on 20/06/2016.
//  Copyright © 2016 JohnClema. All rights reserved.
//

import Foundation

import UIKit

class ImageCache {
    
    // MARK: - Image Cache Singleton
    class func sharedInstance() -> ImageCache {
        
        struct Singleton {
            static var sharedInstance = ImageCache()
        }
        return Singleton.sharedInstance
    }
    
    // MARK: - Shared Image Cache
    struct Caches {
        static let imageCache = ImageCache()
    }
    
    
    fileprivate var inMemoryCache = NSCache<AnyObject, AnyObject>()
    
    
    
    // MARK: - Retreiving images
    
    func imageWithIdentifier(_ identifier: String?) -> UIImage? {
        
        // If the identifier is nil, or empty, return nil
        if identifier == nil || identifier! == "" {
            return nil
        }
        
        let path = pathForIdentifier(identifier!)
        
//        var data: NSData?
        
        // First try the memory cache
        if let image = inMemoryCache.object(forKey: path as AnyObject) as? UIImage {
            return image
        }
        
        // Next Try the hard drive
        if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            return UIImage(data: data)
        }
        
        return nil
    }
    
    // MARK: - Saving images
    
    func storeImage(_ image: UIImage?, withIdentifier identifier: String) {
        let path = pathForIdentifier(identifier)
        
        // If the image is nil, remove images from the cache
        if image == nil {
            inMemoryCache.removeObject(forKey: path as AnyObject)
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch _ {
            }
            return
        }
        
        // Otherwise, keep the image in memory
        inMemoryCache.setObject(image!, forKey: path as AnyObject)
        
        // And in documents directory
        let data = UIImagePNGRepresentation(image!)
        try? data!.write(to: URL(fileURLWithPath: path), options: [.atomic])
    }
    
    // MARK: - Helper
    
    func pathForIdentifier(_ identifier: String) -> String {
        let documentsDirectoryURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL!
        let fullURL = documentsDirectoryURL.appendingPathComponent(identifier)
        
        return fullURL.path
    }
}
