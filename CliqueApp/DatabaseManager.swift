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
    
    func addEventToFirestore(id: String, title: String, location: String, dateTime: Date, attendeesAccepted: [String], attendeesInvited: [String]) async throws {
        let eventRef = db.collection("events").document(id)
        
        let eventData: [String: Any] = [
            "id": id,
            "title": title,
            "location": location,
            "dateTime": dateTime,
            "attendeesAccepted": attendeesAccepted,
            "attendeesInvited": attendeesInvited
        ]
        
        do {
            try await eventRef.setData(eventData)
            print("Event added successfully!")
        } catch {
            print("Error adding event: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getAllEvents() async throws -> [EventModel] {
            let eventsRef = db.collection("events")
            
            do {
                let snapshot = try await eventsRef.getDocuments()
                let events = snapshot.documents.compactMap { document -> EventModel? in
                    let data = document.data()
                    return EventModel(
                        id: document.documentID,
                        title: data["title"] as? String ?? "No Name",
                        location: data["location"] as? String ?? "No Location",
                        dateTime: (data["dateTime"] as? Timestamp)?.dateValue() ?? Date(),
                        attendeesAccepted: data["attendeesAccepted"] as? [String] ?? [],
                        attendeesInvited: data["attendeesInvited"] as? [String] ?? []
                    )
                }
                return events
            } catch {
                print("Error fetching events: \(error.localizedDescription)")
                throw error
            }
        }
}

