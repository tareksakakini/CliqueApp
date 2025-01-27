//
//  UserViewModel.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/23/25.
//

import Foundation

class ViewModel: ObservableObject {
    let users: [UserModel]
    let events: [EventModel]
    
    init() {
        self.users = UserData.userData
        self.events = UserData.eventData
    }
    
    func isUserPresent(username: String, password: String) -> Bool {
        var userPresent = false
        for user in self.users {
            if user.userName == username && user.password == password {
                userPresent = true
            }
        }
        return userPresent
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
}
