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

class HomeController: UIViewController
{
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkIfUserIsLoggedIn()
        enableLocationServices()
        fetchUserData()
        fetchDrivers()
    }
    
    
    //MARK: - Properties
    private let locationManager = LocationHandler.shared.locationManager
    
    private let mapView = MKMapView()
    
    private let locationInputViewHeight: CGFloat = 200
    private let inputActivationView = LocationInputActivationView()
    private let locationInputView = LocationInputView()
    
    private let tableView = UITableView()
    
    private var user: User? {
        didSet {
            locationInputView.user = user
        }
    }
    //MARK: -  API
    func fetchUserData() {
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        Service.shared.fetchUserData(uid: currentUid) { (user) in
            self.user = user
        }
    }
    
    func fetchDrivers() {
        print("HWDP")

        guard let location = locationManager?.location else {return}
        Service.shared.fetchDrivers(location: location) { (driver) in
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
    
    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil{
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: LoginController())
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true, completion: nil)
            }
        }
        else {
            configureUI()
        }
    }
    
    func signOut() {
        do
        {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: LoginController())
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true, completion: nil)
            }
        }
        catch let error {
            print("Error with signing out user \(error)")
        }
    }
    //MARK: - Helper Functions
    
    func configureUI()
    {
        configueMapView()
        configureTableView()
        
        inputActivationView.delegate = self
        view.addSubview(inputActivationView)
        inputActivationView.centerX(inView: view)
        inputActivationView.setDimensions(height: 50, width: view.frame.width - 64)
        inputActivationView.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 32)
        
        //make  View invisible to animate it
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
    
    func configueLocationInputView()
    {
        locationInputView.delegate = self
        view.addSubview(locationInputView)
        locationInputView.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: locationInputViewHeight )
        locationInputView.alpha = 0
        
        UIView.animate(withDuration: 0.5, animations: {
            self.locationInputView.alpha = 1
            
            UIView.animate(withDuration: 0.3) {
                self.tableView.frame.origin.y = self.locationInputViewHeight
            }
        })
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
}

//MARK: - MKMapViewDelegate

extension HomeController: MKMapViewDelegate {
    
    //create annotation with custom image
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation {
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            view.image = #imageLiteral(resourceName: "chevron-sign-to-right")
            return view
        }
        return nil
    }
}

// MARK: - Location services

extension HomeController
{
    func enableLocationServices()
    {
        
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
        configueLocationInputView()
    }
}

//MARK: - LocationInputViewDelegate
extension HomeController: LocationInputViewDelegate
{
    func dissmissLocationInputView() {
        
        
        UIView.animate(withDuration: 0.3, animations:  {
            self.locationInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.frame.height
        }) {_ in
            self.locationInputView.removeFromSuperview()
            UIView.animate(withDuration: 0.3) {
                self.inputActivationView.alpha = 1
            }
            }
    }
}

//MARK: - TableViewDelegates

extension HomeController: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "TEST"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 2 : 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! LocationCell
        return cell
    }
    

}
