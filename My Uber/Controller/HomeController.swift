//
//  HomeController.swift
//  My Uber
//
//  Created by Dawid Jaskulski on 27/03/2020.
//  Copyright © 2020 Dawid Jaskulski. All rights reserved.
//

import UIKit
import Firebase
import MapKit

private let reuseIdentifier = "LocationCell"
private let annotationIdentifier = "DriverAnnotation"

private enum ActionButtonConfiguration {
    case showMenu
    case dismissActionView
    
    init() {
        self = .showMenu
    }
}

private enum AnnotationType: String {
    case pickup
    case destination
}

protocol HomeControllerDelegate: class {
    func handleMenuToogle()
}

class HomeController: UIViewController
{
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        enableLocationServices()
        configureUI()
    }

    
    //MARK: - Properties
    private let locationManager = LocationHandler.shared.locationManager
    
    private let mapView = MKMapView()
    
    private let locationInputViewHeight: CGFloat = 200
    private let rideActionViewHeight: CGFloat = 300
    
    private let inputActivationView = LocationInputActivationView()
    private let rideActionView = RideActionView()
    private let locationInputView = LocationInputView()
    
    private let tableView = UITableView()
    private var searchResults = [MKPlacemark]()
    private var savedLocations = [MKPlacemark]()
    private var actionButtonConfig = ActionButtonConfiguration()
    private var route: MKRoute?
    
    weak var delegate: HomeControllerDelegate?
    
    var user: User? {
        didSet {
            locationInputView.user = user
            
            //checking if user is passenger cuz drivers will not see other drivers
            if user?.accountType == .passenger {
                fetchDrivers()
                configureLocationInputActivationView()
                observeCurrentTrip()
                configureSavedUserLocations()
            }   else {
                observeTrips()
            }
        }
    }
    
    private var trip: Trip? {
        didSet {
            guard let user = user else {return}
            
            if user.accountType == .driver {
                guard let trip = trip else {return}
                let controller = PickupController(trip: trip)
                controller.delegate = self
                self.present(controller,animated: true, completion: nil)
            }
            else {
                
            }
        }
    }
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        return button
    }()
    
    //MARK: - Selectors
    
    @objc func actionButtonPressed() {
        if actionButtonConfig == .showMenu {
            delegate?.handleMenuToogle()
        }
        else if actionButtonConfig == .dismissActionView{
            removeAnnotationsAndOverlays()
            //zoom out on all annotations (drivers and user)
            mapView.showAnnotations(mapView.annotations, animated: true)
            
            UIView.animate(withDuration: 0.3) {
                self.inputActivationView.alpha = 1
                self.configureActionButton(config: .showMenu)
                self.animateRideActionView(shouldShow: false)
            }

        }
    }
    //MARK: -  Passenger API
    
    func observeCurrentTrip() {
        PassengerService.shared.observeCurrentTrip { (trip) in
            self.trip = trip
            guard let driverUid = trip.driverUid else {return}
            //have to unwrap cuz cant do switch on optional value
            guard let state = trip.state else {return}
            
            switch state {
                
            case .requested:
                break
                
            case .accepted:
                self.shouldPresentLoadingView(present: false)
                //get only one annotation with our driver
                self.removeAnnotationsAndOverlays()
                self.zoomForActiveTrip(withDriverUid: driverUid)
                
                Service.shared.fetchUserData(uid: driverUid) { (driver) in
                    self.animateRideActionView(shouldShow: true,
                                               config: .tripAccepted,
                                               user: driver)
                }
            case .driverArrived:
                self.rideActionView.config = .driverArrived
                
            case .inProgress:
                self.rideActionView.config = .tripInProgress
                
            case .arrivedAtDestination:
                self.rideActionView.config = .endTrip
                
            case .completed:
                PassengerService.shared.deleteTrip { (error, ref) in
                    self.animateRideActionView(shouldShow: false)
                    self.centerMapOnUserLocation()
                    self.actionButtonConfig = .showMenu
                    self.configureActionButton(config: .showMenu)
                    self.inputActivationView.alpha = 1
                    self.presentAlertController(withTitle: "Trip Completed", message: "We hope you enjoyed your trip.")
                }
                
            }
        }
    }
    
    func startTrip() {
        guard let trip = self.trip else {return}
        DriverService.shared.updateTripState(trip: trip, state: .inProgress) { (error, ref) in
            self.rideActionView.config = .tripInProgress
            self.removeAnnotationsAndOverlays()
            self.mapView.addAnnotationAndSelect(forCoordinate: trip.destinationCoordinates)
            
            let placemark = MKPlacemark(coordinate: trip.destinationCoordinates)
            let mapItem = MKMapItem(placemark: placemark)
            
            self.setCustomRegion(withType: .destination, coordinates: trip.destinationCoordinates)
            
            self.generatePolyLine(toDestination: mapItem)
            
            self.mapView.zoomToFit(annotations: self.mapView.annotations)
        }
    }
    
    
    func fetchDrivers() {
        
        guard let location = locationManager?.location else {return}
        PassengerService.shared.fetchDrivers(location: location) { (driver) in
            guard let coordinate = driver.location?.coordinate else {return}
            let annotation = DriverAnnotation(uid: driver.uid, coordinate: coordinate)
            
            var driverIsVisible: Bool {
                //if annotation has same uid as as driver, annotation is visible
                // else return false and add new annotation on map
                return self.mapView.annotations.contains { (annotation) -> Bool in
                    guard let driverAnno = annotation as? DriverAnnotation else {return false}
                    if driverAnno.uid == driver.uid
                    {
                        //update postition here
                        driverAnno.updateAnnotationPosition(withCoordinate: coordinate)
                        self.zoomForActiveTrip(withDriverUid: driver.uid )
                        return true
                    }
                    return false
                }
                
            }
            
            if !driverIsVisible {
                self.mapView.addAnnotation(annotation)
            }
            
        }
    }
    
    //MARK: - Drivers API
    
    func observeTrips() {
        DriverService.shared.observeTrips { (trip) in
            self.trip = trip
        }
    }
    
    func observeCancelledTrip(trip: Trip) {
        DriverService.shared.observeTripCancelled(trip: trip) {
            self.removeAnnotationsAndOverlays()
            self.animateRideActionView(shouldShow: false)
            //zooming out when user cancel trip
            self.centerMapOnUserLocation()
            self.presentAlertController(withTitle: "Oops!", message: "The passenger has decided to cancel this ride. Press Ok to continue.")
        }
        
    }

    //MARK: - Helper Functions

    
    fileprivate func configureActionButton(config: ActionButtonConfiguration) {
        if config == .showMenu {
            self.actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonConfig = .showMenu
        }
        else {
            actionButton.setImage(#imageLiteral(resourceName: "baseline_arrow_back_black_36dp-1").withRenderingMode(.alwaysOriginal), for: .normal)
            actionButtonConfig = .dismissActionView
        }
    }
    
    func configureSavedUserLocations() {
        guard let user = user else {return}
        //have to clear array to avoid duplicate
        savedLocations.removeAll()
        
        if let homeLocation = user.homeLocation {
            geocodeAddressString(address: homeLocation)
        }
        
        if let workLocation = user.workLocation {
            geocodeAddressString(address: workLocation)
        }
    }
    
    func geocodeAddressString(address: String) {
        //Creating placemarks from String!!! But there are CLplacemarks so have to convert them into MKPlacemark
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            guard let clPlacemark = placemarks?.first else {return}
            let placemark = MKPlacemark(placemark: clPlacemark)
            
            self.savedLocations.append(placemark)
            self.tableView.reloadData()
        }
    }
    
    func configureUI()
    {
        configueMapView()
        
        configureRideActionView()
        
        
        view.addSubview(actionButton)
        actionButton.anchor(top:view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, paddingTop: 16, paddingLeft: 20, width: 30, height: 30)
        

        configureTableView()
    }
    
    func configureLocationInputActivationView() {
        guard user != nil else {return}
        
        inputActivationView.delegate = self
        view.addSubview(inputActivationView)
        inputActivationView.centerX(inView: view)
        inputActivationView.setDimensions(height: 50, width: view.frame.width - 64)
        inputActivationView.anchor(top: actionButton.bottomAnchor, paddingTop: 32)
        //make invisbile to animate it
        inputActivationView.alpha = 0
        UIView.animate(withDuration: 2) {
            self.inputActivationView.alpha = 1
        }

    }
    func configueMapView()
    {
        view.addSubview(mapView)
        mapView.frame = view.frame
        
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = self
    }
    
    func configureLocationInputView() {
        locationInputView.delegate = self
        view.addSubview(locationInputView)
        locationInputView.anchor(top: view.topAnchor, left: view.leftAnchor,
                                 right: view.rightAnchor, height: locationInputViewHeight)
        locationInputView.alpha = 0
        
        UIView.animate(withDuration: 0.5, animations: {
            self.locationInputView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, animations: {
                self.tableView.frame.origin.y = self.locationInputViewHeight
            })
        }
    }
    
    func configureRideActionView() {
        view.addSubview(rideActionView)
        rideActionView.delegate = self
        rideActionView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: rideActionViewHeight)
    }
    
    func configureTableView(){
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(LocationCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.rowHeight = 60
        tableView.tableFooterView = UIView()
        
        let height = view.frame.height - locationInputViewHeight
        tableView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: height)
        
        view.addSubview(tableView)
    }
    
    func dismissLocationView(completion: ((Bool)->Void)? = nil)
    {
        
        UIView.animate(withDuration: 0.3, animations: {
            self.locationInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.frame.height
            self.locationInputView.removeFromSuperview()
           
        }, completion: completion)
    }
    
    func animateRideActionView(shouldShow: Bool = false, destination: MKPlacemark? = nil, config: RideActionViewConfiguration? = nil, user: User? = nil) {
        UIView.animate(withDuration: 0.3) {
            // if ride action shouldnt show up it will be hidden on the bottom of view cuz
            //  y of the actionView will be height of the general view
            
            let yOrigin = shouldShow ? self.view.frame.height - self.rideActionViewHeight : self.view.frame.height
            
            UIView.animate(withDuration: 0.3) {
                self.rideActionView.frame.origin.y = yOrigin
            }
            
            if shouldShow {
                guard let config = config else {return}
                
                if let user = user {
                    self.rideActionView.user = user
                }
                
                //showing address on actionView
                if let destination = destination {
                    self.rideActionView.destination = destination
                }
                self.rideActionView.config = config
            }
        }
    }
}

//MARK: - Map Helper Functions

private extension HomeController {
    func searchBy(naturalLanguageQuery: String, completion: @escaping([MKPlacemark])->Void) {
        var results = [MKPlacemark]()
        
        let request = MKLocalSearch.Request()
        request.region = mapView.region
        request.naturalLanguageQuery = naturalLanguageQuery
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            guard let response = response else {return}
            //response contains array of mapItem. Append them to array and then in complete array of results
            response.mapItems.forEach { (item) in
                results.append(item.placemark)
            }
            completion(results)
        }
    }
    
    func generatePolyLine(toDestination destination: MKMapItem) {
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination
        request.transportType = .automobile
        
        let directionRequest = MKDirections(request: request)
        directionRequest.calculate { (response, error) in
            guard let response = response else {return}
            self.route = response.routes[0]
            guard let polyline = self.route?.polyline else {return}
            self.mapView.addOverlay(polyline)
        }
    }
    
    func removeAnnotationsAndOverlays() {
        self.mapView.annotations.forEach { (annotation) in
            if let annotation = annotation as? MKPointAnnotation{
                self.mapView.removeAnnotation(annotation)
            }
        }
        //remove all saved routes when (happens when click on back button)
        if mapView.overlays.count > 0 {
            mapView.removeOverlay(mapView.overlays[0])
        }
    }
    
    func centerMapOnUserLocation() {
        guard let coordinate = locationManager?.location?.coordinate else {return}
        let region = MKCoordinateRegion(center: coordinate,
                                        latitudinalMeters: 2000,
                                        longitudinalMeters: 2000)
        mapView.setRegion(region, animated: true)
    }
    
    func setCustomRegion(withType type: AnnotationType, coordinates: CLLocationCoordinate2D) {
        let region = CLCircularRegion(center: coordinates, radius: 40, identifier: type.rawValue)
        locationManager?.startMonitoring(for: region)
    }
    
    func zoomForActiveTrip(withDriverUid uid: String) {
        var annotations = [MKAnnotation]()
        
        self.mapView.annotations.forEach { (annotation) in
            if let anno = annotation as? DriverAnnotation {
                if anno.uid == uid {
                    annotations.append(anno)
                }
            }
            
            if let userAnno = annotation as? MKUserLocation {
                annotations.append(userAnno)
            }
        }
        
        self.mapView.zoomToFit(annotations: annotations)
    }
    
}

//MARK: - MKMapViewDelegate

extension HomeController: MKMapViewDelegate {
    
    //did update user location
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        
        guard let user = self.user else {return}
        guard user.accountType == .driver else {return}
        //create new location from user location cuz function need CLLlocation not MKUserLocation
        guard let location = userLocation.location else {return}
        DriverService.shared.updateDriverLocation(location: location)
    }
    
    //create annotation with custom image
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation {
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            view.image = #imageLiteral(resourceName: "chevron-sign-to-right")
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let route = self.route {
            let polyline = route.polyline
            let lineRenderer = MKPolylineRenderer(overlay: polyline)
            lineRenderer.strokeColor = .mainBlueTint
            lineRenderer.lineWidth = 4
            return lineRenderer
        }
        return MKOverlayRenderer()
    }
}

// MARK: - CLLocationManagerDelegate

extension HomeController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        
        if region.identifier == AnnotationType.pickup.rawValue {
            print("DEBUG: Did start monitoring pick up region \(region)")
        }
        
        if region.identifier == AnnotationType.destination.rawValue {
            print("DEBUG: Did start monitoring destination region \(region)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("DEBUG: Driver did enter passenger regon")
        guard let trip = self.trip else {return}
        
        if region.identifier == AnnotationType.pickup.rawValue {
            DriverService.shared.updateTripState(trip: trip, state: .driverArrived) { (error, ref) in
                self.rideActionView.config = .pickupPassenger
            }
        }
        
        if region.identifier == AnnotationType.destination.rawValue {
            print("DEBUG: Did start monitoring destination region \(region)")
            
            DriverService.shared.updateTripState(trip: trip, state: .arrivedAtDestination) { (error, ref) in
                self.rideActionView.config = .endTrip
            }
        }
        
    }
    
    func enableLocationServices()
    {
        locationManager?.delegate = self
        
        switch CLLocationManager.authorizationStatus()
        {
        case .notDetermined:
            locationManager?.requestWhenInUseAuthorization()
            
        case .restricted:
            break
        case .denied:
            break
            
        case .authorizedAlways:
            locationManager?.startUpdatingLocation()
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            
        case .authorizedWhenInUse:
            locationManager?.requestAlwaysAuthorization()
            
        @unknown default:
            break
        }
        
    }
}

//MARK: - LocationInputActivationViewDelegate
extension HomeController: LocationInputActivationViewDelegate
{
    func presentLocationInputView() {
        inputActivationView.alpha = 0
        configureLocationInputView()
    }
}

//MARK: - LocationInputViewDelegate
extension HomeController: LocationInputViewDelegate
{
    func executeSearch(query: String) {
        searchBy(naturalLanguageQuery: query) { (results) in
            print("DEBUG: \(results)")
            self.searchResults = results
            self.tableView.reloadData()
        }
    }
    
    func dismissLocationInputView() {
        dismissLocationView { _ in
            UIView.animate(withDuration: 0.5, animations: {
                self.inputActivationView.alpha = 1
            })
        }
    }
}

//MARK: - TableViewDelegates

extension HomeController: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Saved Locations" : "Results"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? savedLocations.count : searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! LocationCell
        
        if indexPath.section == 0 {
            cell.placemark = savedLocations[indexPath.row]
        }
        
        if indexPath.section == 1{
            cell.placemark = searchResults[indexPath.row]
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        let selectedPlacemark = indexPath.section == 0 ? savedLocations[indexPath.row] : searchResults[indexPath.row]

        
        configureActionButton(config: .dismissActionView)

        let destination = MKMapItem(placemark: selectedPlacemark)
        generatePolyLine(toDestination: destination)
        
        //create and add new placemarks when user click on table view adress
        dismissLocationView { _ in
            self.mapView.addAnnotationAndSelect(forCoordinate: selectedPlacemark.coordinate)
            
            //Making sure that annotation isnt driver
            let annotations = self.mapView.annotations.filter({!$0.isKind(of: DriverAnnotation.self)})
            // zooming into route between user and placemark
            self.mapView.zoomToFit(annotations: annotations)
            
            
            self.animateRideActionView(shouldShow: true, destination: selectedPlacemark, config: .requestRide)
            
        }
        

    }
}
//MARK: - RideActionViewDelegate

extension HomeController: RideActionViewDelegate {

    func uploadTrip(_ view: RideActionView) {
        guard let pickupCoordinates = locationManager?.location?.coordinate else {return}
        guard let destinationCoordinates = view.destination?.coordinate else {return}
        
        shouldPresentLoadingView(present: true, message: "Finding you a ride...")
        
        PassengerService.shared.uploadTrip(pickupCoordinates: pickupCoordinates, destinationCoordinates: destinationCoordinates) { (error, ref) in
            if error != nil {
                print("DEBUG: \(pickupCoordinates)")
                print("Failed to upload trip \(String(describing: error?.localizedDescription))")
                return
            }
            
            UIView.animate(withDuration: 0.3) {
                self.rideActionView.frame.origin.y = self.view.frame.height
            }
        }
    }
    func dropOffPassenger() {
        
        guard let trip = self.trip else {return}
        DriverService.shared.updateTripState(trip: trip, state: .completed) { (error, ref) in
            self.removeAnnotationsAndOverlays()
            self.centerMapOnUserLocation()
            self.animateRideActionView(shouldShow: false)
        }
    }
    
    func pickupPassenger() {
        startTrip()
    }
    
    func cancelTrip() {
        PassengerService.shared.deleteTrip { (error, ref) in
            if error != nil {
                print("Failed with canceling trip \(String(describing: error))")
                return
            }
            //zooming out after cancel trip
            self.centerMapOnUserLocation()
            self.animateRideActionView(shouldShow: false)
            self.removeAnnotationsAndOverlays()
            
            self.actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonConfig = .showMenu
            
            self.inputActivationView.alpha = 1
        }
    }
}

//MARK: - PickupControllerDelegate

extension HomeController: PickupControllerDelegate {
    func didAcceptTrip(trip: Trip) {
        self.trip = trip
        
        self.mapView.addAnnotationAndSelect(forCoordinate: trip.pickupCoordinates)

        
        //Creating new Region circle, when driver will be in circle status of trip will be pickup
        setCustomRegion(withType: .pickup, coordinates: trip.pickupCoordinates)
        
        let placemark = MKPlacemark(coordinate: trip.pickupCoordinates)
        let mapItem = MKMapItem(placemark: placemark)
        
        generatePolyLine(toDestination: mapItem)
        
        mapView.zoomToFit(annotations: mapView.annotations)
        
        //Happend when user cancel trip
        observeCancelledTrip(trip: trip)
        
        
        self.dismiss(animated: true) {
            Service.shared.fetchUserData(uid: trip.passengerUid) { (passenger) in
            self.animateRideActionView(shouldShow: true, config: .tripAccepted, user: passenger)
            }
        }
    }
}
