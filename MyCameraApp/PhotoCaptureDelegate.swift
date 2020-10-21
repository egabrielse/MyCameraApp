//
//  PhotoCaptureDelegate.swift
//  MyCameraApp
//
//  Created by Ethan Gabrielse on 10/21/20.
//

import Foundation
import AVFoundation
import UIKit


class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    var images: [UIImage];
    
    init(images: [UIImage]) {
        self.images = images;
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("Handling photo capture output...")
        if let error = error {
            print(error);
        } else {
            if let imageData = photo.fileDataRepresentation() {
                print("Photo captured.")
                let img = UIImage(data: imageData)!
                images.append(img);
            }
        }
    }
}
