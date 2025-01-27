//
//  LandingView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct LandingView: View {
    
    @EnvironmentObject private var ud: ViewModel
    
    @State var enteredName: String
    @State var enteredEmail: String
    @State var landing_background_color: Color
    
    @State var events: [String] = ["Snowboarding", "Board Game Night"]
    
    var body: some View {
        
        ZStack {
            landing_background_color.ignoresSafeArea()
            
            VStack {
                HStack {
                    
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundColor(.white)
                        .frame(width: 5, height: 45)
                    
                    Text("Your Events")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Circle()
                        .frame(width: 25, height: 25)
                        .foregroundColor(.white)
                    
                    Text(enteredName)
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .bold()
                }
                .padding()
                
                ScrollView {
                    ForEach(events, id: \.self) { event in
                        VStack(alignment: .leading) {
                            Text("\(event)")
                                .foregroundColor(landing_background_color)
                                .padding(.horizontal)
                                .font(.title3)
                                .bold()
                                
                            
                            Text("Location of Event")
                                .foregroundColor(landing_background_color)
                                .padding(.horizontal)
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 100)
                        .background(.white)
                        .cornerRadius(15)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 5)
                        
                    }
                }
            }
        }
    }
}

#Preview {
    var name: String = "John Doe"
    var email: String = "john@example.com"
    var main_color: Color = Color(#colorLiteral(red: 0.4620226622, green: 0.8382837176, blue: 1, alpha: 1))
    LandingView(enteredName: name, enteredEmail: email, landing_background_color: main_color)
        .environmentObject(ViewModel())
}
