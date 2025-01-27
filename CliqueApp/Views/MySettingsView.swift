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
    
    var body: some View {
        
        ZStack {
            Color.accentColor.ignoresSafeArea()
            
            VStack {
                header
                
                Spacer()
                
                Button {
                    go_to_login_screen = true
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
            
            Circle()
                .frame(width: 25, height: 25)
                .foregroundColor(.white)
            
            Text(user.firstName)
                .foregroundColor(.white)
                .font(.subheadline)
                .bold()
        }
        .padding()
    }
}
