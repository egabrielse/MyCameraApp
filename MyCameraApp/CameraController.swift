//
//  AltCameraController.swift
//  MyCameraApp
//
//  Created by Ethan Gabrielse on 10/18/20.
//

import Foundation
import AVFoundation
import UIKit


/*
 MARK: CameraController
 */
class CameraController: NSObject{
    /// Capture Sessions:
    var captureSession: AVCaptureSession?
    /// Capture Devices:
    var frontCamera: AVCaptureDevice?
    var backCamera: AVCaptureDevice?
    
    /// Inputs:
    var frontCameraInput: AVCaptureDeviceInput?
    var backCameraInput: AVCaptureDeviceInput?
    
    /// Output:
    var previewLayer: AVCaptureVideoPreviewLayer?
    var photoOutput: AVCapturePhotoOutput?
    
    
    // MARK: prepare
    func prepare(completionHandler: @escaping (Error?) -> Void){
        DispatchQueue(label: "prepare").sync {
            do {
                try self.createCaptureSession();
                self.captureSession!.beginConfiguration();
                try self.configureInputDevices();
                try self.configureDeviceInputs();
                try self.configureDeviceOutput();
                self.captureSession!.commitConfiguration();
                self.captureSession!.startRunning();
            }
            catch {
                DispatchQueue.main.async{
                    completionHandler(error)
                }
                return
            }
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
}


/*
 MARK: Setup Functions
 */
extension CameraController {
    
    // MARK: createCaptureSession
    func createCaptureSession() throws {
        let semaphore = DispatchSemaphore(value: 0);
        print("Creating capture session...")
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: /// The user has previously granted access to the camera.
                print("The user has previously granted access to the camera. Creating capture session.")
                self.captureSession = AVCaptureSession()
            case .notDetermined: /// The user has not yet been asked for camera access.
                print("The user has not yet been asked for camera access. Requesting authorization...")
                
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        print("Authorization granted. Creating capture session.")
                        self.captureSession = AVCaptureSession()
                    }
                    semaphore.signal();
                }
                _ = semaphore.wait(timeout: DispatchTime.distantFuture);
            case .denied: /// The user has previously denied access.
                print("The user has previously denied access.")
                throw CameraControllerError.authorizationDenied

            case .restricted: /// The user can't grant access due to restrictions.
                print("The user can't grant access due to restrictions.")
                throw CameraControllerError.authorizationRestricted
        @unknown default:
            throw CameraControllerError.unknown
        }
    }
    
    
    // MARK: configureInputDevices
    func configureInputDevices() throws {
        print("Configuring capture devices...")
        let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front);
        self.frontCamera = frontCamera;
        let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back);
        self.backCamera = backCamera;
        print("Configured capture devices.")
    }
    
    
    // MARK: configureDeviceInputs
    func configureDeviceInputs() throws {
        print("Configuring device inputs...")
        guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
        
        if let backCamera = self.backCamera, let frontCamera = self.frontCamera {
            self.backCameraInput = try AVCaptureDeviceInput(device: backCamera);
            self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera);
            
            if captureSession.canAddInput(self.backCameraInput!) {
                captureSession.addInput(self.backCameraInput!)
                print("Configured camera to use rear-facing camera.")
            } else if captureSession.canAddInput(self.frontCameraInput!) {
                captureSession.addInput(self.frontCameraInput!)
                print("Configured camera to use front-facing camera.")
            } else { throw CameraControllerError.inputsAreInvalid }
        } else { throw CameraControllerError.noCamerasAvailable }
    }
    
    
    // MARK: configureDeviceOutput
    func configureDeviceOutput() throws {
        print("Configuring device output...")
        guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
        
        self.photoOutput = AVCapturePhotoOutput();
        self.photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil);
        
        if captureSession.canAddOutput(self.photoOutput!) {
            print("Configured device output.")
            captureSession.addOutput(self.photoOutput!);
        } else { throw CameraControllerError.unknown}
    }
    
    
    
    // MARK: displayPreview
    func displayPreview(on view: UIView) throws {
        print("Displaying preview...")
        guard let captureSession = self.captureSession, captureSession.isRunning else {
            throw CameraControllerError.captureSessionIsMissing
        }
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.previewLayer?.connection?.videoOrientation = .portrait

        view.layer.insertSublayer(self.previewLayer!, at: 0)
        self.previewLayer?.frame = view.frame
        print("Preview displayed.")
    }
    
    
    // MARK: capturePhoto
    func capturePhoto(delegate: AVCapturePhotoCaptureDelegate) {
        print("Capturing photo...")
        let settings = AVCapturePhotoSettings();
        self.photoOutput?.capturePhoto(with: settings, delegate: delegate);
    }
}
