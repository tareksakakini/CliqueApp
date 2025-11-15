//
//  AccountInfoView.swift
//  CliqueApp
//
//  Created for sign-up flow - personal information entry
//

import SwiftUI

struct AccountInfoView: View {
    
    @EnvironmentObject private var vm: ViewModel
    @Environment(\.dismiss) private var dismiss
    
    let phoneNumber: String
    
    @State private var fullname: String = ""
    @State private var username: String = ""
    @State private var gender: String = "Male"
    @State private var isAgeChecked: Bool = false
    @State private var isAgreePolicy: Bool = false
    @State private var isCheckingUsername = false
    @State private var isUsernameTaken: Bool? = nil
    @FocusState private var usernameFieldIsFocused: Bool
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isCreatingAccount = false
    @State private var user: UserModel? = nil
    @State private var goToMainView: Bool = false
    
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
            .navigationDestination(isPresented: $goToMainView) {
                if let user {
                    MainView(user: user)
                }
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
            Image(systemName: "person.fill.badge.plus")
                .font(.system(size: 60, weight: .medium))
                .foregroundColor(.accent)
                .padding(.bottom, 10)
            
            Text("Complete Your Profile")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Tell us a bit about yourself")
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
            
            checkboxSection
            
            createAccountButton
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
                title: "Full Name",
                text: $fullname,
                placeholder: "Enter your full name",
                icon: "textformat"
            )
            
            ModernUsernameField(
                title: "Username",
                text: $username,
                placeholder: "Choose a unique username",
                isChecking: $isCheckingUsername,
                isAvailable: Binding(
                    get: {
                        guard let taken = isUsernameTaken else { return nil }
                        return !taken
                    },
                    set: { newValue in
                        guard let available = newValue else {
                            isUsernameTaken = nil
                            return
                        }
                        isUsernameTaken = !available
                    }
                ),
                isFocused: $usernameFieldIsFocused,
                onUsernameChange: { newValue in
                    isUsernameTaken = nil
                    if newValue.isEmpty { return }
                    isCheckingUsername = true
                    let currentUsername = newValue
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if username == currentUsername {
                            Task {
                                let taken = await vm.isUsernameTaken(currentUsername)
                                DispatchQueue.main.async {
                                    isUsernameTaken = taken
                                    isCheckingUsername = false
                                }
                            }
                        }
                    }
                }
            )
            
            ModernGenderPicker(selection: $gender)
        }
    }
    
    private var checkboxSection: some View {
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
    }
    
    private var createAccountButton: some View {
        Button {
            createAccount()
        } label: {
            HStack {
                if isCreatingAccount {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(isCreatingAccount ? "Creating Account..." : "Create Account")
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
        .disabled(!isAgeChecked || !isAgreePolicy || isUsernameTaken == true || isCheckingUsername || isCreatingAccount)
        .opacity((!isAgeChecked || !isAgreePolicy || isUsernameTaken == true || isCheckingUsername || isCreatingAccount) ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isAgeChecked)
        .animation(.easeInOut(duration: 0.2), value: isAgreePolicy)
        .animation(.easeInOut(duration: 0.2), value: isUsernameTaken)
        .animation(.easeInOut(duration: 0.2), value: isCheckingUsername)
        .animation(.easeInOut(duration: 0.2), value: isCreatingAccount)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Sign Up Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - Helper Methods
    
    private func createAccount() {
        // Full name validation
        if fullname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            alertMessage = "Full name cannot be empty."
            showAlert = true
            return
        }
        // Username validation
        if username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            alertMessage = "Username cannot be empty."
            showAlert = true
            return
        }
        // Username availability check
        if isUsernameTaken == true {
            alertMessage = "Username is already taken. Please choose a different username."
            showAlert = true
            return
        }
        // Age and policy agreement validation
        if !isAgeChecked {
            alertMessage = "You must confirm that you are 16 years or older."
            showAlert = true
            return
        }
        if !isAgreePolicy {
            alertMessage = "You must agree to the Privacy Policy."
            showAlert = true
            return
        }
        
        // All validations passed, create account
        isCreatingAccount = true
        
        Task {
            do {
                user = try await vm.completeUserProfile(
                    phoneNumber: phoneNumber,
                    fullname: fullname,
                    username: username,
                    profilePic: "userDefault",
                    gender: gender
                )
                
                if let user = user {
                    // Critical validation before navigation
                    guard !user.email.isEmpty else {
                        print("❌ User object has empty email after creation")
                        alertMessage = "Account creation failed - incomplete user data. Please try again."
                        showAlert = true
                        isCreatingAccount = false
                        return
                    }
                    
                    vm.signedInUser = user
                    goToMainView = true
                } else {
                    alertMessage = "Failed to complete profile. Please try again."
                    showAlert = true
                    isCreatingAccount = false
                }
            } catch {
                alertMessage = ErrorHandler.shared.handleError(error, operation: "Complete profile")
                showAlert = true
                isCreatingAccount = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        AccountInfoView(phoneNumber: "+16505551234")
            .environmentObject(ViewModel())
    }
}

