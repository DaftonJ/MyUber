//
//  AuthButton.swift
//  My Uber
//
//  Created by Dawid Jaskulski on 27/03/2020.
//  Copyright © 2020 Dawid Jaskulski. All rights reserved.
//

import UIKit

class AuthButton: UIButton
{
    override init(frame: CGRect)
    {
        super.init(frame:frame)
    
        setTitleColor(UIColor(white:1, alpha: 0.5), for: .normal)
        backgroundColor = .mainBlueTint
        layer.cornerRadius = 5
        heightAnchor.constraint(equalToConstant: 50).isActive = true
        
    }
    required init?(coder: NSCoder) {
        fatalError()
    }
}
