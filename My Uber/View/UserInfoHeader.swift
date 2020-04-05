//
//  UserInfoHeader.swift
//  My Uber
//
//  Created by Dawid Jaskulski on 05/04/2020.
//  Copyright © 2020 Dawid Jaskulski. All rights reserved.
//

import UIKit

class UserInfoHeader: UIView {
    
    //MARK: - Properties
    
    private let user: User
    
      private let profileImageView: UIImageView = {
          let iv = UIImageView()
          iv.backgroundColor = .lightGray
          return iv
      }()
      
      lazy private var fullnameLabel: UILabel = {
          let label = UILabel()
          label.font = UIFont.systemFont(ofSize: 16)
          label.text = user.fullname
          return label
      }()
      
      lazy private var emailLabel: UILabel = {
          let label = UILabel()
          label.font = UIFont.systemFont(ofSize: 14)
          label.textColor = .lightGray
          label.text = user.email
          return label
      }()
    
    //MARK: - Lifecycle
    
    init(user: User, frame: CGRect) {
        self.user = user
        super.init(frame: frame)
        
        
        backgroundColor = .white
        
        addSubview(profileImageView)
        profileImageView.centerY(inView: self, leftAnchor: leftAnchor, paddingLeft: 16)
        profileImageView.setDimensions(height: 64, width: 64)
        profileImageView.layer.cornerRadius = 64/2
        
        let stack = UIStackView(arrangedSubviews: [fullnameLabel, emailLabel])
        stack.distribution = .fillEqually
        stack.spacing = 4
        stack.axis = .vertical
        
        addSubview(stack)
        stack.centerY(inView: profileImageView, leftAnchor: profileImageView.rightAnchor, paddingLeft: 12)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
