//
//  User.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/23/25.
//

import Foundation
import FirebaseCore

struct EventModel: Hashable {
    var id: String = ""
    var title: String = ""
    var location: String = ""
    var dateTime: Date = Date()
    var attendeesAccepted: [String] = []
    var attendeesInvited: [String] = []
    var host: String = ""
    var hours: Int = 0
    var minutes: Int = 0
    
    func initFromFirestore(eventData: [String: Any]) -> EventModel {
        var event = EventModel()
        event.id = eventData["id"] as? String ?? ""
        event.title = eventData["title"] as? String ?? "No Name"
        event.location = eventData["location"] as? String ?? "No Location"
        event.dateTime = (eventData["dateTime"] as? Timestamp)?.dateValue() ?? Date()
        event.attendeesAccepted = eventData["attendeesAccepted"] as? [String] ?? []
        event.attendeesInvited = eventData["attendeesInvited"] as? [String] ?? []
        event.host = eventData["host"] as? String ?? ""
        event.hours = eventData["hours"] as? Int ?? 0
        event.minutes = eventData["minutes"] as? Int ?? 0
        return event
    }
}
