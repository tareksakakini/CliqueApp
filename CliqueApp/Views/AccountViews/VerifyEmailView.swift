//
//  VerifyEmailView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 3/26/25.
//

import SwiftUI

struct VerifyEmailView: View {
    @State var user: UserModel
    @State var isVerified: Bool = false
    let message: String = "A verification link has been sent to your email. Please verify to continue."
    
    var body: some View {
        ZStack {
            if !isVerified {
                VerificationViewContent
            } else {
                MainView(user: user)
            }
        }
        .task {
            await checkEmailVerification()
        }
        .navigationBarHidden(true)
    }
    
    @MainActor
    private func checkEmailVerification() async {
        while !isVerified {
            isVerified = await AuthManager.shared.getEmailVerified()
            if isVerified { break }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
    }
}

#Preview {
    VerifyEmailView(user: UserData.userData[0])
}

extension VerifyEmailView {
    private var VerificationViewContent: some View {
        ZStack {
            Color(.accent).ignoresSafeArea()
            VStack {
                BackNavigation(foregroundColor: .white)
                Spacer()
                Text(message)
                    .foregroundColor(.white)
                    .padding()
                Spacer()
            }
        }
    }
}
