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

class HomeController: UIViewController
{
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkIfUserIsLoggedIn()
        enableLocationServices()
    }
    
    
    //MARK: - Properties
    private let locationManager = CLLocationManager()
    
    private let mapView = MKMapView()
    
    private let inputActivationView = LocationInputActivationView()
    //MARK: -  API
    
    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil{
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: LoginController())
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
        }
        catch let error {
            print("Error with signing out user \(error)")
        }
    }
    //MARK: - Helper Functions
    
    func configureUI()
    {
    configueMapView()

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
    }
    
}
// MARK: - Location services

extension HomeController: CLLocationManagerDelegate
{
    func enableLocationServices()
    {
        locationManager.delegate = self
        
        switch CLLocationManager.authorizationStatus()
        {
            
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            
        case .restricted:
            break
        case .denied:
            break
            
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
            
        @unknown default:
            break
        }
        
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse
        {
            locationManager.requestAlwaysAuthorization()
        }
    }
}
