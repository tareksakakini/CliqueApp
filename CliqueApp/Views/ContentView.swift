//
//  ContentView.swift
//  SwiftfulBootcamp
//
//  Created by Tarek Sakakini on 12/26/24.
//

import SwiftUI

struct ContentView: View {
    // Main View
    // this is a dummy comment
    @State var backgroundColor: Color = Color(#colorLiteral(red: 0.4620226622, green: 0.8382837176, blue: 1, alpha: 1))
    @EnvironmentObject private var ud: UserViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                backgroundColor.ignoresSafeArea()
            
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
    ContentView()
        .environmentObject(UserViewModel())
}

extension ContentView {
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
        NavigationLink("Log In", destination: LoginView(main_color: backgroundColor))
            .bold()
            .font(.title2)
            .padding()
            .padding(.horizontal)
            .background(.white)
            .cornerRadius(10)
            .foregroundColor(backgroundColor)
            .shadow(radius: 10)
    }
}
