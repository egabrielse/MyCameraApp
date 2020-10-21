//
//  Test.swift
//  MyCameraApp
//
//  Created by Ethan Gabrielse on 10/20/20.
//
/*
import Foundation
import UIKit


class Test:UIView {
    init(frame: CGRect, color: UIColor) {
        super.init(frame: frame);
        self.addSubview(self.subView)
        self.backgroundColor = .blue
        
        NSLayoutConstraint.activate([
            self.subView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.subView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        self.addSubview(self.subView)
        self.backgroundColor = .blue
        
        NSLayoutConstraint.activate([
            self.subView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.subView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let subView: UIView = {
        let widtHeight:CGFloat = 100;
        
        let subView = UIView();
        subView.widthAnchor.constraint(equalToConstant: widtHeight).isActive = true;
        subView.heightAnchor.constraint(equalToConstant: widtHeight).isActive = true;
        subView.layer.cornerRadius = widtHeight/2;
        subView.backgroundColor = .red;
        subView.translatesAutoresizingMaskIntoConstraints = false
        return subView;
    }()
}
 */
