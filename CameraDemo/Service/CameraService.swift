//
//  CameraService.swift
//  CameraDemo
//
//  Created by  Edison Gudino on 18/1/21.
//

import Foundation
import Combine
import AVFoundation
import UIKit

public class CameraService: NSObject, Identifiable {
   
   @Published public var shouldShowAlertView = false
   @Published public var isCameraButtonDisabled = false
   @Published public var isCameraUnavailable = false
   @Published public var takenPicture: UIImage?
   
   public var alertError: AlertError = AlertError()
   
   public let session = AVCaptureSession()
   
   private var isSessionRunning = false
   private var isConfigured = false
   private var setupResult: SessionSetupResult = .success
   
   private var videoDeviceInput: AVCaptureDeviceInput!
   private let photoOutput = AVCapturePhotoOutput()
   private let scanOutput = AVCaptureMetadataOutput()
   
   private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
                                                                              mediaType: .video, position: .unspecified)
   private let sessionQueue = DispatchQueue(label: "session queue")
   
   override public init() {
      super.init()
      DispatchQueue.main.async {
         self.isCameraButtonDisabled = true
         self.isCameraUnavailable = true
      }
   }
   
   public func configure() {
      sessionQueue.async { [unowned self] in
         self.configureSession()
      }
   }
   
   private func configureSession() {
      if setupResult != .success {
         return
      }
      
      session.beginConfiguration()
      session.sessionPreset = .photo
      
      var defaultVideoDevice: AVCaptureDevice?
      
      if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
         defaultVideoDevice = backCameraDevice
      } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
         defaultVideoDevice = frontCameraDevice
      }
      
      guard let videoDevice = defaultVideoDevice else {
         setupResult = .configurationFailed
         session.commitConfiguration()
         return
      }
      
      guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
         print("Couldn't create video device input")
         setupResult = .configurationFailed
         session.commitConfiguration()
         return
      }
      
      if !addDeviceInput(input: videoDeviceInput) {
         setupResult = .configurationFailed
         session.commitConfiguration()
         return
      }
      
      if !addDeviceOutput() {
         print("Could not add photo output to the session")
         setupResult = .configurationFailed
         session.commitConfiguration()
         return
      }
      
      _ = addScanOutput()
      
      session.commitConfiguration()
      
      self.isConfigured = true
      sessionQueue.async { [unowned self] in
         self.start()
      }
   }
   
   private func addDeviceInput(input: AVCaptureDeviceInput) -> Bool {
      if let input = self.videoDeviceInput, session.inputs.contains(input) {
         return true
      }
      if session.canAddInput(input) {
         session.addInput(input)
         self.videoDeviceInput = input
         return true
      }
      return false
   }
   
   private func addDeviceOutput() -> Bool {
      if session.outputs.contains(photoOutput) {
         return true
      }
      if session.canAddOutput(photoOutput) {
         session.addOutput(photoOutput)
         photoOutput.isHighResolutionCaptureEnabled = true
         photoOutput.maxPhotoQualityPrioritization = .quality
         return true
      }
      return false
   }
   
   private func addScanOutput() -> Bool {
      if session.outputs.contains(scanOutput) {
         return true
      }
      if session.canAddOutput(scanOutput) {
         session.addOutput(scanOutput)
         scanOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
         scanOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr] //scanOutput.availableMetadataObjectTypes
         return true
      }
      return false
   }
   
   private func start() {
      guard !self.isSessionRunning, self.isConfigured else {
         return
      }
      
      switch self.setupResult {
      case .success:
         self.session.startRunning()
         self.isSessionRunning = self.session.isRunning
         if self.session.isRunning {
            DispatchQueue.main.async {
               self.isCameraButtonDisabled = false
               self.isCameraUnavailable = false
            }
         }
         
      case .notAuthorized:
         DispatchQueue.main.async {
            self.isCameraButtonDisabled = true
            self.isCameraUnavailable = true
         }
         
      case .configurationFailed:
         DispatchQueue.main.async {
            self.alertError = AlertError(title: "Camera Error",
                                         message: "Camera configuration failed. Either your device camera is not available or other application is using it",
                                         primaryButtonTitle: "Accept", secondaryButtonTitle: nil, primaryAction: nil, secondaryAction: nil)
            self.shouldShowAlertView = true
            self.isCameraButtonDisabled = true
            self.isCameraUnavailable = true
         }
      }
   }
   
   public func stop(completion: (() -> ())? = nil) {
      sessionQueue.async { [unowned self] in
         if self.isSessionRunning {
            if self.setupResult == .success {
               self.session.stopRunning()
               self.isSessionRunning = self.session.isRunning
               if !self.session.isRunning {
                  DispatchQueue.main.async {
                     self.isCameraButtonDisabled = true
                     self.isCameraUnavailable = true
                     completion?()
                  }
               }
            }
         }
      }
   }
   
   public func checkForPermissions() {
      switch AVCaptureDevice.authorizationStatus(for: .video) {
      case .authorized:
         break
         
      case .notDetermined:
         sessionQueue.suspend()
         AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
            if !granted {
               self.setupResult = .notAuthorized
            }
            self.sessionQueue.resume()
         })
         
      default:
         setupResult = .notAuthorized
         
         DispatchQueue.main.async {
            self.alertError = AlertError(title: "Camera Access",
                                         message: "Campus no tiene permiso para usar la cámara, por favor cambia la configruación de privacidad",
                                         primaryButtonTitle: "Configuración", secondaryButtonTitle: nil,
                                         primaryAction: {
                                          UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                    options: [:], completionHandler: nil)
                                         }, secondaryAction: nil)
            self.shouldShowAlertView = true
            self.isCameraUnavailable = true
            self.isCameraButtonDisabled = true
         }
      }
   }
   
   public func changeCamera() {
      DispatchQueue.main.async {
         self.isCameraButtonDisabled = true
      }
      
      sessionQueue.async { [unowned self] in
         let currentVideoDevice = self.videoDeviceInput.device
         let currentPosition = currentVideoDevice.position
         
         let preferredPosition: AVCaptureDevice.Position
         let preferredDeviceType: AVCaptureDevice.DeviceType
         
         switch currentPosition {
         case .unspecified, .front:
            preferredPosition = .back
            preferredDeviceType = .builtInWideAngleCamera
            
         case .back:
            preferredPosition = .front
            preferredDeviceType = .builtInWideAngleCamera
            
         @unknown default:
            preferredPosition = .back
            preferredDeviceType = .builtInWideAngleCamera
         }
         let devices = self.videoDeviceDiscoverySession.devices
         var newVideoDevice: AVCaptureDevice? = nil
         
         if let device = devices.first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType }) {
            newVideoDevice = device
         } else if let device = devices.first(where: { $0.position == preferredPosition }) {
            newVideoDevice = device
         }
         
         guard let videoDevice = newVideoDevice, let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
         }
         
         self.session.beginConfiguration()
         self.session.removeInput(self.videoDeviceInput)
         
         if self.session.canAddInput(videoDeviceInput) {
            self.session.addInput(videoDeviceInput)
            self.videoDeviceInput = videoDeviceInput
         } else {
            self.session.addInput(self.videoDeviceInput)
         }
         
         if let connection = self.photoOutput.connection(with: .video) {
            if connection.isVideoStabilizationSupported {
               connection.preferredVideoStabilizationMode = .auto
            }
         }
         
         self.photoOutput.maxPhotoQualityPrioritization = .quality
         self.session.commitConfiguration()
         
         DispatchQueue.main.async {
            self.isCameraButtonDisabled = false
         }
      }
   }
   
   public func capturePhoto() {
      let settings = AVCapturePhotoSettings.init(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
      settings.photoQualityPrioritization = .balanced
      sessionQueue.async { [unowned self] in
         self.photoOutput.capturePhoto(with: settings, delegate: self)
      }
   }
   
}

extension CameraService: AVCapturePhotoCaptureDelegate {
   
   public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
      guard error == nil,
            let data = photo.fileDataRepresentation(),
            let image = UIImage(data: data)  else
      {
         alertError = AlertError(title: "Error", message: "Couldn't take picture", primaryButtonTitle: "Ok")
         return
      }
      if videoDeviceInput.device.position == .front, let cgImage = image.cgImage {
         takenPicture = UIImage(cgImage: cgImage, scale: image.scale, orientation: .leftMirrored)
         return
      }
      takenPicture = UIImage(data: data)
   }
   
}

extension CameraService: AVCaptureMetadataOutputObjectsDelegate {
   
   public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
      guard metadataObjects.count > 0, let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject else {
          return
      }
      if object.type == AVMetadataObject.ObjectType.qr, let value = object.stringValue {
          print("Scanned QR:\n\(value)")
      }
   }
   
}
