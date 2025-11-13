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
    @State var username: String = ""
    @State var gender: String = "Male"
    @State var phoneNumber: String = ""
    @State var verificationCode: String = ""
    @State private var verificationID: String? = nil
    @State private var isSendingCode: Bool = false
    @State private var isCodeSent: Bool = false
    @State private var codeStatusMessage: String = ""
    @State private var codeStatusIsError: Bool = false
    @State var password: String = ""
    @State var isAgeChecked: Bool = false
    @State var isAgreePolicy: Bool = false
    @State var goToMainView: Bool = false
    @State var isPasswordVisible: Bool = false
    @State private var isCheckingUsername = false
    @State private var isUsernameTaken: Bool? = nil
    @FocusState private var usernameFieldIsFocused: Bool
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isCreatingAccount = false
    
    let genderOptions = ["Male", "Female", "Other"]
    
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
                if let user = user {
                    MainView(user: user)
                }
            }
            .onChange(of: phoneNumber) { _, _ in
                verificationID = nil
                verificationCode = ""
                isCodeSent = false
                codeStatusMessage = ""
                codeStatusIsError = false
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
            
            Text("Join the community and plan amazing outings")
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
                        return !taken  // Invert: if taken=false, then available=true
                    },
                    set: { newValue in
                        guard let available = newValue else { 
                            isUsernameTaken = nil
                            return 
                        }
                        isUsernameTaken = !available  // Invert: if available=true, then taken=false
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
            
            ModernTextField(
                title: "Phone Number",
                text: $phoneNumber,
                placeholder: "Enter your mobile number",
                icon: "phone.fill",
                keyboardType: .phonePad
            )
            
            sendCodeButton
            
            if isCodeSent {
                ModernTextField(
                    title: "Verification Code",
                    text: $verificationCode,
                    placeholder: "Enter the 6-digit code",
                    icon: "number.square.fill",
                    keyboardType: .numberPad
                )
            }
            
            if !codeStatusMessage.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: codeStatusIsError ? "xmark.octagon.fill" : "checkmark.circle.fill")
                        .foregroundColor(codeStatusIsError ? .red : .green)
                    Text(codeStatusMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(codeStatusIsError ? .red : .green)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(codeStatusIsError ? Color.red.opacity(0.08) : Color.green.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(codeStatusIsError ? Color.red.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            ModernPasswordField(
                title: "Password",
                text: $password,
                placeholder: "Create a secure password",
                isVisible: $isPasswordVisible
            )
        }
    }
    
    private var sendCodeButton: some View {
        Button {
            requestVerificationCode()
        } label: {
            HStack {
                if isSendingCode {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: isCodeSent ? "paperplane.fill" : "paperplane")
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(isSendingCode ? "Sending..." : (isCodeSent ? "Resend Code" : "Send Code"))
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.accent))
            )
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        }
        .disabled(isSendingCode || phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity((isSendingCode || phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSendingCode)
        .animation(.easeInOut(duration: 0.2), value: phoneNumber)
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
            isCreatingAccount = true
            Task {
                // Full name validation
                if fullname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    alertMessage = "Full name cannot be empty."
                    showAlert = true
                    isCreatingAccount = false
                    return
                }
                // Username validation
                if username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    alertMessage = "Username cannot be empty."
                    showAlert = true
                    isCreatingAccount = false
                    return
                }
                // Phone validation
                let trimmedPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
                if !isValidPhoneNumber(trimmedPhone) {
                    alertMessage = "Please enter a valid phone number."
                    showAlert = true
                    isCreatingAccount = false
                    return
                }
                // Password length validation
                if password.count < 6 {
                    alertMessage = "Password must be at least 6 characters."
                    showAlert = true
                    isCreatingAccount = false
                    return
                }
                // Username availability check
                if isUsernameTaken == true {
                    alertMessage = "Username is already taken. Please choose a different username."
                    showAlert = true
                    isCreatingAccount = false
                    return
                }
                // Age and policy agreement validation
                if !isAgeChecked {
                    alertMessage = "You must confirm that you are 16 years or older."
                    showAlert = true
                    isCreatingAccount = false
                    return
                }
                if !isAgreePolicy {
                    alertMessage = "You must agree to the Privacy Policy."
                    showAlert = true
                    isCreatingAccount = false
                    return
                }
                guard let verificationID = verificationID, !verificationCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    alertMessage = "Enter the verification code we texted you."
                    showAlert = true
                    isCreatingAccount = false
                    return
                }
                
                do {
                    user = try await vm.signUpUserAndAddToFireStore(
                        phoneNumber: trimmedPhone,
                        password: password,
                        verificationID: verificationID,
                        smsCode: verificationCode,
                        fullname: fullname,
                        username: username,
                        profilePic: "userDefault",
                        gender: gender
                    )
                    if let user = user {
                        vm.signedInUser = user
                        goToMainView = true
                    } else {
                        alertMessage = "Sign up failed. Please try again."
                        showAlert = true
                        isCreatingAccount = false
                    }
                } catch {
                    alertMessage = ErrorHandler.shared.handleError(error, operation: "Sign up")
                    showAlert = true
                    isCreatingAccount = false
                }
            }
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
    
    // Helper for phone validation
    private func requestVerificationCode() {
        let trimmedPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidPhoneNumber(trimmedPhone) else {
            alertMessage = "Please enter a valid phone number before requesting a code."
            showAlert = true
            return
        }
        
        isSendingCode = true
        codeStatusMessage = ""
        codeStatusIsError = false
        
        Task {
            do {
                let verification = try await vm.requestPhoneVerificationCode(phoneNumber: trimmedPhone)
                verificationID = verification
                isCodeSent = true
                codeStatusMessage = "Verification code sent! Enter it below."
                codeStatusIsError = false
            } catch {
                codeStatusMessage = ErrorHandler.shared.handleError(error, operation: "Send code")
                codeStatusIsError = true
            }
            isSendingCode = false
        }
    }
    
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        PhoneNumberFormatter.canonical(phone).count >= 10
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
