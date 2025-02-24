//
//  ContentView.swift
//  SwiftfulBootcamp
//
//  Created by Tarek Sakakini on 12/26/24.
//

import SwiftUI

struct StartingView: View {
    // Main View
    @EnvironmentObject private var ud: ViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                Color(.accent).ignoresSafeArea()
            
                VStack {
                    Spacer()
                    
                    mainpage_logo
                    
                    mainpage_subtitle
                    
                    Spacer()
                    Spacer()
                    
                    mainpage_button
                    
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    StartingView()
        .environmentObject(ViewModel())
}

extension StartingView {
    private var mainpage_logo: some View {
        //Image(systemName: "bonjour")
        Image("yalla_transparent")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(Rectangle().offset(x: 0, y: 7).size(width: 400, height: 120))
            .frame(width: 300, height: 120)
            .foregroundColor(.white)
            
        
    }
    
    private var mainpage_subtitle: some View {
        VStack {
            Text("Plan your next outing")
                .foregroundColor(.white)
        }
        
    }
    
    private var mainpage_button: some View {
        NavigationLink("Get Started", destination: LoginView())
            .bold()
            .font(.title2)
            .padding()
            .padding(.horizontal)
            .background(.white)
            .cornerRadius(10)
            .foregroundColor(Color(.accent))
            .shadow(radius: 10)
    }
}
