//
//  EventChatMessage.swift
//  CliqueApp
//
//  Created by Codex on 3/7/25.
//

import Foundation
import FirebaseFirestore

struct EventChatMessage: Identifiable, Hashable {
    let id: String
    let eventId: String
    let senderId: UserID
    let senderHandle: String
    let senderName: String
    let text: String
    let createdAt: Date
    
    init(id: String = UUID().uuidString,
         eventId: String,
         senderId: UserID,
         senderHandle: String,
         senderName: String,
         text: String,
         createdAt: Date = Date()) {
        self.id = id
        self.eventId = eventId
        self.senderId = senderId
        self.senderHandle = senderHandle
        self.senderName = senderName
        self.text = text
        self.createdAt = createdAt
    }
    
    init?(data: [String: Any]) {
        guard
            let id = data["id"] as? String,
            let eventId = data["eventId"] as? String,
            let senderName = data["senderName"] as? String,
            let text = data["text"] as? String
        else {
            return nil
        }
        
        let timestamp = data["createdAt"] as? Timestamp
        let createdAt = timestamp?.dateValue() ?? Date()
        
        self.id = id
        self.eventId = eventId
        self.senderId = data["senderId"] as? String ?? data["senderUID"] as? String ?? data["senderEmail"] as? String ?? ""
        self.senderHandle = data["senderEmail"] as? String ?? ""
        self.senderName = senderName
        self.text = text
        self.createdAt = createdAt
    }
}
