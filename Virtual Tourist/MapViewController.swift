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

struct ButtonTitles {
    static let edit = "Edit"
    static let done = "Done"
}


struct MapRegion {
    static let archive = "mapRegionArchive"

    struct Keys {
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let latitudeDelta = "latitudeDelta"
        static let longitudeDelta = "longitudeDelta"
    }
}

class MapViewController: VirtualTouristViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapViewBottomLayoutGuide: NSLayoutConstraint!
    var rightBarButtonItem: UIBarButtonItem?
    
    var pins = [Pin]()

    // Determines users current edit state
    var editMode : Bool = false
    
    lazy var fetchedResultsController: NSFetchedResultsController<Pin> = {
        // Initialize Fetch Request
        let fetchRequest = NSFetchRequest<Pin>(entityName: Pin.entityName())
        
        // Add Sort Descriptors
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Initialize Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController<Pin>(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    //File path that keeps the last map region the use was on
    var mapRegionFilePath : String {
        let manager = FileManager.default
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first! as URL
        return url.appendingPathComponent(MapRegion.archive).absoluteString
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setRightBarButton(rightBarButtonItem, animated: true)

        restoreMapRegion(false)
        mapView.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch let error {
            print(error)
        }
        
        self.pins = fetchedResultsController.fetchedObjects!
        addPinDropRecognizer()
        
        rightBarButtonItem = UIBarButtonItem(title: ButtonTitles.edit, style: .plain, target: self, action: #selector(MapViewController.editButtonPressed(_:)))
        self.navigationItem.rightBarButtonItem = rightBarButtonItem
        self.restorePersistedAnnotations()
    }
    
    func restorePersistedAnnotations() {
        for pin in self.pins {
            let annotation = MKPointAnnotation()
            annotation.coordinate = pin.coordinate
            mapView.addAnnotation(annotation)
        }
    }

    func editButtonPressed(_ sender: AnyObject) {
        self.navigationItem.rightBarButtonItem?.title == ButtonTitles.edit ? showEditButton() : showDoneButton()
    }
    
    // Move keyboard up and remove pins on tap
    func showEditButton() {
        self.editMode = true
        self.navigationItem.rightBarButtonItem?.title = ButtonTitles.done
        self.view.layoutIfNeeded()
        self.mapViewBottomLayoutGuide.constant += 60
        UIView.animate(withDuration: 0.25, animations: {
            self.view.layoutIfNeeded()
        })     }
    
    // Move keyboard down and resume adding pins
    func showDoneButton() {
        self.editMode = false
        self.navigationItem.rightBarButtonItem?.title = ButtonTitles.edit
        self.view.layoutIfNeeded()
        self.mapViewBottomLayoutGuide.constant -= 60
        UIView.animate(withDuration: 0.25, animations: {
            self.view.layoutIfNeeded()
        }) 
    }
    
    func addPinDropRecognizer() {
        self.mapView.gestureRecognizers = nil
        let pindropGesture = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.dropPin(_:)))
        pindropGesture.minimumPressDuration = 1.5
        self.mapView.addGestureRecognizer(pindropGesture)
    }
    
    func dropPin(_ gestureRecognizer:UIGestureRecognizer){
        if (gestureRecognizer.state == .began) {
            let touchPoint = gestureRecognizer.location(in: self.mapView)
            let newCoordinates = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            
            let pin = Pin(location: newCoordinates, context: sharedContext)
            pins.append(pin)
            self.mapView.addAnnotation(annotation)

            sharedStack.save()
            self.saveMapRegion()
        }
    }
    
    func saveMapRegion() {
        
        // Place the "center" and "span" of the map into a dictionary
        // The "span" is the width and height of the map in degrees.
        // It represents the zoom level of the map.
        
        let dictionary = [
            MapRegion.Keys.latitude : mapView.region.center.latitude,
            MapRegion.Keys.longitude : mapView.region.center.longitude,
            MapRegion.Keys.latitudeDelta : mapView.region.span.latitudeDelta,
            MapRegion.Keys.longitudeDelta : mapView.region.span.longitudeDelta
        ]
    
        // Archive the dictionary into the filePath
        if FileManager().isDeletableFile(atPath: mapRegionFilePath) {
            try! FileManager().removeItem(atPath: mapRegionFilePath)
        }
        UserDefaults.standard.set(dictionary, forKey: MapRegion.archive)
    }
    
    func restoreMapRegion(_ animated: Bool) {
        
        // if we can unarchive a dictionary, we will use it to set the map back to its
        // previous center and span
        if let regionDictionary = UserDefaults.standard.value(forKey: MapRegion.archive) as? [String: Any] {
            
            let longitude = regionDictionary[MapRegion.Keys.longitude] as! CLLocationDegrees
            let latitude = regionDictionary[MapRegion.Keys.latitude] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary[MapRegion.Keys.latitudeDelta] as! CLLocationDegrees
            let latitudeDelta = regionDictionary[MapRegion.Keys.longitudeDelta] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            print("lat: \(latitude), lon: \(longitude), latD: \(latitudeDelta), lonD: \(longitudeDelta)")
            
            mapView.setRegion(savedRegion, animated: animated)
        }
    }
}

extension MapViewController : NSFetchedResultsControllerDelegate {}

extension MapViewController : MKMapViewDelegate {
    
    //Tap and hold gesture for map = drop a new pin at the tap and hold location
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.animatesDrop = true
            pinView!.pinTintColor = UIColor.red
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // Segue to next view and perform request from flickr
        mapView.deselectAnnotation(view.annotation, animated: true)
        var index : Int = 0
        for pin in pins {
            if pin.latitude?.doubleValue == view.annotation?.coordinate.latitude &&
                pin.longitude?.doubleValue == view.annotation?.coordinate.longitude{
                break;
            } else {
                index = index + 1
            }
        }

        if editMode {
            mapView.removeAnnotation(view.annotation!)
            sharedContext.delete(pins[index] as NSManagedObject)
            sharedStack.save()
            self.pins.remove(at: index)
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let controller = storyboard.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
            controller.pin = pins[index]
            self.navigationController!.pushViewController(controller, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
}


