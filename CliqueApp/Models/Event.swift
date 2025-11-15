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
    var description: String = ""
    var startDateTime: Date = {
        // Initialize with current local time converted to UTC-preserving format
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: TimeZone.current, from: now)
        var utcComponents = DateComponents()
        utcComponents.year = components.year
        utcComponents.month = components.month
        utcComponents.day = components.day
        utcComponents.hour = components.hour
        utcComponents.minute = components.minute
        utcComponents.second = components.second
        utcComponents.timeZone = TimeZone(identifier: "UTC")
        
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        return utcCalendar.date(from: utcComponents) ?? Date()
    }()
    var endDateTime: Date = {
        // Initialize with current local time converted to UTC-preserving format
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: TimeZone.current, from: now)
        var utcComponents = DateComponents()
        utcComponents.year = components.year
        utcComponents.month = components.month
        utcComponents.day = components.day
        utcComponents.hour = components.hour
        utcComponents.minute = components.minute
        utcComponents.second = components.second
        utcComponents.timeZone = TimeZone(identifier: "UTC")
        
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        return utcCalendar.date(from: utcComponents) ?? Date()
    }()
    var noEndTime: Bool = false
    /// Stores user IDs (UIDs) for each RSVP bucket.
    var attendeesAccepted: [UserID] = []
    var attendeesInvited: [UserID] = []
    var attendeesDeclined: [UserID] = []
    /// Stores the hosting user's UID (legacy data may still contain emails/usernames).
    var host: UserID = ""
    var eventPic: String = ""
    var invitedPhoneNumbers: [String] = []
    var acceptedPhoneNumbers: [String] = []
    var declinedPhoneNumbers: [String] = []
    
    func initFromFirestore(eventData: [String: Any]) -> EventModel {
        var event = EventModel()
        event.id = eventData["id"] as? String ?? ""
        event.title = eventData["title"] as? String ?? "No Name"
        event.location = eventData["location"] as? String ?? "No Location"
        event.description = eventData["description"] as? String ?? ""
        event.startDateTime = (eventData["startDateTime"] as? Timestamp)?.dateValue() ?? Date()
        event.endDateTime = (eventData["endDateTime"] as? Timestamp)?.dateValue() ?? Date()
        event.noEndTime = eventData["noEndTime"] as? Bool ?? false
        event.attendeesAccepted = eventData["attendeesAccepted"] as? [String] ?? []
        event.attendeesInvited = eventData["attendeesInvited"] as? [String] ?? []
        event.attendeesDeclined = eventData["attendeesDeclined"] as? [String] ?? []
        event.host = eventData["host"] as? String ?? ""
        event.eventPic = eventData["eventPic"] as? String ?? ""
        event.invitedPhoneNumbers = eventData["invitedPhoneNumbers"] as? [String] ?? []
        event.acceptedPhoneNumbers = eventData["acceptedPhoneNumbers"] as? [String] ?? []
        event.declinedPhoneNumbers = eventData["declinedPhoneNumbers"] as? [String] ?? []
        return event
    }
}

extension EventModel {
    /// Returns the unique user IDs for all in-app participants that should be part of the chat.
    var chatParticipantUserIds: [UserID] {
        var participants = Set<UserID>()
        if !host.isEmpty {
            participants.insert(host)
        }
        attendeesAccepted.forEach { identifier in
            if !identifier.isEmpty {
                participants.insert(identifier)
            }
        }
        attendeesInvited.forEach { identifier in
            if !identifier.isEmpty {
                participants.insert(identifier)
            }
        }
        attendeesDeclined.forEach { identifier in
            if !identifier.isEmpty {
                participants.insert(identifier)
            }
        }
        return Array(participants)
    }
    
    /// Indicates whether an email should view the event from the invite tab.
    func isInviteContext(for userId: UserID) -> Bool {
        attendeesInvited.contains(userId) || attendeesDeclined.contains(userId)
    }
}
