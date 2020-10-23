//
//  ViewController.swift
//  MyCameraApp
//
//  Created by Ethan Gabrielse on 10/20/20.
//

import UIKit
import AVFoundation

/*
 MARK: ViewController (Class)
    Interface to the Camera Controller and Image Viewer
 */
class ViewController: UIViewController {
    /// Interface to device's camera
    let cameraController = CameraController();
    /// Array of taken photos (TODO? might be moved into the cameraController)
    var images: [UIImage] = [];
        
    // MARK: viewDidLoad (Func)
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black;
        
        /// Add subviews to the view controller's view
        self.view.addSubview(self.captureButton);
        self.view.addSubview(self.imageView);
        self.view.addSubview(self.switchCameraButton);
        self.view.addSubview(self.toggleFlashButton);

        /// Ready the cameraController for use by calling its prepare function
        cameraController.prepare {(error) in
            if let error = error {
                /// If any errors occur during setup, they will be returned in the completion handler
                print(error)
            } else {
                /// If no errors occured, finish configuring the camera with the view controller:
                /// 1) Display the camera preview onto the view controller's view
                try? self.cameraController.displayPreview(on: self.view);
                /// 2) Get the current state of the cameraController's flash mode and assign a button icon depending on the result:
                self.toggleFlashButton.setImage(self.cameraController.getFlashMode(), for: .normal);
                /// 3) Assign targets to each button
                self.captureButton.addTarget(self, action: #selector(self.capturePhoto), for: .touchUpInside);
                self.switchCameraButton.addTarget(self, action: #selector(self.switchCamera), for: .touchUpInside);
                self.toggleFlashButton.addTarget(self, action: #selector(self.toggleFlash), for: .touchUpInside);
            }
        }

        /// Add layout constraints to subviews
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
     MARK: captureButton (Object)
        When tapped, calls the cameraController's capturePhoto method
     */
    let captureButton: UIButton = {
        let length: CGFloat = 75;
        let btn = UIButton();
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: length).isActive = true;
        btn.heightAnchor.constraint(equalToConstant: length).isActive = true;
        btn.layer.cornerRadius = (length / 2.0);
        btn.backgroundColor = .white;
        return btn;
    }()
    
    /*
     MARK: imageView (Object)
        Displays the most recent image taken by the camera.
        TODO: When tapped, opens up an image picker from all images taken during the current camera
              session can be viewed.
     */
    let imageView: UIImageView = {
        let imgView = UIImageView();
        imgView.translatesAutoresizingMaskIntoConstraints = false;
        imgView.widthAnchor.constraint(equalToConstant: 50).isActive = true;
        imgView.heightAnchor.constraint(equalToConstant: 80).isActive = true;
        imgView.layer.cornerRadius = 5;
        imgView.layer.borderWidth = 3;
        imgView.layer.borderColor = CGColor(red: 255, green: 255, blue: 255, alpha: 1.0);
        imgView.layer.masksToBounds = true;
        imgView.backgroundColor = .black;
        return imgView;
    }()
    
    
    /*
     MARK: switchCameraButton (Object)
     */
    let switchCameraButton: UIButton = {
        let btn = UIButton();
        btn.translatesAutoresizingMaskIntoConstraints = false;
        btn.widthAnchor.constraint(equalToConstant: 30).isActive = true;
        btn.heightAnchor.constraint(equalToConstant: 30).isActive = true;
        let btnImg = UIImage(named: "icons8-switch-camera-50");
        btn.setImage(btnImg, for: .normal)
        return btn;
    }()
    
    /*
     MARK: toggleFlashButton (Object)
     */
    let toggleFlashButton: UIButton = {
        let btn = UIButton();
        btn.translatesAutoresizingMaskIntoConstraints = false;
        btn.widthAnchor.constraint(equalToConstant: 30).isActive = true;
        btn.heightAnchor.constraint(equalToConstant: 30).isActive = true;
        /// Default button icon in case cameraController setup fails.
        btn.setImage(UIImage(named: "icons8-flash-on-50"), for: .normal);
        return btn;
    }()
}




// MARK: UI ACTIONS (Extension)
extension ViewController {

    /*
     MARK: capturePhoto
        Calls the cameraController's capturePhoto method. Delegate is set to self.
        TODO? if images object is moved into or abstracted into a new class, delegate will
        have to be changed.
     */
    @objc func capturePhoto() {
        cameraController.capturePhoto(delegate: self)
    }
    
    /*
     MARK: toggleFlash
        Calls the cameraController's toggleFlashMode method, and
        sets the toggleFlashButton's button icon to the returned UIImage value.
     */
    @objc func toggleFlash() {
        self.toggleFlashButton.setImage(cameraController.toggleFlashMode(), for: .normal);
    }
    
    /*
     MARK: switchCamera
        Calls the cameraController's switchCamera method.
     */
    @objc func switchCamera() {
        cameraController.switchCamera { (error) in
            if let error = error {
                // TODO: Pop-up modal informing user of error.
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
        if let error = error {
            print(error);
            return;
        }
        
        guard let imageData = photo.fileDataRepresentation() else { return }
        let image = UIImage(data: imageData)!
        if cameraController.getCameraSelection() == CameraController.CameraSelection.front {
            let flippedImage = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: .leftMirrored)
            self.images.insert(flippedImage, at: 0);
            print("Photo from front facing camera captured.")
        } else {
            print("Photo from rear facing camera captured.")
            self.images.insert(image, at: 0)
        }
        self.imageView.image = self.images[0];
        
        // TODO: Save image to Photos
    }
}
