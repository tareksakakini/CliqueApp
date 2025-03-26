//
//  VerifyEmailView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 3/26/25.
//

import SwiftUI

struct VerifyEmailView: View {
    @EnvironmentObject private var ud: ViewModel
    
    @State private var isVerified: Bool = false
    @State var user: UserModel
    
    var body: some View {
        ZStack {
            if !isVerified {
                Text("A verification link has been sent to your email. Please verify to continue.")
                    .padding()
            } else {
                MainView(user: user)
            }
        }
        .task {
            await checkEmailVerification()
        }
    }
    
    @MainActor
    private func checkEmailVerification() async {
        while !isVerified {
            isVerified = await AuthManager.shared.getEmailVerified()
            print("Email Verified: \(isVerified)")
            
            if isVerified { break } // Exit loop if verified
            
            try? await Task.sleep(nanoseconds: 2_000_000_000) // Sleep for 2 seconds
        }
    }
}

#Preview {
    VerifyEmailView(user: UserData.userData[0])
        .environmentObject(ViewModel())
}
