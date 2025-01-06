//
//  ContentView.swift
//  SwiftfulBootcamp
//
//  Created by Tarek Sakakini on 12/26/24.
//

import SwiftUI

struct ContentView: View {
    @State var backgroundColor: Color = Color(#colorLiteral(red: 0.4620226622, green: 0.8382837176, blue: 1, alpha: 1))
    
    var body: some View {
        NavigationView {
            ZStack {
                
                backgroundColor.ignoresSafeArea()
            
                VStack {
                    Spacer()
                    
                    Image(systemName: "bonjour")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .foregroundColor(.white)
                    
                    Text("Let's Clique")
                        .font(.custom("Noteworthy-Bold", size: 25))
                        .foregroundColor(.white)
                    
                    RoundedRectangle(cornerRadius: /*@START_MENU_TOKEN@*/25.0/*@END_MENU_TOKEN@*/)
                        .frame(width:120, height:3)
                        .foregroundColor(.white)
                    
                    Spacer()
                    Spacer()
                    
                    NavigationLink("Log In", destination: LoginView(main_color: backgroundColor))
                        .bold()
                        .font(.title2)
                        .padding()
                        .padding(.horizontal)
                        .background(.white)
                        .cornerRadius(10)
                        .foregroundColor(backgroundColor)
                        .shadow(radius: 10)
                    
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
