//
//  LocationHandler.swift
//  My Uber
//
//  Created by Dawid Jaskulski on 30/03/2020.
//  Copyright © 2020 Dawid Jaskulski. All rights reserved.
//

import CoreLocation

class LocationHandler: NSObject, CLLocationManagerDelegate {
    
    static let shared = LocationHandler()
    var locationManager: CLLocationManager!
    var location: CLLocation?
    
    override init() {
        super.init()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse
        {
            locationManager.requestAlwaysAuthorization()
        }
    }

}
