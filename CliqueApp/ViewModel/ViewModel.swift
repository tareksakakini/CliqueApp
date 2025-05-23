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
            let currentDate = Date()
            let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
            let upcomingEvents = fetchedEvents.filter { $0.startDateTime >= oneDayAgo }
            let orderedUpcomingEvents = upcomingEvents.sorted { $0.startDateTime < $1.startDateTime }
            self.events = orderedUpcomingEvents
            print("Fetched")
        } catch {
            print("Failed to fetch events: \(error.localizedDescription)")
        }
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
            return signedInUser
        }
        else {
            return nil
        }
    }
    
    func signUpUserAndAddToFireStore(email: String, password: String, fullname: String, profilePic: String, gender: String) async -> UserModel? {
        do {
            let signup_user = try await AuthManager.shared.signUp(email: email, password: password)
            let firestoreService = DatabaseManager()
            try await firestoreService.addUserToFirestore(uid: signup_user.uid, email: email, fullname: fullname, profilePic: "userDefault", gender: gender)
            let user = try await firestoreService.getUserFromFirestore(uid: signup_user.uid)
            return user
        } catch {
            print("Sign up failed: \(error.localizedDescription)")
            return nil
        }
        
    }
    
    func signInUser(email: String, password: String) async -> UserModel? {
        do {
            let signedInUser = try await AuthManager.shared.signIn(email: email, password: password)
            let firestoreService = DatabaseManager()
            let user = try await firestoreService.getUserFromFirestore(uid: signedInUser.uid)
            print("User signed in: \(user.uid)")
            return user
        } catch {
            print("Sign in failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    func updateOneSignalSubscriptionId(user: UserModel) async {
        if let playerId = await getOneSignalSubscriptionId() {
            print("OneSignal Subscription ID: \(playerId)")
            do {
                let firestoreService = DatabaseManager()
                try await firestoreService.updateUserSubscriptionId(uid: user.uid, subscriptionId: playerId)
            } catch {
                print("Updating subscription id failed: \(error.localizedDescription)")
            }
        } else {
            print("Failed to retrieve OneSignal Subscription ID.")
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
                try await firestoreService.addEventToFirestore(id: eventID, title: event.title, location: event.location, startDateTime: event.startDateTime, endDateTime: event.endDateTime, noEndTime: event.noEndTime, attendeesAccepted: [], attendeesInvited: event.attendeesInvited, host: user.email, invitedPhoneNumbers: event.invitedPhoneNumbers, acceptedPhoneNumbers: [], selectedImage: selectedImage)
            } else {
                try await firestoreService.updateEventInFirestore(id: eventID, title: event.title, location: event.location, startDateTime: event.startDateTime, endDateTime: event.endDateTime, noEndTime: event.noEndTime, attendeesAccepted: [], attendeesInvited: event.attendeesInvited, host: user.email, invitedPhoneNumbers: event.invitedPhoneNumbers, acceptedPhoneNumbers: [], selectedImage: selectedImage)
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


}
