import FirebaseAuth

class AuthManager {
    
    static let shared = AuthManager()
    
    private init() {}
    
    // MARK: - SMS Verification
    
    func sendVerificationCode(to phoneNumber: String) async throws -> String {
        let formattedNumber = PhoneNumberFormatter.e164(phoneNumber)
        guard !formattedNumber.isEmpty else {
            throw ErrorHandler.AppError.invalidData
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            PhoneAuthProvider.provider().verifyPhoneNumber(formattedNumber, uiDelegate: nil) { verificationID, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let verificationID {
                    continuation.resume(returning: verificationID)
                } else {
                    continuation.resume(throwing: ErrorHandler.AppError.operationFailed("Send verification code"))
                }
            }
        }
    }
    
    // MARK: - Authentication
    
    func signUp(phoneNumber: String, password: String, verificationID: String, smsCode: String) async throws -> User {
        let canonicalPhone = PhoneNumberFormatter.canonical(phoneNumber)
        guard !canonicalPhone.isEmpty else {
            throw ErrorHandler.AppError.invalidData
        }
        
        let phoneCredential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: smsCode)
        let phoneSignInResult = try await Auth.auth().signIn(with: phoneCredential)
        
        let pseudoEmail = PhoneNumberFormatter.pseudoEmail(for: canonicalPhone)
        let passwordCredential = EmailAuthProvider.credential(withEmail: pseudoEmail, password: password)
        
        do {
            let linkedResult = try await phoneSignInResult.user.link(with: passwordCredential)
            return linkedResult.user
        } catch let error as NSError {
            if error.code == AuthErrorCode.emailAlreadyInUse.rawValue ||
                error.code == AuthErrorCode.credentialAlreadyInUse.rawValue {
                try? signOut()
                throw ErrorHandler.AppError.authenticationFailed("An account with this phone number already exists. Please sign in instead.")
            }
            throw error
        }
    }
    
    func signIn(phoneNumber: String, password: String) async throws -> User {
        let canonicalPhone = PhoneNumberFormatter.canonical(phoneNumber)
        let pseudoEmail = PhoneNumberFormatter.pseudoEmail(for: canonicalPhone)
        let authResult = try await Auth.auth().signIn(withEmail: pseudoEmail, password: password)
        return authResult.user
    }
    
    func resetPassword(newPassword: String, verificationID: String, smsCode: String) async throws {
        let phoneCredential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: smsCode)
        let phoneSignInResult = try await Auth.auth().signIn(with: phoneCredential)
        
        do {
            try await phoneSignInResult.user.updatePassword(to: newPassword)
            try signOut()
        } catch {
            throw error
        }
    }
    
    // MARK: - Session
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    func getSignedInUserID() async -> String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - Password Management
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user is currently signed in"])
        }
        
        guard let email = user.email else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User email not available"])
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        do {
            try await user.reauthenticate(with: credential)
            try await user.updatePassword(to: newPassword)
            print("Password changed successfully")
        } catch {
            print("Error changing password: \(error.localizedDescription)")
            throw error
        }
    }
}
