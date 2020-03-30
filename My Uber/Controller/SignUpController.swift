//
//  SignUpController.swift
//  My Uber
//
//  Created by Dawid Jaskulski on 27/03/2020.
//  Copyright © 2020 Dawid Jaskulski. All rights reserved.
//

import UIKit
import Firebase
import GeoFire

class SignUpController: UIViewController
{
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
         super.viewDidLoad()
         configureUI()
        
     }
    
    //MARK: - Properties
    
    private var location = LocationHandler.shared.locationManager.location
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "UBER"
        label.font = UIFont(name: "Avenir-Light", size: 36)
        label.textColor = UIColor(white: 1, alpha: 0.8)
        
        return label
    }()

    private lazy var emailContainerView: UIView = {
        return UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_mail_outline_white_2x"), textfield: emailTextField)
    }()
    private lazy var fullnameContainerView: UIView = {
           return UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_person_outline_white_2x"), textfield: fullnameTextField)
       }()
    private lazy var passwordContainerView: UIView = {
        return UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_lock_outline_white_2x"), textfield: passwordTextField)
       }()
    private lazy var accountTypeContainerView: UIView = {
        let view = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_account_box_white_2x"), segmentedControl: accountTypeSegmentedControl )
        return view
       }()
    
    
    
    private let emailTextField: UITextField = {
        return UITextField().createTexfield(withPlaceholder: "Email", isSecureTextEntry: false)
    }()
    
    private let fullnameTextField: UITextField = {
           return UITextField().createTexfield(withPlaceholder: "FullName", isSecureTextEntry: false)
       }()
    
    private let passwordTextField: UITextField = {
        return UITextField().createTexfield(withPlaceholder: "Password", isSecureTextEntry: true)
    }()
    
    private let accountTypeSegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Rider","Driver"])
        sc.backgroundColor = .backgroundColor
        sc.tintColor = UIColor(white: 1, alpha: 0.87)
        sc.selectedSegmentIndex = 0
        return sc
    }()
    
    private let signUpButton: AuthButton =
    {
        let button = AuthButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        return button
    }()
    
    let alreadyHaveAccountButton: UIButton =
       {
           let button = UIButton(type: .system)
           let attributedTitle = NSMutableAttributedString(string: "Already have an account?", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16),
               NSAttributedString.Key.foregroundColor : UIColor.lightGray])
           
           attributedTitle.append (NSMutableAttributedString(string: " Sign Up", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16),
           NSAttributedString.Key.foregroundColor : UIColor.mainBlueTint]))
           button.addTarget(self, action: #selector(handleShowLogin), for: .touchUpInside)
           button.setAttributedTitle(attributedTitle, for: .normal)
           return button
       }()

    
    //MARK: - Selectors
    
    @objc func handleShowLogin()
    {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func handleSignUp()
    {
        guard let email = emailTextField.text else {return}
        guard let password = passwordTextField.text else {return}
        guard let fullname = fullnameTextField.text else {return}
        let accountTypeIndex = accountTypeSegmentedControl.selectedSegmentIndex
        
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if error != nil
            {
                print("Failed to register user with error \(String(describing: error))")
                return
            }
            
            guard let uid = result?.user.uid else {return}
            
            
            let values = ["email": email,
                          "fullname": fullname,
                          "accountType": accountTypeIndex] as [String : Any]
            
            if accountTypeIndex == 1 {
                
                let geofire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
                guard let location = self.location else {return}
                
                geofire.setLocation(location, forKey: uid) { (error) in
                    self.uploadUserDataAndShowHomeController(uid: uid, values: values)
                }
            }
            self.uploadUserDataAndShowHomeController(uid: uid, values: values)
            
            
        }
    }
    //MARK: - Helper Functions
    
    func uploadUserDataAndShowHomeController(uid: String, values: [String:Any]) {
        
        REF_USERS.child(uid).updateChildValues(values) { (error, ref) in
            
            guard let controller = UIApplication.shared.keyWindow?.rootViewController as? HomeController else {return}
            
            controller.configureUI()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func configureUI()
    {
        
            view.backgroundColor = .backgroundColor
            
            view.addSubview(titleLabel)
            titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor)
            titleLabel.centerX(inView: view)
            
            let stack = UIStackView(arrangedSubviews:[emailContainerView,
                                                      fullnameContainerView,
                                                      passwordContainerView,
                                                      accountTypeContainerView,
                                                      signUpButton])
            stack.axis = .vertical
            stack.distribution = .fillProportionally
            stack.spacing = 16
            
            view.addSubview(stack)
            stack.anchor(top: titleLabel.bottomAnchor,left: view.leftAnchor, right: view.rightAnchor,paddingTop: 40, paddingLeft: 16, paddingRight: 16)
            
        view.addSubview(alreadyHaveAccountButton)
        alreadyHaveAccountButton.centerX(inView: view)
        alreadyHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, height: 32)

           
    }
}
