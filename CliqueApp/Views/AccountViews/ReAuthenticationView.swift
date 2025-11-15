//
//  ReAuthenticationView.swift
//  CliqueApp
//
//  Created for re-authentication before sensitive operations
//

import SwiftUI
import FirebaseAuth

struct ReAuthenticationView: View {
    
    @EnvironmentObject private var vm: ViewModel
    @Environment(\.dismiss) private var dismiss
    
    let phoneNumber: String
    let onSuccess: () -> Void
    let onCancel: () -> Void
    
    @State private var verificationID: String? = nil
    @State private var verificationCode: String = ""
    @State private var isSendingCode: Bool = false
    @State private var isVerifying: Bool = false
    @State private var isCodeSent: Bool = false
    @State private var errorMessage: String = " "
    @State private var canResend: Bool = false
    @State private var resendTimer: Timer? = nil
    @State private var timeRemaining: Int = 60
    @State private var isResending: Bool = false
    @State private var newVerificationID: String? = nil
    
    var currentVerificationID: String {
        newVerificationID ?? (verificationID ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        
                        if isCodeSent {
                            codeInputSection
                        } else {
                            phoneDisplaySection
                        }
                        
                        if !errorMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            errorMessageView
                        }
                        
                        if isCodeSent {
                            resendSection
                            verifyButton
                        } else {
                            sendCodeButton
                        }
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
            .onAppear {
                // Auto-send code on appear
                sendVerificationCode()
                startResendTimer()
            }
            .onDisappear {
                resendTimer?.invalidate()
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
            Image(systemName: "shield.checkered")
                .font(.system(size: 60, weight: .medium))
                .foregroundColor(.accent)
                .padding(.bottom, 10)
            
            Text("Verify Your Identity")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(isCodeSent ? "Enter the code we sent to \(formatPhoneNumber(phoneNumber))" : "We'll send a verification code to \(formatPhoneNumber(phoneNumber))")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }
    
    private var phoneDisplaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Phone Number")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: "phone.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Text(formatPhoneNumber(phoneNumber))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
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
    
    private var codeInputSection: some View {
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
    
    private var sendCodeButton: some View {
        Button {
            sendVerificationCode()
        } label: {
            HStack {
                if isSendingCode {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(isSendingCode ? "Sending Code..." : "Send Verification Code")
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
        .disabled(isSendingCode)
        .opacity(isSendingCode ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSendingCode)
    }
    
    private var verifyButton: some View {
        Button {
            verifyAndReauthenticate()
        } label: {
            HStack {
                if isVerifying {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(isVerifying ? "Verifying..." : "Verify & Continue")
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
    
    private func sendVerificationCode() {
        isSendingCode = true
        errorMessage = " "
        
        Task {
            do {
                let verification = try await vm.requestPhoneVerificationCode(phoneNumber: phoneNumber)
                verificationID = verification
                isCodeSent = true
                isSendingCode = false
            } catch {
                errorMessage = ErrorHandler.shared.handleError(error, operation: "Send verification code")
                isSendingCode = false
            }
        }
    }
    
    private func verifyAndReauthenticate() {
        isVerifying = true
        errorMessage = " "
        
        Task {
            do {
                // Create phone credential
                let phoneCredential = PhoneAuthProvider.provider().credential(
                    withVerificationID: currentVerificationID,
                    verificationCode: verificationCode
                )
                
                // Re-authenticate the user
                guard let currentUser = Auth.auth().currentUser else {
                    errorMessage = "No user is currently signed in"
                    isVerifying = false
                    return
                }
                
                try await currentUser.reauthenticate(with: phoneCredential)
                
                // Success! Call the success callback
                isVerifying = false
                onSuccess()
            } catch {
                errorMessage = ErrorHandler.shared.handleError(error, operation: "Verify code")
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
    ReAuthenticationView(
        phoneNumber: "6505551234",
        onSuccess: {
            print("Re-authentication successful")
        },
        onCancel: {
            print("Re-authentication cancelled")
        }
    )
    .environmentObject(ViewModel())
}

