import FirebaseAuth

class AuthManager {
    static let shared = AuthManager()
    
    func signUp(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            completion(error == nil, error?.localizedDescription)
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            completion(error == nil, error?.localizedDescription)
        }
    }
    
    func signOut(completion: @escaping (Bool, String?) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(true, nil)
        } catch {
            completion(false, error.localizedDescription)
        }
    }
}
