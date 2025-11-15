//
//  EventChatService.swift
//  CliqueApp
//
//  Created by Codex on 3/7/25.
//

import Foundation
import FirebaseFirestore

final class EventChatService {
    static let shared = EventChatService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Listeners
    
    func listenForMetadata(eventId: String,
                           handler: @escaping (Result<EventChatMetadata, Error>) -> Void) -> ListenerRegistration {
        chatDocument(for: eventId).addSnapshotListener { snapshot, error in
            if let error = error {
                handler(.failure(error))
                return
            }
            
            guard let snapshot = snapshot, let data = snapshot.data() else {
                handler(.success(EventChatMetadata(eventId: eventId)))
                return
            }
            
            let metadata = EventChatMetadata(eventId: eventId, data: data)
            handler(.success(metadata))
        }
    }
    
    func listenForMessages(eventId: String,
                           handler: @escaping (Result<[EventChatMessage], Error>) -> Void) -> ListenerRegistration {
        messagesCollection(for: eventId)
            .order(by: "createdAt", descending: false)
            .limit(toLast: 200)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    handler(.failure(error))
                    return
                }
                
                let messages = snapshot?.documents.compactMap { doc in
                    EventChatMessage(data: doc.data())
                } ?? []
                
                handler(.success(messages))
            }
    }
    
    // MARK: - Write Operations
    
    func sendMessage(event: EventModel, sender: UserModel, text: String) async throws {
        try ErrorHandler.shared.validateNetworkConnection()
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        guard !event.id.isEmpty else { throw ErrorHandler.AppError.invalidData }
        
        let messageRef = messagesCollection(for: event.id).document()
        let timestamp = Timestamp(date: Date())
        
        let payload: [String: Any] = [
            "id": messageRef.documentID,
            "eventId": event.id,
            "senderEmail": sender.email,
            "senderName": sender.fullname,
            "text": trimmedText,
            "createdAt": timestamp
        ]
        
        try await messageRef.setData(payload)
        try await updateMetadata(for: event, sender: sender, timestamp: timestamp, messageText: trimmedText)
        await notifyParticipantsAboutMessage(event: event, sender: sender, text: trimmedText)
    }
    
    func markChatAsRead(eventId: String, userEmail: String) async throws {
        guard !eventId.isEmpty else { return }
        
        try await db.runTransaction { [weak self] transaction, _ in
            guard let self = self else { return nil }
            let docRef = self.chatDocument(for: eventId)
            let snapshot = try? transaction.getDocument(docRef)
            var data = snapshot?.data() ?? [:]
            var unreadCounts = data["unreadCounts"] as? [String: Int] ?? [:]
            var readStates = data["readStates"] as? [String: Timestamp] ?? [:]
            
            unreadCounts[userEmail] = 0
            readStates[userEmail] = Timestamp(date: Date())
            
            transaction.setData([
                "unreadCounts": unreadCounts,
                "readStates": readStates
            ], forDocument: docRef, merge: true)
            return nil
        }
    }
    
    // MARK: - Private Helpers
    
    private func chatDocument(for eventId: String) -> DocumentReference {
        db.collection("eventChats").document(eventId)
    }
    
    private func messagesCollection(for eventId: String) -> CollectionReference {
        chatDocument(for: eventId).collection("messages")
    }
    
    private func updateMetadata(for event: EventModel,
                                sender: UserModel,
                                timestamp: Timestamp,
                                messageText: String) async throws {
        let docRef = chatDocument(for: event.id)
        let latestParticipants = Set(event.chatParticipantEmails)
        
        try await db.runTransaction { transaction, _ in
            let snapshot = try? transaction.getDocument(docRef)
            var data = snapshot?.data() ?? [:]
            var storedParticipants = Set(data["participants"] as? [String] ?? [])
            storedParticipants.formUnion(latestParticipants)
            storedParticipants.insert(sender.email)
            
            var unreadCounts = data["unreadCounts"] as? [String: Int] ?? [:]
            var readStates = data["readStates"] as? [String: Timestamp] ?? [:]
            
            for participant in storedParticipants {
                if participant == sender.email {
                    unreadCounts[participant] = 0
                } else {
                    unreadCounts[participant] = (unreadCounts[participant] ?? 0) + 1
                }
            }
            
            readStates[sender.email] = timestamp
            
            transaction.setData([
                "eventId": event.id,
                "lastMessage": messageText,
                "lastMessageSender": sender.fullname,
                "lastMessageSenderEmail": sender.email,
                "lastMessageAt": timestamp,
                "participants": Array(storedParticipants),
                "unreadCounts": unreadCounts,
                "readStates": readStates
            ], forDocument: docRef, merge: true)
            return nil
        }
    }
    
    private func notifyParticipantsAboutMessage(event: EventModel,
                                                sender: UserModel,
                                                text: String) async {
        let recipients = event.chatParticipantEmails.filter { $0 != sender.email }
        guard !recipients.isEmpty else { return }
        
        let users = await fetchUsers(byEmails: recipients)
        guard !users.isEmpty else { return }
        
        let snippet = text.count > 120 ? String(text.prefix(117)) + "..." : text
        
        for user in users {
            let inviteView = event.isInviteContext(for: user.email)
            let preferredTab: NotificationRouter.NotificationTab = inviteView ? .invites : .myEvents
            let route = NotificationRouteBuilder.eventDetail(eventId: event.id,
                                                             inviteView: inviteView,
                                                             preferredTab: preferredTab,
                                                             openChat: true)
            await sendPushNotificationWithBadge(notificationText: "\(sender.fullname): \(snippet)",
                                                receiverUID: user.uid,
                                                receiverEmail: user.email,
                                                route: route,
                                                title: event.title)
        }
    }
    
    private func fetchUsers(byEmails emails: [String]) async -> [UserModel] {
        guard !emails.isEmpty else { return [] }
        
        var results: [UserModel] = []
        let chunkSize = 10
        let uniqueEmails = Array(Set(emails))
        
        for chunkStart in stride(from: 0, to: uniqueEmails.count, by: chunkSize) {
            let chunk = Array(uniqueEmails[chunkStart..<min(chunkStart + chunkSize, uniqueEmails.count)])
            do {
                let snapshot = try await db.collection("users")
                    .whereField("email", in: chunk)
                    .getDocuments()
                
                let users = snapshot.documents.compactMap { doc in
                    UserModel().initFromFirestore(userData: doc.data())
                }
                results.append(contentsOf: users)
            } catch {
                print("Failed to fetch users for chat notification: \(error.localizedDescription)")
            }
        }
        
        return results
    }
}
