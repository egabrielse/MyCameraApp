//
//  ViewController.swift
//  MyCameraApp
//
//  Created by Ethan Gabrielse on 10/20/20.
//

import UIKit
import AVFoundation

/*
 MARK: ViewController
 */
class ViewController: UIViewController {
    let cameraController = CameraController();
    var images: [UIImage] = [];
        
    // MARK: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black;
        self.view.addSubview(self.captureButton);
        self.view.addSubview(self.imageView);
        self.view.addSubview(self.switchCameraButton);
        self.view.addSubview(self.toggleFlashButton);

        cameraController.prepare {(error) in
            if let error = error {
                print(error)
            } else {
                try? self.cameraController.displayPreview(on: self.view);
                
                let flashIcon = self.cameraController.getFlashMode();
                self.toggleFlashButton.setImage(flashIcon, for: .normal);
            }
        }

        NSLayoutConstraint.activate([
            self.captureButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.captureButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -25),
            self.imageView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -25),
            self.imageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 25),
            self.switchCameraButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -30),
            self.switchCameraButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30),
            self.toggleFlashButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -30),
            self.toggleFlashButton.bottomAnchor.constraint(equalTo: self.switchCameraButton.topAnchor, constant: -15),
        ])
    }

    
    /*
     MARK: UI Components
     */
    let captureButton: UIButton = {
        let length: CGFloat = 75;
        let btn = UIButton();
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: length).isActive = true;
        btn.heightAnchor.constraint(equalToConstant: length).isActive = true;
        btn.layer.cornerRadius = (length / 2.0);
        btn.backgroundColor = .white;
        btn.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        return btn;
    }()
    
    
    let imageView: UIImageView = {
        let imgView = UIImageView();
        imgView.translatesAutoresizingMaskIntoConstraints = false;
        imgView.widthAnchor.constraint(equalToConstant: 50).isActive = true;
        imgView.heightAnchor.constraint(equalToConstant: 75).isActive = true;
        imgView.layer.cornerRadius = 5;
        imgView.layer.borderWidth = 3;
        imgView.layer.borderColor = CGColor(red: 255, green: 255, blue: 255, alpha: 1.0);
        imgView.backgroundColor = .black;
        return imgView;
    }()
    
    
    let switchCameraButton: UIButton = {
        let btn = UIButton();
        btn.translatesAutoresizingMaskIntoConstraints = false;
        btn.widthAnchor.constraint(equalToConstant: 30).isActive = true;
        btn.heightAnchor.constraint(equalToConstant: 30).isActive = true;
        let btnImg = UIImage(named: "icons8-switch-camera-50");
        btn.setImage(btnImg, for: .normal)
        btn.addTarget(self, action: #selector(switchCamera), for: .touchUpInside);
        return btn;
    }()
    
    
    let toggleFlashButton: UIButton = {
        let btn = UIButton();
        btn.translatesAutoresizingMaskIntoConstraints = false;
        btn.widthAnchor.constraint(equalToConstant: 30).isActive = true;
        btn.heightAnchor.constraint(equalToConstant: 30).isActive = true;
        btn.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside);
        return btn;
    }()
}




/*
 MARK: UI Actions
 */
extension ViewController {
    
    // MARK: capturePhoto
    @objc func capturePhoto() {
        cameraController.capturePhoto(delegate: self)
    }
    
    // MARK: toggleFlash
    @objc func toggleFlash() {
        let flashIcon = cameraController.toggleFlashMode();
        self.toggleFlashButton.setImage(flashIcon, for: .normal);
    }
    
    // MARK: switchCamera
    @objc func switchCamera() {
        if cameraController.selectedCamera == CameraController.CameraSelection.front {
            do {
                try cameraController.switchCameraToRear();
            } catch {
                print(error);
            }
        } else {
            do {
                try cameraController.switchCameraToFront();
            } catch {
                print(error);
            }
        }
    }
}




/*
 MARK: Capture Delegate Methods
    Functions related to AVCapturePhotoCaptureDelegate.
 */
extension ViewController: AVCapturePhotoCaptureDelegate {
    // MARK: photoOutput
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("Handling photo capture output...")
        if let error = error {
            print(error);
            return;
        }
        
        guard let imageData = photo.fileDataRepresentation() else { return }
        print("Photo captured.")
        let img = UIImage(data: imageData)!
        self.images.insert(img, at: 0);
        self.imageView.image = self.images[0];
    }
}
