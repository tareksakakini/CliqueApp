//
//  LoginView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct LoginView: View {
    
    @EnvironmentObject private var ud: ViewModel
    
    @State var enteredUsername: String = ""
    @State var enteredPassword: String = ""
    
    @State var show_wrong_message: Bool = false
    
    @State var go_to_landing_screen: Bool = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack {
                
                
                
                Spacer()
                
                header
                
                Spacer()
                
                user_fields
                
                if show_wrong_message {
                    Text("Wrong username/password. Try again").font(.caption)
                        .foregroundColor(.white)
                }
                
                
                
                Spacer()
                
                signin_button
                
                Spacer()
                
                
            }
            .frame(width: 300, height: 500)
            .background(Color.accentColor)
            .cornerRadius(20)
            .shadow(radius: 50)
        }
        
        
    }
}

#Preview {
    LoginView()
        .environmentObject(ViewModel())
}

extension LoginView {
    private var header: some View {
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
    }
    
    private var user_fields: some View {
        
        VStack {
            TextField("Enter your username here ...", text: $enteredUsername)
                .padding()
                .background(.white)
                .cornerRadius(10)
                .padding()
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            
            TextField("Enter your password here ...", text: $enteredPassword)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .padding()
                .background(.white)
                .cornerRadius(10)
                .padding()
        }
        
    }
    
    private var signin_button: some View {
        
        Button {
            if ud.isUser(username: enteredUsername, password: enteredPassword) {
                go_to_landing_screen = true
                show_wrong_message = false
            }
            else {
                show_wrong_message = true
            }
            
        } label: {
            Text("Sign in")
                .padding()
                .padding(.horizontal)
                .background(.white)
                .cornerRadius(10)
                .foregroundColor(Color.accentColor)
                .bold()
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
        }
        .navigationDestination(isPresented: $go_to_landing_screen) {
            if let user = ud.getUser(username: enteredUsername) {
                MainView(user: user)
            }
            
        }
    }
}
