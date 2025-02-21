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
            Color(.accent).ignoresSafeArea()
            
            VStack {
                HeaderView(user: user, title: "My Settings")
                
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
                    
                } label: {
                    Text("Sign out")
                        .padding()
                        .padding(.horizontal)
                        .background(.white)
                        .cornerRadius(10)
                        .foregroundColor(Color(.accent))
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
