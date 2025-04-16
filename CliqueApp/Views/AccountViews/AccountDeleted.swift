//
//  AccountDeleted.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 4/15/25.
//

import SwiftUI

struct AccountDeleted: View {
    @State var goToLoginScreen: Bool = false
    var body: some View {
        ZStack {
            Color(.accent).ignoresSafeArea()
            
            VStack {
                Text("Account deleted successfully")
                    .foregroundColor(.white)
                
                Button {
                    Task {
                        goToLoginScreen = true
                    }
                } label: {
                    Text("Go to Login Page")
                        .frame(width: 200, height: 60)
                        .background(.white)
                        .cornerRadius(10)
                        .foregroundColor(Color(.accent))
                        .bold()
                        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
                }
                .navigationDestination(isPresented: $goToLoginScreen) {
                    LoginView()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    AccountDeleted()
}
