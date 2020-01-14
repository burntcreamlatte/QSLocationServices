//
//  MapScreen.swift
//  TestMap
//
//  Created by Aaron Shackelford on 1/8/20.
//  Copyright © 2020 Aaron Shackelford. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

class MapScreen: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return directionsTableView.directions?.steps.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "directionsCell", for: indexPath)
        //directionsTableView.directions?.steps.remove(at: 0)
        var correctedStepsArray = directionsTableView.directions?.steps
        let step = correctedStepsArray?[indexPath.row]
        let instructions = step?.instructions
        
        cell.textLabel?.text = "\(instructions ?? "")"

        return cell
    }
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var routeButton: UIButton!
    @IBOutlet weak var directionsTableView: DirectionsTableView!
    @IBOutlet weak var etaLabel: UILabel!
    
    
    let locationManager = CLLocationManager()
    let regionInMeters: Double = 10000
    var previousLocation: CLLocation?
    
    let geoCoder = CLGeocoder()
    var directionsArray = [MKDirections]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        directionsTableView.delegate = self
        directionsTableView.dataSource = self
        designRouteButton()
        checkLocationServices()
        self.mapView.showsUserLocation = true //may need moved
    }
    
    @IBAction func routeButtonTapped(_ sender: UIButton) {
        getDirections()
    }
    
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest //best for navigation?
    }
    
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        } else {
            //show alert to user to allow location services
        }
    }
    
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            break
        case .authorizedWhenInUse:
            startTrackingUserLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            //show alert for parental controls/MDM
            break
        case .denied:
            //show alert instructing them how to turn on permissions
            break
        @unknown default:
            print("Unknown error occured during checking location authorization permissions.")
            fatalError()
        }
    }
    
    func startTrackingUserLocation() {
        //would test to determine when phone suspended
        //refocuses view onto center of user; will need to allow people to look around map
        centerViewOnUserLocation()
        //self.mapView.showsUserLocation = true
        locationManager.startUpdatingLocation()
        previousLocation = getCenterLocation(for: mapView)
    }
    
    func designRouteButton() {
        routeButton.layer.backgroundColor = UIColor.systemGreen.cgColor
        
        routeButton.setTitle("Route", for: .normal)
        routeButton.setTitleColor(.white, for: .normal)
        
        routeButton.layer.cornerRadius = routeButton.frame.height / 2
    }
    
    //extra testing
    
}

extension MapScreen: CLLocationManagerDelegate {
    //    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    //        guard let location = locations.last else { return }
    //        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    //        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
    //        mapView.setRegion(region, animated: true)
    //    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
    
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    func getDirections() {
        guard let location = locationManager.location?.coordinate else {
            //show error message
            print("Error in getting directions.")
            return
        }
        
        let request = createDirectionsRequest(from: location)
        let directions = MKDirections(request: request)
        
        //reseting map with NEW directions here to cancel old directions list
        resetMapView(withNew: directions)
        
        directions.calculate { [unowned self] (response, error) in
            guard let response = response else { return } //show response in alertcontroller
            
            for route in response.routes {
                //if steps are needed
                var steps = route.steps
                self.mapView.addOverlay(route.polyline)
                //will need to bring rect out more
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                
                //shows individual routing steps
                for step in steps {
                    print(step.instructions)
                    if !step.instructions.isEmpty {
                        steps.remove(at: 0)
                    }
                }
                self.directionsTableView.directions = route
                self.directionsTableView.reloadData()
            }
        }
    }
    
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        let destinationCoordinate = getCenterLocation(for: mapView).coordinate
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        //likely won't need but here it is
        //request.requestsAlternateRoutes = true
        
        return request
    }
    
    
    func resetMapView(withNew directions: MKDirections) {
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        //only cancels a PENDING REQUEST, does not remove
        let _ = directionsArray.map { $0.cancel() }
    }
    
    func getDirectionsTest() {
        guard let location = locationManager.location?.coordinate else {
            //show error message
            print("Error in getting directions.")
            return
        }
        
        let request = createDirectionsRequest(from: location)
        let directions = MKDirections(request: request)
        //reseting map with NEW directions here to cancel old directions list
        resetMapView(withNew: directions)
        
        directions.calculate { [unowned self] (response, error) in
            guard let response = response else { return } //show response in alertcontroller
            
            for route in response.routes {
                //if steps are needed
                //route.expectedTravelTime //will need this
                let steps = route.steps
                self.mapView.addOverlay(route.polyline)
                //will need to bring rect out more
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                
                //shows individual routing steps
                for step in steps {
                    print(step.instructions)
                    
                }
            }
        }
        
        func clearMapView() {
            mapView.removeOverlays(mapView.overlays)
        }
    }
}
extension MapScreen: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getCenterLocation(for: mapView)
        //let geoCoder = CLGeocoder()
        
        guard let previousLocation = self.previousLocation else { return }
        //must me more than 50 meters difference before updates request for location
        guard center.distance(from: previousLocation) > 50 else { return }
        self.previousLocation = center
        
        geoCoder.cancelGeocode()
        
        //        After initiating a reverse-geocoding request, do not attempt to initiate another reverse- or forward-geocoding request. Geocoding requests are rate-limited for each app, so making too many requests in a short period of time may cause some of the requests to fail. When the maximum rate is exceeded, the geocoder passes an error object with the value CLError.Code.network to your completion handler.
        geoCoder.reverseGeocodeLocation(center) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            guard let placemark = placemarks?.first else {
                //show alert to user
                return
            }
            
            let streetNumber = placemark.subThoroughfare ?? ""
            let streetName = placemark.thoroughfare ?? ""
            
            DispatchQueue.main.async {
                self.addressLabel.text = "\(streetNumber) \(streetName)"
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .purple
        
        return renderer
    }
}
