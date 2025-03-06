import FirebaseFirestore
import FirebaseDatabaseInternal
import FirebaseAuth
import FirebaseDatabase

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
                profilePic: data["profilePic"] as? String ?? "",
                subscriptionId: data["subscriptionId"] as? String ?? ""
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
    
    func getAllUsers() async throws -> [UserModel] {
        let usersRef = db.collection("users")
        
        do {
            let snapshot = try await usersRef.getDocuments()
            let users = snapshot.documents.compactMap { document -> UserModel? in
                let data = document.data()
                return UserModel(
                    uid: document.documentID,
                    fullname: data["fullname"] as? String ?? "No Name",
                    email: data["email"] as? String ?? "No Email",
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    profilePic: data["profilePic"] as? String ?? "userDefault",
                    subscriptionId: data["subscriptionId"] as? String ?? ""
                )
            }
            return users
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
    
    func addFriends(user1: String, user2: String) async throws {
        let user1Ref = db.collection("friendships").document(user1)
        let user2Ref = db.collection("friendships").document(user2)
        
        do {
            // Fetch both users' current friend lists in parallel
            async let user1Snapshot = user1Ref.getDocument()
            async let user2Snapshot = user2Ref.getDocument()
            let (user1Data, user2Data) = try await (user1Snapshot, user2Snapshot)
            
            var user1Friends = user1Data.data()?["friends"] as? [String] ?? []
            var user2Friends = user2Data.data()?["friends"] as? [String] ?? []
            
            if !user1Friends.contains(user2) {
                user1Friends.append(user2)
            }
            if !user2Friends.contains(user1) {
                user2Friends.append(user1)
            }
            
            // Update Firestore in parallel
            async let updateUser1: Void = user1Ref.setData(["friends": user1Friends], merge: true)
            async let updateUser2: Void = user2Ref.setData(["friends": user2Friends], merge: true)
            //try await (updateUser1, updateUser2)
        } catch {
            throw error
        }
    }
    
    func removeFriends(user1: String, user2: String) async throws {
        let user1Ref = db.collection("friendships").document(user1)
        let user2Ref = db.collection("friendships").document(user2)
        
        do {
            // Fetch both users' current friend lists in parallel
            async let user1Snapshot = user1Ref.getDocument()
            async let user2Snapshot = user2Ref.getDocument()
            let (user1Data, user2Data) = try await (user1Snapshot, user2Snapshot)
            
            var user1Friends = user1Data.data()?["friends"] as? [String] ?? []
            var user2Friends = user2Data.data()?["friends"] as? [String] ?? []
            
            if user1Friends.contains(user2) {
                user1Friends.removeAll() { $0 == user2 }
            }
            if user2Friends.contains(user1) {
                user2Friends.removeAll() { $0 == user1 }
            }
            
            // Update Firestore in parallel
            async let updateUser1: Void = user1Ref.setData(["friends": user1Friends], merge: true)
            async let updateUser2: Void = user2Ref.setData(["friends": user2Friends], merge: true)
            //try await (updateUser1, updateUser2)
        } catch {
            throw error
        }
    }
    
    func sendFriendRequest(sender: String, receiver: String) async throws {
        let receiverRef = db.collection("friendRequests").document(receiver)
        
        do {
            // Fetch both users' current friend lists in parallel
            async let receiverSnapshot = receiverRef.getDocument()
            let receiverData = try await receiverSnapshot
            
            var receiverRequests = receiverData.data()?["requests"] as? [String] ?? []
            
            if !receiverRequests.contains(sender) {
                receiverRequests.append(sender)
            }
            
            // Update Firestore in parallel
            async let updateReceiver: Void = receiverRef.setData(["requests": receiverRequests], merge: true)
            //try await (updateUser1, updateUser2)
        } catch {
            throw error
        }
    }
    
    func removeFriendRequest(sender: String, receiver: String) async throws {
        let receiverRef = db.collection("friendRequests").document(receiver)
        
        do {
            // Fetch both users' current friend lists in parallel
            async let receiverSnapshot = receiverRef.getDocument()
            let receiverData = try await receiverSnapshot
            
            var receiverRequests = receiverData.data()?["requests"] as? [String] ?? []
            
            if receiverRequests.contains(sender) {
                receiverRequests.removeAll() { $0 == sender }
            }
            
            // Update Firestore in parallel
            async let updateReceiver: Void = receiverRef.setData(["requests": receiverRequests], merge: true)
            //try await (updateUser1, updateUser2)
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
            
            var receiverRequests = receiverData.data()?["requests"] as? [String] ?? []
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
            
            var receiverRequests = receiverData.data()?["friends"] as? [String] ?? []
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
}

