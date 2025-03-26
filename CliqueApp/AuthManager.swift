import FirebaseAuth

class AuthManager {
    
    static let shared = AuthManager()
    
    private init() {}
    
    /// Signs up a new user with email and password
    func signUp(email: String, password: String) async throws -> User {
        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            try await authResult.user.sendEmailVerification()
            return authResult.user
        } catch {
            throw error
        }
    }
    
    /// Signs in an existing user with email and password
    func signIn(email: String, password: String) async throws -> User {
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            return authResult.user
        } catch {
            throw error
        }
    }
    
    /// Signs out the currently logged-in user
    func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw error
        }
    }
    
    func sendPasswordReset(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            print("Password reset email sent successfully.")
        } catch {
            throw error
        }
    }
    
    func getSignedInUser() async -> String? {
        let signedInUser = Auth.auth().currentUser
        if let signedInUser = signedInUser {
            return signedInUser.uid
        } else {
            return nil
        }
    }
    
    func getEmailVerified() async -> Bool {
        guard let user = Auth.auth().currentUser else { return false }
        
        do {
            try await user.reload() // Refresh user data from Firebase
            print("User Email Verified Status: \(user.isEmailVerified)")
            return user.isEmailVerified
        } catch {
            print("Error reloading user: \(error.localizedDescription)")
            return false
        }
    }

}
