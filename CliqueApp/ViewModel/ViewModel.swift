//
//  UserViewModel.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/23/25.
//

import Foundation

class ViewModel: ObservableObject {
    @Published var users: [UserModel]
    @Published var events: [EventModel]
    @Published var friendship: [String: [String]]
    
    init() {
        self.users = UserData.userData
        self.events = UserData.eventData
        self.friendship = UserData.friendshipData
    }
    
    func isUser(username: String, password: String) -> Bool {
        for user in self.users {
            if user.userName == username && user.password == password {
                return true
            }
        }
        return false
    }
    
    func getUser(username: String) -> UserModel? {
        for user in self.users {
            if user.userName == username {
                return user
            }
        }
        return nil
    }
    
    func getEvents(username: String) -> [EventModel] {
        var eventsForUser: [EventModel] = []
        for event in self.events {
            if event.attendeesAccepted.contains(username) {
                eventsForUser.append(event)
            }
        }
        return eventsForUser
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
    
    func stringMatchUsers(query: String) -> [UserModel] {
        var to_return: [UserModel] = []
        for user in self.users {
            if user.userName.contains(query) {
                to_return += [user]
            }
        }
        return to_return
    }
    
    func addFriendship(username1: String, username2: String) {
        if self.friendship.keys.contains(username1) {
            self.friendship[username1]! += [username2]
        }
        else {
            self.friendship[username1]! = [username2]
        }
        
        if self.friendship.keys.contains(username2) {
            self.friendship[username2]! += [username1]
        }
        else {
            self.friendship[username2]! = [username1]
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
    
    func createEvent(title: String, location: String, date: String, time: String, user: UserModel, invitees: [String]) {
        
        let nextID = getNextEventID()
        
        var new_event: EventModel = EventModel(id: nextID, title: title, location: location, date: date, time: time, attendeesAccepted: [user.userName], attendeesInvited: invitees)
        self.events += [new_event]
    }
            
}
