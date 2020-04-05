//
//  LocationCell.swift
//  My Uber
//
//  Created by Dawid Jaskulski on 29/03/2020.
//  Copyright © 2020 Dawid Jaskulski. All rights reserved.
//

import UIKit
import MapKit

class LocationCell: UITableViewCell {

  //MARK: - Lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        

        let stack = UIStackView(arrangedSubviews: [titleLabel,addressLabel])
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 4
        
        addSubview(stack)
        stack.centerY(inView: self, leftAnchor: leftAnchor,paddingLeft: 8)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
  //MARK: - Properties
    
    var placemark:MKPlacemark? {
        didSet {
            titleLabel.text = placemark?.name
            addressLabel.text = placemark?.address
        }
    }
    
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    let addressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .lightGray
        return label
    }()
}
