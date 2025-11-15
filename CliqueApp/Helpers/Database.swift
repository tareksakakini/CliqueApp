import Foundation
import FirebaseFirestore
import FirebaseDatabaseInternal
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class DatabaseManager {
    private let db = Firestore.firestore()
    
    func addUserToFirestore(userId: String,
                            authUID: String,
                            fullname: String,
                            username: String,
                            profilePic: String,
                            gender: String,
                            phoneNumber: String = "") async throws {
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
        // Validate inputs
        guard !userId.isEmpty else {
            throw NSError(domain: "DatabaseError", code: 400, userInfo: [NSLocalizedDescriptionKey: "User ID cannot be empty"])
        }
        guard !authUID.isEmpty else {
            throw NSError(domain: "DatabaseError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Auth UID cannot be empty"])
        }
        
        let userRef = db.collection("users").document(userId)
        
        // Determine which phone to use and canonicalize it
        let canonicalPhone = PhoneNumberFormatter.canonical(phoneNumber)
        let phoneE164 = PhoneNumberFormatter.e164(phoneNumber)
        let storedPhoneNumber = phoneE164.isEmpty
            ? (canonicalPhone.isEmpty ? phoneNumber : canonicalPhone)
            : phoneE164
        
        let userData: [String: Any] = [
            "uid": userId,
            "authUID": authUID,
            "createdAt": Date(),
            "fullname": fullname,
            "username": username,
            "profilePic": profilePic,
            "gender": gender,
            "phoneNumber": storedPhoneNumber
        ]
        
        print("📝 Creating Firestore user document with userId: \(userId)")
        
        do {
            try await userRef.setData(userData)
            print("✅ User added successfully to Firestore!")
        } catch {
            print("❌ Error adding user: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getUserById(_ userId: String) async throws -> UserModel {
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
        let userRef = db.collection("users").document(userId)
        
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
    
    func getUserByAuthUID(_ authUID: String) async throws -> UserModel {
        try ErrorHandler.shared.validateNetworkConnection()
        
        let snapshot = try await db.collection("users")
            .whereField("authUID", isEqualTo: authUID)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            throw NSError(domain: "FirestoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found for auth UID"])
        }
        return UserModel().initFromFirestore(userData: document.data())
    }
    
    func addEventToFirestore(id: String, title: String, location: String, description: String, startDateTime: Date, endDateTime: Date, noEndTime: Bool, attendeesAccepted: [String], attendeesInvited: [String], attendeesDeclined: [String], host: String, invitedPhoneNumbers: [String], acceptedPhoneNumbers: [String], declinedPhoneNumbers: [String], selectedImage: UIImage?) async throws {
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
        let eventRef = db.collection("events").document(id)
        
        let eventData: [String: Any] = [
            "id": id,
            "title": title,
            "location": location,
            "description": description,
            "startDateTime": startDateTime,
            "endDateTime": endDateTime,
            "noEndTime": noEndTime,
            "attendeesAccepted": attendeesAccepted,
            "attendeesInvited": attendeesInvited,
            "attendeesDeclined": attendeesDeclined,
            "host": host,
            "invitedPhoneNumbers": invitedPhoneNumbers,
            "acceptedPhoneNumbers": acceptedPhoneNumbers,
            "declinedPhoneNumbers": declinedPhoneNumbers
        ]
        
        do {
            try await eventRef.setData(eventData)
            if let selectedImage {
                let storageLocation = "event_images/\(id).jpg"
                await self.uploadImage(image: selectedImage, storageLocation: storageLocation, referenceLocation: eventRef, fieldName: "eventPic")
            }
            print("Event added successfully!")
            
        } catch {
            print("Error adding event: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateEventInFirestore(id: String, title: String, location: String, description: String, startDateTime: Date, endDateTime: Date, noEndTime: Bool, attendeesAccepted: [String], attendeesInvited: [String], attendeesDeclined: [String], host: String, invitedPhoneNumbers: [String], acceptedPhoneNumbers: [String], declinedPhoneNumbers: [String], selectedImage: UIImage?) async throws {
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
        let eventRef = db.collection("events").document(id)
        
        let updatedEventData: [String: Any] = [
            "title": title,
            "location": location,
            "description": description,
            "startDateTime": startDateTime,
            "endDateTime": endDateTime,
            "noEndTime": noEndTime,
            "attendeesAccepted": attendeesAccepted,
            "attendeesInvited": attendeesInvited,
            "attendeesDeclined": attendeesDeclined,
            "host": host,
            "invitedPhoneNumbers": invitedPhoneNumbers,
            "acceptedPhoneNumbers": acceptedPhoneNumbers,
            "declinedPhoneNumbers": declinedPhoneNumbers
        ]
        
        do {
            try await eventRef.updateData(updatedEventData)
            
            if let selectedImage {
                let storageLocation = "event_images/\(id).jpg"
                await self.uploadImage(image: selectedImage, storageLocation: storageLocation, referenceLocation: eventRef, fieldName: "eventPic")
            }
            
            print("Event updated successfully!")
            
        } catch {
            print("Error updating event: \(error.localizedDescription)")
            throw error
        }
    }

    
    func deleteEventFromFirestore(id: String) async throws {
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
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
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
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
    
    @MainActor
    func getEventById(id: String) async throws -> EventModel? {
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
        let eventRef = db.collection("events").document(id)
        
        do {
            let snapshot = try await eventRef.getDocument()
            guard let data = snapshot.data() else {
                print("Event with ID \(id) not found")
                return nil
            }
            return EventModel().initFromFirestore(eventData: data)
        } catch {
            print("Error fetching event: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getAllUsers() async throws -> [UserModel] {
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
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
    
    // MARK: - Real-time Listeners
    
    func listenToAllEvents(handler: @escaping (Result<[EventModel], Error>) -> Void) -> ListenerRegistration {
        db.collection("events")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    handler(.failure(error))
                    return
                }
                
                let events = snapshot?.documents.compactMap { document in
                    EventModel().initFromFirestore(eventData: document.data())
                } ?? []
                
                handler(.success(events))
            }
    }
    
    func listenToFriends(userId: String,
                         handler: @escaping (Result<[String], Error>) -> Void) -> ListenerRegistration {
        db.collection("friendships")
            .document(userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    handler(.failure(error))
                    return
                }
                
                let friends = snapshot?.data()?["friends"] as? [String] ?? []
                handler(.success(friends))
            }
    }
    
    func listenToFriendRequests(userId: String,
                                handler: @escaping (Result<[String], Error>) -> Void) -> ListenerRegistration {
        db.collection("friendRequests")
            .document(userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    handler(.failure(error))
                    return
                }
                
                let requests = snapshot?.data()?["requests"] as? [String] ?? []
                handler(.success(requests))
            }
    }
    
    func listenToFriendRequestsSent(userId: String,
                                    handler: @escaping (Result<[String], Error>) -> Void) -> ListenerRegistration {
        db.collection("friendRequestsSent")
            .document(userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    handler(.failure(error))
                    return
                }
                
                let requests = snapshot?.data()?["requests"] as? [String] ?? []
                handler(.success(requests))
            }
    }
    
    func respondInvite(eventId: String, userId: String, action: String) async throws {
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
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
                var attendeesDeclined = eventData["attendeesDeclined"] as? [String] ?? []
                var host = eventData["host"] as? String ?? ""
                
                if action == "reject" || action == "accept" {
                    // Ensure user exists in inviteeAttended list
                    guard let index = attendeesInvited.firstIndex(of: userId) else {
                        print("User not found in inviteeAttended list")
                        return nil
                    }
                    // Remove from invited
                    attendeesInvited.remove(at: index)
                    if action == "accept" {
                        attendeesAccepted.append(userId)
                    } else if action == "reject" {
                        attendeesDeclined.append(userId)
                    }
                } else if action == "acceptDeclined" {
                    // Move user from declined to accepted
                    guard let index = attendeesDeclined.firstIndex(of: userId) else {
                        print("User not found in attendeesDeclined list")
                        return nil
                    }
                    attendeesDeclined.remove(at: index)
                    if !attendeesAccepted.contains(userId) {
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
                        // Move user to declined list when leaving
                        if !attendeesDeclined.contains(userId) {
                            attendeesDeclined.append(userId)
                        }
                    }
                }
                
                // Update Firestore document
                transaction.updateData([
                    "attendeesInvited": attendeesInvited,
                    "attendeesAccepted": attendeesAccepted,
                    "attendeesDeclined": attendeesDeclined,
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
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
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
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
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
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
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
    
    func retrieveFriendRequest(userId: String) async throws -> [String] {
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
        let receiverRef = db.collection("friendRequests").document(userId)
        
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
    
    func retrieveFriendRequestSent(userId: String) async throws -> [String] {
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
        let receiverRef = db.collection("friendRequestsSent").document(userId)
        
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
    
    func retrieveFriends(userId: String) async throws -> [String] {
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
        let receiverRef = db.collection("friendships").document(userId)
        
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
    
    func deleteUserAccount(userId: String, authUID: String) async throws {
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
        let userRef = db.collection("users").document(userId)
        let userFriendRef = db.collection("friendships").document(userId)
        let friendRequestRef = db.collection("friendRequests").document(userId)
        
        do {
            // Delete the user's authentication account
            if let user = Auth.auth().currentUser, user.uid == authUID {
                try await user.delete()
            }
            
            // Fetch all events where the user is an attendee
            let eventSnapshot = try await db.collection("events").whereField("attendeesAccepted", arrayContains: userId).getDocuments()
            for document in eventSnapshot.documents {
                let eventRef = db.collection("events").document(document.documentID)
                try await eventRef.updateData([
                    "attendeesAccepted": FieldValue.arrayRemove([userId])
                ])
            }
            
            let invitedSnapshot = try await db.collection("events").whereField("attendeesInvited", arrayContains: userId).getDocuments()
            for document in invitedSnapshot.documents {
                let eventRef = db.collection("events").document(document.documentID)
                try await eventRef.updateData([
                    "attendeesInvited": FieldValue.arrayRemove([userId])
                ])
            }
            
            let hostingSnapshot = try await db.collection("events").whereField("host", isEqualTo: userId).getDocuments()
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
                        "friends": FieldValue.arrayRemove([userId])
                    ])
                }
            }
            
            // Remove all friend requests **sent** by the user
            let friendRequestsSnapshot = try await db.collection("friendRequests").getDocuments()
            for document in friendRequestsSnapshot.documents {
                let friendRequestRef = db.collection("friendRequests").document(document.documentID)
                if var requests = document.data()["requests"] as? [String], requests.contains(userId) {
                    requests.removeAll { $0 == userId }
                    try await friendRequestRef.updateData(["requests": requests])
                }
            }
            
            // Delete user data from Firestore
            try await userRef.delete()
            try await userFriendRef.delete()
            try await friendRequestRef.delete()
            
            print("User account and associated data deleted successfully.")
        } catch {
            print("Error deleting user data: \(error.localizedDescription)")
            throw error
        }
    }
    
    
    func updateUserFullName(uid: String, fullName: String) async throws {
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
        let userRef = db.collection("users").document(uid)
        
        do {
            try await userRef.updateData(["fullname": fullName])
            print("Full name updated successfully!")
        } catch {
            print("Error updating full name: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateUserUsername(uid: String, username: String) async throws {
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
        let userRef = db.collection("users").document(uid)
        
        do {
            try await userRef.updateData(["username": username])
            print("Username updated successfully!")
        } catch {
            print("Error updating username: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateUserPhoneNumber(uid: String, phoneNumber: String) async throws {
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
        let userRef = db.collection("users").document(uid)
        let phoneE164 = PhoneNumberFormatter.e164(phoneNumber)
        let canonicalPhone = PhoneNumberFormatter.canonical(phoneNumber)
        let storedPhone = phoneE164.isEmpty ? canonicalPhone : phoneE164
        
        do {
            try await userRef.updateData(["phoneNumber": storedPhone])
            print("Phone number updated successfully!")
        } catch {
            print("Error updating phone number: \(error.localizedDescription)")
            throw error
        }
    }
    
    func linkPhoneNumberToUser(uid: String, phoneNumber: String) async throws -> [EventModel] {
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
        // First, update the user's phone number
        try await updateUserPhoneNumber(uid: uid, phoneNumber: phoneNumber)
        
        // Get user information to use for updating events
        let user = try await getUserById(uid)
        let userIdentifier = user.stableIdentifier
        
        // Find all events where this phone number is invited
        let allEvents = try await getAllEvents()
        var updatedEvents: [EventModel] = []
        
        for event in allEvents {
            var eventUpdated = false
            var updatedEvent = event
            
            // Get the actual Firestore document to check rsvps field
            let eventRef = db.collection("events").document(event.id)
            let eventDoc = try await eventRef.getDocument()
            let eventData = eventDoc.data() ?? [:]
            let rsvps = eventData["rsvps"] as? [String: Bool] ?? [:]
            
            // Check invited phone numbers
            if let matchingPhone = event.invitedPhoneNumbers.first(where: { PhoneNumberFormatter.numbersMatch($0, phoneNumber) }) {
                // Remove from phone invitations and add to regular invitations
                updatedEvent.invitedPhoneNumbers.removeAll { PhoneNumberFormatter.numbersMatch($0, phoneNumber) }
                if !updatedEvent.attendeesInvited.contains(userIdentifier) {
                    updatedEvent.attendeesInvited.append(userIdentifier)
                }
                eventUpdated = true
                print("Linked phone \(phoneNumber) to user \(userIdentifier) for event \(event.title) (invited)")
            }
            
            // Check accepted phone numbers
            if let matchingPhone = event.acceptedPhoneNumbers.first(where: { PhoneNumberFormatter.numbersMatch($0, phoneNumber) }) {
                // Remove from phone acceptances and add to regular acceptances
                updatedEvent.acceptedPhoneNumbers.removeAll { PhoneNumberFormatter.numbersMatch($0, phoneNumber) }
                if !updatedEvent.attendeesAccepted.contains(userIdentifier) {
                    updatedEvent.attendeesAccepted.append(userIdentifier)
                }
                eventUpdated = true
                print("Linked phone \(phoneNumber) to user \(userIdentifier) for event \(event.title) (accepted)")
            }
            
            // Check declined phone numbers
            if let matchingPhone = event.declinedPhoneNumbers.first(where: { PhoneNumberFormatter.numbersMatch($0, phoneNumber) }) {
                // Remove from phone declines and add to regular declines
                updatedEvent.declinedPhoneNumbers.removeAll { PhoneNumberFormatter.numbersMatch($0, phoneNumber) }
                if !updatedEvent.attendeesDeclined.contains(userIdentifier) {
                    updatedEvent.attendeesDeclined.append(userIdentifier)
                }
                eventUpdated = true
                print("Linked phone \(phoneNumber) to user \(userIdentifier) for event \(event.title) (declined)")
            }
            
            // Check for phone numbers in rsvps field (legacy support and web app responses)
            for (rsvpPhone, isAccepted) in rsvps {
                if PhoneNumberFormatter.numbersMatch(rsvpPhone, phoneNumber) {
                    if isAccepted {
                        // This phone number has accepted the invitation via rsvps
                        if !updatedEvent.attendeesAccepted.contains(userIdentifier) {
                            updatedEvent.attendeesAccepted.append(userIdentifier)
                        }
                        print("Linked phone \(phoneNumber) to user \(userIdentifier) for event \(event.title) (accepted via rsvps)")
                    } else {
                        // This phone number has declined the invitation via rsvps
                        if !updatedEvent.attendeesDeclined.contains(userIdentifier) {
                            updatedEvent.attendeesDeclined.append(userIdentifier)
                        }
                        print("Linked phone \(phoneNumber) to user \(userIdentifier) for event \(event.title) (declined via rsvps)")
                    }
                    
                    // Remove the rsvp entry since we're converting to user-based invitation
                    var updatedRsvps = rsvps
                    updatedRsvps.removeValue(forKey: rsvpPhone)
                    try await eventRef.updateData(["rsvps": updatedRsvps])
                    eventUpdated = true
                    break
                }
            }
            
            if eventUpdated {
                // Update the event in Firestore
                try await updateEventInFirestore(
                    id: updatedEvent.id,
                    title: updatedEvent.title,
                    location: updatedEvent.location,
                    description: updatedEvent.description,
                    startDateTime: updatedEvent.startDateTime,
                    endDateTime: updatedEvent.endDateTime,
                    noEndTime: updatedEvent.noEndTime,
                    attendeesAccepted: updatedEvent.attendeesAccepted,
                    attendeesInvited: updatedEvent.attendeesInvited,
                    attendeesDeclined: updatedEvent.attendeesDeclined,
                    host: updatedEvent.host,
                    invitedPhoneNumbers: updatedEvent.invitedPhoneNumbers,
                    acceptedPhoneNumbers: updatedEvent.acceptedPhoneNumbers,
                    declinedPhoneNumbers: updatedEvent.declinedPhoneNumbers,
                    selectedImage: nil
                )
                updatedEvents.append(updatedEvent)
            }
        }
        
        print("Successfully linked phone number \(phoneNumber) to user \(userIdentifier). Updated \(updatedEvents.count) events.")
        return updatedEvents
    }
    
    func removeUserProfilePic(uid: String) async throws {
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
        let userRef = db.collection("users").document(uid)
        do {
            try await userRef.updateData(["profilePic": "userDefault"])
            print("Profile picture removed successfully!")
        } catch {
            print("Error removing profile picture: \(error.localizedDescription)")
            throw error
        }
    }
    
    func uploadUserProfilePic(uid: String, image: UIImage) async throws -> String {
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let storageRef = Storage.storage().reference()
        let profilePicRef = storageRef.child("profile_pictures/\(uid).jpg")
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.cacheControl = "no-store, max-age=0"
        metadata.customMetadata = ["updatedAt": "\(timestamp)"]
        
        // Upload the image using async/await pattern
        let _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<StorageMetadata?, Error>) in
            profilePicRef.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: metadata)
                }
            }
        }
        
        // Get the download URL
        let downloadURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            profilePicRef.downloadURL { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let url = url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: NSError(domain: "DownloadError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"]))
                }
            }
        }
        
        var profilePicUrl = downloadURL.absoluteString
        let cacheBustValue = timestamp
        let separator = profilePicUrl.contains("?") ? "&" : "?"
        profilePicUrl += "\(separator)t=\(cacheBustValue)"
        
        // Update Firestore with the new profile picture URL
        let userRef = db.collection("users").document(uid)
        try await userRef.updateData(["profilePic": profilePicUrl])
        
        print("Profile picture uploaded successfully!")
        return profilePicUrl
    }
    
    func uploadImage(image: UIImage, storageLocation: String, referenceLocation: DocumentReference, fieldName: String) async {
        guard let imageData = image.jpegData(compressionQuality: 0.4) else { return }
        let storageRef = Storage.storage().reference()
        let fileRef = storageRef.child(storageLocation)
        
        do {
            // Upload the image using async/await pattern
            let _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<StorageMetadata?, Error>) in
                fileRef.putData(imageData, metadata: nil) { metadata, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: metadata)
                    }
                }
            }
            
            // Get the download URL
            let downloadURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                fileRef.downloadURL { url, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let url = url {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(throwing: NSError(domain: "DownloadError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"]))
                    }
                }
            }
            
            // Save the URL to Firestore
            try await saveImageURLtoFirestore(url: downloadURL.absoluteString, referenceLocation: referenceLocation, fieldName: fieldName)
            
        } catch {
            print("Upload failed: \(error.localizedDescription)")
        }
    }
    
    func saveImageURLtoFirestore(url: String, referenceLocation: DocumentReference, fieldName: String) async throws {
        try await referenceLocation.setData([fieldName: url], merge: true)
        print("Picture updated successfully!")
    }
    
    func isUsernameTaken(username: String) async throws -> Bool {
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
        let usersRef = db.collection("users")
        
        do {
            // Query for users where username field exists and equals the input username
            let query = usersRef.whereField("username", isEqualTo: username)
            let snapshot = try await query.getDocuments()
            
            // Additional check: make sure the found documents actually have a non-empty username
            let validMatches = snapshot.documents.filter { document in
                if let docUsername = document.data()["username"] as? String {
                    return !docUsername.isEmpty && docUsername == username
                }
                return false
            }
            
            let isTaken = !validMatches.isEmpty
            print("Username '\(username)' check: \(isTaken ? "TAKEN" : "AVAILABLE") (found \(validMatches.count) valid matches)")
            return isTaken
        } catch {
            print("Error checking username availability: \(error.localizedDescription)")
            throw error
        }
    }
    
    func isPhoneNumberRegistered(phoneNumber: String) async throws -> Bool {
        // Check network connection before attempting operation
        try ErrorHandler.shared.validateNetworkConnection()
        
        let usersRef = db.collection("users")
        
        do {
            // Normalize the phone number to match stored format
            let canonicalPhone = PhoneNumberFormatter.canonical(phoneNumber)
            
            // Query for users where phoneNumber field matches the canonical phone
            let phoneQuery = usersRef.whereField("phoneNumber", isEqualTo: canonicalPhone)
            let phoneSnapshot = try await phoneQuery.getDocuments()
            
            // Check if we found any valid matches
            let phoneMatches = phoneSnapshot.documents.filter { document in
                if let phone = document.data()["phoneNumber"] as? String {
                    return PhoneNumberFormatter.numbersMatch(phone, canonicalPhone)
                }
                return false
            }
            
            let isRegistered = !phoneMatches.isEmpty
            print("Phone '\(phoneNumber)' (canonical: \(canonicalPhone)) check: \(isRegistered ? "REGISTERED" : "AVAILABLE") (matches: \(phoneMatches.count))")
            return isRegistered
        } catch {
            print("Error checking phone number registration: \(error.localizedDescription)")
            throw error
        }
    }
}
