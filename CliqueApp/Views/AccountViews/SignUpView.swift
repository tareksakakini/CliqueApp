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
    
    @State private var phoneNumber: String = ""
    @State private var selectedCountry: Country = Country.default
    @State private var verificationID: String? = nil
    @State private var isSendingCode: Bool = false
    @State private var errorMessage: String = " "
    @State private var goToVerificationScreen: Bool = false
    
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
            .navigationDestination(isPresented: $goToVerificationScreen) {
                if let verificationID = verificationID {
                    let fullPhoneNumber = PhoneNumberFormatter.e164(
                        countryCode: selectedCountry.dialCode,
                        phoneNumber: phoneNumber
                    )
                    VerificationCodeView(
                        phoneNumber: fullPhoneNumber,
                        verificationID: verificationID,
                        isSignUp: true
                    )
                }
            }
            .onAppear {
                phoneNumber = ""
                errorMessage = " "
                verificationID = nil
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
            Text("Create Account")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Enter your phone number to get started")
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
            phoneNumberField
            
            if !errorMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessageView
            }
            
            accountManagement
            
            continueButton
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
    
    private var phoneNumberField: some View {
        PhoneNumberFieldWithCountryCode(
            title: "Phone Number",
            phoneNumber: $phoneNumber,
            selectedCountry: $selectedCountry,
            placeholder: "Enter your mobile number"
        )
    }
    
    private var errorMessageView: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.red)
            
            Text(errorMessage)
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
        HStack {
            Text("Already have an account?")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Button {
                dismiss()
            } label: {
                Text("Sign In")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
    
    private var continueButton: some View {
        Button {
            sendCodeAndNavigate()
        } label: {
            HStack {
                if isSendingCode {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(isSendingCode ? "Sending Code..." : "Continue")
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
        .disabled(isSendingCode || phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity((isSendingCode || phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSendingCode)
        .animation(.easeInOut(duration: 0.2), value: phoneNumber.isEmpty)
    }
    
    private func sendCodeAndNavigate() {
        let trimmedPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).filter { $0.isNumber }
        guard !trimmedPhone.isEmpty else {
            errorMessage = "Please enter a valid phone number."
            return
        }
        
        let fullPhoneNumber = PhoneNumberFormatter.e164(
            countryCode: selectedCountry.dialCode,
            phoneNumber: trimmedPhone
        )
        
        isSendingCode = true
        errorMessage = " "
        
        Task {
            do {
                let verification = try await vm.requestPhoneVerificationCode(phoneNumber: fullPhoneNumber)
                verificationID = verification
                isSendingCode = false
                goToVerificationScreen = true
            } catch {
                errorMessage = ErrorHandler.shared.handleError(error, operation: "Send code")
                isSendingCode = false
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
    var autocapitalization: TextInputAutocapitalization = .never
    
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
                    .textInputAutocapitalization(autocapitalization)
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
            
            Picker("Gender", selection: $selection) {
                Text("Male").foregroundColor(.secondary).tag("Male")
                Text("Female").foregroundColor(.secondary).tag("Female")
                Text("Other").foregroundColor(.secondary).tag("Other")
            }
            .pickerStyle(SegmentedPickerStyle())
            .font(.system(size: 16, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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

struct ModernUsernameField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    @Binding var isChecking: Bool
    @Binding var isAvailable: Bool?
    @FocusState.Binding var isFocused: Bool
    let onUsernameChange: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            usernameInputField
            
            // Status message
            if isFocused {
                if isAvailable == true {
                    Text("Username is available")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                } else if isAvailable == false && !text.isEmpty {
                    Text("Username is already taken")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private var usernameInputField: some View {
        HStack {
            Image(systemName: "at")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16, weight: .medium))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .focused($isFocused)
                .onChange(of: text) { _, newValue in
                    onUsernameChange(newValue)
                }
            
            // Status indicator
            if isFocused {
                statusIndicator
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
                )
        )
    }
    
    @ViewBuilder
    private var statusIndicator: some View {
        if isChecking {
            ProgressView()
                .scaleEffect(0.7)
                .frame(width: 20, height: 20)
        } else if isAvailable == false {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
                .font(.system(size: 20, weight: .medium))
        } else if isAvailable == true && !text.isEmpty {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 20, weight: .medium))
        }
    }
    
    private var borderColor: Color {
        if isFocused {
            if isAvailable == false {
                return Color.red
            } else if isAvailable == true && !text.isEmpty {
                return Color.green
            } else {
                return Color(.systemGray4)
            }
        } else {
            return Color(.systemGray4)
        }
    }
}
