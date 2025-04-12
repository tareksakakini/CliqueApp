//
//  LoginView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct LoginView: View {
    
    @EnvironmentObject private var ud: ViewModel
    
    @State var user: UserModel = UserModel(uid: "", fullname: "", email: "", createdAt: Date(), profilePic: "userDefault")
    @State var enteredUsername: String = ""
    @State var enteredPassword: String = ""
    @State var showWrongMessage: Bool = false
    @State var goToLandingScreen: Bool = false
    @State var goToVerificationScreen: Bool = false
    @State var isPasswordVisible = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack {
                Title
                UserFields
                if showWrongMessage {
                    Text("Wrong username/password. Try again")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                AccountManagement
                signin_button
                
            }
            .frame(width: 300, height: 500)
            .background(Color(.accent))
            .cornerRadius(20)
            .shadow(radius: 50)
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    LoginView()
        .environmentObject(ViewModel())
}

extension LoginView {
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
            
            Text("Login")
                .foregroundColor(.white)
                .font(.largeTitle)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    
    private var UserFields: some View {
        
        VStack {
            TextField("", text: $enteredUsername, prompt: Text("Enter your email here ...").foregroundColor(Color.black.opacity(0.5)))
                .foregroundColor(.black)
                .padding()
                .background(.white)
                .cornerRadius(10)
                .padding()
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            
            HStack {
                if isPasswordVisible {
                    TextField("", text: $enteredPassword, prompt: Text("Enter your password here ...").foregroundColor(Color.black.opacity(0.5)))
                        .foregroundColor(.black)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .background(.white)
                        .cornerRadius(10)
                        .padding()
                } else {
                    SecureField("", text: $enteredPassword, prompt: Text("Enter your password here ...").foregroundColor(Color.black.opacity(0.5)))
                        .foregroundColor(.black)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .background(.white)
                        .cornerRadius(10)
                        .padding()
                }
                
                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
            .padding(.horizontal)
        }
    }
    
    private var AccountManagement: some View {
        VStack {
            HStack {
                Text("Don't have an account?")
                    .font(.caption)
                    .foregroundColor(.white)
                NavigationLink {
                    SignUpView()
                } label: {
                    Text("Create Account")
                        .font(.caption)
                        .foregroundColor(Color(#colorLiteral(red: 0.4513868093, green: 0.9930960536, blue: 1, alpha: 1)))
                }
                .tint(.white)
                
            }
            HStack {
                Text("Forgot your password?")
                    .font(.caption)
                    .foregroundColor(.white)
                NavigationLink {
                    ResetPassordView()
                } label: {
                    Text("Reset Password")
                        .font(.caption)
                        .foregroundColor(Color(#colorLiteral(red: 0.4513868093, green: 0.9930960536, blue: 1, alpha: 1)))
                }
                
            }
        }
        .padding()
    }
    
    private var signin_button: some View {
        
        Button {
            
            Task {
                do {
                    let authenticated_user = try await AuthManager.shared.signIn(email: enteredUsername, password: enteredPassword)
                    let firestoreService = DatabaseManager()
                    user = try await firestoreService.getUserFromFirestore(uid: authenticated_user.uid)
                    print("User fetched: \(user.fullname), Email: \(user.email)")
                    if await AuthManager.shared.getEmailVerified() {
                        goToLandingScreen = true
                    } else {
                        goToVerificationScreen = true
                    }
                    
                    showWrongMessage = false
                    print("User signed in: \(authenticated_user.uid)")
                } catch {
                    print("Sign in failed: \(error.localizedDescription)")
                    showWrongMessage = true
                }
            }
        } label: {
            Text("Sign in")
                .padding()
                .padding(.horizontal)
                .background(.white)
                .cornerRadius(10)
                .foregroundColor(Color(.accent))
                .bold()
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
        }
        .navigationDestination(isPresented: $goToLandingScreen) {
            MainView(user: user)
        }
        .navigationDestination(isPresented: $goToVerificationScreen) {
            VerifyEmailView(user: user)
        }
    }
}
