//
//  User.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/23/25.
//

import Foundation

struct EventModel: Hashable {
    var id: String
    var title: String
    var location: String
    var date: String
    var time: String
    var attendeesAccepted: [String]
    var attendeesInvited: [String]
}
