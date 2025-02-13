//
//  UserViewModel.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/23/25.
//

import Foundation

@MainActor
class ViewModel: ObservableObject {
    @Published var users: [UserModel]
    @Published var events: [EventModel]
    @Published var friendship: [String: [String]]
    @Published var friendInviteSent: [String: [String]]
    @Published var friendInviteReceived: [String: [String]]
    
    init() {
        self.users = UserData.userData
        self.events = []
        self.friendship = UserData.friendshipData
        self.friendInviteSent = UserData.friendInviteSent
        self.friendInviteReceived = UserData.friendInviteReceived
    }
    
    func getAllEvents() async {
        let firestoreService = DatabaseManager()
        do {
            let fetchedEvents = try await firestoreService.getAllEvents()
            self.events = fetchedEvents
        } catch {
            print("Failed to fetch events: \(error.localizedDescription)")
        }
    }
    
    //    func isUser(username: String, password: String) -> Bool {
    //        for user in self.users {
    //            if user.userName == username && user.password == password {
    //                return true
    //            }
    //        }
    //        return false
    //    }
    
    
    func getEvents(username: String) async throws -> [EventModel] {
        let firestoreService = DatabaseManager()
        do {
            let events = try await firestoreService.getAllEvents()
            return events
        } catch {
            print("Failed to fetch events: \(error.localizedDescription)")
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
    
    func getUserByName(name: String) -> UserModel? {
        for user in self.users {
            if user.fullname == name {
                return user
            }
        }
        return nil
    }
    
    //    func getEvents(username: String) -> [EventModel] {
    //        var eventsForUser: [EventModel] = []
    //        for event in self.events {
    //            if event.attendeesAccepted.contains(username) {
    //                eventsForUser.append(event)
    //            }
    //        }
    //        eventsForUser = eventsForUser.sorted { $0.dateTime < $1.dateTime }
    //        return eventsForUser
    //    }
    
    func getEvent(eventID: String) -> EventModel? {
        for event in self.events {
            if event.id == eventID {
                return event
            }
        }
        return nil
    }
    
    func getInvites(username: String) -> [EventModel] {
        var eventsForUser: [EventModel] = []
        for event in self.events {
            if event.attendeesInvited.contains(username) {
                eventsForUser.append(event)
            }
        }
        eventsForUser = eventsForUser.sorted { $0.dateTime < $1.dateTime }
        return eventsForUser
    }
    
    func getFriends(username: String) -> [String] {
        if let friends = self.friendship[username] {
            return friends
        }
        else {
            return []
        }
    }
    
    func getFriendInvites(username: String) -> [String] {
        if let invitations = self.friendInviteReceived[username] {
            return invitations
        }
        else {
            return []
        }
    }
    
    func stringMatchUsers(query: String, viewingUser: UserModel, isFriend: Bool = false) -> [UserModel] {
        var to_return: [UserModel] = []
        var names_to_check: [String] = []
        
        if isFriend {
            if self.friendship.keys.contains(viewingUser.email) {
                for username in self.friendship[viewingUser.email]! {
                    if let curr_user = self.getUser(username: username) {
                        names_to_check += [curr_user.fullname]
                    }
                }
            }
        }
        else {
            for user in self.users {
                names_to_check += [user.fullname]
            }
        }
        
        
        for name in names_to_check {
            if name.lowercased().contains(query.lowercased()) {
                if let grabbed_user = self.getUserByName(name: name) {
                    to_return += [grabbed_user]
                }
            }
        }
        return to_return
    }
    
    //    func addFriendship(username1: String, username2: String) {
    //        if self.friendship.keys.contains(username1) {
    //            self.friendship[username1]! += [username2]
    //        }
    //        else {
    //            self.friendship[username1] = [username2]
    //        }
    //
    //        if self.friendship.keys.contains(username2) {
    //            self.friendship[username2]! += [username1]
    //        }
    //        else {
    //            self.friendship[username2] = [username1]
    //        }
    //
    //    }
    
    func sendFriendshipRequest(sender: String, receiver: String) {
        
        if self.friendInviteSent.keys.contains(sender) {
            self.friendInviteSent[sender]! += [receiver]
        }
        else {
            self.friendInviteSent[sender] = [receiver]
        }
        
        if self.friendInviteReceived.keys.contains(receiver) {
            self.friendInviteReceived[receiver]! += [sender]
        }
        else {
            self.friendInviteReceived[receiver] = [sender]
        }
    }
    
    func acceptFriendshipRequest(sender: String, receiver: String) {
        
        if self.friendInviteSent.keys.contains(sender) {
            self.friendInviteSent[sender]!.removeAll { $0 == receiver }
        }
        
        if self.friendInviteReceived.keys.contains(receiver) {
            self.friendInviteReceived[receiver]!.removeAll { $0 == sender }
        }
        
        if self.friendship.keys.contains(sender) {
            self.friendship[sender]! += [receiver]
        }
        else {
            self.friendship[sender] = [receiver]
        }
        
        if self.friendship.keys.contains(receiver) {
            self.friendship[receiver]! += [sender]
        }
        else {
            self.friendship[receiver] = [sender]
        }
    }
    
    func removeFriendship(username1: String, username2: String) {
        if self.friendship.keys.contains(username1) {
            if self.friendship[username1]!.contains(username2) {
                self.friendship[username1]!.removeAll { $0 == username2 }
            }
        }
        
        if self.friendship.keys.contains(username2) {
            if self.friendship[username2]!.contains(username1) {
                self.friendship[username2]!.removeAll { $0 == username1 }
            }
        }
    }
    
    func inviteRespond(username: String, event_id: String, accepted: Bool) {
        if let index = self.events.firstIndex(where: { $0.id == event_id }) {
            if accepted {
                self.events[index].attendeesAccepted.append(username)
                self.events[index].attendeesInvited.removeAll { $0 == username }
            } else {
                self.events[index].attendeesInvited.removeAll { $0 == username }
            }
        }
    }
    
    func eventLeave(username: String, event_id: String) {
        if let index = self.events.firstIndex(where: { $0.id == event_id }) {
            self.events[index].attendeesAccepted.removeAll { $0 == username }
        }
    }
    
    func getNextEventID() -> String {
        
        if self.events.isEmpty {
            return "1"
        }
        var IDs: [Int] = []
        for event in self.events {
            IDs.append(Int(event.id)!)
        }
        return String(IDs.max()! + 1)
    }
    
    func createEvent(title: String, location: String, dateTime: Date, user: UserModel, invitees: [String]) {
        
        let nextID = getNextEventID()
        
        let new_event: EventModel = EventModel(id: nextID, title: title, location: location, dateTime: dateTime, attendeesAccepted: [user.email], attendeesInvited: invitees)
        self.events += [new_event]
    }
    
    func addUser(fullname: String, email: String, createdAt: Date) {
        let newUser = UserModel(fullname: fullname, email: email, createdAt: Date())
        self.users += [newUser]
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
    
}
