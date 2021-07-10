//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Khalil Kum on 6/20/21.
//

import Foundation
import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, NSFetchedResultsControllerDelegate {
    // MARK: Properties
    let regionKey = "persistedRegion"
    var dataStackHandler: CoreDataStackHandler!
    var fetchResultsController: NSFetchedResultsController<Pin>!
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: View States
    override func viewDidLoad() {
        super.viewDidLoad()
        loadPersistedRegion()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadPersistedPins()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveCurrentRegion()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destinationVC = segue.destination as? AlbumViewController else {
            print("invalid segue destination")
            return
        }
        let annotation: MKPointAnnotation = sender as! MKPointAnnotation
        let pin = fetchPin(annotation: annotation)
        
        destinationVC.pin = pin
        destinationVC.dataStackHandler = dataStackHandler
    }

    // MARK: Actions
    @IBAction func mapLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let locationCoordinate = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
            
            addPinToMapView(coordinate: locationCoordinate)
        }
    }

    // MARK: Functions
    func presentErrorMessage(_ message: String) {
        let alertVC = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alertVC, animated: true, completion: nil)
    }

    func addPinToMapView(coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        CLGeocoder().reverseGeocodeLocation(location) { placeMarks, error in
            if let placeMark = placeMarks?.first {
                annotation.title = placeMark.name ?? "Unknown location"
                annotation.coordinate = coordinate
                
                self.createAndPersistPin(annotation: annotation)
                self.mapView.addAnnotation(annotation)
            } else {
                print(error?.localizedDescription ?? "Couldn't place location")
            }
        }
    }
    
    func fetchPin(annotation: MKPointAnnotation) -> Pin? {
        let predicate = NSPredicate(format: "longitude = %@ AND latitude = %@", argumentArray: [annotation.coordinate.longitude, annotation.coordinate.latitude])
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataStackHandler.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchResultsController.delegate = self
        
        do {
            try fetchResultsController.performFetch()
        } catch {
            fatalError("Failed to fetch Pin. Errors: \(error.localizedDescription)")
        }
        
        guard let pin = fetchResultsController.fetchedObjects?.first else {
            print("Failed to fetch pin")
            return nil
        }
        
        return pin
    }
    
    func loadPersistedRegion() {
        if let persistedRegion = UserDefaults.standard.dictionary(forKey: regionKey) {
            let region = persistedRegion as! [String: CLLocationDegrees]
            let center = CLLocationCoordinate2D(latitude: region["latitude"]!, longitude: region["longitude"]!)
            let span = MKCoordinateSpan(latitudeDelta: region["latitudeDelta"]!, longitudeDelta: region["longitudeDelta"]!)
            
            mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
        }
    }
    
    func loadPersistedPins() {
        activityIndicator.startAnimating()
        mapView.removeAnnotations(mapView.annotations)
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        dataStackHandler.viewContext.perform {
            do {
                let pins = try self.dataStackHandler.viewContext.fetch(fetchRequest)
                self.mapView.addAnnotations(pins.map { pin in
                    let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = coordinate
                    return annotation
                })
            } catch {
                self.presentErrorMessage("Failed to load existing pins")
            }
        }
        activityIndicator.stopAnimating()
        
    }
    
    func saveCurrentRegion() {
        let center = mapView.region.center
        let span = mapView.region.span
        let currentRegion = [
            "latitude" : center.latitude,
            "longitude" : center.longitude,
            "latitudeDelta" : span.latitudeDelta,
            "longitudeDelta" : span.longitudeDelta
        ]
        
        UserDefaults.standard.setValue(currentRegion, forKey: regionKey)
    }
    
    func createAndPersistPin(annotation: MKPointAnnotation) {
        let pin = Pin(context: dataStackHandler.viewContext)
        pin.createdAt = Date()
        pin.longitude = annotation.coordinate.longitude
        pin.latitude = annotation.coordinate.latitude
        pin.locationName = annotation.title
        pin.pagesCount = 0
        
        do {
            try dataStackHandler.viewContext.save()
        } catch {
            print("Failed to persist pin.")
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let resuseId = "locationPin"

        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: resuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: resuseId)
            pinView!.canShowCallout = true
            pinView!.animatesDrop = true
            pinView!.rightCalloutAccessoryView = UIButton(type: .infoLight)
        } else {
            pinView!.annotation = annotation
        }

        return pinView
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation as? MKPointAnnotation {
            mapView.deselectAnnotation(annotation, animated: false)
            self.performSegue(withIdentifier: "albumViewSegue", sender: annotation)
        }
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        saveCurrentRegion()
    }
}
