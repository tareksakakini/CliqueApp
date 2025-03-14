////
////  LandingView.swift
////  CliqueApp
////
////  Created by Tarek Sakakini on 1/6/25.
////
//
//import SwiftUI
//import MapKit
//
//struct LocationPickerView: View {
//    
//    @StateObject private var locationSearchHelper = LocationSearchHelper()
//    @State private var query = ""
//    
//    var body: some View {
//        ZStack {
//            Color(.accent).ignoresSafeArea()
//            
//            VStack {
//                TextField("Enter address", text: $query)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .padding()
//                    .onChange(of: query) { newValue in
//                        locationSearchHelper.updateSearchResults(for: newValue)
//                    }
//                
//                List(locationSearchHelper.suggestions, id: \.title) { suggestion in
//                    VStack(alignment: .leading) {
//                        Text(suggestion.title).font(.headline)
//                        Text(suggestion.subtitle).font(.subheadline).foregroundColor(.gray)
//                    }
//                    .onTapGesture {
//                        print("Selected: \(suggestion.title), \(suggestion.subtitle)")
//                    }
//                }
//            }
//            .padding()
//        }
//    }
//    
//}
//
//#Preview {
//    LocationPickerView()
//}
