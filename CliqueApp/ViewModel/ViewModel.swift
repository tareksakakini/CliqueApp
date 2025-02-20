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
    @Published var friendship: [String]
    @Published var friendInviteReceived: [String]
    
    init() {
        self.users = []
        self.events = []
        self.friendship = []
        self.friendInviteReceived = []
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
    
    func getAllEvents() async {
        let firestoreService = DatabaseManager()
        do {
            let fetchedEvents = try await firestoreService.getAllEvents()
            let ordered_fetchedEvents = fetchedEvents.sorted { $0.dateTime < $1.dateTime }
            self.events = ordered_fetchedEvents
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
    
    func getUserByName(name: String) -> UserModel? {
        for user in self.users {
            if user.fullname == name {
                return user
            }
        }
        return nil
    }
    
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
    
    //    func getFriends(username: String) -> [String] {
    //        if let friends = self.friendship[username] {
    //            return friends
    //        }
    //        else {
    //            return []
    //        }
    //    }
    
    //    func getFriendInvites(username: String) -> [String] {
    //        if let invitations = self.friendInviteReceived[username] {
    //            return invitations
    //        }
    //        else {
    //            return []
    //        }
    //    }
    
    func stringMatchUsers(query: String, viewingUser: UserModel, isFriend: Bool = false) -> [UserModel] {
        var to_return: [UserModel] = []
        var names_to_check: [String] = []
        
        if isFriend {
            
            for username in self.friendship {
                if let curr_user = self.getUser(username: username) {
                    names_to_check += [curr_user.fullname]
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
        

        self.friendInviteReceived += [sender]
        
    }
    
    func acceptFriendshipRequest(sender: String, receiver: String) {
        
        
        self.friendInviteReceived.removeAll { $0 == sender }
        self.friendship += [receiver]
    }
    
    func removeFriendship(username1: String, username2: String) {

        self.friendship.removeAll { $0 == username2 }
            
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
