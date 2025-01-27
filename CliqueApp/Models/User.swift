//
//  User.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/23/25.
//

import Foundation

struct UserModel {
    let firstName: String
    let lastName: String
    let userName: String
    let password: String
    let eventsAccepted: [String]
    let eventsInvited: [String]
}

struct EventModel: Hashable {
    let id: String
    let title: String
    let location: String
    let date: String
    let time: String
    let attendeesAccepted: [String]
    let attendeesInvited: [String]
}
