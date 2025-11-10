//
//  LoginView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct LoginView: View {
    
    @EnvironmentObject private var vm: ViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State var user: UserModel? = nil
    @State var email: String = ""
    @State var password: String = ""
    @State var showWrongMessage: Bool = false
    @State var goToNextScreen: Bool = false
    @State var isPasswordVisible = false
    @State var isVerified = false
    @State var wrongMessage: String = " "
    @State var isLoading: Bool = false
    
    var body: some View {
        mainContent
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(Color(.systemGray5), for: .navigationBar)
            .toolbarBackground(.automatic, for: .navigationBar)
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
            .navigationDestination(isPresented: $goToNextScreen) {
                if let user {
                    if isVerified {
                        MainView(user: user)
                    } else {
                        VerifyEmailView(user: user)
                    }
                }
            }
            .onAppear {
                email = ""
                password = ""
                wrongMessage = " "
                isLoading = false
            }
    }
    
    private var mainContent: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 0) {
                        headerSection
                        
                        formCard
                    }
                }
            }
        }
    }
    
    private var backgroundGradient: some View {
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
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Welcome Back")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Sign in to plan your next outing")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.top, 20)
        .padding(.bottom, 32)
    }
    
    private var formCard: some View {
        VStack(spacing: 24) {
            formFields
            
            if !wrongMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage
            }
            
            accountManagement
            
            signInButton
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
    
    private var formFields: some View {
        VStack(spacing: 20) {
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
                placeholder: "Enter your password",
                isVisible: $isPasswordVisible
            )
        }
    }
    
    private var errorMessage: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.red)
            
            Text(wrongMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.red)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var accountManagement: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Don't have an account?")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                NavigationLink {
                    SignUpView()
                } label: {
                    Text("Create Account")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            
            HStack {
                Text("Forgot your password?")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                NavigationLink {
                    ResetPassordView()
                } label: {
                    Text("Reset Password")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var signInButton: some View {
        Button {
            isLoading = true
            wrongMessage = " "
            Task {
                do {
                    user = try await vm.signInUser(email: email, password: password)
                    if user != nil {
                        vm.signedInUser = user
                        isVerified = await AuthManager.shared.getEmailVerified()
                        // Always navigate to next screen for successful login
                        goToNextScreen = true
                    } else {
                        wrongMessage = "Email or password is incorrect"
                        isLoading = false
                    }
                } catch {
                    wrongMessage = ErrorHandler.shared.handleError(error, operation: "Sign in")
                    isLoading = false
                }
            }
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(isLoading ? "Signing In..." : "Sign In")
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
        .disabled(isLoading || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
        .opacity((isLoading || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty) ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .animation(.easeInOut(duration: 0.2), value: email.isEmpty)
        .animation(.easeInOut(duration: 0.2), value: password.isEmpty)
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(ViewModel())
    }
}

