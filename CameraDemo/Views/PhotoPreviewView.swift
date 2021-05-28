//
//  PhotoPreviewView.swift
//  CameraDemo
//
//  Created by  Edison Gudino on 18/1/21.
//

import SwiftUI
import UIKit

struct PhotoPreviewView: View {
   
   @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
   
   var photo: UIImage?
   
   private let photoHPadding: CGFloat = 5.0
   
   var body: some View {
      VStack(alignment: .leading) {
         
         Text("Do yout like this selfie?")
         
         if let photo = photo {
            GeometryReader { reader in
               Image(uiImage: photo)
                  .resizable()
                  .frame(width: reader.size.width*0.80, height: reader.size.width * 0.8)
                  .scaledToFill()
                  .cornerRadius(10)
            }
         }
         
         HStack {
            Spacer()
            
            Button(action: { self.presentationMode.wrappedValue.dismiss() }) {
               Text("Retry")
            }
            
            Spacer()
            
            Button(action: {}) {
               Text("Accept")
            }
            
            Spacer()
         }
         
         Spacer()
      }
      .padding(.horizontal, photoHPadding)
   }
}

struct PhotoPreviewView_Previews: PreviewProvider {
   static var previews: some View {
      NavigationView {
         PhotoPreviewView(photo: UIImage.imageWithColor(color: .blue))
      }
   }
}

extension UIImage {
   class func imageWithColor(color: UIColor) -> UIImage {
      let rect: CGRect = CGRect(x: 0, y: 0, width: 1000, height: 1000)
      UIGraphicsBeginImageContextWithOptions(CGSize(width: 1000, height: 1000), false, 0)
      color.setFill()
      UIRectFill(rect)
      let image: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      return image!
   }
}
