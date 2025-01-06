//
//  LoginView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct LoginView: View {
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
                
                NavigationLink("Sign in", destination: LandingView(enteredName: name, enteredEmail: email, landing_background_color: main_color))
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

#Preview {
    var backgroundColor: Color = Color(#colorLiteral(red: 0.4620226622, green: 0.8382837176, blue: 1, alpha: 1))
    LoginView(main_color: backgroundColor)
}
