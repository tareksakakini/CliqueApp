//
//  EventChatMetadata.swift
//  CliqueApp
//
//  Created by Codex on 3/7/25.
//

import Foundation
import FirebaseFirestore

struct EventChatMetadata: Equatable {
    let eventId: String
    var lastMessage: String
    var lastMessageSender: String
    var lastMessageSenderEmail: String
    var lastMessageAt: Date?
    var unreadCounts: [String: Int]
    var participants: [String]
    
    init(eventId: String,
         lastMessage: String = "",
         lastMessageSender: String = "",
         lastMessageSenderEmail: String = "",
         lastMessageAt: Date? = nil,
         unreadCounts: [String: Int] = [:],
         participants: [String] = []) {
        self.eventId = eventId
        self.lastMessage = lastMessage
        self.lastMessageSender = lastMessageSender
        self.lastMessageSenderEmail = lastMessageSenderEmail
        self.lastMessageAt = lastMessageAt
        self.unreadCounts = unreadCounts
        self.participants = participants
    }
    
    init(eventId: String, data: [String: Any]) {
        let timestamp = data["lastMessageAt"] as? Timestamp
        self.eventId = eventId
        self.lastMessage = data["lastMessage"] as? String ?? ""
        self.lastMessageSender = data["lastMessageSender"] as? String ?? ""
        self.lastMessageSenderEmail = data["lastMessageSenderEmail"] as? String ?? ""
        self.lastMessageAt = timestamp?.dateValue()
        self.unreadCounts = data["unreadCounts"] as? [String: Int] ?? [:]
        self.participants = data["participants"] as? [String] ?? []
    }
    
    func unreadCount(for email: String) -> Int {
        unreadCounts[email] ?? 0
    }
    
    var hasMessageHistory: Bool {
        !lastMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
