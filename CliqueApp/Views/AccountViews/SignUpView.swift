//
//  LoginView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct SignUpView: View {
    
    @EnvironmentObject private var vm: ViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State var user: UserModel? = nil
    @State var fullname: String = ""
    @State var gender: String = "Male"
    @State var email: String = ""
    @State var password: String = ""
    @State var isAgeChecked: Bool = false
    @State var isAgreePolicy: Bool = false
    @State var goToVerifyView: Bool = false
    @State var isPasswordVisible: Bool = false
    
    let genderOptions = ["Male", "Female", "Other"]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Modern neutral gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemGray5),
                        Color(.systemGray4).opacity(0.3),
                        Color(.systemGray5).opacity(0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header section
                        VStack(spacing: 12) {
                            Text("Create Account")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("Join the community and plan amazing outings")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                        
                        // Main form card
                        VStack(spacing: 24) {
                            // Form fields
                            VStack(spacing: 20) {
                                ModernTextField(
                                    title: "Full Name",
                                    text: $fullname,
                                    placeholder: "Enter your full name",
                                    icon: "textformat"
                                )
                                
                                ModernGenderPicker(selection: $gender)
                                
                                ModernTextField(
                                    title: "Email",
                                    text: $email,
                                    placeholder: "Enter your email address",
                                    icon: "envelope.fill",
                                    keyboardType: .emailAddress
                                )
                                
                                ModernPasswordField(
                                    title: "Password",
                                    text: $password,
                                    placeholder: "Create a secure password",
                                    isVisible: $isPasswordVisible
                                )
                            }
                            
                            // Checkboxes
                            VStack(spacing: 16) {
                                ModernCheckbox(
                                    isChecked: $isAgeChecked,
                                    text: "I am 16 years or older"
                                )
                                
                                HStack(spacing: 12) {
                                    ModernCheckbox(
                                        isChecked: $isAgreePolicy,
                                        text: ""
                                    )
                                    
                                    HStack(spacing: 4) {
                                        Text("I agree to the")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary)
                                        
                                        NavigationLink(destination: PrivacyPolicyView()) {
                                            Text("Privacy Policy")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 4)
                            
                            // Create account button
                            Button {
                                Task {
                                    user = await vm.signUpUserAndAddToFireStore(
                                        email: email,
                                        password: password,
                                        fullname: fullname,
                                        profilePic: "userDefault",
                                        gender: gender
                                    )
                                    if let user = user {
                                        print("User signed up: \(user.uid)")
                                        goToVerifyView = true
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Create Account")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(.accent), Color(.accent).opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                            }
                            .disabled(!isAgeChecked || !isAgreePolicy)
                            .opacity((!isAgeChecked || !isAgreePolicy) ? 0.6 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isAgeChecked)
                            .animation(.easeInOut(duration: 0.2), value: isAgreePolicy)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color(.accent).opacity(0.1), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
                                .shadow(color: Color(.accent).opacity(0.1), radius: 24, x: 0, y: 12)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .navigationDestination(isPresented: $goToVerifyView) {
            if let user = user {
                VerifyEmailView(user: user)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(ViewModel())
    }
}

// MARK: - Modern UI Components

struct ModernTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .font(.system(size: 16, weight: .medium))
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .keyboardType(keyboardType)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            )
        }
    }
}

struct ModernPasswordField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Group {
                    if isVisible {
                        TextField(placeholder, text: $text)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                }
                .font(.system(size: 16, weight: .medium))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                
                Button {
                    isVisible.toggle()
                } label: {
                    Image(systemName: isVisible ? "eye.fill" : "eye.slash.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            )
        }
    }
}

struct ModernGenderPicker: View {
    @Binding var selection: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gender")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: "person.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Picker("Gender", selection: $selection) {
                    Text("Male").tag("Male")
                    Text("Female").tag("Female")
                    Text("Other").tag("Other")
                }
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(height: 55)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            )
        }
    }
}

struct ModernCheckbox: View {
    @Binding var isChecked: Bool
    let text: String
    
    var body: some View {
        Button {
            isChecked.toggle()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isChecked ? .blue : .secondary)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isChecked)
                
                if !text.isEmpty {
                    Text(text)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
