//
//  Constants.swift
//  Virtual Tourist
//
//  Created by John Clema on 11/05/2016.
//  Copyright © 2016 JohnClema. All rights reserved.
//
//

import UIKit

extension FlickrClient {
    
    struct Constants {
        
        static let APIKey = "a4f51938e13c4ee05c5545d41936d2b2"
        
        static let FlickrURL = "https://api.flickr.com/services/rest/"
        
        static let SearchBBoxHalfWidth = 1.0
        static let SearchBBoxHalfHeight = 1.0
        static let SearchLatRange = (-90.0, 90.0)
        static let SearchLonRange = (-180.0, 180.0)
    }
    
    struct Methods {
        static let Search = "flickr.photos.search"
    }
    
    struct URLKeys {
        static let APIKey = "api_key"
        static let BoundingBox = "bbox"
        static let Format = "format"
        static let Extras = "extras"
        static let Latitude = "lat"
        static let Longitude = "lon"
        static let Method = "method"
        static let NoJSONCallback = "nojsoncallback"
        static let Page = "page"
        static let PerPage = "per_page"
        static let Sort = "sort"
    }
    
    struct URLValues {
        static let JSONFormat = "json"
        static let URLMediumPhoto = "url_m"
    }
    
    struct JSONResponseKeys {
        static let Status = "stat"
        static let Code = "code"
        static let Message = "message"
        static let Pages = "pages"
        static let Photos = "photos"
        static let Photo = "photo"
    }
    
    struct JSONResponseValues {
        
        static let Fail = "fail"
        static let Ok = "ok"
    }
    
    
}