//
//  UserViewModel.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/23/25.
//

import Foundation

class ViewModel: ObservableObject {
    var users: [UserModel]
    var events: [EventModel]
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
}
