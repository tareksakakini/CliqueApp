//
//  EventChatActivityTracker.swift
//  CliqueApp
//
//  Tracks whether the user currently has an event chat screen open so we can
//  avoid showing redundant foreground notifications for the same conversation.
//

import Foundation

final class EventChatActivityTracker {
    static let shared = EventChatActivityTracker()
    
    private let queue = DispatchQueue(label: "CliqueApp.EventChatActivityTracker")
    private var activeEventId: String?
    
    private init() {}
    
    func enterChat(eventId: String) {
        guard !eventId.isEmpty else { return }
        queue.sync {
            self.activeEventId = eventId
        }
    }
    
    func leaveChat(eventId: String) {
        queue.sync {
            if eventId.isEmpty || self.activeEventId == eventId {
                self.activeEventId = nil
            }
        }
    }
    
    func isChatOpen(for eventId: String) -> Bool {
        guard !eventId.isEmpty else { return false }
        return queue.sync {
            self.activeEventId == eventId
        }
    }
}
