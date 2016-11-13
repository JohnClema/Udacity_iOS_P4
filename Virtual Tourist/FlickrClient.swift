//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by John Clema on 15/05/2016.
//  Copyright © 2016 JohnClema. All rights reserved.
//

import Foundation
import CoreLocation

class FlickrClient : NSObject {
    
    var session = URLSession.shared
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
    func taskForGETMethod(_ url: String?, parameters: [String:AnyObject]?, parseJSON: Bool, completionHandlerForGET: @escaping (_ result: Any?, _ error: Error?) -> Void) -> URLSessionDataTask {
        
        var urlString = (url != nil) ? url : Constants.FlickrURL
        if parameters != nil {
            var mutableParameters = parameters
            mutableParameters![FlickrClient.URLKeys.APIKey] = Constants.APIKey as AnyObject?
            urlString = urlString! + FlickrClient.escapedParameters(mutableParameters!)
        }
        
        let url = URL(string: urlString!)!
        let request = URLRequest(url: url)
        
        /* 4. Make the request */
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode , statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            if parseJSON {
                self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForGET)
            } else {
                completionHandlerForGET(data as AnyObject?, nil)
            }
        }) 
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }
    
    // create a URL from parameters
//    private func flickrURLFromParameters(parameters: [String:AnyObject], withPathExtension: String? = nil) -> NSURL {
//        
//        let components = NSURLComponents()
//        components.scheme = FlickrClient.Constants.ApiScheme
//        components.host = FlickrClient.Constants.ApiHost
//        components.path = FlickrClient.Constants.ApiPath + (withPathExtension ?? "")
//        components.queryItems = [NSURLQueryItem]()
//        
//        for (key, value) in parameters {
//            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
//            components.queryItems!.append(queryItem)
//        }
//        
//        return components.URL!
//    }
    
    class func escapedParameters(_ parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joined(separator: "&")
    }
    
    // given raw JSON, return a usable Foundation object
    fileprivate func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: Any?, _ error: NSError?) -> Void) {
        
        var parsedResult: Any!
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(parsedResult, nil)
    }
    
    fileprivate func bboxString(_ coordinate: CLLocationCoordinate2D) -> String {
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        let minLon = max(longitude - FlickrClient.Constants.SearchBBoxHalfWidth, FlickrClient.Constants.SearchLonRange.0)
        let minLat = max(latitude - FlickrClient.Constants.SearchBBoxHalfHeight, FlickrClient.Constants.SearchLonRange.0)
        let maxLon = min(longitude - FlickrClient.Constants.SearchBBoxHalfWidth, FlickrClient.Constants.SearchLonRange.1)
        let maxLat = min(latitude - FlickrClient.Constants.SearchBBoxHalfHeight, FlickrClient.Constants.SearchLonRange.1)
        return "\(minLon),\(minLat),\(maxLon),\(maxLat)"
    }

}
