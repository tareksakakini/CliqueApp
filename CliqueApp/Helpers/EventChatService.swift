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
            "senderId": sender.uid,
            "senderEmail": sender.uid,
            "senderName": sender.fullname,
            "text": trimmedText,
            "createdAt": timestamp
        ]
        
        try await messageRef.setData(payload)
        try await updateMetadata(for: event, sender: sender, timestamp: timestamp, messageText: trimmedText)
        await notifyParticipantsAboutMessage(event: event, sender: sender, text: trimmedText)
    }
    
    func markChatAsRead(eventId: String, userIdentifier: String) async throws {
        guard !eventId.isEmpty, !userIdentifier.isEmpty else { return }
        
        try await db.runTransaction { [weak self] transaction, _ in
            guard let self = self else { return nil }
            let docRef = self.chatDocument(for: eventId)
            let snapshot = try? transaction.getDocument(docRef)
            var data = snapshot?.data() ?? [:]
            var unreadCounts = data["unreadCounts"] as? [String: Int] ?? [:]
            var readStates = data["readStates"] as? [String: Timestamp] ?? [:]
            
            unreadCounts[userIdentifier] = 0
            readStates[userIdentifier] = Timestamp(date: Date())
            
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
        let latestParticipants = Set(event.chatParticipantUserIds)
        
        try await db.runTransaction { transaction, _ in
            let snapshot = try? transaction.getDocument(docRef)
            var data = snapshot?.data() ?? [:]
            var storedParticipants = Set(data["participants"] as? [String] ?? [])
            storedParticipants.formUnion(latestParticipants)
            storedParticipants.insert(sender.uid)
            
            var unreadCounts = data["unreadCounts"] as? [String: Int] ?? [:]
            var readStates = data["readStates"] as? [String: Timestamp] ?? [:]
            
            for participant in storedParticipants {
                if participant == sender.uid {
                    unreadCounts[participant] = 0
                } else {
                    unreadCounts[participant] = (unreadCounts[participant] ?? 0) + 1
                }
            }
            
            readStates[sender.uid] = timestamp
            
            transaction.setData([
                "eventId": event.id,
                "lastMessage": messageText,
                "lastMessageSender": sender.fullname,
                "lastMessageSenderId": sender.uid,
                "lastMessageSenderEmail": sender.uid,
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
        let recipients = event.chatParticipantUserIds.filter { $0 != sender.uid }
        guard !recipients.isEmpty else { return }
        
        let users = await fetchUsers(byIdentifiers: recipients)
        guard !users.isEmpty else { return }
        
        let snippet = text.count > 120 ? String(text.prefix(117)) + "..." : text
        
        for user in users {
            let inviteView = event.isInviteContext(for: user.uid)
            let preferredTab: NotificationRouter.NotificationTab = inviteView ? .invites : .myEvents
            let route = NotificationRouteBuilder.eventDetail(eventId: event.id,
                                                             inviteView: inviteView,
                                                             preferredTab: preferredTab,
                                                             openChat: true)
            await sendPushNotificationWithBadge(notificationText: "\(sender.fullname): \(snippet)",
                                                receiverUID: user.uid,
                                                route: route,
                                                title: event.title)
        }
    }
    
    private func fetchUsers(byIdentifiers identifiers: [String]) async -> [UserModel] {
        guard !identifiers.isEmpty else { return [] }
        
        var results: [UserModel] = []
        let uniqueIdentifiers = Array(Set(identifiers)).filter { !$0.isEmpty }
        var unresolved = Set(uniqueIdentifiers)
        let chunkSize = 10
        
        // First, try fetching by UID
        for chunkStart in stride(from: 0, to: uniqueIdentifiers.count, by: chunkSize) {
            let chunk = Array(uniqueIdentifiers[chunkStart..<min(chunkStart + chunkSize, uniqueIdentifiers.count)])
            do {
                let snapshot = try await db.collection("users")
                    .whereField("uid", in: chunk)
                    .getDocuments()
                
                let users = snapshot.documents.compactMap { doc -> UserModel? in
                    unresolved.remove(doc.documentID)
                    return UserModel().initFromFirestore(userData: doc.data())
                }
                results.append(contentsOf: users)
            } catch {
                print("Failed to fetch users by UID chunk: \(error.localizedDescription)")
            }
        }
        
        let remainingHandles = Array(unresolved)
        guard !remainingHandles.isEmpty else { return results }
        
        // Fallback: fetch by email/contact handle
        for chunkStart in stride(from: 0, to: remainingHandles.count, by: chunkSize) {
            let chunk = Array(remainingHandles[chunkStart..<min(chunkStart + chunkSize, remainingHandles.count)])
            do {
                let snapshot = try await db.collection("users")
                    .whereField("email", in: chunk)
                    .getDocuments()
                
                let users = snapshot.documents.compactMap { doc in
                    UserModel().initFromFirestore(userData: doc.data())
                }
                results.append(contentsOf: users)
            } catch {
                print("Failed to fetch users by contact handle chunk: \(error.localizedDescription)")
            }
        }
        
        return results
    }
}
