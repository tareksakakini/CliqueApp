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
    
    func acceptInvite(eventId: String, userId: String) async throws {
        let eventRef = db.collection("events").document(eventId)
        
        do {
            _ = try await db.runTransaction { transaction, _ in
                let eventSnapshot: DocumentSnapshot
                do {
                    eventSnapshot = try transaction.getDocument(eventRef)
                } catch {
                    return nil // Returning nil means the transaction will fail
                }
                
                guard let eventData = eventSnapshot.data() else {
                    print("Event not found")
                    return nil
                }
                
                var inviteeAttended = eventData["attendeesInvited"] as? [String] ?? []
                var inviteeAccepted = eventData["attendeesAccepted"] as? [String] ?? []
                
                // Ensure user exists in inviteeAttended list
                guard let index = inviteeAttended.firstIndex(of: userId) else {
                    print("User not found in inviteeAttended list")
                    return nil
                }
                
                // Remove from attended and add to accepted
                inviteeAttended.remove(at: index)
                inviteeAccepted.append(userId)
                
                // Update Firestore document
                transaction.updateData([
                    "attendeesInvited": inviteeAttended,
                    "attendeesAccepted": inviteeAccepted
                ], forDocument: eventRef)
                
                return nil // Transaction closure must return a non-throwing value
            }
            print("Successfully updated invite status")
        } catch {
            print("Error updating invite status: \(error.localizedDescription)")
            throw error
        }
        
    }
    
    func rejectInvite(eventId: String, userId: String) async throws {
        let eventRef = db.collection("events").document(eventId)
        
        do {
            _ = try await db.runTransaction { transaction, _ in
                let eventSnapshot: DocumentSnapshot
                do {
                    eventSnapshot = try transaction.getDocument(eventRef)
                } catch {
                    return nil // Returning nil means the transaction will fail
                }
                
                guard let eventData = eventSnapshot.data() else {
                    print("Event not found")
                    return nil
                }
                
                var inviteeAttended = eventData["attendeesInvited"] as? [String] ?? []
                
                // Ensure user exists in inviteeAttended list
                guard let index = inviteeAttended.firstIndex(of: userId) else {
                    print("User not found in inviteeAttended list")
                    return nil
                }
                
                // Remove from attended and add to accepted
                inviteeAttended.remove(at: index)
                
                // Update Firestore document
                transaction.updateData([
                    "attendeesInvited": inviteeAttended,
                ], forDocument: eventRef)
                
                return nil // Transaction closure must return a non-throwing value
            }
            print("Successfully updated invite status")
        } catch {
            print("Error updating invite status: \(error.localizedDescription)")
            throw error
        }
        
    }
    
    func leaveEvent(eventId: String, userId: String) async throws {
        let eventRef = db.collection("events").document(eventId)
        
        do {
            _ = try await db.runTransaction { transaction, _ in
                let eventSnapshot: DocumentSnapshot
                do {
                    eventSnapshot = try transaction.getDocument(eventRef)
                } catch {
                    return nil // Returning nil means the transaction will fail
                }
                
                guard let eventData = eventSnapshot.data() else {
                    print("Event not found")
                    return nil
                }
                
                var attendeesAccepted = eventData["attendeesAccepted"] as? [String] ?? []
                
                // Ensure user exists in inviteeAttended list
                guard let index = attendeesAccepted.firstIndex(of: userId) else {
                    print("User not found in inviteeAttended list")
                    return nil
                }
                
                // Remove from attended and add to accepted
                attendeesAccepted.remove(at: index)
                
                // Update Firestore document
                transaction.updateData([
                    "attendeesAccepted": attendeesAccepted,
                ], forDocument: eventRef)
                
                return nil // Transaction closure must return a non-throwing value
            }
            print("Successfully updated invite status")
        } catch {
            print("Error updating invite status: \(error.localizedDescription)")
            throw error
        }
        
    }
    
}

