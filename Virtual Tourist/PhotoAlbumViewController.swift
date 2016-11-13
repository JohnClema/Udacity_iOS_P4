//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by John Clema on 13/11/16.
//  Copyright © 2016 JohnClema. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PhotoAlbumViewController: VirtualTouristViewController {
    
    @IBOutlet weak var downloadActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    var pin : Pin?
    
    var isSelecting : Bool = false
    
    var selectedIndexes   = [IndexPath]()
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths : [IndexPath]!
    var updatedIndexPaths : [IndexPath]!
 
    
    
    var mapRegionFilePath : String {
        let manager = FileManager.default
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first! as URL
        let fullURL = url.appendingPathComponent("mapRegionArchive")
        return fullURL.absoluteString
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController<Photo> = {
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin!)
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController<Photo>(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.downloadActivityIndicator.isHidden = true
        self.noImagesLabel.isHidden = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = true
        let annotation : MKPointAnnotation = MKPointAnnotation()
        annotation.coordinate = (pin?.coordinate)!
        self.mapView.addAnnotation(annotation)
        
        self.mapView.centerCoordinate = (pin?.coordinate)!
        
        self.getMapRegionForPin()
        
        do {
            try fetchedResultsController.performFetch()
        } catch (let error) {
            print(error.localizedDescription)
        }
        if pin!.photos!.isEmpty {
            self.requestPhotos()

        }

    }
    @IBAction func newCollectionButtonTapped(_ sender: Any) {
        
        loadNewCollectionSet()
    }
    func loadNewCollectionSet() {
        if collectionView.indexPathsForSelectedItems!.isEmpty {
            for photo in self.pin!.photos! {
                self.sharedContext.delete(photo)
                self.sharedStack.save()
            }
            
            self.requestPhotos()

        } else {
            for indexPath in collectionView.indexPathsForSelectedItems! {
                let photo = fetchedResultsController.object(at: indexPath)
                self.sharedContext.delete(photo)
            }
            collectionView.performBatchUpdates({ 
                try! self.sharedContext.save()
            }, completion: { (completed) in
                if completed {
                    self.newCollectionButton.title = "New Collection"
                }
            })
            
        }
    }
    
    func requestPhotos() {
        self.newCollectionButton.isEnabled = false
        self.downloadActivityIndicator.isHidden = false
        self.downloadActivityIndicator.startAnimating()
        FlickrClient.sharedInstance().downloadPhotosForPin(self.pin!, completionHandler: { (completed, errormessage) in
            if completed {
                self.downloadActivityIndicator.stopAnimating()
                self.downloadActivityIndicator.isHidden = true
                if self.pin!.photos!.isEmpty {
                    self.noImagesLabel.isHidden = false
                    self.newCollectionButton.isEnabled = false
                } else {
                    self.noImagesLabel.isHidden = true
                    self.newCollectionButton.isEnabled = true
                }
            } 
        })
    }
    
    fileprivate func getMapRegionForPin() {
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObject(withFile: mapRegionFilePath) as? [String : AnyObject] {
            let longitude = pin?.coordinate.longitude
            let latitude = pin?.coordinate.latitude
            let center = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            print("lat: \(latitude), lon: \(longitude), latD: \(latitudeDelta), lonD: \(longitudeDelta)")
            
            mapView.setRegion(savedRegion, animated: true)
        }
    }
}

extension PhotoAlbumViewController : UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        }
        
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        return 0
    }
    
    func photoForIndexPath(_ indexPath : IndexPath) -> Photo? {
        if let photo = pin?.photos?[indexPath.row] {
            return photo
        } else {
            return Photo()
        }
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCell
        let photo = fetchedResultsController.object(at: indexPath)
        if photo.image != nil {
            
//            let image = UIImage(contentsOfFile: photo.imagePath!)
            cell.activityIndicator.stopAnimating()
            cell.activityIndicator.isHidden = true

            cell.imageView.image = photo.image!
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if collectionView.indexPathsForSelectedItems!.isEmpty {
            self.newCollectionButton.title = "New Collection"
        }
        
//        collectionView.deselectItem(at: indexPath, animated: true)
//        collectionView.cellForItem(at: indexPath)?.isSelected = false

    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !collectionView.indexPathsForSelectedItems!.isEmpty {
            self.newCollectionButton.title = "Remove Selected Photos"
        }
    }
    
}

extension PhotoAlbumViewController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let totalSpace = flowLayout.sectionInset.left
            + flowLayout.sectionInset.right
            + (flowLayout.minimumInteritemSpacing * CGFloat(3 - 1))
        let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(3))
        return CGSize(width: size, height: size)
    }
}

extension PhotoAlbumViewController : NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths  = [IndexPath]()
        updatedIndexPaths  = [IndexPath]()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            insertedIndexPaths.append(newIndexPath!)
        case .update:
            updatedIndexPaths.append(indexPath!)
        case .delete:
            deletedIndexPaths.append(indexPath!)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItems(at: [indexPath])
            }
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [indexPath])
            }
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItems(at: [indexPath])
            }
        }, completion: nil)
    }
}
