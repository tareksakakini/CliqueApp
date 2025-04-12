import FirebaseFirestore
import FirebaseDatabaseInternal
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class DatabaseManager {
    private let db = Firestore.firestore()
    
    func addUserToFirestore(uid: String, email: String, fullname: String, profilePic: String, gender: String) async throws {
        let userRef = db.collection("users").document(uid)
        
        let userData: [String: Any] = [
            "uid": uid,
            "email": email,
            "createdAt": Date(),
            "fullname": fullname,
            "profilePic": profilePic,
            "gender": gender
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
            return UserModel().initFromFirestore(userData: data)
        } catch {
            print("Error fetching user: \(error.localizedDescription)")
            throw error
        }
    }
    
    func addEventToFirestore(id: String, title: String, location: String, dateTime: Date, attendeesAccepted: [String], attendeesInvited: [String], host: String, hours: String, minutes: String, invitedPhoneNumbers: [String], acceptedPhoneNumbers: [String]) async throws {
        let eventRef = db.collection("events").document(id)
        
        let eventData: [String: Any] = [
            "id": id,
            "title": title,
            "location": location,
            "dateTime": dateTime,
            "attendeesAccepted": attendeesAccepted,
            "attendeesInvited": attendeesInvited,
            "host": host,
            "hours": hours,
            "minutes": minutes,
            "invitedPhoneNumbers": invitedPhoneNumbers,
            "acceptedPhoneNumbers": acceptedPhoneNumbers
        ]
        
        do {
            try await eventRef.setData(eventData)
            print("Event added successfully!")
        } catch {
            print("Error adding event: \(error.localizedDescription)")
            throw error
        }
    }
    
    func deleteEventFromFirestore(id: String) async throws {
        let eventRef = db.collection("events").document(id)
        
        do {
            try await eventRef.delete()
            print("Event deleted successfully!")
        } catch {
            print("Error deleting event: \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    func getAllEvents() async throws -> [EventModel] {
        let eventsRef = db.collection("events")
        
        do {
            let snapshot = try await eventsRef.getDocuments()
            let events = snapshot.documents.compactMap { document -> EventModel? in
                let data = document.data()
                return EventModel().initFromFirestore(eventData: data)
            }
            return events
        } catch {
            print("Error fetching events: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getAllUsers() async throws -> [UserModel] {
        let usersRef = db.collection("users")
        
        do {
            let snapshot = try await usersRef.getDocuments()
            let users = snapshot.documents.compactMap { document -> UserModel? in
                let data = document.data()
                return UserModel().initFromFirestore(userData: data)
            }
            return users
        } catch {
            print("Error fetching events: \(error.localizedDescription)")
            throw error
        }
    }
    
    func respondInvite(eventId: String, userId: String, action: String) async throws {
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
                
                var attendeesInvited = eventData["attendeesInvited"] as? [String] ?? []
                var attendeesAccepted = eventData["attendeesAccepted"] as? [String] ?? []
                var host = eventData["host"] as? String ?? ""
                
                if action == "reject" || action == "accept" {
                    // Ensure user exists in inviteeAttended list
                    guard let index = attendeesInvited.firstIndex(of: userId) else {
                        print("User not found in inviteeAttended list")
                        return nil
                    }
                    // Remove from attended
                    attendeesInvited.remove(at: index)
                    if action == "accept" {
                        attendeesAccepted.append(userId)
                    }
                } else if action == "leave" {
                    if userId == host {
                        host = ""
                    } else {
                        guard let index = attendeesAccepted.firstIndex(of: userId) else {
                            print("User not found in attendeesAccepted list")
                            return nil
                        }
                        attendeesAccepted.remove(at: index)
                    }
                }
                
                // Update Firestore document
                transaction.updateData([
                    "attendeesInvited": attendeesInvited,
                    "attendeesAccepted": attendeesAccepted,
                    "host": host
                ], forDocument: eventRef)
                
                return nil // Transaction closure must return a non-throwing value
            }
            print("Successfully updated invite status")
        } catch {
            print("Error updating invite status: \(error.localizedDescription)")
            throw error
        }
        
    }
    
    func updateFriends(viewing_user: String, viewed_user: String, action: String) async throws {
        let user1Ref = db.collection("friendships").document(viewing_user)
        let user2Ref = db.collection("friendships").document(viewed_user)
        
        do {
            // Fetch both users' current friend lists in parallel
            async let user1Snapshot = user1Ref.getDocument()
            async let user2Snapshot = user2Ref.getDocument()
            let (user1Data, user2Data) = try await (user1Snapshot, user2Snapshot)
            
            var user1Friends = user1Data.data()?["friends"] as? [String] ?? []
            var user2Friends = user2Data.data()?["friends"] as? [String] ?? []
            
            if action == "add" {
                if !user1Friends.contains(viewed_user) {
                    user1Friends.append(viewed_user)
                }
                if !user2Friends.contains(viewing_user) {
                    user2Friends.append(viewing_user)
                }
                try? await self.removeFriendRequest(sender: viewed_user, receiver: viewing_user)
            } else if action == "remove" {
                if user1Friends.contains(viewed_user) {
                    user1Friends.removeAll() { $0 == viewed_user }
                }
                if user2Friends.contains(viewing_user) {
                    user2Friends.removeAll() { $0 == viewing_user }
                }
            }
            
            // Update Firestore in parallel
            try? await user1Ref.setData(["friends": user1Friends], merge: true)
            try? await user2Ref.setData(["friends": user2Friends], merge: true)
        } catch {
            throw error
        }
    }
    
    func sendFriendRequest(sender: String, receiver: String) async throws {
        let receiverRef = db.collection("friendRequests").document(receiver)
        let senderRef = db.collection("friendRequestsSent").document(sender)
        
        do {
            // Fetch both users' current friend lists in parallel
            async let receiverSnapshot = receiverRef.getDocument()
            async let senderSnapshot = senderRef.getDocument()
            let receiverData = try await receiverSnapshot
            let senderData = try await senderSnapshot
            
            var receiverRequests = receiverData.data()?["requests"] as? [String] ?? []
            var senderRequests = senderData.data()?["requests"] as? [String] ?? []
            
            if !receiverRequests.contains(sender) {
                receiverRequests.append(sender)
            }
            if !senderRequests.contains(receiver) {
                senderRequests.append(receiver)
            }
            
            // Update Firestore in parallel
            try? await receiverRef.setData(["requests": receiverRequests], merge: true)
            try? await senderRef.setData(["requests": senderRequests], merge: true)
        } catch {
            throw error
        }
    }
    
    func removeFriendRequest(sender: String, receiver: String) async throws {
        let receiverRef = db.collection("friendRequests").document(receiver)
        let senderRef = db.collection("friendRequestsSent").document(sender)
        
        do {
            // Fetch both users' current friend lists in parallel
            async let receiverSnapshot = receiverRef.getDocument()
            async let senderSnapshot = senderRef.getDocument()
            let receiverData = try await receiverSnapshot
            let senderData = try await senderSnapshot
            
            var receiverRequests = receiverData.data()?["requests"] as? [String] ?? []
            var senderRequests = senderData.data()?["requests"] as? [String] ?? []
            
            if receiverRequests.contains(sender) {
                receiverRequests.removeAll() { $0 == sender }
            }
            if senderRequests.contains(receiver) {
                senderRequests.removeAll() { $0 == receiver }
            }
            
            // Update Firestore in parallel
            try? await receiverRef.setData(["requests": receiverRequests], merge: true)
            try? await senderRef.setData(["requests": senderRequests], merge: true)
        } catch {
            throw error
        }
    }
    
    func retrieveFriendRequest(user_email: String) async throws -> [String] {
        let receiverRef = db.collection("friendRequests").document(user_email)
        
        do {
            // Fetch both users' current friend lists in parallel
            async let receiverSnapshot = receiverRef.getDocument()
            let receiverData = try await receiverSnapshot
            
            let receiverRequests = receiverData.data()?["requests"] as? [String] ?? []
            return receiverRequests
        } catch {
            throw error
        }
    }
    
    func retrieveFriendRequestSent(user_email: String) async throws -> [String] {
        let receiverRef = db.collection("friendRequestsSent").document(user_email)
        
        do {
            // Fetch both users' current friend lists in parallel
            async let receiverSnapshot = receiverRef.getDocument()
            let receiverData = try await receiverSnapshot
            
            let receiverRequests = receiverData.data()?["requests"] as? [String] ?? []
            return receiverRequests
        } catch {
            throw error
        }
    }
    
    func retrieveFriends(user_email: String) async throws -> [String] {
        let receiverRef = db.collection("friendships").document(user_email)
        
        do {
            // Fetch both users' current friend lists in parallel
            async let receiverSnapshot = receiverRef.getDocument()
            let receiverData = try await receiverSnapshot
            
            let receiverRequests = receiverData.data()?["friends"] as? [String] ?? []
            return receiverRequests
        } catch {
            throw error
        }
    }
    
    func deleteUserAccount(uid: String, email: String) async throws {
        let userRef = db.collection("users").document(uid)
        let userFriendRef = db.collection("friendships").document(email)
        let friendRequestRef = db.collection("friendRequests").document(email)
        
        do {
            // Fetch all events where the user is an attendee
            let eventSnapshot = try await db.collection("events").whereField("attendeesAccepted", arrayContains: email).getDocuments()
            for document in eventSnapshot.documents {
                let eventRef = db.collection("events").document(document.documentID)
                try await eventRef.updateData([
                    "attendeesAccepted": FieldValue.arrayRemove([email])
                ])
            }
            
            let invitedSnapshot = try await db.collection("events").whereField("attendeesInvited", arrayContains: email).getDocuments()
            for document in invitedSnapshot.documents {
                let eventRef = db.collection("events").document(document.documentID)
                try await eventRef.updateData([
                    "attendeesInvited": FieldValue.arrayRemove([email])
                ])
            }
            
            let hostingSnapshot = try await db.collection("events").whereField("host", isEqualTo: email).getDocuments()
            for document in hostingSnapshot.documents {
                let eventRef = db.collection("events").document(document.documentID)
                try await eventRef.updateData([
                    "host": ""
                ])
            }
            
            // Remove user from all friends' lists
            let friendshipsSnapshot = try await userFriendRef.getDocument()
            if let friendsList = friendshipsSnapshot.data()?["friends"] as? [String] {
                for friendId in friendsList {
                    let friendRef = db.collection("friendships").document(friendId)
                    try await friendRef.updateData([
                        "friends": FieldValue.arrayRemove([email])
                    ])
                }
            }
            
            // Remove all friend requests **sent** by the user
            let friendRequestsSnapshot = try await db.collection("friendRequests").getDocuments()
            for document in friendRequestsSnapshot.documents {
                let friendRequestRef = db.collection("friendRequests").document(document.documentID)
                if var requests = document.data()["requests"] as? [String], requests.contains(email) {
                    requests.removeAll { $0 == email }
                    try await friendRequestRef.updateData(["requests": requests])
                }
            }
            
            // Delete user data from Firestore
            try await userRef.delete()
            try await userFriendRef.delete()
            try await friendRequestRef.delete()
            
            // Delete the user's authentication account
            if let user = Auth.auth().currentUser {
                try await user.delete()
            }
            
            print("User account and associated data deleted successfully.")
        } catch {
            print("Error deleting user data: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateUserSubscriptionId(uid: String, subscriptionId: String) async throws {
        let userRef = db.collection("users").document(uid)
        
        do {
            try await userRef.updateData(["subscriptionId": subscriptionId])
            print("Subscription ID updated successfully!")
        } catch {
            print("Error updating subscription ID: \(error.localizedDescription)")
            throw error
        }
    }
    
    func uploadEventImage(image: UIImage, event_id: String) async {
        guard let imageData = image.jpegData(compressionQuality: 0.4) else { return }
        let storageRef = Storage.storage().reference()
        let fileRef = storageRef.child("event_images/\(event_id).jpg")
        
        fileRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Upload failed: \(error.localizedDescription)")
                return
            }
            
            fileRef.downloadURL { url, error in
                guard let downloadURL = url else { return }
                self.saveEventImageURLToFirestore(url: downloadURL.absoluteString, event_id: event_id)
            }
        }
    }
    
    func saveEventImageURLToFirestore(url: String, event_id: String) {
            let db = Firestore.firestore()
            db.collection("events").document(event_id).setData(["eventPic": url], merge: true) { error in
                if let error = error {
                    print("Error updating Firestore: \(error.localizedDescription)")
                } else {
                    print("Event picture updated successfully!")
                }
            }
        }
    
    func uploadProfileImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.4) else { return }
        let storageRef = Storage.storage().reference()
        let userId = Auth.auth().currentUser?.uid ?? UUID().uuidString
        let fileRef = storageRef.child("profile_pictures/\(userId).jpg")
        
        fileRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Upload failed: \(error.localizedDescription)")
                return
            }
            
            fileRef.downloadURL { url, error in
                guard let downloadURL = url else { return }
                self.saveImageURLToFirestore(url: downloadURL.absoluteString)
            }
        }
    }
    
    func saveImageURLToFirestore(url: String) {
            let db = Firestore.firestore()
            let userId = Auth.auth().currentUser?.uid ?? UUID().uuidString
            db.collection("users").document(userId).setData(["profilePic": url], merge: true) { error in
                if let error = error {
                    print("Error updating Firestore: \(error.localizedDescription)")
                } else {
                    print("Profile picture updated successfully!")
                }
            }
        }
}

