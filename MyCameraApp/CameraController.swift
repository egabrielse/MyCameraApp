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
 MARK: CAMERACONTROLLER
    Interface between for using the camera.
 */
class CameraController: NSObject{
    /// Capture Sessions:
    fileprivate var captureSession: AVCaptureSession?
    /// Capture Devices:
    fileprivate var frontCamera: AVCaptureDevice?
    fileprivate var rearCamera: AVCaptureDevice?
    /// Inputs:
    fileprivate var frontCameraInput: AVCaptureDeviceInput?
    fileprivate var rearCameraInput: AVCaptureDeviceInput?
    /// Output:
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer?
    fileprivate var photoOutput: AVCapturePhotoOutput?
    /// Settings:
    fileprivate var flashMode = AVCaptureDevice.FlashMode.off;
    fileprivate var selectedCamera: CameraSelection?;
    
    /*
     MARK: prepare
        Prepares the CameraController to interface between the camera and the UI.
        1) Initialize - Initialize the AVCaptureSession and AVCaptureDevice
        2) Configure - Configure the inputs and outputs for the capture session.
        3a) Success - Capture session is now live and ready for use. Return a completion handler without error.
        3a) Failure - An error occured during setup. Return a completion handler with the captured error.
     */
    func prepare(completionHandler: @escaping (Error?) -> Void){
        DispatchQueue(label: "prepare").async {
            do {
                /// 1) Initialize
                try self.initializingCaptureSession();
                try self.initializeInputDevices();
                
                /// 2) Configure
                self.captureSession!.beginConfiguration();
                try self.configureDeviceInput();
                try self.configureDeviceOutput();
                self.captureSession!.commitConfiguration();
                /// 3a) Success
                self.captureSession!.startRunning();
                DispatchQueue.main.async {
                    completionHandler(nil); /// Return completion handler without error
                }
            } catch {
                /// 3b) Failure
                DispatchQueue.main.async{
                    completionHandler(error); /// Return completion handler with the caught error
                }
            }
        }
    }
}



 /*
 MARK: SETUP METHODS
 */
extension CameraController {
    /*
     MARK: createCaptureSession
        Checks the user's current authorization status for camera usage by the app.
        If granted - initializes an AVCaptureSession.
        If undetermined - requests authorization.
        If denied or restricted - throws the appropriate error.
     */
    func initializingCaptureSession() throws {
        print("\nInitializing capture session...")
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: /// The user has previously granted access to the camera.
                print("The user has previously granted access to the camera. Initializing capture session.")
                self.captureSession = AVCaptureSession()
            case .notDetermined: /// The user has not yet been asked for camera access.
                print("The user has not yet been asked for camera access. Requesting authorization...")
                /// Using a semaphore to await user's response to camera authorization request.
                /// TODO: Ideally this will be made to function asynchronously later.
                let semaphore = DispatchSemaphore(value: 0);
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        print("Authorization granted. Initializing capture session.")
                        self.captureSession = AVCaptureSession()
                        semaphore.signal();
                    }
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
    
    
    /*
     MARK: initializeInputDevices
        Initializes two AVCaptureDevices: front and rear facing cameras.
     */
    func initializeInputDevices() throws {
        print("\nInitializing capture devices...")
        self.frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front);
        self.rearCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back);
        print("Configured capture devices.")
    }
    
    
    /*
     MARK: configureDeviceInput
        Links the input devices to the camera session.
     */
    func configureDeviceInput() throws {
        print("\nConfiguring device inputs...")
        /// Verify that the capture session has been initialized
        guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
        
        /// Unwrap the rear and front cameras. If neither are initiated, throw noCamerasAvailable error
        if let rearCamera = self.rearCamera, let frontCamera = self.frontCamera {
            /// Initialize the device inputs
            self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera);
            self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera);

            if captureSession.canAddInput(self.rearCameraInput!) {
                /// First check if the rear camera can be added
                captureSession.addInput(self.rearCameraInput!)
                self.selectedCamera = CameraSelection.rear;
                print("Configured camera to use rear-facing camera.")
            } else if captureSession.canAddInput(self.frontCameraInput!) {
                /// If the rear camera input cannot be added, then try adding the front camera input
                captureSession.addInput(self.frontCameraInput!)
                self.selectedCamera = CameraSelection.front;
                print("Configured camera to use front-facing camera.")
            } else {
                /// If neither camera input can be added throw unableToAddInputToSession
                throw CameraControllerError.unableToAddInputToSession
            }
        } else { throw CameraControllerError.noCamerasAvailable }
    }
    
    
    /*
     MARK: configureDeviceOutput
        Links the camera session to the ouputs (currently only AVCapturePhotoOutput) .
     */
    func configureDeviceOutput() throws {
        print("\nConfiguring device output...")
        /// Verify that the capture session is initialized.
        guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
        
        /// Initialize still image photo output (AVCapturePhotoOutput).
        self.photoOutput = AVCapturePhotoOutput();
        self.photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil);
        
        /// If the output can be added to the capture session, do so. Otherwise throw error.
        if captureSession.canAddOutput(self.photoOutput!) {
            print("Configured device output.")
            captureSession.addOutput(self.photoOutput!);
        } else { throw CameraControllerError.unableToAddOutputToSession }
    }
}




/*
 MARK: USAGE METHODS
 */
extension CameraController {
    /*
     MARK: displayPreview
        Takes a UIView as a parameter. Inserts the CameraController's
        AVCaptureVideoPreviewLayer as a sublayer to the view.
     */
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
    

    /*
     MARK: capturePhoto
        Takes an AVCapturePhotoCaptureDelegate as parameter. Sets the AVCapturePhotoSettings
        based on the provided user preferences, then calls the AVCapturePhotoOutput's capturePhoto method.
        
     */
    func capturePhoto(delegate: AVCapturePhotoCaptureDelegate) {
        print("\nCapturing photo...")
        /// Edit the capture settings with the provided user preferences:
        let settings = AVCapturePhotoSettings();
        settings.flashMode = self.flashMode;
        self.photoOutput?.capturePhoto(with: settings, delegate: delegate);
    }
    
    // MARK: switchCamera
    func switchCamera(completionHandler: @escaping (Error?) -> Void) {
        do {
            /// Call the approptriate helper method to switch the currently selected camera:
            if self.selectedCamera == CameraSelection.front {
                try self.switchCameraToRear();
            } else {
                try self.switchCameraToFront();
            }
            completionHandler(nil); /// completionHandler returns without error
        } catch {
            completionHandler(error); /// return completionHandler with given error
        }
    }
    
    
    /*
     MARK: switchCameraToFront
        Helper method to switchCamera that switches the CameraController from using
        the rear facing to the front facing camera.
     */
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
        } else { throw CameraControllerError.unableToAddInputToSession }
    }
    
    /*
     MARK: switchCameraToRear
        Helper method to switchCamera that switches the CameraController from using
        the front facing to the rear facing camera.
     */
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
        } else { throw CameraControllerError.unableToAddInputToSession }
    }
    
    /*
     MARK: toggleFlashMode
        Toggles the flash mode setting and returns the appropriate button icon to reflect the current state.
     */
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
    
    /*
     MARK: getFlashMode
        Returns a button icon that reflects the current state of the flash mode setting.
     */
    func getFlashMode() -> UIImage {
        if self.flashMode == AVCaptureDevice.FlashMode.on {
            return UIImage(named: "icons8-flash-on-50")!;
        } else {
            return UIImage(named: "icons8-flash-off-50")!;
        }
    }
    
    /*
     MARK: getCameraSelection
        Returns a the currently selected camera.
     */
    func getCameraSelection() -> CameraController.CameraSelection {
        return self.selectedCamera!;
    }
}



/*
 MARK: ENUMERATIONS
    Adds enumerations used by the CameraController class.
 */
extension CameraController {
    // Errors that come from the CameraController
    enum CameraControllerError: Swift.Error {
        case rearCaptureDeviceInputMissing
        case frontCaptureDeviceInputMissing
        case authorizationRestricted /// user cannot give authorization to device's cameras
        case authorizationDenied /// user has denied acces to device's cameras
        case captureSessionIsMissing /// capture session has not been intialized
        case unableToAddInputToSession /// capture session was unable to add the device input
        case unableToAddOutputToSession /// capture session was unable to add the device output
        case noCamerasAvailable /// Unable to find and input devices
        case unknown /// unknown error
    }
    
    // Indicates which camera is currently in use.
    enum CameraSelection {
        case front
        case rear
    }
}
