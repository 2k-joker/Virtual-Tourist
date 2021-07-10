//
//  AlbumViewController.swift
//  VirtualTourist
//
//  Created by Khalil Kum on 6/20/21.
//

import Foundation
import UIKit
import MapKit
import CoreData

class AlbumViewController: UIViewController {
    // MARK: Properties
    var fetchResultsController: NSFetchedResultsController<Photo>!
    var pin: Pin!
    var dataStackHandler: CoreDataStackHandler!
    let maxFlickrPhotosPerLocation = 4000

    // MARK: Outlets
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var navBarTitle: UINavigationItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var refreshCollectionButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: View States
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchResultsController()
        searchFlickrPhotosForPin()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navBarTitle.title = pin.locationName ?? "Location Photos"
        deleteButton.isEnabled = false
        setUpMapView()
        setupFlowLayout()
    }

    // MARK: Actions
    @IBAction func refreshCollection(_ sender: UIButton) {
        if let fetchedPhotos = fetchResultsController.fetchedObjects {
            for photo in fetchedPhotos {
                dataStackHandler.viewContext.delete(photo)
                
                do {
                    try dataStackHandler.viewContext.save()
                } catch {
                    print("Failed to delete a photo")
                }
            }
        }
        searchFlickrPhotosForPin()
    }

    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func deleteButtonPressed(_ sender: UIBarButtonItem) {
        deleteSelectedPhotos()
        deleteButton.isEnabled = false
    }

    // MARK: Functions
    func presentErrorMessage(_ message: String) {
        let alertVC = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alertVC, animated: true, completion: nil)
    }

    func searchFlickrPhotosForPin() {
        activityIndicator.startAnimating()
        refreshCollectionButton.isEnabled = false
        guard (fetchResultsController.fetchedObjects?.isEmpty)! else {
            activityIndicator.stopAnimating()
            refreshCollectionButton.isEnabled = true
            return
        }
        let photosPerPage = 25
        let totalPages = min(Int(pin.pagesCount), maxFlickrPhotosPerLocation/photosPerPage)
        let pageNum = Int.random(in: 0...totalPages)
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        FlickrClient.searchFlickerPhotos(latitude: coordinate.latitude, longitude: coordinate.longitude, pageNum: pageNum, photosPerPage: photosPerPage, completionHandler: handleSearchPhotosResponse(photosData:error:))
    }
    
    func handleSearchPhotosResponse(photosData: FlickrPhotosData?, error: Error?) {
        activityIndicator.stopAnimating()

        guard let photosData = photosData else {
            refreshCollectionButton.isEnabled = true
            presentErrorMessage(error!.localizedDescription)
            return
        }
        
        if Int(pin.pagesCount) == 0 {
            pin.pagesCount = Int32(photosData.numberOfPages)
        }
        
        let downloadedPhotos = photosData.photos
        
        if !downloadedPhotos.isEmpty {
            for photo in photosData.photos {
                let newPhoto = Photo(context: dataStackHandler.viewContext)
                newPhoto.imageId = photo.id
                newPhoto.imageData = nil
                newPhoto.imageUrl = URL(string: photo.mediumSizeURL)
                newPhoto.pin = self.pin
                
                do {
                    try dataStackHandler.viewContext.save()
                } catch {
                    print("Failed to save photo. Errors: \(error.localizedDescription)")
                }
            }
        } else {
            presentErrorMessage(CustomErrorMessages.emptyPhotosObject.message)
        }

    }
}

extension AlbumViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            self.collectionView.insertItems(at: [newIndexPath!])
        case .delete:
            self.collectionView.deleteItems(at: [indexPath!])
        case .update:
            self.collectionView.reloadItems(at: [indexPath!])
        default:
            break
        }
    }

    fileprivate func setupFetchResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin = %@", pin)
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataStackHandler.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchResultsController.delegate = self
        
        do {
            try fetchResultsController.performFetch()
        } catch {
            fatalError("Unable to perform fetch. Errors: \(error.localizedDescription)")
        }
    }
}
