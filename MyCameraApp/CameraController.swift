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
    var rearCamera: AVCaptureDevice?
    
    /// Inputs:
    var frontCameraInput: AVCaptureDeviceInput?
    var rearCameraInput: AVCaptureDeviceInput?
    
    /// Output:
    var previewLayer: AVCaptureVideoPreviewLayer?
    var photoOutput: AVCapturePhotoOutput?
    
    /// Settings:
    var flashMode = AVCaptureDevice.FlashMode.off;
    var selectedCamera: CameraSelection?;
    
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
 MARK: SETUP METHODS
 */
extension CameraController {
    
    // MARK: createCaptureSession
    func createCaptureSession() throws {
        let semaphore = DispatchSemaphore(value: 0);
        print("\nCreating capture session...")
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
        print("\nConfiguring capture devices...")
        let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front);
        self.frontCamera = frontCamera;
        let rearCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back);
        self.rearCamera = rearCamera;
        print("Configured capture devices.")
    }
    
    
    // MARK: configureDeviceInputs
    func configureDeviceInputs() throws {
        print("\nConfiguring device inputs...")
        guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
        
        if let rearCamera = self.rearCamera, let frontCamera = self.frontCamera {
            self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera);
            self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera);
            
            if captureSession.canAddInput(self.rearCameraInput!) {
                captureSession.addInput(self.rearCameraInput!)
                self.selectedCamera = CameraSelection.rear;
                print("Configured camera to use rear-facing camera.")
            } else if captureSession.canAddInput(self.frontCameraInput!) {
                captureSession.addInput(self.frontCameraInput!)
                self.selectedCamera = CameraSelection.front;
                print("Configured camera to use front-facing camera.")
            } else { throw CameraControllerError.inputsAreInvalid }
        } else { throw CameraControllerError.noCamerasAvailable }
    }
    
    
    // MARK: configureDeviceOutput
    func configureDeviceOutput() throws {
        print("\nConfiguring device output...")
        guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
        
        self.photoOutput = AVCapturePhotoOutput();
        self.photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil);
        
        if captureSession.canAddOutput(self.photoOutput!) {
            print("Configured device output.")
            captureSession.addOutput(self.photoOutput!);
        } else { throw CameraControllerError.unknown}
    }
}




/*
 MARK: USAGE METHODS
 */
extension CameraController {
    
    // MARK: displayPreview
    func displayPreview(on view: UIView) throws {
        print("\nDisplaying preview...")
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
        print("\nCapturing photo...")
        let settings = AVCapturePhotoSettings();
        settings.flashMode = self.flashMode;
        self.photoOutput?.capturePhoto(with: settings, delegate: delegate);
    }
    
    
    // MARK: switchCameraToFront
    func switchCameraToFront() throws {
        print("\nSwitching device input from rear to front...")
        guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
        
        guard let rearCameraInput = self.rearCameraInput, captureSession.inputs.contains(rearCameraInput) else {
            throw CameraControllerError.rearCaptureDeviceInputMissing;
        }
        
        self.frontCameraInput = try AVCaptureDeviceInput(device: self.frontCamera!)
        captureSession.removeInput(rearCameraInput)

        if captureSession.canAddInput(self.frontCameraInput!) {
            captureSession.addInput(self.frontCameraInput!)
            self.selectedCamera = .front;
            print("Switched device input to front.")
        } else { throw CameraControllerError.invalidOperation }
    }
    
    // MARK: switchCameraToRear
    func switchCameraToRear() throws {
        print("\nSwitching device input from front to rear...")
        guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
        
        guard let frontCameraInput = self.frontCameraInput, captureSession.inputs.contains(frontCameraInput) else {
            throw CameraControllerError.frontCaptureDeviceInputMissing;
        }
        
        self.rearCameraInput = try AVCaptureDeviceInput(device: self.rearCamera!)
        captureSession.removeInput(frontCameraInput)

        if captureSession.canAddInput(self.rearCameraInput!) {
            captureSession.addInput(self.rearCameraInput!)
            self.selectedCamera = .rear;
            print("Switched device input to rear.")
        } else { throw CameraControllerError.invalidOperation }
    }
    
    
    func toggleFlashMode() -> UIImage {
        if self.flashMode == AVCaptureDevice.FlashMode.on {
            print("\nFlash mode is now off.")
            self.flashMode = AVCaptureDevice.FlashMode.off;
            return UIImage(named: "icons8-flash-off-50")!;
        } else {
            self.flashMode = AVCaptureDevice.FlashMode.on;
            print("\nFlash mode is now on.")
            return UIImage(named: "icons8-flash-on-50")!;
        }
    }
    
    func getFlashMode() -> UIImage {
        if self.flashMode == AVCaptureDevice.FlashMode.on {
            return UIImage(named: "icons8-flash-on-50")!;
        } else {
            return UIImage(named: "icons8-flash-off-50")!;
        }
    }
}




extension CameraController {
    enum CameraControllerError: Swift.Error {
        case rearCaptureDeviceInputMissing
        case frontCaptureDeviceInputMissing
        case authorizationRestricted
        case authorizationDenied
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case unknown
    }
    
    enum CameraSelection {
        case front
        case rear
    }
}
