//
//  LoginView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct LoginView: View {
    
    @EnvironmentObject private var vm: ViewModel
    
    @State var user: UserModel? = nil
    @State var email: String = ""
    @State var password: String = ""
    @State var showWrongMessage: Bool = false
    @State var goToNextScreen: Bool = false
    @State var isPasswordVisible = false
    @State var isVerified = false
    @State var wrongMessage: String = " "
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack {
                BackNavigation(foregroundColor: Color(.accent))
                Spacer()
                LoginSheet
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    LoginView()
        .environmentObject(ViewModel())
}

extension LoginView {
    private var LoginSheet: some View {
        VStack {
            Title
            UserFields
            WrongMessage
            AccountManagement
            SignInButton
            
        }
        .frame(width: 300, height: 450)
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
            EmailField
            PasswordField
        }
    }
    
    private var EmailField: some View {
        TextField("", text: $email, prompt: Text("Enter your email here ...").foregroundColor(Color.black.opacity(0.5)))
            .foregroundColor(.black)
            .padding()
            .background(.white)
            .cornerRadius(10)
            .padding()
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
    }
    
    private var PasswordField: some View {
        HStack {
            if isPasswordVisible {
                TextField("", text: $password, prompt: Text("Enter your password here ...").foregroundColor(Color.black.opacity(0.5)))
                    .foregroundColor(.black)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .background(.white)
                    .cornerRadius(10)
                    .padding()
            } else {
                SecureField("", text: $password, prompt: Text("Enter your password here ...").foregroundColor(Color.black.opacity(0.5)))
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
    
    private var WrongMessage: some View {
        Text(wrongMessage)
            .font(.caption)
            .foregroundColor(.white)
            .padding(2)
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
    
    private var SignInButton: some View {
        
        Button {
            wrongMessage = " "
            Task {
                user = await vm.signInUser(email: email, password: password)
                isVerified = await AuthManager.shared.getEmailVerified()
                if user != nil {
                    goToNextScreen = true
                } else {
                    wrongMessage = "Email or password is incorrect"
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
        .navigationDestination(isPresented: $goToNextScreen) {
            if let user {
                isVerified ? AnyView(MainView(user: user)) : AnyView(VerifyEmailView(user: user))
            }
        }
    }
}
