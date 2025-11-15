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
    var lastMessageSenderId: UserID
    var lastMessageSenderHandle: String
    var lastMessageAt: Date?
    var unreadCounts: [String: Int]
    var participants: [UserID]
    
    init(eventId: String,
         lastMessage: String = "",
         lastMessageSender: String = "",
         lastMessageSenderId: UserID = "",
         lastMessageSenderHandle: String = "",
         lastMessageAt: Date? = nil,
         unreadCounts: [String: Int] = [:],
         participants: [UserID] = []) {
        self.eventId = eventId
        self.lastMessage = lastMessage
        self.lastMessageSender = lastMessageSender
        self.lastMessageSenderId = lastMessageSenderId
        self.lastMessageSenderHandle = lastMessageSenderHandle
        self.lastMessageAt = lastMessageAt
        self.unreadCounts = unreadCounts
        self.participants = participants
    }
    
    init(eventId: String, data: [String: Any]) {
        let timestamp = data["lastMessageAt"] as? Timestamp
        self.eventId = eventId
        self.lastMessage = data["lastMessage"] as? String ?? ""
        self.lastMessageSender = data["lastMessageSender"] as? String ?? ""
        self.lastMessageSenderId = data["lastMessageSenderId"] as? String
            ?? data["lastMessageSenderUID"] as? String
            ?? data["lastMessageSenderEmail"] as? String
            ?? ""
        self.lastMessageSenderHandle = data["lastMessageSenderEmail"] as? String ?? ""
        self.lastMessageAt = timestamp?.dateValue()
        self.unreadCounts = data["unreadCounts"] as? [String: Int] ?? [:]
        self.participants = data["participants"] as? [String] ?? []
    }
    
    func unreadCount(for identifier: String) -> Int {
        if let direct = unreadCounts[identifier] {
            return direct
        }
        if let fallback = unreadCounts.first(where: { key, _ in
            key.caseInsensitiveCompare(identifier) == .orderedSame
        }) {
            return fallback.value
        }
        return 0
    }
    
    var hasMessageHistory: Bool {
        !lastMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
