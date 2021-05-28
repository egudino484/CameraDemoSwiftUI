//
//  CameraViewModel.swift
//  CameraDemo
//
//  Created by  Edison Gudino on 18/1/21.
//

import Foundation
import AVFoundation
import Combine
import UIKit

final class CameraViewModel: ObservableObject {
   
   private let service = CameraService()
   
   @Published var showPreview = false
   @Published var showAlertError = false
   @Published var isFlashOn = false
   
   var takenPicture: UIImage?
   
   var alertError: AlertError!
   
   var session: AVCaptureSession
   
   private var subscriptions = Set<AnyCancellable>()
   
   init() {
      self.session = service.session
      
      service.$takenPicture
         .sink(receiveValue: { [weak self] photo in
            guard let photo = photo else { return }
            self?.showPreview = true
            self?.takenPicture = photo
         })
         .store(in: &subscriptions)
      
      service.$shouldShowAlertView.sink { [weak self] (val) in
         self?.alertError = self?.service.alertError
         self?.showAlertError = val
      }
      .store(in: &self.subscriptions)
   }
   
   func configure() {
      service.checkForPermissions()
      service.configure()
   }
   
   func capturePhoto() {
      service.capturePhoto()
   }
   
   func flipCamera() {
      service.changeCamera()
   }
   
   func stop() {
      service.stop()
   }
   
}
