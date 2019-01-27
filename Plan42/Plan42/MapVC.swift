//
//  ViewController.swift
//  Plan42
//
//  Created by Maryna POPOVYCH on 26.01.2019.
//  Copyright © 2019 Maryna POPOVYCH. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

let directionsApi = "AIzaSyCxl4gr6gw8u0DeyOqmKFaqrgP1TO4EGp4"

class MapVC: UIViewController, UISearchDisplayDelegate{
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var start: UITextField!
    @IBOutlet weak var destination: UITextField!
    @IBOutlet weak var showPath: UIButton!
    @IBOutlet weak var nightMode: UIButton!
    
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var resultView: UITextView?
    
    var locationStart = CLLocation()
    var locationDestination = CLLocation()
    
    var polyline: GMSPolyline?
    var markerStart: GMSMarker?
    var markerDest: GMSMarker?
    
    var nightStyle: Bool = false
    
    private let locationManager = CLLocationManager()
    
    enum Location {
        case start
        case destination
    }
    
    var locationNow = Location.start
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showPath.layer.cornerRadius = showPath.frame.width / 2
        showPath.layer.shadowOffset = CGSize(width: -0.8, height: 1.5)
        showPath.layer.shadowRadius = 1
        showPath.layer.shadowOpacity = 0.8
        
        
        nightMode.layer.cornerRadius = showPath.frame.width / 2
        nightMode.layer.shadowOffset = CGSize(width: -0.2, height: 1.5)
        nightMode.layer.shadowRadius = 1.2
        nightMode.layer.shadowOpacity = 0.4
        
        // request location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startMonitoringSignificantLocationChanges()
        mapView.settings.compassButton = true
        mapView.settings.zoomGestures = true
        mapView.settings.myLocationButton = true
        mapView.delegate = self
    }

    func didFailAutocompleteWithError(_ error: Error) {
        showAlert(title: "Ooops!", message: error.localizedDescription)
    }
    
    //start location
    @IBAction func chooseStart(_ sender: UITextField) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        locationNow = .start
        present(autocompleteController, animated: true, completion: nil)
    }
    
    //destination location
    @IBAction func chooseDestination(_ sender: UITextField) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        locationNow = .destination
        present(autocompleteController, animated: true, completion: nil)
    }
    
    //SHOW PATH
    @IBAction func showPath(_ sender: UIButton) {
        guard mapView.isMyLocationEnabled else { return }
        
        let start = "\(locationStart.coordinate.latitude),\( locationStart.coordinate.longitude)"
        let dest = "\(locationDestination.coordinate.latitude),\( locationDestination.coordinate.longitude)"
        let url = URL(string : "https://maps.googleapis.com/maps/api/directions/json?origin=" + start + "&destination=" + dest + "&key=" + directionsApi)
        
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
                guard let data = data else { return }
                print(String(data: data, encoding: .utf8)!)
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options:.allowFragments) as! [String : AnyObject]
                    let routes = json["routes"] as! NSArray
                    
                    guard routes.count != 0 else {
                        if self.start.text != "" && self.destination.text != "" {
                            self.showAlert(title: "Ooops!", message: "No routes found:(")
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        self.locationManager.stopMonitoringSignificantLocationChanges()
        
                        for route in routes
                        {
                            let routeOverviewPolyline:NSDictionary = (route as! NSDictionary).value(forKey: "overview_polyline") as! NSDictionary
                            let points = routeOverviewPolyline.object(forKey: "points")
                            let path = GMSPath.init(fromEncodedPath: points! as! String)
                            if let polyline = self.polyline {
                                polyline.map = nil
                            }
                            self.polyline = GMSPolyline.init(path: path)
                            self.polyline?.strokeWidth = 4
                            
                            let bounds = GMSCoordinateBounds(path: path!)
                            self.mapView!.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 30.0))
                            self.polyline?.map = self.mapView
                        }
                    }
                }catch let error as NSError{
                    print("error:\(error)")
                    self.showAlert(title: "Ooops!", message: error.localizedDescription)
                }
            }
            task.resume()
    }
    
    @IBAction func changeMapStyle(_ button: UIButton) {
        var styleName: String
        
        if nightStyle {
            nightStyle = false
            styleName = "defaultStyle"
            button.setImage(UIImage(named: "moon5"), for: .normal)
        } else {
            nightStyle = true
            styleName = "nightStyle"
            button.setImage(UIImage(named: "moon2"), for: .normal)
        }
        
        do {
            if let styleURL = Bundle.main.url(forResource: styleName, withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                NSLog("Unable to find JSON file")
            }
        } catch {
            NSLog("One or more of the map styles failed to load. \(error)")
        }
    }
}

//request on location
extension MapVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse else {
            return
        }
        locationManager.startUpdatingLocation()
        mapView.isMyLocationEnabled = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
    }
}

extension MapVC: GMSMapViewDelegate  {
    func hideIcons() {
        mapView.settings.myLocationButton = false
        self.start.isHidden = true
        self.destination.isHidden = true
        self.showPath.isHidden = true
        self.nightMode.isHidden = true
    }
    
    func showIcons() {
        mapView.settings.myLocationButton = true
        self.start.isHidden = false
        self.destination.isHidden = false
        self.showPath.isHidden = false
        self.nightMode.isHidden = false
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        print("You tapped at \(coordinate.latitude), \(coordinate.longitude)")
        if mapView.settings.myLocationButton == true {
            hideIcons()
        } else {
            showIcons()
        }
    }
}

extension MapVC {
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
}




