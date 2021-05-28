//
//  ContentView.swift
//  CameraDemo
//
//  Created by  Edison Gudino on 18/1/21.
//

import SwiftUI

struct CameraView: View {
   
   @StateObject var model = CameraViewModel()
   
   var body: some View {
      VStack(alignment: .leading) {
         
         Text("Take a selfie to continue")
//            .foregroundColor(Color(.darkGray))
         
         CameraPreview(session: model.session)
            .cornerRadius(10)
            .onAppear {
               model.configure()
               
            }
            .onDisappear {
               model.stop()
               
            }
         
         ZStack {
            CaptureButton(capture: model.capturePhoto)
            
            HStack {
               Spacer()
               
               FlipCameraButton(flip: model.flipCamera)
                  .padding(.horizontal, 20)
            }
         }
         
         NavigationLink(destination: PhotoPreviewView(photo: model.takenPicture),
                        isActive: $model.showPreview) { EmptyView() }
      }
      .padding(.horizontal)
      .navigationTitle("Selfie")
      
   }
}

struct CaptureButton: View {
   
   var capture: () -> Void
   
   var body: some View {
      Button(action: capture, label: {
         Circle()
            .foregroundColor(Color("CaptureButton1Color"))
            .frame(width: 80, height: 80, alignment: .center)
            .overlay(
               Circle()
                  .stroke(Color("CaptureButton2Color"), lineWidth: 2)
                  .frame(width: 65, height: 65, alignment: .center)
            )
      })
   }
}

struct FlipCameraButton: View {
   
   var flip: () -> Void
   
   var body: some View {
      Button(action: flip, label: {
         Circle()
            .foregroundColor(Color.gray.opacity(0.2))
            .frame(width: 45, height: 45, alignment: .center)
            .overlay(
               Image(systemName: "camera.rotate.fill")
                  .foregroundColor(.white))
      })
   }
   
}

struct ContentView_Previews: PreviewProvider {
   static var previews: some View {
      NavigationView {
         CameraView()
            .environment(\.colorScheme, .dark)
      }
   }
}
