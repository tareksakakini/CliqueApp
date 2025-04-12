//
//  LoginView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct ResetPassordView: View {
    
    @EnvironmentObject private var ud: ViewModel
    
    @State var username: String = ""
    @State var confirmationMessage: String = " "
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack {
                BackNavigation(foregroundColor: Color(.accent))
                Spacer()
                ResetPasswordSheet
                Spacer()
            }
            
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    ResetPassordView()
        .environmentObject(ViewModel())
}

extension ResetPassordView {
    private var ResetPasswordSheet: some View {
        VStack {
            Title
            EmailField
            ConfirmationMessage
            ResetButton
        }
        .frame(width: 300, height: 350)
        .background(Color(.accent))
        .cornerRadius(20)
        .shadow(radius: 50)
    }
    private var Title: some View {
        HStack {
            Image("yalla_transparent")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
                .foregroundColor(.white)
            
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(.white)
                .frame(width: 5, height: 50, alignment: .leading)
            
            Text("Reset Password")
                .foregroundColor(.white)
                .font(.title2)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    
    private var ConfirmationMessage: some View {
        Text(confirmationMessage)
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(2)
    }
    
    private var EmailField: some View {
        
        VStack(alignment: .leading) {
            Text("Email")
                .padding(.top, 15)
                .padding(.leading, 25)
                .font(.title2)
                .foregroundColor(.white)
            
            TextField("", text: $username, prompt: Text("Enter your email here ...").foregroundColor(Color.black.opacity(0.5)))
                .foregroundColor(.black)
                .padding()
                .background(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
    }
    
    private var ResetButton: some View {
        
        Button {
            Task {
                do {
                    try await AuthManager.shared.sendPasswordReset(email: username)
                    confirmationMessage = "Reset password email sent"
                } catch {
                    print("Failed to send password reset email: \(error.localizedDescription)")
                }
            }
        } label: {
            Text("Reset Password")
                .padding()
                .padding(.horizontal)
                .background(.white)
                .cornerRadius(10)
                .foregroundColor(Color(.accent))
                .bold()
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
        }
        .padding(.bottom, 30)
    }
}
