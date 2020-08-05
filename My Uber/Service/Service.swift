//
//  Service.swift
//  My Uber
//
//  Created by Dawid Jaskulski on 30/03/2020.
//  Copyright © 2020 Dawid Jaskulski. All rights reserved.
//

import Firebase
import CoreLocation
import GeoFire

let DB_REF = Database.database().reference()
let REF_USERS = DB_REF.child("users")
let REF_DRIVER_LOCATIONS = DB_REF.child("driver-locations")

struct Service {
    
    static let shared = Service()
    let currentUId = Auth.auth().currentUser?.uid
    
    func fetchUserData(uid: String,completion: @escaping(User) -> Void) {
        REF_USERS.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            guard let dictionary = snapshot.value as? [String:Any] else {return}
            let uid = snapshot.key
            
            let user = User(uid: uid,dictionary: dictionary)
            
            completion(user)
        }
    }
    
    func fetchDrivers(location: CLLocation, completion: @escaping(User)->Void)
    {
        let geofire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
 
        // Want to take all drivers with radius 50 from user location and take them uid and location
        REF_DRIVER_LOCATIONS.observe(.value){ (snapshot) in
            geofire.query(at: location, withRadius: 50).observe(.keyEntered, with: { (uid, location) in
                self.fetchUserData(uid: uid) { (user) in
                    var driver = user
                    driver.location = location
                    completion(driver)
                }
            })
            
        }
    }

}
