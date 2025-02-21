import FirebaseAuth

class AuthManager {
    
    static let shared = AuthManager()
    
    private init() {}

    /// Signs up a new user with email and password
    func signUp(email: String, password: String) async throws -> User {
        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
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
}
