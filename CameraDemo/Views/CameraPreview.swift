//
//  CameraPreview.swift
//  CameraDemo
//
//  Created by  Edison Gudino on 18/1/21.
//

import Foundation
import UIKit
import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
   
   let session: AVCaptureSession
   
   class VideoPreviewView: UIView {
      override class var layerClass: AnyClass {
         AVCaptureVideoPreviewLayer.self
      }
      
      var videoPreviewLayer: AVCaptureVideoPreviewLayer {
         return layer as! AVCaptureVideoPreviewLayer
      }
   }
   
   func makeUIView(context: Context) -> VideoPreviewView {
      let view = VideoPreviewView()
      view.backgroundColor = .black
      view.videoPreviewLayer.cornerRadius = 0
      view.videoPreviewLayer.session = session
      view.videoPreviewLayer.connection?.videoOrientation = .portrait
      view.videoPreviewLayer.videoGravity = .resizeAspectFill
      
      return view
   }
   
   func updateUIView(_ uiView: VideoPreviewView, context: Context) {}
   
}
