//
//  EventChatUnreadStore.swift
//  CliqueApp
//
//  Created by Codex on 3/9/25.
//

import Foundation
import FirebaseFirestore

/// Keeps a lightweight cache of chat metadata for events and exposes per-user unread counts.
final class EventChatUnreadStore: ObservableObject {
    @Published private(set) var metadataByEvent: [String: EventChatMetadata] = [:]
    
    private let service = EventChatService.shared
    private var listeners: [String: ListenerRegistration] = [:]
    private let accessQueue = DispatchQueue(label: "CliqueApp.EventChatUnreadStore")
    
    func startListening(for eventId: String) {
        guard !eventId.isEmpty else { return }
        
        accessQueue.sync {
            guard listeners[eventId] == nil else { return }
            
            let listener = service.listenForMetadata(eventId: eventId) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let metadata):
                        self?.metadataByEvent[eventId] = metadata
                    case .failure:
                        // Reset to an empty metadata snapshot so counts disappear gracefully.
                        self?.metadataByEvent[eventId] = EventChatMetadata(eventId: eventId)
                    }
                }
            }
            
            listeners[eventId] = listener
        }
    }
    
    func stopListening(for eventId: String) {
        guard !eventId.isEmpty else { return }
        
        accessQueue.sync {
            listeners[eventId]?.remove()
            listeners[eventId] = nil
            metadataByEvent.removeValue(forKey: eventId)
        }
    }
    
    func unreadCount(for eventId: String, userEmail: String) -> Int {
        guard !eventId.isEmpty else { return 0 }
        return metadataByEvent[eventId]?.unreadCount(for: userEmail) ?? 0
    }
    
    deinit {
        accessQueue.sync {
            listeners.values.forEach { $0.remove() }
            listeners.removeAll()
        }
    }
}
