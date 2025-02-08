import FirebaseFirestore

class DatabaseManager {
    static let shared = DatabaseManager()
    private let db = Firestore.firestore()

    func addUser(uid: String, email: String, fullname: String, completion: @escaping (Bool, String?) -> Void) {
        let userData: [String: Any] = [
            "uid": uid,
            "email": email,
            "createdAt": Timestamp(),
            "fullname": fullname,
            "profilePic": "userDefault"
        ]

        db.collection("users").document(uid).setData(userData) { error in
            completion(error == nil, error?.localizedDescription)
        }
    }

    func getUserInfo(uid: String, completion: @escaping ([String: Any]?, String?) -> Void) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data(), error == nil {
                completion(data, nil)
            } else {
                completion(nil, error?.localizedDescription)
            }
        }
    }
}
