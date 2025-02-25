//
//  LoginView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct ResetPassordView: View {
    
    @EnvironmentObject private var ud: ViewModel
    
    @State var user = UserModel(fullname: "", email: "", createdAt: Date())
    
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
                
                reset_button
                
                Text("\(message)")
                
                Spacer()
                Spacer()
                Spacer()
                
                
            }
            .frame(width: 400, height: 400)
            .background(Color(.accent))
            .cornerRadius(20)
            .shadow(radius: 50)
        }
        
        
    }
}

#Preview {
    ResetPassordView()
        .environmentObject(ViewModel())
}

extension ResetPassordView {
    private var header: some View {
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
                .font(.largeTitle)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    
    private var user_fields: some View {
        
        VStack(alignment: .leading) {
            
            Text("Email")
                .padding(.top, 15)
                .padding(.leading, 25)
                .font(.title2)
                .foregroundColor(.white)
            
            TextField("Enter your email here ...", text: $username)
                .padding()
                .background(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
        
    }
    
    private var reset_button: some View {
        
        Button {
            Task {
                do {
                    try await AuthManager.shared.sendPasswordReset(email: username)
                    print("Check your email for reset instructions.")
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
        .navigationDestination(isPresented: $goToMainView) {
            
            MainView(user: user)
            
        }
    }
}
