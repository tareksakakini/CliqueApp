//
//  LoginView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct SignUpView: View {
    
    @EnvironmentObject private var ud: ViewModel
    
    @State var fullname: String = ""
    @State var username: String = ""
    @State var password: String = ""
    @State var message: String = ""
    
    
    @State var show_wrong_message: Bool = false
    
    @State var goToMainView: Bool = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack {
                
                
                
                Spacer()
                
                header
                
                Spacer()
                
                user_fields
                
                Spacer()
                Spacer()
                Spacer()
                
                signup_button
                
                Text("\(message)")
                
                Spacer()
                Spacer()
                Spacer()
                
                
            }
            .frame(width: 400, height: 700)
            .background(Color.accentColor)
            .cornerRadius(20)
            .shadow(radius: 50)
        }
        
        
    }
}

#Preview {
    SignUpView()
        .environmentObject(ViewModel())
}

extension SignUpView {
    private var header: some View {
        HStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(.white)
                .frame(width: 5, height: 50, alignment: .leading)
            
            Text("Sign Up")
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
        
        VStack(alignment: .leading) {
            Text("Full Name")
                .padding(.top, 30)
                .padding(.leading, 25)
                .font(.title2)
                .foregroundColor(.white)
            
            TextField("Enter your name here ...", text: $fullname)
                .padding()
                .background(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            
            Text("Username")
                .padding(.top, 15)
                .padding(.leading, 25)
                .font(.title2)
                .foregroundColor(.white)
            
            TextField("Enter your username here ...", text: $username)
                .padding()
                .background(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            
            Text("Password")
                .padding(.top, 15)
                .padding(.leading, 25)
                .font(.title2)
                .foregroundColor(.white)
            
            SecureField("Enter your password here ...", text: $password)
                .padding()
                .background(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
        
    }
    
    private var signup_button: some View {
        
        Button {
            AuthManager.shared.signUp(email: username, password: password, fullname: fullname) { success, error in
                message = success ? "Sign Up Successful!" : error ?? "Unknown error"
            }
            //ud.addUser(fullname: fullname, username: username, password: password)
            goToMainView = true
            
        } label: {
            Text("Create Account")
                .padding()
                .padding(.horizontal)
                .background(.white)
                .cornerRadius(10)
                .foregroundColor(Color.accentColor)
                .bold()
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
        }
        .navigationDestination(isPresented: $goToMainView) {
            if let user = ud.getUser(username: username) {
                MainView(user: user)
            }
        }
    }
}
