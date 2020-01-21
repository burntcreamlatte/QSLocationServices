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
import AVFoundation

class MapScreen: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //potential better array as property in file
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        (directionsTableView.directions?.steps.count ?? 1) - 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "directionsCell", for: indexPath)
        //directionsTableView.directions?.steps.remove(at: 0)
        var correctedStepsArray = directionsTableView.directions?.steps
        correctedStepsArray?.remove(at: 0)
        let step = correctedStepsArray?[indexPath.row]
        let instructions = step?.instructions
        
        if instructions != nil {
            cell.textLabel?.text = "\(instructions ?? "void")"
        }

        return cell
    }
    
    //MARK: - Outlets
    
    @IBOutlet weak var routeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var routeButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var directionsTableView: DirectionsTableView!
    @IBOutlet weak var etaLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var routeButtonYBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var currentDirectionStepLabel: UILabel!
    
    //MARK: - Properties
    static var shared = MapScreen()
    
    let locationManager = CLLocationManager()
    let regionInMeters: Double = 2000
    var previousLocation: CLLocation?
    var currentCoordinate: CLLocationCoordinate2D!
    
    let geoCoder = CLGeocoder()
    var routingSteps = [MKRoute.Step]()
    var stepCounter = 0 //
    
    var directionsArray = [MKDirections]()
    let speechSynthesizer = AVSpeechSynthesizer()
    
    var selectedSpot: SpotAnnotation?
    var geoFenceRegion = CLCircularRegion()
    let postDistanceLimit: Double = 245
        
    //annotations array
    
    
    //MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.register(CustomAnnotation.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        directionsTableView.delegate = self //
        directionsTableView.dataSource = self //
        addressLabel.isHidden = true
        directionsTableView.isHidden = true
        designRouteButtonAndView()
        designClearButton()
        checkLocationServices()
        self.mapView.showsUserLocation = true //may need moved
        locationManager.distanceFilter = 1609
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print(mapView.userLocation.coordinate)
            geoFenceRegion = CLCircularRegion(center: mapView.userLocation.coordinate, radius: locationManager.distanceFilter, identifier: "userRadius")
            locationManager.startMonitoring(for: geoFenceRegion)
            print(geoFenceRegion.center.self)
            print(mapView.userLocation.coordinate)
            //let circle = MKCircle(center: geoFenceRegion.center.self, radius: locationManager.distanceFilter)
            //mapView.addOverlay(circle)
    }
    
    // MARK: - Actions
    
    @IBAction func routeButtonTapped(_ sender: UIButton) {
        if routeSegmentedControl.selectedSegmentIndex == 0 {
            //getDirections() does not work with current requirements to annotation
            if !directionsTableView.isHidden {
                UIView.animate(withDuration: 1.0) {
                    self.routeButtonYBottomConstraint.constant = self.addressLabel.frame.height + self.directionsTableView.frame.height + 16
                }
            }
        } else if routeSegmentedControl.selectedSegmentIndex == 1 {
            //TODO
            presentPostSpotAlert()
            
        }
    }
    
    @IBAction func routeSegmentedControlToggled(_ sender: UISegmentedControl) {
        designRouteButtonAndView()
    }
    @IBAction func clearButtonTapped(_ sender: UIButton) {
        mapView.removeOverlays(mapView.overlays)
        etaLabel.text = ""
        distanceLabel.text = ""
        mapView.deselectAnnotation(mapView.selectedAnnotations[0], animated: true)
        hideRoutingAndReplaceButton()
    }
    
    func hideRoutingAndReplaceButton() {
        self.addressLabel.isHidden = true
        self.directionsTableView.isHidden = true
        self.routeButtonYBottomConstraint.constant = 16
    }
    
    func showRoutingAndReplaceButton() {
        self.addressLabel.isHidden = false
        self.directionsTableView.isHidden = false
        self.routeButtonYBottomConstraint.constant = addressLabel.frame.height + directionsTableView.frame.height + 16
    }
    
    //MARK: Setup Location Manager
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest //best for navigation?
    }
    
    //MARK: Center View on User Location
    
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    //MARK: Check Location Services
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        } else {
            //show alert to user to allow location services
        }
    }
    
    //MARK: Check Location Auth
    
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
    
    // MARK: Start Tracking User Location
    
    func startTrackingUserLocation() {
        //would test to determine when phone suspended
        //refocuses view onto center of user; will need to allow people to look around map
        centerViewOnUserLocation()
        //self.mapView.showsUserLocation = true
        locationManager.startUpdatingLocation()
        previousLocation = getCenterLocation(for: mapView)
    }
    
    // MARK: Design Route Button and View
    
    func designRouteButtonAndView() {
        if routeSegmentedControl.selectedSegmentIndex == 0 {
        routeButton.layer.backgroundColor = UIColor.systemGreen.cgColor
        
        routeButton.setTitle("Route", for: .normal)
        routeButton.setTitleColor(.white, for: .normal)
        
        routeButton.layer.cornerRadius = routeButton.frame.height / 2
            
        //SHOW
        //showRoutingAndReplaceButton()

        } else if routeSegmentedControl.selectedSegmentIndex == 1 {
            //mapView.removeOverlays(mapView.overlays)
            routeButton.layer.backgroundColor = UIColor.systemBlue.cgColor
            
            routeButton.setTitle("Post", for: .normal)
            routeButton.setTitleColor(.white, for: .normal)
            
            routeButton.layer.cornerRadius = routeButton.frame.height / 2
            //HIDE
            hideRoutingAndReplaceButton()
        }
    }
    
    func designClearButton() {
        clearButton.layer.backgroundColor = UIColor.black.cgColor
        
        clearButton.setTitle("Clear UI", for: .normal)
        clearButton.setTitleColor(.white, for: .normal)
        
        clearButton.layer.cornerRadius = routeButton.frame.height / 2
    }
    
    // MARK: Present Post Alert Controller
    
    func presentPostSpotAlert() {
        let title = NSLocalizedString("Post a spot here?", comment: "")
        let message = NSLocalizedString("Message", comment: "")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "")
        let postActionTitle = NSLocalizedString("Post", comment: "")
        let hideActionTitle = NSLocalizedString("Hide", comment: "")
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Create the actions.
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel) { _ in
            print("Cancel action occurred.")
        }
        
        let postAction = UIAlertAction(title: postActionTitle, style: .default) { _ in
            print("Post action occurred.")
            guard let text = alertController.textFields?.first?.text, !text.isEmpty else { return }
            //let coordinate = self.getCenterLocation(for: self.mapView).coordinate
            //let date = Date().formatted()
            //TODO; Date().timeAgo() functionality
            //self.placeCustomAnnotation(title: text, subtitle: "Posted at \(Date().formatted())", locationName: "", discipline: "", coordinate: coordinate)
            //self.timePostedLabel.text = "\(Date.formatted(Date()))"
            self.addAnnotation(title: text, description: "desc", coordinate: self.getCenterLocation(for: self.mapView).coordinate)
        }
        
        
        let hideAction = UIAlertAction(title: hideActionTitle, style: .destructive) { _ in
            print("Hide action occurred.")
            //TODO: hide/*delete* annotation
            print("Checking to see how many spots are currently on the whole mapView: \(self.mapView.annotations.count)")
        }
        
        // Add the actions.
        alertController.addAction(cancelAction)
        alertController.addAction(postAction)
        alertController.addAction(hideAction)
        alertController.addTextField { (textFieldTitle) in
            textFieldTitle.placeholder = "Name your spot"
            textFieldTitle.autocorrectionType = .yes
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    //extra testing
    
    //MARK: Place Custom Annotation
    func placeCustomAnnotation(title: String, subtitle: String, locationName: String, discipline: String, coordinate: CLLocationCoordinate2D) {
        
        let annotation = SpotAnnotation(title: title, subtitle: subtitle, locationName: locationName, discipline: discipline, coordinate: coordinate)
        mapView.addAnnotation(annotation)
        
    }
    
}

// MARK: - CLLocationManagerDelegate

extension MapScreen: CLLocationManagerDelegate {
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//            guard let location = locations.last else { return }
//            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
//            let region = MKCoordinateRegion.init(center: center, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
//            mapView.setRegion(region, animated: true)
            //manager.stopUpdatingLocation()
            guard let currentLocation = locations.first else { return }
            currentCoordinate = currentLocation.coordinate
            mapView.userTrackingMode = .followWithHeading
        }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
    
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    // MARK: Get Distance
    
    func getDistance() {
        
    }
    
    
    
    // MARK: Get Directions
    
    func getDirections() {
        
        showRoutingAndReplaceButton()
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
                let steps = route.steps //mnn
                //steps.removeFirst()
                
                //MARK:
                
                self.locationManager.monitoredRegions.forEach( {self.locationManager.stopMonitoring(for: $0)} )
                
                self.routingSteps = route.steps
                self.mapView.addOverlay(route.polyline)
                //will need to bring rect out more
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                
                //shows individual routing steps
                //steps.remove(at: 0)
//                for step in steps {
//                    print(step.instructions)
//                }
                for i in 0 ..< route.steps.count {
                    let step = route.steps[i]
                    print(step.instructions)
                    print(step.distance)
                    let region = CLCircularRegion(center: step.polyline.coordinate, radius: 20, identifier: "\(i)")
                    self.locationManager.startMonitoring(for: region)
                    let circle = MKCircle(center: region.center, radius: region.radius)
                    self.mapView.addOverlay(circle)
                }
//                let initialMessage = "Yo how dope is this? I'm guessing you guys would love this in, yeah?"
//                let speechUtterance = AVSpeechUtterance(string: initialMessage)
//                self.speechSynthesizer.speak(speechUtterance)
//                self.currentDirectionStepLabel.text = initialMessage
                //STEP COUNTER
                self.stepCounter += 1
                if self.stepCounter < self.routingSteps.count {
                    let currentStep = self.routingSteps[self.stepCounter]
                    let message = "In \((currentStep.distance*3.28084)) feet, \(self.routingSteps[self.stepCounter].instructions)"
                    self.currentDirectionStepLabel.text = message
                    let speechUtterance = AVSpeechUtterance(string: message)
                    self.speechSynthesizer.speak(speechUtterance)
                } else {
                    let message = "Hot dang, y'all arrived at your destination, bruh"
                    self.currentDirectionStepLabel.text = message
                    let speechUtterance = AVSpeechUtterance(string: message)
                    self.speechSynthesizer.speak(speechUtterance)
                    self.stepCounter = 0
                    
                    self.locationManager.monitoredRegions.forEach({ self.locationManager.stopMonitoring(for: $0) })
                }
                self.directionsTableView.directions = route
                //TODO; format
                //self.etaLabel.text = ("\(Int((route.expectedTravelTime)/60)) min")
                self.etaLabel.text = "ETA: \(Date.formatted(Date().advanced(by: route.expectedTravelTime))())"
                let formattedDistance = route.distance / 1000
                self.distanceLabel.text = String(format: "%.01fmi", formattedDistance)
                self.directionsTableView.reloadData()
            }
        }
    }
    
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        
        //getcenter
        let destinationCoordinate = mapView.selectedAnnotations[0].coordinate
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
        self.mapView.removeOverlays(self.mapView.overlays)
        directionsArray.append(directions)
        //only cancels a PENDING REQUEST, does not remove
        let _ = directionsArray.map { $0.cancel() }
    }
        
    func clearMapView() {
        mapView.removeOverlays(mapView.overlays)
        //mapView.removeAnnotations(mapView.annotations)
    }
    
    // MARK: - Annotations

    func addAnnotation(title: String, postedTime: Date = Date(), description: String?, coordinate: CLLocationCoordinate2D) {
        
        //let center = getCenterLocation(for: mapView).coordinate

        let parkingSpotAnnotation = SpotAnnotation(title: title, subtitle: "Spotted at \(postedTime.formatted())", locationName: "", discipline: "", coordinate: coordinate)
        //parkingSpotAnnotation.title = title
        //parkingSpotAnnotation.subtitle = "Spotted at \(postedTime.formatted())"
        print(postedTime.formatted())
        //parkingSpotAnnotation.coordinate = center
        let userLoc = CLLocation(latitude: self.mapView.userLocation.coordinate.latitude, longitude: self.mapView.userLocation.coordinate.longitude)
        let spotLoc = CLLocation(latitude: parkingSpotAnnotation.coordinate.latitude, longitude: parkingSpotAnnotation.coordinate.longitude)
        let distance = userLoc.distance(from: spotLoc)
        let formattedDistance = distance / 1000
        self.distanceLabel.text = "Test Spot Distance: " + String(format: "%.01fmi", formattedDistance)
        print(distance)
        if distance > locationManager.distanceFilter {
            print("Too Far to post")
        }
        if distance > postDistanceLimit {
            print("Too Far to post")
        }
//        if parkingSpotAnnotation.coordinate. {
//        }
        self.mapView.addAnnotation(parkingSpotAnnotation)

    }
//    private func setupBridgeAnnotationView(for annotation: BridgeAnnotation, on mapView: MKMapView) -> MKAnnotationView {
//        let identifier = NSStringFromClass(BridgeAnnotation.self)
//        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier, for: annotation)
//        if let markerAnnotationView = view as? MKMarkerAnnotationView {
//            markerAnnotationView.animatesWhenAdded = true
//            markerAnnotationView.canShowCallout = true
//            markerAnnotationView.markerTintColor = UIColor(named: "internationalOrange")
//
//
//            let rightButton = UIButton(type: .detailDisclosure)
//            markerAnnotationView.rightCalloutAccessoryView = rightButton
//        }
//
//        return view
//    }
}

// MARK: - MKMapViewDelegate

extension MapScreen: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        //find a way to ignore center location if user is not placing pin
        let center = getCenterLocation(for: mapView)
        //let geoCoder = CLGeocoder()
        
        guard let previousLocation = self.previousLocation else { return }
        //must me more than 50 meters difference before updates request for location
        guard center.distance(from: previousLocation) > 25 else { return }
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

//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let latestLocation = locations.first else { return }
//
//        centerViewOnUserLocation()
//        constructRoute(userLocation: latestLocation.coordinate)
//    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        //POLYLINES
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 5
            
            return renderer
        }
        //CIRCLE GEOFENCE TESTER
        if overlay is MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay as! MKCircle)
            renderer.strokeColor = .red
            renderer.fillColor = .clear
            renderer.alpha = 0.5
            
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        guard let annotation = annotation as? SpotAnnotation else { return nil }
        let identifier = "spotMarker"
        var view: MKMarkerAnnotationView
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            //view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view = CustomAnnotation(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: 0, y: 0)
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            
        }
        return view
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        MapScreen.shared.selectedSpot = view.annotation as? SpotAnnotation
        print("Annotation selected: \(String(describing: view.annotation?.title))")
        print("Annotion coordinates: \(String(describing: view.annotation?.coordinate))")
        
        getDirections()
        
        
        
//        if !directionsTableView.isHidden {
//            self.directionsTableView.isHidden = true
//            self.addressLabel.isHidden = true
//            self.routeButtonYBottomConstraint.constant = 16
//        }
        
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        print("Annotation deselected: \(String(describing: view.annotation?.title))")
        
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered \(region.identifier).")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited \(region.identifier).")
    }
}
