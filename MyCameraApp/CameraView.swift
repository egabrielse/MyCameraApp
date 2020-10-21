//
//  CameraView.swift
//  MyCameraApp
//
//  Created by Ethan Gabrielse on 10/20/20.
//

import Foundation
import UIKit


class CameraView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame);
        setUpButtons();
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    func setUpButtons() {
        self.backgroundColor = .blue;
    }
}
