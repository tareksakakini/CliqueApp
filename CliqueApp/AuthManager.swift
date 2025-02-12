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




//import FirebaseAuth
//
//class AuthManager {
//    static let shared = AuthManager()
//
//    func signUp(email: String, password: String, fullname: String, completion: @escaping (Bool, String?) -> Void) {
//        Auth.auth().createUser(withEmail: email, password: password) { result, error in
//            if let user = result?.user, error == nil {
//                DatabaseManager.shared.addUser(uid: user.uid, email: email, fullname: fullname) { success, dbError in
//                    completion(success, dbError ?? "User created but data not saved")
//                }
//            } else {
//                completion(false, error?.localizedDescription)
//            }
//        }
//    }
//
//    func signIn(email: String, password: String, completion: @escaping (Bool, [String: Any]?, String?) -> Void) {
//        Auth.auth().signIn(withEmail: email, password: password) { result, error in
//            if let user = result?.user, error == nil {
//                DatabaseManager.shared.getUserInfo(uid: user.uid) { data, dbError in
//                    if let data = data {
//                        completion(true, data, nil)  // Pass user data
//                    } else {
//                        completion(false, nil, dbError ?? "Failed to fetch user info")
//                    }
//                }
//            } else {
//                completion(false, nil, error?.localizedDescription)
//            }
//        }
//    }
//
//    func signOut(completion: @escaping (Bool, String?) -> Void) {
//        do {
//            try Auth.auth().signOut()
//            completion(true, nil)
//        } catch {
//            completion(false, error.localizedDescription)
//        }
//    }
//}
