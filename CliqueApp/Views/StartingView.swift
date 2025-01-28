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
                
                Color.accentColor.ignoresSafeArea()
            
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
        Image(systemName: "bonjour")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 150, height: 150)
            .foregroundColor(.white)
        
    }
    
    private var mainpage_subtitle: some View {
        VStack {
            Text("Let's Clique")
                .font(.custom("Noteworthy-Bold", size: 25))
                .foregroundColor(.white)
            
            RoundedRectangle(cornerRadius: /*@START_MENU_TOKEN@*/25.0/*@END_MENU_TOKEN@*/)
                .frame(width:120, height:3)
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
            .foregroundColor(Color.accentColor)
            .shadow(radius: 10)
    }
}
