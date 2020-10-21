//
//  CameraErrors.swift
//  MyCameraApp
//
//  Created by Ethan Gabrielse on 10/21/20.
//

import Foundation

enum CameraControllerError: Swift.Error {
    case authorizationRestricted
    case authorizationDenied
    case captureSessionAlreadyRunning
    case captureSessionIsMissing
    case inputsAreInvalid
    case invalidOperation
    case noCamerasAvailable
    case unknown
}
