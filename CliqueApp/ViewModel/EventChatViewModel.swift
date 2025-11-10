//
//  EventChatViewModel.swift
//  CliqueApp
//
//  Created by Codex on 3/7/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore

@MainActor
final class EventChatViewModel: ObservableObject {
    @Published private(set) var messages: [EventChatMessage] = []
    @Published private(set) var summary: EventChatMetadata
    @Published var composerText: String = ""
    @Published var isSending: Bool = false
    @Published var isLoadingMessages: Bool = false
    @Published var chatError: AlertConfig?
    
    private let service = EventChatService.shared
    private var metadataListener: ListenerRegistration?
    private var messageListener: ListenerRegistration?
    
    private(set) var event: EventModel
    let currentUser: UserModel
    
    init(event: EventModel, currentUser: UserModel) {
        self.event = event
        self.currentUser = currentUser
        self.summary = EventChatMetadata(eventId: event.id)
        startSummaryListener()
    }
    
    // MARK: - Public API
    
    var unreadCountForCurrentUser: Int {
        summary.unreadCount(for: currentUser.email)
    }
    
    var eventTitle: String {
        event.title
    }
    
    func updateEvent(_ updatedEvent: EventModel) {
        guard updatedEvent.id == event.id else { return }
        event = updatedEvent
    }
    
    func startSummaryListener() {
        guard metadataListener == nil else { return }
        guard !event.id.isEmpty else { return }
        
        metadataListener = service.listenForMetadata(eventId: event.id) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let metadata):
                    self?.summary = metadata
                case .failure(let error):
                    self?.chatError = AlertConfig(message: ErrorHandler.shared.handleError(error, operation: "Load chat preview"))
                }
            }
        }
    }
    
    func stopSummaryListener() {
        metadataListener?.remove()
        metadataListener = nil
    }
    
    func startMessagesListener() {
        guard messageListener == nil else { return }
        guard !event.id.isEmpty else { return }
        
        isLoadingMessages = true
        messageListener = service.listenForMessages(eventId: event.id) { [weak self] result in
            Task { @MainActor in
                self?.isLoadingMessages = false
                switch result {
                case .success(let messages):
                    self?.messages = messages
                case .failure(let error):
                    self?.chatError = AlertConfig(message: ErrorHandler.shared.handleError(error, operation: "Load chat messages"))
                }
            }
        }
    }
    
    func stopMessagesListener() {
        messageListener?.remove()
        messageListener = nil
    }
    
    func sendCurrentMessage() {
        let trimmed = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !isSending else { return }
        
        let messageText = trimmed
        isSending = true
        composerText = ""
        
        Task {
            do {
                try await service.sendMessage(event: event, sender: currentUser, text: messageText)
            } catch {
                await MainActor.run {
                    composerText = messageText
                    chatError = AlertConfig(message: ErrorHandler.shared.handleError(error, operation: "Send message"))
                }
            }
            await MainActor.run {
                isSending = false
            }
        }
    }
    
    func markChatAsRead() {
        Task {
            do {
                try await service.markChatAsRead(eventId: event.id, userEmail: currentUser.email)
            } catch {
                await MainActor.run {
                    chatError = AlertConfig(message: ErrorHandler.shared.handleError(error, operation: "Refresh unread count"))
                }
            }
        }
    }
    
    func isCurrentUser(_ message: EventChatMessage) -> Bool {
        message.senderEmail == currentUser.email
    }
}
