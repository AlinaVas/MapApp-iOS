//
//  AutoCompletion.swift
//  Plan42
//
//  Created by Alina FESYK on 1/27/19.
//  Copyright © 2019 Maryna POPOVYCH. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

extension MapVC :  GMSAutocompleteViewControllerDelegate {
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        if locationNow == .start {
            start.text = place.name
            locationStart = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
            setMapCamera(location: locationStart.coordinate)
            if let markerStart = markerStart {
                markerStart.map = nil
            }
            markerStart = putMarker(titleMarker: place.name, latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        } else {
            destination.text = place.name
            locationDestination = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
            setMapCamera(location: locationDestination.coordinate)
            if let markerDest = markerDest {
                markerDest.map = nil
            }
            markerDest = putMarker(titleMarker: place.name, latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print("Error: ", error.localizedDescription)
        showAlert(title: "Ooops!", message: error.localizedDescription)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
        start.resignFirstResponder()
        destination.resignFirstResponder()
    }
    
    /* create marker! */
    func putMarker(titleMarker: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> GMSMarker {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(latitude, longitude)
        marker.title = title
        marker.appearAnimation = GMSMarkerAnimation.pop
        marker.map = mapView
        return marker
    }
    
    func setMapCamera(location: CLLocationCoordinate2D) {
        CATransaction.begin()
        CATransaction.setValue(2, forKey: kCATransactionAnimationDuration)
        mapView.animate(toLocation: location)
        CATransaction.commit()
    }
}
