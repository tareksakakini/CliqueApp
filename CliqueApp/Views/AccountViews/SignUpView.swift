//
//  LoginView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct SignUpView: View {
    
    @EnvironmentObject private var ud: ViewModel
    @Environment(\.dismiss) var dismiss
    
    @State var user = UserModel(fullname: "", email: "", createdAt: Date())
    @State var fullname: String = ""
    @State var gender: String = "Male"
    @State var username: String = ""
    @State var password: String = ""
    @State var isAgeChecked: Bool = false
    @State var isAgreePolicy: Bool = false
    @State var show_wrong_message: Bool = false
    @State var goToMainView: Bool = false
    @State var isPasswordVisible: Bool = false
    
    let genderOptions = ["Male", "Female", "Other"]
    
    var body: some View {
        ZStack {
            Color(.accent).ignoresSafeArea()
            
            
            VStack {
                BackNavigation()
                
                ScrollView {
                    VStack() {
                        
                        header
                        
                        user_fields
                        
                        VStack(alignment: .leading) {
                            HStack() {
                                Image(systemName: isAgeChecked ? "checkmark.square.fill" : "square.fill")
                                    .foregroundColor(isAgeChecked ? .blue.opacity(0.5) : .white)
                                    .background(Color.white) // White background for checkbox
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .onTapGesture {
                                        isAgeChecked.toggle()
                                    }
                                
                                Text("I am 16 years or older.")
                                    .foregroundColor(.white)
                            }
                            
                            HStack() {
                                Image(systemName: isAgreePolicy ? "checkmark.square.fill" : "square.fill")
                                    .foregroundColor(isAgreePolicy ? .blue.opacity(0.5) : .white)
                                    .background(Color.white) // White background for checkbox
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .onTapGesture {
                                        isAgreePolicy.toggle()
                                    }
                                
                                Text("I have read and agree to the").foregroundColor(.white)
                                
                                NavigationLink(destination: PrivacyPolicyView()) {
                                    Text("Privacy Policy")
                                        .foregroundColor(Color(#colorLiteral(red: 0, green: 0.9914394021, blue: 1, alpha: 1)))
                                        .underline()
                                        .bold()
                                }
                                
                            }
                        }
                        .padding()
                        
                        Spacer()
                        Spacer()
                        Spacer()
                        
                        signup_button
                    }
                }
            }
            
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(ViewModel())
    }
    
}

extension SignUpView {
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
            
            Text("Sign Up")
                .foregroundColor(.white)
                .font(.largeTitle)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    
    private var user_fields: some View {
        
        VStack(alignment: .leading) {
            Text("Full Name")
            //.padding(.top, 30)
                .padding(.leading, 25)
                .font(.title2)
                .foregroundColor(.white)
            
            TextField("", text: $fullname, prompt: Text("Enter your name here ...").foregroundColor(Color.black.opacity(0.5)))
                .foregroundColor(.black)
                .padding()
                .background(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            
            Text("Gender")
                .padding(.top, 15)
                .padding(.leading, 25)
                .font(.title2)
                .foregroundColor(.white)
            
            Picker(
                selection : $gender,
                label: Text("Gender"),
                content: {
                    Text("Male").tag("Male")
                    Text("Female").tag("Female")
                    Text("Other").tag("Other")
                }
            )
            .foregroundColor(.black)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            
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
            
            Text("Password")
                .padding(.top, 15)
                .padding(.leading, 25)
                .font(.title2)
                .foregroundColor(.white)
            
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
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
            .padding(.horizontal)
        }
        
    }
    
    private var signup_button: some View {
        
        Button {
            Task {
                do {
                    let signup_user = try await AuthManager.shared.signUp(email: username, password: password)
                    let firestoreService = DatabaseManager()
                    try await firestoreService.addUserToFirestore(uid: signup_user.uid, email: username, fullname: fullname, profilePic: "userDefault", gender: gender)
                    user = try await firestoreService.getUserFromFirestore(uid: signup_user.uid)
                    print("User signed up: \(user.uid)")
                    goToMainView = true
                } catch {
                    print("Sign up failed: \(error.localizedDescription)")
                }
            }
        } label: {
            Text("Create Account")
                .padding()
                .padding(.horizontal)
                .background(.white)
                .cornerRadius(10)
                .foregroundColor(Color(.accent))
                .bold()
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
        }
        .disabled(!isAgeChecked || !isAgreePolicy)
        .navigationDestination(isPresented: $goToMainView) {
            VerifyEmailView(user: user)
        }
    }
}
