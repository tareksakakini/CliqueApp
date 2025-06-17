//
//  VerifyEmailView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 3/26/25.
//

import SwiftUI

struct VerifyEmailView: View {
    @EnvironmentObject private var vm: ViewModel
    @Environment(\.dismiss) private var dismiss
    @State var user: UserModel
    @State private var isCheckingVerification = false
    @State private var isResendingEmail = false
    @State private var showSuccessMessage = false
    @State private var showNotVerifiedMessage = false
    @State private var emailResent = false
    @State private var navigateToMainView = false
    @State private var showResendError = false
    @State private var resendErrorMessage = ""
    @State private var showStartingView = false
    
    var body: some View {
        ZStack {
            // Modern neutral gradient background matching SignUpView
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
            
            VStack(spacing: 30) {
                Spacer()
                
                // Email icon with modern styling
                Image(systemName: "envelope.circle.fill")
                    .font(.system(size: 80, weight: .medium))
                    .foregroundColor(.accent)
                    .padding(.bottom, 10)
                
                // Title with modern typography
                Text("Verify Your Email")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                // Subtitle section with modern card design
                VStack(spacing: 12) {
                    Text("We sent a verification link to:")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(user.email)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.accent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.accent).opacity(0.2), lineWidth: 1)
                                )
                        )
                }
                
                // Instructions with modern styling
                Text("Please check your inbox and click the verification link to continue using the app.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                // Status messages with modern card design
                statusMessagesSection
                
                // Action buttons with modern styling
                actionButtonsSection
                
                Spacer()
                
                // Sign out option with subtle styling
                Button("Sign Out") {
                    Task {
                        await vm.signoutButtonPressed()
                        showStartingView = true
                    }
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToMainView) {
            MainView(user: user)
        }
        .navigationDestination(isPresented: $showStartingView) {
            StartingView()
        }
        .onAppear {
            // Set the signed in user and check verification status
            vm.signedInUser = user
            Task {
                await vm.checkEmailVerificationStatus()
            }
        }
        .onChange(of: vm.signedInUser?.isEmailVerified) { _, isVerified in
            if isVerified == true {
                // Navigate to main view when verified
                navigateToMainView = true
            }
        }
    }
    
    @ViewBuilder
    private var statusMessagesSection: some View {
        VStack(spacing: 12) {
            // Success message when verification is found
            if showSuccessMessage {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 20, weight: .medium))
                    Text("Email verified successfully!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.green.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            // Not verified message
            if showNotVerifiedMessage {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 20, weight: .medium))
                        Text("Email not verified yet")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Please check your inbox (including spam/junk folder)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("and click the verification link, then try again.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .multilineTextAlignment(.center)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            // Email resent confirmation
            if emailResent {
                HStack(spacing: 12) {
                    Image(systemName: "paperplane.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 20, weight: .medium))
                    Text("Verification email sent!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            // Resend error message
            if showResendError {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 20, weight: .medium))
                        Text("Failed to send email")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                    }
                    
                    Text(resendErrorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showSuccessMessage)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showNotVerifiedMessage)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: emailResent)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showResendError)
    }
    
    @ViewBuilder
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Primary verification check button
            Button(action: {
                Task {
                    isCheckingVerification = true
                    // Hide any previous messages
                    showNotVerifiedMessage = false
                    showSuccessMessage = false
                    
                    await vm.checkEmailVerificationStatus()
                    
                    if vm.signedInUser?.isEmailVerified == true {
                        showSuccessMessage = true
                        // Brief delay to show success message before proceeding
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            navigateToMainView = true
                        }
                    } else {
                        // Show not verified message
                        showNotVerifiedMessage = true
                        
                        // Auto-hide the message after a few seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                            showNotVerifiedMessage = false
                        }
                    }
                    
                    isCheckingVerification = false
                }
            }) {
                HStack(spacing: 12) {
                    if isCheckingVerification {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    Text(isCheckingVerification ? "Checking..." : "I've Verified My Email")
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
            .disabled(isCheckingVerification)
            
            // Secondary resend email button
            Button(action: {
                Task {
                    isResendingEmail = true
                    // Hide all previous messages
                    emailResent = false
                    showNotVerifiedMessage = false
                    showResendError = false
                    
                    let result = await vm.resendVerificationEmail()
                    isResendingEmail = false
                    
                    if result.success {
                        emailResent = true
                        // Auto-hide the confirmation after a few seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            emailResent = false
                        }
                    } else {
                        // Show resend error with specific message
                        showResendError = true
                        resendErrorMessage = result.errorMessage ?? "Unable to send email right now. Please wait a bit and try again."
                        
                        // Auto-hide the error after a few seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                            showResendError = false
                        }
                    }
                }
            }) {
                HStack(spacing: 12) {
                    if isResendingEmail {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.accent)
                    } else {
                        Image(systemName: "envelope.arrow.triangle.branch")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    Text(isResendingEmail ? "Sending..." : "Resend Verification Email")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.accent)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.accent), lineWidth: 2)
                        )
                )
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            }
            .disabled(isResendingEmail)
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    NavigationStack {
        VerifyEmailView(user: UserModel())
            .environmentObject(ViewModel())
    }
}
