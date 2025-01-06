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
                    
                    NavigationLink("Log In", destination: LogInScreen(main_color: backgroundColor))
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

struct LogInScreen: View {
    @State var name: String = ""
    @State var email: String = ""
    
    @State var loginBackgroundColor: Color = Color.white
    @State var main_color: Color
    
    var body: some View {
        ZStack {
            loginBackgroundColor.ignoresSafeArea()
            
//            RoundedRectangle(cornerRadius: /*@START_MENU_TOKEN@*/25.0/*@END_MENU_TOKEN@*/)
//                .frame(width: 300, height:500)
//                .foregroundColor(Color(#colorLiteral(red: 0.5818830132, green: 0.2156915367, blue: 1, alpha: 1)))
            
            VStack {
                
                Spacer()
                
                HStack {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(.white)
                        .frame(width: 5, height: 50, alignment: .leading)
                    
                    Text("Login")
                        .foregroundColor(.white)
                        .font(.largeTitle)
                    
                    Spacer()
                    
                    Image(systemName: "bonjour")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
                Spacer()
                
                TextField("Enter your name here ...", text: $name)
                    .padding()
                    .background(.white)
                    .cornerRadius(10)
                    .padding()
                
                TextField("Enter your e-mail here ...", text: $email)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .padding()
                    .background(.white)
                    .cornerRadius(10)
                    .padding()
                
                Spacer()
                
                NavigationLink("Sign in", destination: landingScreen(enteredName: name, enteredEmail: email, landing_background_color: main_color))
                    .padding()
                    .padding(.horizontal)
                    .background(.white)
                    .cornerRadius(10)
                    .foregroundColor(main_color)
                    .bold()
                    .shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                
                Spacer()
                    
                
            }
            .frame(width: 300, height: 500)
            .background(main_color)
            .cornerRadius(20)
            .shadow(radius: 50)
        }
        
        
    }
}

struct landingScreen: View {
    @State var enteredName: String
    @State var enteredEmail: String
    @State var landing_background_color: Color
    
    @State var events: [String] = ["Snowboarding", "Board Game Night", "Snowboarding", "Board Game Night", "Snowboarding", "Board Game Night", "Snowboarding", "Board Game Night", "Snowboarding", "Board Game Night", "Snowboarding", "Board Game Night", "Snowboarding", "Board Game Night", "Snowboarding", "Board Game Night", "Snowboarding", "Board Game Night", "Snowboarding", "Board Game Night", "Snowboarding", "Board Game Night", "Snowboarding", "Board Game Night"]
    
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
                    
                    Text("Tarek")
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
    ContentView()
}
