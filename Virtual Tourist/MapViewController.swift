//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by John Clema on 27/04/2016.
//  Copyright © 2016 JohnClema. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import CoreLocation

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapViewBottomLayoutGuide: NSLayoutConstraint!
    
    var mapRegionFilePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        restoreMapRegion(false)
        mapView.delegate = self
        let editButton = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: #selector(MapViewController.showDeleteButton))
        self.navigationItem.setRightBarButtonItem(editButton, animated: true)
        addPinDropRecognizer()
//        showEditButton()
//        showDeleteButton()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func editButtonPressed(sender: AnyObject) {
        //1. Turn into edit mode
        //2. Red message at bottom of map appears
        //3. Tapping a location deletes it from the map
        //4. Deletes it from CoreData
        showDeleteButton()
    }
    
    func showDeleteButton() {
        let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(MapViewController.showEditButton))
        self.navigationItem.setRightBarButtonItem(doneButton, animated: true)
        self.view.layoutIfNeeded()
        self.mapViewBottomLayoutGuide.constant -= 60
        UIView.animateWithDuration(0.25) {
            self.view.layoutIfNeeded()
        }
    }
    
    func showEditButton() {
        self.view.layoutIfNeeded()
        self.mapViewBottomLayoutGuide.constant += 60
        UIView.animateWithDuration(0.25) {
            self.view.layoutIfNeeded()
        }
    }
    
    func addPinDropRecognizer() {
        self.mapView.gestureRecognizers = nil
        let pindropGesture = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.dropPin(_:)))
        self.mapView.addGestureRecognizer(pindropGesture)
    }
    
    func dropPin(gestureRecognizer:UIGestureRecognizer){
        let touchPoint = gestureRecognizer.locationInView(self.mapView)
        let newCoordinates = self.mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        self.mapView.addAnnotation(annotation)
    }
    
    func saveMapRegion() {
        
        // Place the "center" and "span" of the map into a dictionary
        // The "span" is the width and height of the map in degrees.
        // It represents the zoom level of the map.
        
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        
        // Archive the dictionary into the filePath
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: mapRegionFilePath)
    }
    
    func restoreMapRegion(animated: Bool) {
        
        // if we can unarchive a dictionary, we will use it to set the map back to its
        // previous center and span
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(mapRegionFilePath) as? [String : AnyObject] {
            
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            print("lat: \(latitude), lon: \(longitude), latD: \(latitudeDelta), lonD: \(longitudeDelta)")
            
            mapView.setRegion(savedRegion, animated: animated)
        }
    }
    
    
}

extension MapViewController : MKMapViewDelegate {
    
    //Tap and hold gesture for map = drop a new pin at the tap and hold location
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.animatesDrop = true
            pinView!.pinTintColor = UIColor.redColor()
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        // Segue to next view and perform request from flickr
        print(view.annotation?.coordinate)
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
}


