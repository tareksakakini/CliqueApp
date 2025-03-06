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
    var dateTime: Date
    var attendeesAccepted: [String]
    var attendeesInvited: [String]
    var host: String
}
