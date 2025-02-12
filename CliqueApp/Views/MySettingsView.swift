//
//  LandingView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct MySettingsView: View {
    
    @EnvironmentObject private var ud: ViewModel
    
    
    @State var user: UserModel
    @State var go_to_login_screen: Bool = false
    @State var message: String = ""
    
    var body: some View {
        
        ZStack {
            Color.accentColor.ignoresSafeArea()
            
            VStack {
                header
                
                Spacer()
                
                Button {
                    
                    Task {
                        do {
                            try AuthManager.shared.signOut()
                            go_to_login_screen = true
                            print("User signed out")
                        } catch {
                            print("Sign out failed")
                        }
                    }
                    
//                    AuthManager.shared.signOut { success, error in
//                        if success {
//                            //isLoggedIn = false
//                            //message = "Signed Out"
//                            go_to_login_screen = true
//                        } else {
//                            message = error ?? "Unknown error"
//                        }
//                    }
                    
                } label: {
                    Text("Sign out")
                        .padding()
                        .padding(.horizontal)
                        .background(.white)
                        .cornerRadius(10)
                        .foregroundColor(Color.accentColor)
                        .bold()
                        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
                }
                .navigationDestination(isPresented: $go_to_login_screen) {
                    LoginView()
                }
                
                Text("\(message)")
                
                Spacer()
            }
        }
    }
}

#Preview {
    MySettingsView(user: UserData.userData[0])
        .environmentObject(ViewModel())
}

extension MySettingsView {
    private var header: some View {
        HStack {
            
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(.white)
                .frame(width: 5, height: 45)
            
            Text("My Settings")
                .font(.largeTitle)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(user.profilePic)
                .resizable()
                .scaledToFit()
                .clipShape(Circle())
                .frame(width: 30)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .padding(.leading)
            
            Text(user.email)
                .foregroundColor(.white)
                .font(.subheadline)
                .bold()
        }
        .padding()
    }
}
