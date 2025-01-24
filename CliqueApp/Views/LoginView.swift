//
//  LoginView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct LoginView: View {
    
    @EnvironmentObject private var ud: UserViewModel
    
    @State var enteredUsername: String = ""
    @State var enteredPassword: String = ""
    
    @State var loginBackgroundColor: Color = Color.white
    @State var main_color: Color
    
    @State var show_wrong_message: Bool = false
    
    @State var go_to_landing_screen: Bool = false
    
    var body: some View {
        ZStack {
            loginBackgroundColor.ignoresSafeArea()
            
            VStack {
                
                
                
                Spacer()
                
                header
                
                Spacer()
                
                user_fields
                
                if show_wrong_message {
                    Text("Wrong username/password. Try again.").font(.caption)
                        .foregroundColor(.red.opacity(0.8 ))
                }
                
                
                
                Spacer()
                
                signin_button
                
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
        .environmentObject(UserViewModel())
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
        
        
        //        NavigationLink(
        //            "Sign in",
        //            destination: {
        //                if ud.isUserPresent(username: enteredUsername, password: enteredPassword) {
        //                    LandingView(enteredName: enteredUsername, enteredEmail: enteredPassword, landing_background_color: main_color)
        //                }
        //            })
        //        .padding()
        //        .padding(.horizontal)
        //        .background(.white)
        //        .cornerRadius(10)
        //        .foregroundColor(main_color)
        //        .bold()
        //        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
        
        Button {
            if ud.isUserPresent(username: enteredUsername, password: enteredPassword) {
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
                .foregroundColor(main_color)
                .bold()
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
        }
        .navigationDestination(isPresented: $go_to_landing_screen) {
            LandingView(enteredName: enteredUsername, enteredEmail: enteredPassword, landing_background_color: main_color)
        }

        //        NavigationLink(
        //            "Sign in",
        //            destination: LandingView(enteredName: enteredUsername, enteredEmail: enteredPassword, landing_background_color: main_color)
        //        )
        //        .padding()
        //        .padding(.horizontal)
        //        .background(.white)
        //        .cornerRadius(10)
        //        .foregroundColor(main_color)
        //        .bold()
        //        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
        //        .disabled(!ud.isUserPresent(username: enteredUsername, password: enteredPassword))
        //        .onTapGesture {
        //            if !ud.isUserPresent(username: enteredUsername, password: enteredPassword) {
        //                show_wrong_message = true
        //            }
        //            else {
        //                show_wrong_message = false
        //            }
        //        }
    }
}
