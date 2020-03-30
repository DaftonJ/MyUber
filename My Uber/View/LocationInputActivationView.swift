//
//  LocationInputActivationView.swift
//  My Uber
//
//  Created by Dawid Jaskulski on 28/03/2020.
//  Copyright © 2020 Dawid Jaskulski. All rights reserved.
//

import UIKit

protocol LocationInputActivationViewDelegate: class
{
    func presentLocationInputView()
}

class LocationInputActivationView: UIView
{
    // MARK: - Lifecycle
    override init(frame:CGRect)
    {
        super.init(frame: frame)
        
        backgroundColor = .white
        addShadow()
        
        addSubview(indicatiorView)
        indicatiorView.centerY(inView: self, leftAnchor: leftAnchor, paddingLeft: 16)
        indicatiorView.setDimensions(height: 6, width: 6)
        
        addSubview(placeholderLabel)
        placeholderLabel.centerY(inView: self, leftAnchor: indicatiorView.rightAnchor, paddingLeft: 20)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleShowLocationInputView))
        addGestureRecognizer(tap)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
   
    //MARK: - Properties
    
    weak var delegate: LocationInputActivationViewDelegate?
    
    private let indicatiorView: UIView =
    {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    private let placeholderLabel: UILabel = {
           let label = UILabel()
           label.text = "Where to?"
           label.font = UIFont.systemFont(ofSize: 18)
           label.textColor = .darkGray
           return label
       }()
    
    //MARK: - Selectors
    
    @objc func handleShowLocationInputView()
    {
        delegate?.presentLocationInputView()
    }
}

