//
//  ResetPassordView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct ResetPassordView: View {
    
    @EnvironmentObject private var ud: ViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var phoneNumber: String = ""
    @State private var verificationCode: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var verificationID: String? = nil
    @State private var confirmationMessage: String = " "
    @State private var isLoading: Bool = false
    @State private var isSendingCode: Bool = false
    @State private var codeStatusMessage: String = ""
    @State private var codeStatusIsError: Bool = false
    @State private var isCodeSent: Bool = false
    @State private var isNewPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false
    @State private var resetWasSuccessful: Bool = false
    
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
            Text("Reset Password")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Enter your phone number and we'll text you a verification code to reset your password")
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
            phoneField
            
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
                title: "New Password",
                text: $newPassword,
                placeholder: "Enter your new password",
                isVisible: $isNewPasswordVisible
            )
            
            ModernPasswordField(
                title: "Confirm New Password",
                text: $confirmPassword,
                placeholder: "Confirm your new password",
                isVisible: $isConfirmPasswordVisible
            )
            
            if !confirmationMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                confirmationMessageView
            }
            
            resetButton
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
    
    private var phoneField: some View {
        ModernTextField(
            title: "Phone Number",
            text: $phoneNumber,
            placeholder: "Enter your mobile number",
            icon: "phone.fill",
            keyboardType: .phonePad
        )
    }
    
    private var sendCodeButton: some View {
        Button {
            requestResetCode()
        } label: {
            HStack {
                if isSendingCode {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "message.fill")
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
    }
    
    private var confirmationMessageView: some View {
        HStack {
            Image(systemName: resetWasSuccessful ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(resetWasSuccessful ? .green : .orange)
            
            Text(confirmationMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(resetWasSuccessful ? .green : .orange)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill((resetWasSuccessful ? Color.green : Color.orange).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke((resetWasSuccessful ? Color.green : Color.orange).opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func requestResetCode() {
        let trimmedPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard PhoneNumberFormatter.canonical(trimmedPhone).count >= 10 else {
            codeStatusMessage = "Please enter a valid phone number."
            codeStatusIsError = true
            return
        }
        
        isSendingCode = true
        codeStatusMessage = ""
        codeStatusIsError = false
        
        Task {
            do {
                let verification = try await ud.requestPhoneVerificationCode(phoneNumber: trimmedPhone)
                verificationID = verification
                isCodeSent = true
                codeStatusMessage = "Verification code sent! Enter it above."
                codeStatusIsError = false
            } catch {
                codeStatusMessage = ErrorHandler.shared.handleError(error, operation: "Send code")
                codeStatusIsError = true
            }
            isSendingCode = false
        }
    }
    
    private var resetButton: some View {
        Button {
            isLoading = true
            confirmationMessage = " "
            Task {
                guard let verificationID = verificationID, !verificationCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    confirmationMessage = "Enter the verification code we texted you."
                    isLoading = false
                    return
                }
                
                guard newPassword.count >= 6 else {
                    confirmationMessage = "New password must be at least 6 characters."
                    isLoading = false
                    return
                }
                
                guard newPassword == confirmPassword else {
                    confirmationMessage = "Passwords do not match."
                    isLoading = false
                    return
                }
                
                let result = await ud.resetPasswordWithPhone(newPassword: newPassword, verificationID: verificationID, smsCode: verificationCode)
                resetWasSuccessful = result.success
                confirmationMessage = result.success ? "Password updated! You can sign in with your new password." : (result.errorMessage ?? "Failed to reset password.")
                isLoading = false
            }
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "envelope.arrow.triangle.branch")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(isLoading ? "Resetting..." : "Reset Password")
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
        .disabled(isLoading || phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity((isLoading || phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .animation(.easeInOut(duration: 0.2), value: phoneNumber.isEmpty)
    }
}

#Preview {
    NavigationStack {
        ResetPassordView()
            .environmentObject(ViewModel())
    }
}
