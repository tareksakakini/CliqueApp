//
//  UserViewModel.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/23/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ViewModel: ObservableObject {
    @Published var users: [UserModel]
    @Published var events: [EventModel]
    @Published var friendship: [String]
    @Published var friendInviteReceived: [String]
    @Published var friendInviteSent: [String]
    @Published var eventRefreshTrigger: Bool
    @Published var userProfilePic: UIImage?
    @Published var signedInUser: UserModel?
    
    init() {
        self.users = []
        self.events = []
        self.friendship = []
        self.friendInviteReceived = []
        self.friendInviteSent = []
        self.eventRefreshTrigger = false
        self.userProfilePic = nil
    }
    
    func refreshData(user_email: String) async {
        await self.getAllUsers()
        await self.getAllEvents()
        await self.getUserFriends(user_email: user_email)
        await self.getUserFriendRequests(user_email: user_email)
        await self.getUserFriendRequestsSent(user_email: user_email)
    }
    
    func getUserFriends(user_email: String) async {
        let firestoreService = DatabaseManager()
        do {
            let fetchedRequests = try await firestoreService.retrieveFriends(user_email: user_email)
            self.friendship = fetchedRequests
        } catch {
            print("Failed to fetch events: \(error.localizedDescription)")
        }
    }
    
    func getUserFriendRequests(user_email: String) async {
        let firestoreService = DatabaseManager()
        do {
            let fetchedRequests = try await firestoreService.retrieveFriendRequest(user_email: user_email)
            self.friendInviteReceived = fetchedRequests
        } catch {
            print("Failed to fetch events: \(error.localizedDescription)")
        }
    }
    
    func getUserFriendRequestsSent(user_email: String) async {
        let firestoreService = DatabaseManager()
        do {
            let fetchedRequests = try await firestoreService.retrieveFriendRequestSent(user_email: user_email)
            self.friendInviteSent = fetchedRequests
        } catch {
            print("Failed to fetch events: \(error.localizedDescription)")
        }
    }
    
    func getAllEvents() async {
        let firestoreService = DatabaseManager()
        do {
            let fetchedEvents = try await firestoreService.getAllEvents()
            // Store all events, filtering will be done in the view
            self.events = fetchedEvents.sorted { $0.startDateTime < $1.startDateTime }
            print("Fetched all events")
        } catch {
            print("Failed to fetch events: \(error.localizedDescription)")
        }
    }
    
    func refreshEventById(id: String) async -> EventModel? {
        let firestoreService = DatabaseManager()
        do {
            let refreshedEvent = try await firestoreService.getEventById(id: id)
            if let event = refreshedEvent {
                // Update the event in the local cache
                if let index = self.events.firstIndex(where: { $0.id == id }) {
                    self.events[index] = event
                }
                print("Refreshed event with ID: \(id)")
                return event
            }
        } catch {
            print("Failed to refresh event: \(error.localizedDescription)")
        }
        return nil
    }
    
    func getAllUsers() async {
        let firestoreService = DatabaseManager()
        do {
            let fetchedUsers = try await firestoreService.getAllUsers()
            self.users = fetchedUsers
        } catch {
            print("Failed to fetch events: \(error.localizedDescription)")
        }
    }
    
    func getUser(username: String) -> UserModel? {
        for user in self.users {
            if user.email == username {
                return user
            }
        }
        return nil
    }
    
    func stringMatchUsers(query: String, viewingUser: UserModel, isFriend: Bool = false) -> [UserModel] {
        var to_return: [UserModel] = []
        var users_to_check: [UserModel] = []
        
        if isFriend {
            for username in self.friendship {
                if let curr_user = self.getUser(username: username) {
                    users_to_check += [curr_user]
                }
            }
        }
        else {
            for user in self.users {
                users_to_check += [user]
            }
        }
        
        
        for user in users_to_check {
            if user.fullname.lowercased().contains(query.lowercased()) {
                to_return += [user]
            }
        }
        return to_return
    }
    
    func formatDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        return dateFormatter.string(from: date)
    }
    
    func formatTime(time: Date) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        return timeFormatter.string(from: time)
    }
    
    func deleteEvent(event_id: String) {
        for event in self.events {
            if event.id == event_id {
                self.events.removeAll { $0.id == event_id }
                return
            }
        }
    }
    
    func getSignedInUser() async -> UserModel? {
        let signedInUserUID = await AuthManager.shared.getSignedInUserID()
        if let signedInUserUID = signedInUserUID {
            let firestoreService = DatabaseManager()
            let signedInUser = try? await firestoreService.getUserFromFirestore(uid: signedInUserUID)
            if let user = signedInUser {
                self.signedInUser = user
            }
            return signedInUser
        }
        else {
            return nil
        }
    }
    
    func signUpUserAndAddToFireStore(email: String, password: String, fullname: String, username: String, profilePic: String, gender: String) async -> UserModel? {
        do {
            let signup_user = try await AuthManager.shared.signUp(email: email, password: password)
            let firestoreService = DatabaseManager()
            try await firestoreService.addUserToFirestore(uid: signup_user.uid, email: email, fullname: fullname, username: username, profilePic: "userDefault", gender: gender)
            let user = try await firestoreService.getUserFromFirestore(uid: signup_user.uid)
            
            // Set up OneSignal for the new user
            await setupOneSignalForUser(userID: user.uid)
            
            return user
        } catch {
            print("Sign up failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    func isUsernameTaken(_ username: String) async -> Bool {
        let firestoreService = DatabaseManager()
        do {
            let isTaken = try await firestoreService.isUsernameTaken(username: username)
            return isTaken
        } catch {
            print("Failed to check username availability: \(error.localizedDescription)")
            return true // Return true to be safe in case of error
        }
    }
    
    func signInUser(email: String, password: String) async -> UserModel? {
        do {
            let signedInUser = try await AuthManager.shared.signIn(email: email, password: password)
            let firestoreService = DatabaseManager()
            let user = try await firestoreService.getUserFromFirestore(uid: signedInUser.uid)
            
            print("🔐 User authenticated: \(user.uid)")
            
            // CRITICAL: Clear any existing OneSignal association first
            print("🧹 Clearing any existing OneSignal associations...")
            await clearOneSignalForUser()
            
            // Set up OneSignal for this user
            print("🔗 Setting up OneSignal for new user...")
            await setupOneSignalForUser(userID: user.uid)
            
            // Verify the setup worked
            let verified = await verifyOneSignalState(expectedUserID: user.uid)
            if !verified {
                print("⚠️ WARNING: OneSignal setup verification failed for user \(user.uid)")
            }
            
            print("User signed in: \(user.uid)")
            return user
        } catch {
            print("Sign in failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    func updateOneSignalSubscriptionId(user: UserModel) async {
        // Ensure OneSignal is properly configured for this user first
        if !isOneSignalConfiguredForUser(expectedUserID: user.uid) {
            print("OneSignal not configured for user \(user.uid), setting up...")
            await setupOneSignalForUser(userID: user.uid)
            
            // Wait a bit for OneSignal to process the login
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        if let playerId = await getOneSignalSubscriptionId() {
            print("OneSignal Subscription ID: \(playerId)")
            do {
                let firestoreService = DatabaseManager()
                try await firestoreService.updateUserSubscriptionId(uid: user.uid, subscriptionId: playerId)
                print("Successfully updated subscription ID for user \(user.uid)")
            } catch {
                print("Updating subscription id failed: \(error.localizedDescription)")
            }
        } else {
            print("Failed to retrieve OneSignal Subscription ID for user \(user.uid)")
        }
    }
    
    func acceptButtonPressed(user: UserModel, event: EventModel) async {
        do {
            let databaseManager = DatabaseManager()
            try await databaseManager.respondInvite(eventId: event.id, userId: user.email, action: "accept")
            print("User successfully moved from inviteeAttended to inviteeAccepted!")
            if let host = self.getUser(username: event.host) {
                let notificationText: String = "\(user.fullname) is coming to your event!"
                sendPushNotification(notificationText: notificationText, receiverID: host.subscriptionId)
            }
        } catch {
            print("Failed to update: \(error.localizedDescription)")
        }
    }
    
    func declineButtonPressed(user: UserModel, event: EventModel) async {
        do {
            let databaseManager = DatabaseManager()
            try await databaseManager.respondInvite(eventId: event.id, userId: user.email, action: "reject")
            print("User successfully removed from inviteeAttended!")
            if let host = self.getUser(username: event.host) {
                if event.host != user.email {
                    let notificationText: String = "\(user.fullname) cannot make it to your event."
                    sendPushNotification(notificationText: notificationText, receiverID: host.subscriptionId)
                }
            }
        } catch {
            print("Failed to update: \(error.localizedDescription)")
        }
    }
    
    func leaveButtonPressed(user: UserModel, event: EventModel) async {
        do {
            let databaseManager = DatabaseManager()
            try await databaseManager.respondInvite(eventId: event.id, userId: user.email, action: "leave")
            print("User successfully removed from inviteeAttended!")
            if let host = self.getUser(username: event.host) {
                if event.host != user.email {
                    let notificationText: String = "\(user.fullname) cannot make it anymore to your event."
                    sendPushNotification(notificationText: notificationText, receiverID: host.subscriptionId)
                }
            }
        } catch {
            print("Failed to update: \(error.localizedDescription)")
        }
    }
    
    func createEventButtonPressed(eventID: String, user: UserModel, event: EventModel, selectedImage: UIImage?, isNewEvent: Bool, oldEvent: EventModel) async {
        do {
            let firestoreService = DatabaseManager()
            if isNewEvent {
                try await firestoreService.addEventToFirestore(id: eventID, title: event.title, location: event.location, description: event.description, startDateTime: event.startDateTime, endDateTime: event.endDateTime, noEndTime: event.noEndTime, attendeesAccepted: [], attendeesInvited: event.attendeesInvited, attendeesDeclined: [], host: user.email, invitedPhoneNumbers: event.invitedPhoneNumbers, acceptedPhoneNumbers: [], declinedPhoneNumbers: [], selectedImage: selectedImage)
            } else {
                try await firestoreService.updateEventInFirestore(id: eventID, title: event.title, location: event.location, description: event.description, startDateTime: event.startDateTime, endDateTime: event.endDateTime, noEndTime: event.noEndTime, attendeesAccepted: [], attendeesInvited: event.attendeesInvited, attendeesDeclined: [], host: user.email, invitedPhoneNumbers: event.invitedPhoneNumbers, acceptedPhoneNumbers: [], declinedPhoneNumbers: [], selectedImage: selectedImage)
            }
            
            var newInvitees: [String] = []
            for invitee in event.attendeesInvited {
                if !oldEvent.attendeesInvited.contains(invitee) {
                    newInvitees.append(invitee)
                }
            }
            
            let notificationText: String = "\(user.fullname) just invited you to an event!"
            for invitee in newInvitees {
                if let inviteeFull = self.getUser(username: invitee) {
                    sendPushNotification(notificationText: notificationText, receiverID: inviteeFull.subscriptionId)
                }
            }
        } catch {
            print("Failed to add or update event: \(error.localizedDescription)")
        }
    }
    
    func saveProfilePicture(image: UIImage) async {
        let firestoreService = DatabaseManager()
        let db = Firestore.firestore()
        let userID = Auth.auth().currentUser?.uid ?? UUID().uuidString
        let storageLocation: String = "profile_pictures/\(userID).jpg"
        let referenceLocation: DocumentReference = db.collection("users").document(userID)
        await firestoreService.uploadImage(image: image, storageLocation: storageLocation, referenceLocation: referenceLocation, fieldName: "profilePic")
    }
    
    func loadProfilePic(imageUrl: String) async {
        // Don't attempt to load if URL is empty or the default placeholder
        guard !imageUrl.isEmpty && imageUrl != "userDefault" else { return }
        guard let url = URL(string: imageUrl) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                self.userProfilePic = uiImage
            }
        } catch {
            print("Error loading image: \(error)")
        }
    }

    func calculateDuration(startDateTime: Date, endDateTime: Date) -> (hours: Int, minutes: Int) {
        let calendar = Calendar.current

        // Strip seconds and nanoseconds
        let startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: startDateTime)
        let endComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: endDateTime)

        guard let trimmedStart = calendar.date(from: startComponents),
              let trimmedEnd = calendar.date(from: endComponents) else {
            return (0, 0)
        }

        let interval = trimmedEnd.timeIntervalSince(trimmedStart)
        let totalMinutes = Int(interval) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        return (hours, minutes)
    }
    
    func checkEmailVerificationStatus() async {
        do {
            // Reload the current Firebase Auth user to get latest verification status
            try await Auth.auth().currentUser?.reload()
            
            // Update the signedInUser with latest verification status
            if let currentUser = Auth.auth().currentUser {
                let firestoreService = DatabaseManager()
                let updatedUser = try await firestoreService.getUserFromFirestore(uid: currentUser.uid)
                var userWithVerification = updatedUser
                userWithVerification.isEmailVerified = currentUser.isEmailVerified
                self.signedInUser = userWithVerification
            }
        } catch {
            print("Failed to check email verification status: \(error.localizedDescription)")
        }
    }
    
    func resendVerificationEmail() async -> (success: Bool, errorMessage: String?) {
        do {
            guard let currentUser = Auth.auth().currentUser else {
                print("No current user found - user may not be signed in")
                return (false, "Please sign in again to resend verification email.")
            }
            
            // Check if user is already verified
            try await currentUser.reload()
            if currentUser.isEmailVerified {
                print("User email is already verified")
                return (true, nil)
            }
            
            print("Attempting to send verification email to: \(currentUser.email ?? "unknown")")
            try await currentUser.sendEmailVerification()
            print("Verification email sent successfully to: \(currentUser.email ?? "unknown")")
            return (true, nil)
        } catch let error as NSError {
            print("Failed to resend verification email - Error code: \(error.code)")
            print("Error description: \(error.localizedDescription)")
            print("Error domain: \(error.domain)")
            
            // Check for specific Firebase Auth errors
            if error.domain == "FIRAuthErrorDomain" {
                switch error.code {
                case 17999: // FIRAuthErrorCodeTooManyRequests
                    print("Too many requests - user should wait before trying again")
                    return (false, "Too many requests. Please wait a few minutes before trying again.")
                case 17011: // FIRAuthErrorCodeUserNotFound
                    print("User not found - may need to sign in again")
                    return (false, "User session expired. Please sign in again.")
                case 17020: // FIRAuthErrorCodeNetworkError
                    print("Network error - check internet connection")
                    return (false, "Network error. Please check your internet connection and try again.")
                default:
                    print("Other Firebase Auth error: \(error.code)")
                    return (false, "Unable to send email right now. Please wait a bit and try again.")
                }
            }
            
            // Generic error message for unknown errors
            return (false, "Unable to send email right now. Please wait a bit and try again.")
        }
    }
    
    func signoutButtonPressed() async {
        do {
            print("🚪 Starting sign out process...")
            
            // Clear OneSignal user association before signing out
            print("🧹 Clearing OneSignal associations...")
            await clearOneSignalForUser()
            
            // Verify the clearing worked
            let verified = await verifyOneSignalState(expectedUserID: nil)
            if !verified {
                print("⚠️ WARNING: OneSignal clearing verification failed")
                // Force clear again
                await clearOneSignalForUser()
            }
            
            try Auth.auth().signOut()
            self.signedInUser = nil
            print("✅ User signed out successfully")
        } catch {
            print("❌ Failed to sign out: \(error.localizedDescription)")
        }
    }
    
    func updateUserFullName(fullName: String) async -> (success: Bool, errorMessage: String?) {
        guard let user = signedInUser else {
            return (false, "No user is currently signed in")
        }
        
        do {
            let firestoreService = DatabaseManager()
            try await firestoreService.updateUserFullName(uid: user.uid, fullName: fullName)
            
            // Update the local user object
            DispatchQueue.main.async {
                self.signedInUser?.fullname = fullName
            }
            
            return (true, nil)
        } catch {
            print("Error updating full name: \(error.localizedDescription)")
            return (false, "Failed to update full name. Please try again.")
        }
    }
    
    func updateUserUsername(username: String) async -> (success: Bool, errorMessage: String?) {
        guard let user = signedInUser else {
            return (false, "No user is currently signed in")
        }
        
        do {
            let firestoreService = DatabaseManager()
            try await firestoreService.updateUserUsername(uid: user.uid, username: username)
            
            // Update the local user object
            DispatchQueue.main.async {
                self.signedInUser?.username = username
            }
            return (true, nil)
        } catch {
            print("Error updating username: \(error.localizedDescription)")
            return (false, error.localizedDescription)
        }
    }
    
    func changePassword(currentPassword: String, newPassword: String) async -> (success: Bool, errorMessage: String?) {
        do {
            try await AuthManager.shared.changePassword(currentPassword: currentPassword, newPassword: newPassword)
            return (true, nil)
        } catch {
            print("Error changing password: \(error.localizedDescription)")
            
            // Provide user-friendly error messages
            let errorMessage: String
            if error.localizedDescription.contains("wrong-password") || error.localizedDescription.contains("invalid-credential") {
                errorMessage = "Current password is incorrect. Please try again."
            } else if error.localizedDescription.contains("weak-password") {
                errorMessage = "New password is too weak. Please choose a stronger password."
            } else if error.localizedDescription.contains("requires-recent-login") {
                errorMessage = "For security reasons, please sign out and sign back in, then try changing your password again."
            } else if error.localizedDescription.contains("network") || error.localizedDescription.contains("internet") {
                errorMessage = "Network error. Please check your internet connection and try again."
            } else {
                errorMessage = "Failed to change password. Please try again."
            }
            
            return (false, errorMessage)
        }
    }
    
    func removeUserProfilePic() async -> (success: Bool, errorMessage: String?) {
        guard let user = signedInUser else {
            return (false, "No user is currently signed in")
        }
        do {
            let firestoreService = DatabaseManager()
            try await firestoreService.removeUserProfilePic(uid: user.uid)
            DispatchQueue.main.async {
                self.signedInUser?.profilePic = "userDefault"
            }
            return (true, nil)
        } catch {
            print("Error removing profile picture: \(error.localizedDescription)")
            return (false, error.localizedDescription)
        }
    }

    func uploadUserProfilePic(image: UIImage) async -> (success: Bool, errorMessage: String?, profilePicUrl: String?) {
        guard let user = signedInUser else {
            return (false, "No user is currently signed in", nil)
        }
        
        do {
            let firestoreService = DatabaseManager()
            
            // Upload image and get the new URL
            let newProfilePicUrl = try await firestoreService.uploadUserProfilePic(uid: user.uid, image: image)
            
            // Update local user object
            DispatchQueue.main.async {
                self.signedInUser?.profilePic = newProfilePicUrl
                self.userProfilePic = image
            }
            
            return (true, nil, newProfilePicUrl)
        } catch {
            print("Error uploading profile picture: \(error.localizedDescription)")
            return (false, error.localizedDescription, nil)
        }
    }

}
