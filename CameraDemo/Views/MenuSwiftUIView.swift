//
//  MenuSwiftUIView.swift
//  CameraDemo for Swift UI
//
//  Created by Edison Gudiño on 28/5/21.
//

import SwiftUI

struct MenuSwiftUIView: View {
   @State var showCamera = false
   @State var isBusy = false
   //Since the response is an array of TaskEntry object
   @State var results = [TaskEntry]()
   var body: some View {
      VStack(alignment: .leading) {
         
         Button(action: {
            
            loadData()
         }, label: {
            Text("Go to camera")
         })
         if isBusy {
            Text("Cargando Datos...")
         }
         NavigationLink(destination: CameraView(),
                        isActive: $showCamera) { EmptyView() }
      }
      .padding(.horizontal)
      .navigationTitle("Selfie")
      
   }
   
   func loadData() {
      isBusy = true
      guard let url = URL(string: "https://jsonplaceholder.typicode.com/todos") else {
         print("Invalid URL")
         return
      }
      let request = URLRequest(url: url)
      
      URLSession.shared.dataTask(with: request) { data, response, error in
         if let data = data {
            isBusy = false
            print(response)
            if let response = try? JSONDecoder().decode([TaskEntry].self, from: data) {
               DispatchQueue.main.async {
                  self.results = response
                  showCamera = true
               }
               return
            }
         }
      }.resume()
   }
}


struct MenuSwiftUIView_Previews: PreviewProvider {
   static var previews: some View {
      MenuSwiftUIView()
   }
}
