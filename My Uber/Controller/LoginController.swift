//
//  LoginController.swift
//  My Uber
//
//  Created by Dawid Jaskulski on 27/03/2020.
//  Copyright © 2020 Dawid Jaskulski. All rights reserved.
//

import UIKit

class LoginController: UIViewController {

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    // Mark: - Properties
    
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
    private lazy var passwordContainerView: UIView = {
        return UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_lock_outline_white_2x"), textfield: passwordTextField)
       }()
    private let emailTextField: UITextField = {
        return UITextField().createTexfield(withPlaceholder: "Email", isSecureTextEntry: false)
    }()
    
    private let passwordTextField: UITextField = {
        return UITextField().createTexfield(withPlaceholder: "Password", isSecureTextEntry: true)
    }()
    
    private let loginButton: AuthButton =
    {
        let button = AuthButton(type: .system)
        button.setTitle("Log In", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        return button
    }()
    
    let dontHaveAccountButton: UIButton =
    {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString(string: "Don't have an account?", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16),
            NSAttributedString.Key.foregroundColor : UIColor.lightGray])
        
        attributedTitle.append (NSMutableAttributedString(string: " Sign In", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16),
        NSAttributedString.Key.foregroundColor : UIColor.mainBlueTint]))
        button.addTarget(self, action: #selector(handleShowSignUp), for: .touchUpInside)
        button.setAttributedTitle(attributedTitle, for: .normal)
        return button
    }()

    // MARK: - Selectors
    
    @objc func handleShowSignUp()
    {
        let controller = SignUpController()
        navigationController?.pushViewController(controller, animated: true)
    }
    
    // MARK: - Helper Functions
    func configureUI()
    {
            configuteNavigationBar()
        
            view.backgroundColor = .backgroundColor
            
            view.addSubview(titleLabel)
            titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor)
            titleLabel.centerX(inView: view)
            
            let stack = UIStackView(arrangedSubviews: [emailContainerView, passwordContainerView, loginButton])
            stack.axis = .vertical
            stack.distribution = .fillEqually
            stack.spacing = 16
            
            view.addSubview(stack)
            stack.anchor(top: titleLabel.bottomAnchor,left: view.leftAnchor, right: view.rightAnchor,paddingTop: 40, paddingLeft: 16, paddingRight: 16)
            
            view.addSubview(dontHaveAccountButton)
            dontHaveAccountButton.centerX(inView: view)
            dontHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, height: 32)
        }
    func configuteNavigationBar() {
        navigationController?.navigationBar.isHidden = true
    }
}
