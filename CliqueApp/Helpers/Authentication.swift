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
        
        print("📱 Sending verification code to: \(formattedNumber)")
        
        return try await withCheckedThrowingContinuation { continuation in
            PhoneAuthProvider.provider().verifyPhoneNumber(formattedNumber, uiDelegate: nil) { verificationID, error in
                if let error {
                    print("❌ Verification code error: \(error.localizedDescription)")
                    print("❌ Error details: \(error)")
                    continuation.resume(throwing: error)
                } else if let verificationID {
                    print("✅ Verification ID received: \(verificationID)")
                    continuation.resume(returning: verificationID)
                } else {
                    print("❌ No verification ID and no error")
                    continuation.resume(throwing: ErrorHandler.AppError.operationFailed("Send verification code"))
                }
            }
        }
    }
    
    // MARK: - Authentication
    
    func signUp(phoneNumber: String, verificationID: String, smsCode: String) async throws -> User {
        let canonicalPhone = PhoneNumberFormatter.canonical(phoneNumber)
        guard !canonicalPhone.isEmpty else {
            throw ErrorHandler.AppError.invalidData
        }
        
        let phoneCredential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: smsCode)
        
        do {
            let phoneSignInResult = try await Auth.auth().signIn(with: phoneCredential)
            return phoneSignInResult.user
        } catch let error as NSError {
            if error.code == AuthErrorCode.credentialAlreadyInUse.rawValue {
                throw ErrorHandler.AppError.authenticationFailed("An account with this phone number already exists. Please sign in instead.")
            }
            throw error
        }
    }
    
    func signIn(phoneNumber: String, verificationID: String, smsCode: String) async throws -> User {
        let canonicalPhone = PhoneNumberFormatter.canonical(phoneNumber)
        guard !canonicalPhone.isEmpty else {
            throw ErrorHandler.AppError.invalidData
        }
        
        let phoneCredential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: smsCode)
        let authResult = try await Auth.auth().signIn(with: phoneCredential)
        return authResult.user
    }
    
    // MARK: - Session
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    func getSignedInUserID() async -> String? {
        Auth.auth().currentUser?.uid
    }
    
}
