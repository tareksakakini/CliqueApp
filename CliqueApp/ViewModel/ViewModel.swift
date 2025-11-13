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
    @Published var signedInUser: UserModel? {
        didSet {
            guard signedInUser?.email != oldValue?.email else { return }
            
            stopRealtimeListeners()
            
            guard let email = signedInUser?.email, !email.isEmpty else {
                resetUserScopedData()
                return
            }
            
            if oldValue != nil {
                resetUserScopedData()
            }
            
            startRealtimeListeners(for: email)
        }
    }
    
    private var eventsListener: ListenerRegistration?
    private var friendsListener: ListenerRegistration?
    private var friendRequestsListener: ListenerRegistration?
    private var friendRequestsSentListener: ListenerRegistration?
    
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
        // Silent refresh - don't throw errors, just log them
        do {
            try await self.getAllUsers()
        } catch {
            print("Failed to refresh users: \(error.localizedDescription)")
        }
        
        do {
            try await self.getAllEvents()
        } catch {
            print("Failed to refresh events: \(error.localizedDescription)")
        }
        
        do {
            try await self.getUserFriends(user_email: user_email)
        } catch {
            print("Failed to refresh friends: \(error.localizedDescription)")
        }
        
        do {
            try await self.getUserFriendRequests(user_email: user_email)
        } catch {
            print("Failed to refresh friend requests: \(error.localizedDescription)")
        }
        
        do {
            try await self.getUserFriendRequestsSent(user_email: user_email)
        } catch {
            print("Failed to refresh sent friend requests: \(error.localizedDescription)")
        }
        
        // Update badge after refreshing data
        await BadgeManager.shared.updateBadge(for: user_email)
    }
    
    func getUserFriends(user_email: String) async throws {
        let firestoreService = DatabaseManager()
        do {
            let fetchedRequests = try await firestoreService.retrieveFriends(user_email: user_email)
            self.friendship = fetchedRequests
        } catch {
            print("Failed to fetch friends: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getUserFriendRequests(user_email: String) async throws {
        let firestoreService = DatabaseManager()
        do {
            let fetchedRequests = try await firestoreService.retrieveFriendRequest(user_email: user_email)
            self.friendInviteReceived = fetchedRequests
        } catch {
            print("Failed to fetch friend requests: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getUserFriendRequestsSent(user_email: String) async throws {
        let firestoreService = DatabaseManager()
        do {
            let fetchedRequests = try await firestoreService.retrieveFriendRequestSent(user_email: user_email)
            self.friendInviteSent = fetchedRequests
        } catch {
            print("Failed to fetch sent friend requests: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getAllEvents() async throws {
        let firestoreService = DatabaseManager()
        do {
            let fetchedEvents = try await firestoreService.getAllEvents()
            // Store all events, filtering will be done in the view
            self.events = fetchedEvents.sorted { $0.startDateTime < $1.startDateTime }
            print("Fetched all events")
        } catch {
            print("Failed to fetch events: \(error.localizedDescription)")
            throw error
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
    
    func getAllUsers() async throws {
        let firestoreService = DatabaseManager()
        do {
            let fetchedUsers = try await firestoreService.getAllUsers()
            self.users = fetchedUsers
        } catch {
            print("Failed to fetch users: \(error.localizedDescription)")
            throw error
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
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        return dateFormatter.string(from: date)
    }
    
    func formatTime(time: Date) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        timeFormatter.timeZone = TimeZone(identifier: "UTC")
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
    
    func deleteEventWithNotification(event: EventModel, user: UserModel) async throws {
        let firestoreService = DatabaseManager()
        
        // Send notifications to all invitees before deleting
        await sendEventDeletionNotifications(user: user, event: event)
        
        // Delete the event from Firestore
        try await firestoreService.deleteEventFromFirestore(id: event.id)
        
        // Remove from local cache
        self.events.removeAll { $0.id == event.id }
        
        print("Event '\(event.title)' deleted successfully with notifications sent")
    }
    
    private func sendEventDeletionNotifications(user: UserModel, event: EventModel) async {
        // Get all invitees (accepted, invited, and declined)
        let allInvitees = Set(event.attendeesAccepted + event.attendeesInvited + event.attendeesDeclined)
        
        let notificationText = "\(user.fullname) deleted the event \(event.title)"
        
        // Send notifications to all invitees except the host
        for inviteeEmail in allInvitees {
            if inviteeEmail != user.email { // Don't notify the host
                if let invitee = self.getUser(username: inviteeEmail) {
                    let inviteView = event.attendeesInvited.contains(inviteeEmail) || event.attendeesDeclined.contains(inviteeEmail)
                    let preferredTab: NotificationRouter.NotificationTab = inviteView ? .invites : .myEvents
                    let route = NotificationRouteBuilder.tab(preferredTab)
                    await sendPushNotificationWithBadge(notificationText: notificationText,
                                                        receiverID: invitee.subscriptionId,
                                                        receiverEmail: invitee.email,
                                                        route: route)
                    print("Sent event deletion notification to: \(inviteeEmail)")
                }
            }
        }
        
        print("Event deletion notifications sent to \(allInvitees.count) invitee(s)")
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
    
    func signUpUserAndAddToFireStore(phoneNumber: String, password: String, verificationID: String, smsCode: String, fullname: String, username: String, profilePic: String, gender: String) async throws -> UserModel? {
        do {
            try ErrorHandler.shared.validateNetworkConnection()
            
            let canonicalPhone = PhoneNumberFormatter.canonical(phoneNumber)
            let normalizedPhone = canonicalPhone.isEmpty ? phoneNumber : canonicalPhone
            let signupUser = try await AuthManager.shared.signUp(phoneNumber: normalizedPhone, password: password, verificationID: verificationID, smsCode: smsCode)
            let firestoreService = DatabaseManager()
            try await firestoreService.addUserToFirestore(uid: signupUser.uid, contactHandle: normalizedPhone, fullname: fullname, username: username, profilePic: profilePic, gender: gender, phoneNumber: normalizedPhone)
            let user = try await firestoreService.getUserFromFirestore(uid: signupUser.uid)
            
            self.signedInUser = user
            
            await setupOneSignalForUser(userID: user.uid)
            _ = await linkPhoneNumberToUser(phoneNumber: normalizedPhone)
            
            return user
        } catch {
            print("Sign up failed: \(error.localizedDescription)")
            throw error
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
    
    func requestPhoneVerificationCode(phoneNumber: String) async throws -> String {
        try ErrorHandler.shared.validateNetworkConnection()
        return try await AuthManager.shared.sendVerificationCode(to: phoneNumber)
    }
    
    func resetPasswordWithPhone(newPassword: String, verificationID: String, smsCode: String) async -> (success: Bool, errorMessage: String?) {
        do {
            try ErrorHandler.shared.validateNetworkConnection()
            try await AuthManager.shared.resetPassword(newPassword: newPassword, verificationID: verificationID, smsCode: smsCode)
            return (true, nil)
        } catch {
            let message = ErrorHandler.shared.handleError(error, operation: "Reset password")
            return (false, message)
        }
    }
    
    func signInUser(phoneNumber: String, password: String) async throws -> UserModel? {
        do {
            // Check network connection before attempting operation
            try ErrorHandler.shared.validateNetworkConnection()
            
            let canonicalPhone = PhoneNumberFormatter.canonical(phoneNumber)
            let normalizedPhone = canonicalPhone.isEmpty ? phoneNumber : canonicalPhone
            let signedInUser = try await AuthManager.shared.signIn(phoneNumber: normalizedPhone, password: password)
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
            throw error
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
    
    func acceptButtonPressed(user: UserModel, event: EventModel) async throws {
        do {
            let databaseManager = DatabaseManager()
            try await databaseManager.respondInvite(eventId: event.id, userId: user.email, action: "accept")
            print("User successfully moved from inviteeAttended to inviteeAccepted!")
            
            // Update badge for the user who accepted
            await BadgeManager.shared.updateBadge(for: user.email)
            
            if let host = self.getUser(username: event.host), !event.id.isEmpty {
                let notificationText: String = "\(user.fullname) is coming to your event!"
                let route = NotificationRouteBuilder.eventDetail(eventId: event.id,
                                                                 inviteView: false,
                                                                 preferredTab: .myEvents)
                await sendPushNotificationWithBadge(notificationText: notificationText,
                                                    receiverID: host.subscriptionId,
                                                    receiverEmail: host.email,
                                                    route: route)
            }
        } catch {
            print("Failed to accept invite: \(error.localizedDescription)")
            throw error
        }
    }
    
    func declineButtonPressed(user: UserModel, event: EventModel) async throws {
        do {
            let databaseManager = DatabaseManager()
            try await databaseManager.respondInvite(eventId: event.id, userId: user.email, action: "reject")
            print("User successfully removed from inviteeAttended!")
            
            // Update badge for the user who declined
            await BadgeManager.shared.updateBadge(for: user.email)
            
            if let host = self.getUser(username: event.host), !event.id.isEmpty {
                if event.host != user.email {
                    let notificationText: String = "\(user.fullname) cannot make it to your event."
                    let route = NotificationRouteBuilder.eventDetail(eventId: event.id,
                                                                     inviteView: false,
                                                                     preferredTab: .myEvents)
                    await sendPushNotificationWithBadge(notificationText: notificationText,
                                                        receiverID: host.subscriptionId,
                                                        receiverEmail: host.email,
                                                        route: route)
                }
            }
        } catch {
            print("Failed to decline invite: \(error.localizedDescription)")
            throw error
        }
    }
    
    func leaveButtonPressed(user: UserModel, event: EventModel) async throws {
        do {
            let databaseManager = DatabaseManager()
            try await databaseManager.respondInvite(eventId: event.id, userId: user.email, action: "leave")
            print("User successfully removed from inviteeAttended!")
            
            // Update badge for the user who left
            await BadgeManager.shared.updateBadge(for: user.email)
            
            if let host = self.getUser(username: event.host), !event.id.isEmpty {
                if event.host != user.email {
                    let notificationText: String = "\(user.fullname) cannot make it anymore to your event."
                    let route = NotificationRouteBuilder.eventDetail(eventId: event.id,
                                                                     inviteView: false,
                                                                     preferredTab: .myEvents)
                    await sendPushNotificationWithBadge(notificationText: notificationText,
                                                        receiverID: host.subscriptionId,
                                                        receiverEmail: host.email,
                                                        route: route)
                }
            }
        } catch {
            print("Failed to leave event: \(error.localizedDescription)")
            throw error
        }
    }
    
    func createEventButtonPressed(eventID: String, user: UserModel, event: EventModel, selectedImage: UIImage?, isNewEvent: Bool, oldEvent: EventModel) async throws {
        do {
            let firestoreService = DatabaseManager()
            if isNewEvent {
                try await firestoreService.addEventToFirestore(
                    id: eventID,
                    title: event.title,
                    location: event.location,
                    description: event.description,
                    startDateTime: event.startDateTime,
                    endDateTime: event.endDateTime,
                    noEndTime: event.noEndTime,
                    attendeesAccepted: event.attendeesAccepted,
                    attendeesInvited: event.attendeesInvited,
                    attendeesDeclined: event.attendeesDeclined,
                    host: user.email,
                    invitedPhoneNumbers: event.invitedPhoneNumbers,
                    acceptedPhoneNumbers: event.acceptedPhoneNumbers,
                    declinedPhoneNumbers: event.declinedPhoneNumbers,
                    selectedImage: selectedImage
                )
            } else {
                try await firestoreService.updateEventInFirestore(
                    id: eventID,
                    title: event.title,
                    location: event.location,
                    description: event.description,
                    startDateTime: event.startDateTime,
                    endDateTime: event.endDateTime,
                    noEndTime: event.noEndTime,
                    attendeesAccepted: event.attendeesAccepted,
                    attendeesInvited: event.attendeesInvited,
                    attendeesDeclined: event.attendeesDeclined,
                    host: user.email,
                    invitedPhoneNumbers: event.invitedPhoneNumbers,
                    acceptedPhoneNumbers: event.acceptedPhoneNumbers,
                    declinedPhoneNumbers: event.declinedPhoneNumbers,
                    selectedImage: selectedImage
                )
            }
            
            // Handle new invitees
            var newInvitees: [String] = []
            for invitee in event.attendeesInvited {
                if !oldEvent.attendeesInvited.contains(invitee) {
                    newInvitees.append(invitee)
                }
            }
            
            let invitationNotificationText: String = "\(user.fullname) just invited you to an event!"
            for invitee in newInvitees {
                if let inviteeFull = self.getUser(username: invitee) {
                    let resolvedEventId = event.id.isEmpty ? eventID : event.id
                    let route = resolvedEventId.isEmpty ? nil :
                        NotificationRouteBuilder.eventDetail(eventId: resolvedEventId,
                                                              inviteView: true,
                                                              preferredTab: .invites)
                    await sendPushNotificationWithBadge(notificationText: invitationNotificationText,
                                                        receiverID: inviteeFull.subscriptionId,
                                                        receiverEmail: inviteeFull.email,
                                                        route: route)
                }
            }
            
            // Handle event updates for existing invitees
            if !isNewEvent {
                await sendEventUpdateNotifications(user: user, oldEvent: oldEvent, newEvent: event)
            }
        } catch {
            print("Failed to create/update event: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Event Update Notifications
    
    private func sendEventUpdateNotifications(user: UserModel, oldEvent: EventModel, newEvent: EventModel) async {
        // Collect all changes
        var changes: [String] = []
        
        // Check for title change
        if oldEvent.title != newEvent.title {
            changes.append("title")
        }
        
        // Check for location change
        if oldEvent.location != newEvent.location {
            changes.append("location")
        }
        
        // Check for description change
        if oldEvent.description != newEvent.description {
            changes.append("description")
        }
        
        // Check for start date/time change
        if oldEvent.startDateTime != newEvent.startDateTime {
            changes.append("start time")
        }
        
        // Check for end date/time change
        if oldEvent.endDateTime != newEvent.endDateTime {
            changes.append("end time")
        }
        
        // If no relevant changes, don't send notifications
        if changes.isEmpty {
            print("No relevant event changes detected, skipping update notifications")
            return
        }
        
        // Create notification message
        let notificationText = createEventUpdateNotificationText(hostName: user.fullname, oldEventTitle: oldEvent.title, newEventTitle: newEvent.title, changes: changes)
        
        // Get all invitees (accepted, invited, and declined)
        let allInvitees = Set(oldEvent.attendeesAccepted + oldEvent.attendeesInvited + oldEvent.attendeesDeclined)
        
        // Send notifications to all invitees except the host
        for inviteeEmail in allInvitees {
            if inviteeEmail != user.email { // Don't notify the host
                if let invitee = self.getUser(username: inviteeEmail) {
                    let inviteView = newEvent.attendeesInvited.contains(inviteeEmail) || newEvent.attendeesDeclined.contains(inviteeEmail)
                    let preferredTab: NotificationRouter.NotificationTab = inviteView ? .invites : .myEvents
                    let route = newEvent.id.isEmpty ? nil :
                        NotificationRouteBuilder.eventDetail(eventId: newEvent.id,
                                                              inviteView: inviteView,
                                                              preferredTab: preferredTab)
                    await sendPushNotificationWithBadge(notificationText: notificationText,
                                                        receiverID: invitee.subscriptionId,
                                                        receiverEmail: invitee.email,
                                                        route: route)
                    print("Sent event update notification to: \(inviteeEmail)")
                }
            }
        }
        
        print("Event update notifications sent to \(allInvitees.count - 1) invitees for \(changes.count) change(s)")
    }
    
    private func createEventUpdateNotificationText(hostName: String, oldEventTitle: String, newEventTitle: String, changes: [String]) -> String {
        let titleChanged = changes.contains("title")
        let displayTitle = oldEventTitle // Always use old title so users know which event
        
        if changes.count == 1 {
            if titleChanged {
                return "\(hostName) changed the title of \(oldEventTitle) (now \(newEventTitle))"
            } else {
                return "\(hostName) changed the \(changes[0]) of \(displayTitle)"
            }
        } else if changes.count == 2 {
            if titleChanged {
                // When title changed along with one other thing
                let otherChange = changes.first(where: { $0 != "title" }) ?? ""
                return "\(hostName) changed the title and \(otherChange) of \(oldEventTitle) (now \(newEventTitle))"
            } else {
                return "\(hostName) changed the \(changes[0]) and \(changes[1]) of \(displayTitle)"
            }
        } else {
            // For 3+ changes
            if titleChanged {
                return "\(hostName) changed the title and other details of \(oldEventTitle) (now \(newEventTitle))"
            } else {
                return "\(hostName) changed multiple details of \(displayTitle)"
            }
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
    
    func loadProfilePic(imageUrl: String) async throws {
        // Don't attempt to load if URL is empty or the default placeholder
        guard !imageUrl.isEmpty && imageUrl != "userDefault" else { return }
        guard let url = URL(string: imageUrl) else { return }
        
        do {
            // Check network connection before attempting operation
            try ErrorHandler.shared.validateNetworkConnection()
            
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                self.userProfilePic = uiImage
            }
        } catch {
            print("Error loading image: \(error)")
            throw error
        }
    }
    
    func linkPhoneNumberToUser(phoneNumber: String) async -> (success: Bool, linkedEventsCount: Int, errorMessage: String?) {
        guard let user = signedInUser else {
            return (false, 0, "No user is currently signed in")
        }
        let canonicalPhone = PhoneNumberFormatter.canonical(phoneNumber)
        let phoneToLink = canonicalPhone.isEmpty ? phoneNumber : canonicalPhone
        
        do {
            let firestoreService = DatabaseManager()
            let linkedEvents = try await firestoreService.linkPhoneNumberToUser(uid: user.uid, phoneNumber: phoneToLink)
            
            // Update the local user object
            DispatchQueue.main.async {
                self.signedInUser?.phoneNumber = phoneToLink
            }
            
            // Refresh events to show updated information
            try await getAllEvents()
            
            return (true, linkedEvents.count, nil)
        } catch {
            print("Error linking phone number: \(error.localizedDescription)")
            return (false, 0, "Failed to link phone number. Please try again.")
        }
    }

    func calculateDuration(startDateTime: Date, endDateTime: Date) -> (days: Int, hours: Int, minutes: Int) {
        let calendar = Calendar.current

        // Strip seconds and nanoseconds
        let startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: startDateTime)
        let endComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: endDateTime)

        guard let trimmedStart = calendar.date(from: startComponents),
              let trimmedEnd = calendar.date(from: endComponents) else {
            return (0, 0, 0)
        }

        let interval = trimmedEnd.timeIntervalSince(trimmedStart)
        let totalMinutes = Int(interval) / 60
        let totalHours = totalMinutes / 60
        let days = totalHours / 24
        let hours = totalHours % 24
        let minutes = totalMinutes % 60

        return (days, hours, minutes)
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
    
    // MARK: - Real-time listeners
    
    private func startRealtimeListeners(for userEmail: String) {
        guard !userEmail.isEmpty else { return }
        
        let firestoreService = DatabaseManager()
        
        eventsListener = firestoreService.listenToAllEvents { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                switch result {
                case .success(let events):
                    self.events = events.sorted { $0.startDateTime < $1.startDateTime }
                case .failure(let error):
                    print("Failed to listen for events: \(error.localizedDescription)")
                }
            }
        }
        
        friendsListener = firestoreService.listenToFriends(userEmail: userEmail) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                switch result {
                case .success(let friends):
                    self.friendship = friends
                case .failure(let error):
                    print("Failed to listen for friends: \(error.localizedDescription)")
                }
            }
        }
        
        friendRequestsListener = firestoreService.listenToFriendRequests(userEmail: userEmail) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                switch result {
                case .success(let requests):
                    self.friendInviteReceived = requests
                case .failure(let error):
                    print("Failed to listen for friend requests: \(error.localizedDescription)")
                }
            }
        }
        
        friendRequestsSentListener = firestoreService.listenToFriendRequestsSent(userEmail: userEmail) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                switch result {
                case .success(let requests):
                    self.friendInviteSent = requests
                case .failure(let error):
                    print("Failed to listen for sent friend requests: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func stopRealtimeListeners() {
        eventsListener?.remove()
        eventsListener = nil
        
        friendsListener?.remove()
        friendsListener = nil
        
        friendRequestsListener?.remove()
        friendRequestsListener = nil
        
        friendRequestsSentListener?.remove()
        friendRequestsSentListener = nil
    }
    
    private func resetUserScopedData() {
        events = []
        friendship = []
        friendInviteReceived = []
        friendInviteSent = []
    }
}
