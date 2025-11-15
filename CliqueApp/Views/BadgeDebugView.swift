//
//  BadgeDebugView.swift
//  CliqueApp
//
//  Debug view to help troubleshoot badge counting issues
//

import SwiftUI

struct BadgeDebugView: View {
    @EnvironmentObject private var vm: ViewModel
    @State private var debugInfo: String = "Tap 'Refresh Debug Info' to see badge details"
    @State private var isLoading: Bool = false
    @State private var selectedUserId: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // User selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select User to Debug:")
                        .font(.headline)
                    
                    if let signedInUser = vm.signedInUser {
                        Button(action: {
                            selectedUserId = signedInUser.uid
                        }) {
                            HStack {
                                Image(systemName: selectedUserId == signedInUser.uid ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(.green)
                                Text("Current User ID: \(signedInUser.uid)")
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Or enter user ID manually
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.gray)
                        TextField("Or enter user ID manually", text: $selectedUserId)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Refresh button
                Button(action: {
                    refreshDebugInfo()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Refresh Debug Info")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }
                .disabled(isLoading || selectedUserId.isEmpty)
                
                // Debug output
                ScrollView {
                    Text(debugInfo)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Badge Debug")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func refreshDebugInfo() {
        guard !selectedUserId.isEmpty else { return }
        
        isLoading = true
        Task {
            let info = await BadgeManager.shared.debugBadgeCount(for: selectedUserId)
            await MainActor.run {
                debugInfo = info
                isLoading = false
            }
        }
    }
}

#Preview {
    BadgeDebugView()
        .environmentObject(ViewModel())
}
