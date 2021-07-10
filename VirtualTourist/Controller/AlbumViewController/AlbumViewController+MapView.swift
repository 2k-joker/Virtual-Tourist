//
//  AlbumViewController+MapView.swift
//  VirtualTourist
//
//  Created by Khalil Kum on 6/28/21.
//

import Foundation
import MapKit

extension AlbumViewController: MKMapViewDelegate {
       
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
           
           let reuseId = "pin"
           var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
       

           if pinView == nil {
               pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
               pinView!.animatesDrop = true
            
           } else {
               pinView!.annotation = annotation
           }
           
           pinView?.isSelected = true
           pinView?.isUserInteractionEnabled = false
           return pinView
       }
    
    func setUpMapView() {
        let span = MKCoordinateSpan(latitudeDelta:  CLLocationDegrees(5), longitudeDelta: CLLocationDegrees(5))
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
}
