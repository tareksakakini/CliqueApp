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
    
    //    func deleteAccount() throws {
    //        do {
    //            try Auth.auth().currentUser!.delete
    //        } catch {
    //            throw error
    //        }
    //    }
    
    /// Deletes the currently logged-in user
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "No user is currently signed in."])
        }
        
        do {
            try await user.delete()
            print("User deleted successfully.")
        } catch {
            throw error
        }
    }
}
