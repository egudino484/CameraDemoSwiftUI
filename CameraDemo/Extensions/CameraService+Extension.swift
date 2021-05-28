//
//  CameraService+Extension.swift
//  CameraDemo
//
//  Created by Edison Gudino on 18/1/21.
//

import Foundation

extension CameraService {
   
   enum LivePhotoMode {
      case on
      case off
   }
   
   enum DepthDataDeliveryMode {
      case on
      case off
   }
   
   enum PortraitEffectsMatteDeliveryMode {
      case on
      case off
   }
   
   enum SessionSetupResult {
      case success
      case notAuthorized
      case configurationFailed
   }
   
   enum CaptureMode: Int {
      case photo = 0
      case movie = 1
   }
   
}
