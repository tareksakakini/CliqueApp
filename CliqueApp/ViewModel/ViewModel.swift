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
            guard signedInUser?.uid != oldValue?.uid else { return }
            
            stopRealtimeListeners()
            
            guard let userId = signedInUser?.uid, !userId.isEmpty else {
                resetUserScopedData()
                return
            }
            
            if oldValue != nil {
                resetUserScopedData()
            }
            
            startRealtimeListeners(for: userId)
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
    
    func refreshData(userId: String) async {
        // Guard against empty identifier to prevent Firestore errors
        guard !userId.isEmpty else {
            print("❌ Cannot refresh data: userId is empty")
            return
        }
        
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
            try await self.getUserFriends(userId: userId)
        } catch {
            print("Failed to refresh friends: \(error.localizedDescription)")
        }
        
        do {
            try await self.getUserFriendRequests(userId: userId)
        } catch {
            print("Failed to refresh friend requests: \(error.localizedDescription)")
        }
        
        do {
            try await self.getUserFriendRequestsSent(userId: userId)
        } catch {
            print("Failed to refresh sent friend requests: \(error.localizedDescription)")
        }
        
        // Update badge after refreshing data
        await BadgeManager.shared.updateBadge(for: userId)
    }
    
    func getUserFriends(userId: String) async throws {
        let firestoreService = DatabaseManager()
        do {
            let fetchedRequests = try await firestoreService.retrieveFriends(userId: userId)
            self.friendship = fetchedRequests
        } catch {
            print("Failed to fetch friends: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getUserFriendRequests(userId: String) async throws {
        let firestoreService = DatabaseManager()
        do {
            let fetchedRequests = try await firestoreService.retrieveFriendRequest(userId: userId)
            self.friendInviteReceived = fetchedRequests
        } catch {
            print("Failed to fetch friend requests: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getUserFriendRequestsSent(userId: String) async throws {
        let firestoreService = DatabaseManager()
        do {
            let fetchedRequests = try await firestoreService.retrieveFriendRequestSent(userId: userId)
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
    
    func getUser(by identifier: String) -> UserModel? {
        guard !identifier.isEmpty else { return nil }
        
        if let match = users.first(where: { $0.matchesIdentifier(identifier) }) {
            return match
        }
        
        let normalized = identifier.lowercased()
        return users.first { $0.username.lowercased() == normalized }
    }
    
    func stringMatchUsers(query: String, viewingUser: UserModel, isFriend: Bool = false) -> [UserModel] {
        var to_return: [UserModel] = []
        var users_to_check: [UserModel] = []
        
        if isFriend {
            for username in self.friendship {
                if let curr_user = self.getUser(by: username) {
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
        for inviteeId in allInvitees {
            if inviteeId != user.uid { // Don't notify the host
                if let invitee = self.getUser(by: inviteeId) {
                    let inviteView = event.attendeesInvited.contains(inviteeId) || event.attendeesDeclined.contains(inviteeId)
                    let preferredTab: NotificationRouter.NotificationTab = inviteView ? .invites : .myEvents
                    let route = NotificationRouteBuilder.tab(preferredTab)
                    await sendPushNotificationWithBadge(notificationText: notificationText,
                                                        receiverUID: invitee.uid,
                                                        route: route)
                    print("Sent event deletion notification to: \(inviteeId)")
                }
            }
        }
        
        print("Event deletion notifications sent to \(allInvitees.count) invitee(s)")
    }
    
    func getSignedInUser() async -> UserModel? {
        guard let authUID = await AuthManager.shared.getSignedInUserID() else {
            return nil
        }
        
        let firestoreService = DatabaseManager()
        do {
            let user = try await firestoreService.getUserByAuthUID(authUID)
            self.signedInUser = user
            return user
        } catch {
            print("Failed to fetch signed in user: \(error.localizedDescription)")
            return nil
        }
    }
    
    func signUpUserAndAddToFireStore(phoneNumber: String, verificationID: String, smsCode: String, fullname: String, username: String, profilePic: String, gender: String) async throws -> UserModel? {
        do {
            try ErrorHandler.shared.validateNetworkConnection()
            
            let canonicalPhone = PhoneNumberFormatter.canonical(phoneNumber)
            let e164Phone = PhoneNumberFormatter.e164(phoneNumber)
            let normalizedPhone = canonicalPhone.isEmpty ? phoneNumber : canonicalPhone
            let storedPhone = e164Phone.isEmpty ? normalizedPhone : e164Phone
            let signupUser = try await AuthManager.shared.signUp(phoneNumber: normalizedPhone, verificationID: verificationID, smsCode: smsCode)
            let firestoreService = DatabaseManager()
            let userId = UUID().uuidString
            try await firestoreService.addUserToFirestore(userId: userId,
                                                          authUID: signupUser.uid,
                                                          fullname: fullname,
                                                          username: username,
                                                          profilePic: profilePic,
                                                          gender: gender,
                                                          phoneNumber: storedPhone)
            let user = try await firestoreService.getUserById(userId)
            
            self.signedInUser = user
            
            // Run OneSignal setup and phone linking in parallel for faster completion
            async let oneSignalSetup: Void = setupOneSignalForUser(userID: user.uid)
            async let phoneLink: (success: Bool, linkedEventsCount: Int, errorMessage: String?) = linkPhoneNumberToUser(phoneNumber: storedPhone)
            
            // Wait for both operations to complete
            _ = await oneSignalSetup
            _ = await phoneLink
            
            return user
        } catch {
            print("Sign up failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func completeUserProfile(phoneNumber: String, fullname: String, username: String, profilePic: String, gender: String) async throws -> UserModel? {
        do {
            try ErrorHandler.shared.validateNetworkConnection()
            
            // Get the currently authenticated user
            guard let currentUser = await AuthManager.shared.getSignedInUserID() else {
                throw ErrorHandler.AppError.authenticationFailed("No authenticated user found")
            }
            
            let canonicalPhone = PhoneNumberFormatter.canonical(phoneNumber)
            let e164Phone = PhoneNumberFormatter.e164(phoneNumber)
            let normalizedPhone = canonicalPhone.isEmpty ? phoneNumber : canonicalPhone
            let storedPhone = e164Phone.isEmpty ? normalizedPhone : e164Phone
            
            // Validate that phone number is not empty
            guard !normalizedPhone.isEmpty else {
                print("❌ Phone number is empty in completeUserProfile")
                throw ErrorHandler.AppError.authenticationFailed("Phone number cannot be empty")
            }
            
            print("🔐 Creating user profile for phone: \(normalizedPhone), uid: \(currentUser)")
            
            // Add user info to Firestore
            let firestoreService = DatabaseManager()
            let userId = UUID().uuidString
            try await firestoreService.addUserToFirestore(userId: userId,
                                                          authUID: currentUser,
                                                          fullname: fullname,
                                                          username: username,
                                                          profilePic: profilePic,
                                                          gender: gender,
                                                          phoneNumber: storedPhone)
            
            print("✅ User document created in Firestore")
            
            // Fetch the user back to verify it was created
            let user = try await firestoreService.getUserById(userId)
            
            // Critical validation: ensure the user has a valid identifier
            guard !user.uid.isEmpty else {
                print("❌ CRITICAL: User fetched from Firestore has empty userId field")
                throw ErrorHandler.AppError.authenticationFailed("User data is incomplete - user ID field is empty")
            }
            
            print("✅ User fetched from Firestore - uid: \(user.uid)")
            
            self.signedInUser = user
            
            // Set up OneSignal and link phone number to existing event invitations
            // Run these in parallel since they don't depend on each other
            async let oneSignalSetup: Void = setupOneSignalForUser(userID: user.uid)
            async let phoneLink: (success: Bool, linkedEventsCount: Int, errorMessage: String?) = linkPhoneNumberToUser(phoneNumber: storedPhone)
            
            // Wait for both operations to complete
            _ = await oneSignalSetup
            _ = await phoneLink
            
            return user
        } catch {
            print("❌ Complete profile failed: \(error.localizedDescription)")
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
    
    func isPhoneNumberRegistered(_ phoneNumber: String) async -> Bool {
        let firestoreService = DatabaseManager()
        do {
            let isRegistered = try await firestoreService.isPhoneNumberRegistered(phoneNumber: phoneNumber)
            return isRegistered
        } catch {
            print("Failed to check phone number registration: \(error.localizedDescription)")
            return false // Return false to allow the flow to continue in case of error
        }
    }
    
    func requestPhoneVerificationCode(phoneNumber: String) async throws -> String {
        try ErrorHandler.shared.validateNetworkConnection()
        return try await AuthManager.shared.sendVerificationCode(to: phoneNumber)
    }
    
    func signInUser(phoneNumber: String, verificationID: String, smsCode: String) async throws -> UserModel? {
        do {
            // Check network connection before attempting operation
            try ErrorHandler.shared.validateNetworkConnection()
            
            let canonicalPhone = PhoneNumberFormatter.canonical(phoneNumber)
            let normalizedPhone = canonicalPhone.isEmpty ? phoneNumber : canonicalPhone
            let signedInUser = try await AuthManager.shared.signIn(phoneNumber: normalizedPhone,
                                                                   verificationID: verificationID,
                                                                   smsCode: smsCode)
            let firestoreService = DatabaseManager()
            // Fetch by authUID because Firestore documents use a UUID as their primary key
            let user = try await firestoreService.getUserByAuthUID(signedInUser.uid)
            
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
    
    
    func acceptButtonPressed(user: UserModel, event: EventModel) async throws {
        do {
            let databaseManager = DatabaseManager()
            try await databaseManager.respondInvite(eventId: event.id, userId: user.uid, action: "accept")
            print("User successfully moved from inviteeAttended to inviteeAccepted!")
            
            // Update badge for the user who accepted
            await BadgeManager.shared.updateBadge(for: user.uid)
            
            if let host = self.getUser(by: event.host), !event.id.isEmpty {
                let notificationText: String = "\(user.fullname) is coming to your event!"
                let route = NotificationRouteBuilder.eventDetail(eventId: event.id,
                                                                 inviteView: false,
                                                                 preferredTab: .myEvents)
                await sendPushNotificationWithBadge(notificationText: notificationText,
                                                    receiverUID: host.uid,
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
            try await databaseManager.respondInvite(eventId: event.id, userId: user.uid, action: "reject")
            print("User successfully removed from inviteeAttended!")
            
            // Update badge for the user who declined
            await BadgeManager.shared.updateBadge(for: user.uid)
            
            if let host = self.getUser(by: event.host), !event.id.isEmpty {
                if event.host != user.uid {
                    let notificationText: String = "\(user.fullname) cannot make it to your event."
                    let route = NotificationRouteBuilder.eventDetail(eventId: event.id,
                                                                     inviteView: false,
                                                                     preferredTab: .myEvents)
                    await sendPushNotificationWithBadge(notificationText: notificationText,
                                                        receiverUID: host.uid,
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
            try await databaseManager.respondInvite(eventId: event.id, userId: user.uid, action: "leave")
            print("User successfully removed from inviteeAttended!")
            
            // Update badge for the user who left
            await BadgeManager.shared.updateBadge(for: user.uid)
            
            if let host = self.getUser(by: event.host), !event.id.isEmpty {
                if event.host != user.uid {
                    let notificationText: String = "\(user.fullname) cannot make it anymore to your event."
                    let route = NotificationRouteBuilder.eventDetail(eventId: event.id,
                                                                     inviteView: false,
                                                                     preferredTab: .myEvents)
                    await sendPushNotificationWithBadge(notificationText: notificationText,
                                                        receiverUID: host.uid,
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
                    host: user.uid,
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
                    host: user.uid,
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
                if let inviteeFull = self.getUser(by: invitee) {
                    let resolvedEventId = event.id.isEmpty ? eventID : event.id
                    let route = resolvedEventId.isEmpty ? nil :
                        NotificationRouteBuilder.eventDetail(eventId: resolvedEventId,
                                                              inviteView: true,
                                                              preferredTab: .invites)
                    await sendPushNotificationWithBadge(notificationText: invitationNotificationText,
                                                        receiverUID: inviteeFull.uid,
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
        for inviteeId in allInvitees {
            if inviteeId != user.uid { // Don't notify the host
                if let invitee = self.getUser(by: inviteeId) {
                    let inviteView = newEvent.attendeesInvited.contains(inviteeId) || newEvent.attendeesDeclined.contains(inviteeId)
                    let preferredTab: NotificationRouter.NotificationTab = inviteView ? .invites : .myEvents
                    let route = newEvent.id.isEmpty ? nil :
                        NotificationRouteBuilder.eventDetail(eventId: newEvent.id,
                                                              inviteView: inviteView,
                                                              preferredTab: preferredTab)
                    await sendPushNotificationWithBadge(notificationText: notificationText,
                                                        receiverUID: invitee.uid,
                                                        route: route)
                    print("Sent event update notification to: \(inviteeId)")
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
        let e164Phone = PhoneNumberFormatter.e164(phoneNumber)
        let phoneToLink = e164Phone.isEmpty ? (canonicalPhone.isEmpty ? phoneNumber : canonicalPhone) : e164Phone
        
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
    
    private func startRealtimeListeners(for userId: String) {
        guard !userId.isEmpty else { return }
        
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
        
        friendsListener = firestoreService.listenToFriends(userId: userId) { [weak self] result in
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
        
        friendRequestsListener = firestoreService.listenToFriendRequests(userId: userId) { [weak self] result in
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
        
        friendRequestsSentListener = firestoreService.listenToFriendRequestsSent(userId: userId) { [weak self] result in
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
