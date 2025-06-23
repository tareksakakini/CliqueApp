//
//  PhoneNumberLinkView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct PhoneNumberLinkView: View {
    @EnvironmentObject private var vm: ViewModel
    @Environment(\.dismiss) private var dismiss
    @State var user: UserModel
    @State private var phoneNumber: String = ""
    @State private var isLinking: Bool = false
    @State private var showResult: Bool = false
    @State private var linkingResult: (success: Bool, linkedEventsCount: Int, errorMessage: String?) = (false, 0, nil)
    @State private var navigateToMainView: Bool = false
    @State private var showSkipConfirmation: Bool = false
    
    var body: some View {
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
            
            VStack(spacing: 24) {
                // Header Section
                VStack(spacing: 16) {
                    Image(systemName: "phone.connection")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(Color(.accent))
                        .padding(.top, 40)
                    
                    Text("Link Your Phone Number")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Connect your phone number to see invitations that were sent to you before you joined the app")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Main Content Card
                VStack(spacing: 24) {
                    if !showResult {
                        phoneInputSection
                    } else {
                        resultSection
                    }
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
                
                Spacer()
                
                // Skip option
                if !showResult && !isLinking {
                    Button("Skip for now") {
                        showSkipConfirmation = true
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToMainView) {
            MainView(user: user)
        }
        .confirmationDialog(
            "Skip Phone Number Linking",
            isPresented: $showSkipConfirmation,
            titleVisibility: .visible
        ) {
            Button("Continue to App") {
                navigateToMainView = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You can always add your phone number later in settings to link existing invitations.")
        }
        .alert("Linking Result", isPresented: $showResult) {
            Button("Continue to App") {
                navigateToMainView = true
            }
        } message: {
            if linkingResult.success {
                if linkingResult.linkedEventsCount > 0 {
                    Text("Great! We found \(linkingResult.linkedEventsCount) event invitation(s) for your phone number. You'll now see them in your events.")
                } else {
                    Text("Phone number saved! We didn't find any existing invitations, but you're all set for future ones.")
                }
            } else {
                Text(linkingResult.errorMessage ?? "An error occurred while linking your phone number.")
            }
        }
    }
    
    private var phoneInputSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Phone Number")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    TextField("Enter your phone number", text: $phoneNumber)
                        .font(.system(size: 16, weight: .medium))
                        .keyboardType(.phonePad)
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
            
            Text("Enter the phone number you use for text messages. We'll check if any event invitations were sent to this number.")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                linkPhoneNumber()
            } label: {
                HStack {
                    if isLinking {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "link")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    
                    Text(isLinking ? "Linking..." : "Link Phone Number")
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
            .disabled(isLinking || phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity((isLinking || phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.6 : 1.0)
        }
    }
    
    private var resultSection: some View {
        VStack(spacing: 20) {
            Image(systemName: linkingResult.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(linkingResult.success ? .green : .orange)
            
            VStack(spacing: 8) {
                Text(linkingResult.success ? "Success!" : "Notice")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(resultMessage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                navigateToMainView = true
            } label: {
                Text("Continue to App")
                    .font(.system(size: 18, weight: .semibold))
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
        }
    }
    
    private var resultMessage: String {
        if linkingResult.success {
            if linkingResult.linkedEventsCount > 0 {
                return "We found \(linkingResult.linkedEventsCount) event invitation(s) for your phone number. You'll see them in your events now!"
            } else {
                return "Phone number saved! We didn't find any existing invitations, but you're all set for future ones."
            }
        } else {
            return linkingResult.errorMessage ?? "An error occurred while linking your phone number."
        }
    }
    
    private func linkPhoneNumber() {
        guard !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isLinking = true
        Task {
            let result = await vm.linkPhoneNumberToUser(phoneNumber: phoneNumber)
            DispatchQueue.main.async {
                self.linkingResult = result
                self.isLinking = false
                self.showResult = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        PhoneNumberLinkView(user: UserData.userData[0])
            .environmentObject(ViewModel())
    }
} 