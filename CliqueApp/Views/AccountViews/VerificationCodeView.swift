//
//  VerificationCodeView.swift
//  CliqueApp
//
//  Created for passwordless authentication flow
//

import SwiftUI
import FirebaseAuth

struct VerificationCodeView: View {
    
    @EnvironmentObject private var vm: ViewModel
    @Environment(\.dismiss) private var dismiss
    
    let phoneNumber: String
    let verificationID: String
    let isSignUp: Bool // true for sign up, false for login
    
    @State private var verificationCode: String = ""
    @State private var isVerifying: Bool = false
    @State private var errorMessage: String = " "
    @State private var goToMainView: Bool = false
    @State private var goToAccountInfo: Bool = false
    @State private var user: UserModel? = nil
    @State private var canResend: Bool = false
    @State private var resendTimer: Timer? = nil
    @State private var timeRemaining: Int = 60
    @State private var isResending: Bool = false
    @State private var newVerificationID: String? = nil
    
    var currentVerificationID: String {
        newVerificationID ?? verificationID
    }
    
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
            .navigationDestination(isPresented: $goToAccountInfo) {
                AccountInfoView(
                    phoneNumber: phoneNumber,
                    verificationID: currentVerificationID,
                    verificationCode: verificationCode
                )
            }
            .onAppear {
                startResendTimer()
            }
            .onDisappear {
                resendTimer?.invalidate()
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
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60, weight: .medium))
                .foregroundColor(.accent)
                .padding(.bottom, 10)
            
            Text("Enter Verification Code")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("We sent a code to \(formatPhoneNumber(phoneNumber))")
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
            codeInputField
            
            if !errorMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessageView
            }
            
            resendSection
            
            verifyButton
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
    
    private var codeInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Verification Code")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: "number.square.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                TextField("Enter 6-digit code", text: $verificationCode)
                    .font(.system(size: 16, weight: .medium))
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
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
    
    private var resendSection: some View {
        VStack(spacing: 12) {
            if canResend {
                Button {
                    resendCode()
                } label: {
                    HStack(spacing: 8) {
                        if isResending {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        Text(isResending ? "Resending..." : "Resend Code")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.blue)
                }
                .disabled(isResending)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("Resend code in \(timeRemaining)s")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var verifyButton: some View {
        Button {
            verifyCode()
        } label: {
            HStack {
                if isVerifying {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: isSignUp ? "arrow.right.circle.fill" : "person.fill")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(isVerifying ? "Verifying..." : (isSignUp ? "Continue" : "Sign In"))
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
        .disabled(isVerifying || verificationCode.isEmpty)
        .opacity((isVerifying || verificationCode.isEmpty) ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isVerifying)
        .animation(.easeInOut(duration: 0.2), value: verificationCode.isEmpty)
    }
    
    // MARK: - Helper Methods
    
    private func verifyCode() {
        isVerifying = true
        errorMessage = " "
        
        Task {
            do {
                if isSignUp {
                    // Sign up flow - just verify the code and navigate to account info
                    // We'll verify by checking if we can create a credential
                    let phoneCredential = PhoneAuthProvider.provider().credential(
                        withVerificationID: currentVerificationID,
                        verificationCode: verificationCode
                    )
                    
                    // Try to verify the credential by attempting to sign in
                    _ = try await Auth.auth().signIn(with: phoneCredential)
                    
                    // Verification successful, but we need to sign out immediately
                    // The actual account creation will happen in AccountInfoView
                    try? Auth.auth().signOut()
                    
                    isVerifying = false
                    goToAccountInfo = true
                } else {
                    // Login flow - complete sign in
                    user = try await vm.signInUser(
                        phoneNumber: phoneNumber,
                        verificationID: currentVerificationID,
                        smsCode: verificationCode
                    )
                    
                    if user != nil {
                        vm.signedInUser = user
                        goToMainView = true
                    } else {
                        errorMessage = "Sign in failed. Please try again."
                        isVerifying = false
                    }
                }
            } catch {
                errorMessage = ErrorHandler.shared.handleError(error, operation: isSignUp ? "Verify code" : "Sign in")
                isVerifying = false
            }
        }
    }
    
    private func resendCode() {
        isResending = true
        
        Task {
            do {
                let verification = try await vm.requestPhoneVerificationCode(phoneNumber: phoneNumber)
                newVerificationID = verification
                
                // Reset timer
                canResend = false
                timeRemaining = 60
                startResendTimer()
                
                isResending = false
            } catch {
                errorMessage = ErrorHandler.shared.handleError(error, operation: "Resend code")
                isResending = false
            }
        }
    }
    
    private func startResendTimer() {
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                canResend = true
                resendTimer?.invalidate()
            }
        }
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        let digits = number.filter { $0.isNumber }
        if digits.count == 10 {
            let areaCode = String(digits.prefix(3))
            let middle = String(digits.dropFirst(3).prefix(3))
            let last = String(digits.suffix(4))
            return "(\(areaCode)) \(middle)-\(last)"
        }
        return number
    }
}

#Preview {
    NavigationStack {
        VerificationCodeView(
            phoneNumber: "6505551234",
            verificationID: "test-verification-id",
            isSignUp: false
        )
        .environmentObject(ViewModel())
    }
}

