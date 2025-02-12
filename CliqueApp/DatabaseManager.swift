import FirebaseFirestore
import FirebaseAuth

class DatabaseManager {
    private let db = Firestore.firestore()
    
    func addUserToFirestore(uid: String, email: String, fullname: String, profilePic: String) async throws {
        let userRef = db.collection("users").document(uid)
        
        let userData: [String: Any] = [
            "uid": uid,
            "email": email,
            "createdAt": Date(),
            "fullname": fullname,
            "profilePic": profilePic
        ]
        
        do {
            try await userRef.setData(userData)
            print("User added successfully!")
        } catch {
            print("Error adding user: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getUserFromFirestore(uid: String) async throws -> UserModel {
            let userRef = db.collection("users").document(uid)
            
            do {
                let document = try await userRef.getDocument()
                guard let data = document.data() else {
                    throw NSError(domain: "FirestoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
                }
                
                return UserModel(
                    uid: data["uid"] as? String ?? "",
                    fullname: data["fullname"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    profilePic: data["profilePic"] as? String ?? ""
                )
            } catch {
                print("Error fetching user: \(error.localizedDescription)")
                throw error
            }
        }
}




//import FirebaseFirestore
//
//class DatabaseManager {
//    static let shared = DatabaseManager()
//    private let db = Firestore.firestore()
//
//    func addUser(uid: String, email: String, fullname: String, completion: @escaping (Bool, String?) -> Void) {
//        let userData: [String: Any] = [
//            "uid": uid,
//            "email": email,
//            "createdAt": Timestamp(),
//            "fullname": fullname,
//            "profilePic": "userDefault"
//        ]
//
//        db.collection("users").document(uid).setData(userData) { error in
//            completion(error == nil, error?.localizedDescription)
//        }
//    }
//
//    func getUserInfo(uid: String, completion: @escaping ([String: Any]?, String?) -> Void) {
//        db.collection("users").document(uid).getDocument { snapshot, error in
//            if let data = snapshot?.data(), error == nil {
//                completion(data, nil)
//            } else {
//                completion(nil, error?.localizedDescription)
//            }
//        }
//    }
//}
