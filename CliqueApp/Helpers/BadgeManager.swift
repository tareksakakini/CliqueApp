//
//  BadgeManager.swift
//  CliqueApp
//
//  Manages app icon badge counts for event invites and friend requests
//

import Foundation
import UIKit
import FirebaseFirestore

@MainActor
class BadgeManager {
    static let shared = BadgeManager()
    
    private init() {}
    
    private struct BadgeUserContext {
        let uid: String
        let canonicalPhone: String
    }
    
    // MARK: - Public Methods
    
    /// Updates the app badge with the total count of unanswered invites and friend requests
    func updateBadge(for identifier: String) async {
        guard let context = await resolveUserContext(for: identifier) else {
            print("⚠️ Unable to resolve user context for badge update (\(identifier))")
            return
        }
        let count = await calculateBadgeCount(for: context)
        await setBadgeCount(count)
    }
    
    /// Manually set the badge count
    func setBadgeCount(_ count: Int) async {
        await MainActor.run {
            UIApplication.shared.applicationIconBadgeNumber = count
            print("📛 Badge count updated to: \(count)")
        }
    }
    
    /// Clear the badge
    func clearBadge() async {
        await setBadgeCount(0)
    }
    
    // MARK: - Badge Calculation
    
    /// Calculates the total badge count for a user
    func calculateBadgeCount(for identifier: String) async -> Int {
        guard let context = await resolveUserContext(for: identifier) else {
            print("⚠️ Unable to resolve user context for badge calculation (\(identifier))")
            return 0
        }
        return await calculateBadgeCount(for: context)
    }
    
    private func calculateBadgeCount(for context: BadgeUserContext) async -> Int {
        let eventInvitesCount = await getUnansweredEventInvitesCount(for: context)
        let friendRequestsCount = await getFriendRequestsCount(for: context.uid)
        let total = eventInvitesCount + friendRequestsCount
        
        print("📊 Badge count breakdown for \(context.uid):")
        print("  - Event invites: \(eventInvitesCount)")
        print("  - Friend requests: \(friendRequestsCount)")
        print("  - Total: \(total)")
        
        return total
    }
    
    /// Gets the count of unanswered event invitations for a user
    /// Only counts upcoming events (not past events)
    private func getUnansweredEventInvitesCount(for context: BadgeUserContext) async -> Int {
        do {
            let snapshots = try await fetchInvitedEventSnapshots(for: context)
            
            // Filter to only count upcoming events (not past)
            let now = Date().toUTCPreservingWallClock()
            let upcomingInvites = snapshots.filter { document in
                let data = document.data()
                guard let startDateTime = (data["startDateTime"] as? Timestamp)?.dateValue() else {
                    return false
                }
                return startDateTime >= now
            }
            
            let count = upcomingInvites.count
            print("📅 Upcoming event invites for \(context.uid): \(count) (filtered from \(snapshots.count) total)")
            
            return count
        } catch {
            print("❌ Error fetching event invites count: \(error.localizedDescription)")
            return 0
        }
    }
    
    /// Gets the count of pending friend requests for a user
    private func getFriendRequestsCount(for userId: String) async -> Int {
        let db = Firestore.firestore()
        
        do {
            let snapshot = try await db.collection("friendRequests")
                .document(userId)
                .getDocument()
            
            let requests = snapshot.data()?["requests"] as? [String] ?? []
            return requests.count
        } catch {
            print("❌ Error fetching friend requests count: \(error.localizedDescription)")
            return 0
        }
    }
    
    private func resolveUserContext(for identifier: String) async -> BadgeUserContext? {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        let db = Firestore.firestore()
        
        do {
            // Attempt to fetch by UID (document ID)
            let directDoc = try await db.collection("users").document(trimmed).getDocument()
            if let data = directDoc.data() {
                let rawPhone = data["phoneNumber"] as? String ?? ""
                let canonicalPhone = PhoneNumberFormatter.canonical(rawPhone)
                return BadgeUserContext(uid: directDoc.documentID,
                                        canonicalPhone: canonicalPhone)
            }
            
            // Fallback: look up by auth UID
            let snapshot = try await db.collection("users")
                .whereField("authUID", isEqualTo: trimmed)
                .limit(to: 1)
                .getDocuments()
            
            if let doc = snapshot.documents.first {
                let rawPhone = doc.data()["phoneNumber"] as? String ?? ""
                let canonicalPhone = PhoneNumberFormatter.canonical(rawPhone)
                return BadgeUserContext(uid: doc.documentID,
                                        canonicalPhone: canonicalPhone)
            }
        } catch {
            print("❌ Error resolving user context for \(identifier): \(error.localizedDescription)")
        }
        
        return nil
    }
    
    private func fetchInvitedEventSnapshots(for context: BadgeUserContext) async throws -> [QueryDocumentSnapshot] {
        let db = Firestore.firestore()
        var documents: [QueryDocumentSnapshot] = []
        var seen = Set<String>()
        
        let primarySnapshot = try await db.collection("events")
            .whereField("attendeesInvited", arrayContains: context.uid)
            .getDocuments()
        for doc in primarySnapshot.documents where seen.insert(doc.documentID).inserted {
            documents.append(doc)
        }
        
        let phone = context.canonicalPhone
        if !phone.isEmpty {
            let phoneSnapshot = try await db.collection("events")
                .whereField("invitedPhoneNumbers", arrayContains: phone)
                .getDocuments()
            for doc in phoneSnapshot.documents where seen.insert(doc.documentID).inserted {
                documents.append(doc)
            }
        }
        
        return documents
    }
    
    // MARK: - Helper Methods for Push Notifications
    
    /// Gets badge data to include in push notifications
    /// Returns a dictionary with badge count and breakdown
    func getBadgeDataForNotification(receiverIdentifier: String) async -> [String: Any] {
        guard let context = await resolveUserContext(for: receiverIdentifier) else {
            return ["badge": 0, "receiverId": receiverIdentifier]
        }
        
        let badgeCount = await calculateBadgeCount(for: context)
        
        return [
            "badge": badgeCount,
            "receiverId": context.uid
        ]
    }
    
    // MARK: - Debugging Methods
    
    /// Detailed debugging information about badge count
    func debugBadgeCount(for identifier: String) async -> String {
        guard let context = await resolveUserContext(for: identifier) else {
            return "Unable to resolve user for identifier: \(identifier)"
        }
        let db = Firestore.firestore()
        var debugInfo = "🔍 Badge Debug for: \(context.uid)\n"
        debugInfo += "================================\n\n"
        
        // Check event invites
        do {
            let eventSnapshots = try await fetchInvitedEventSnapshots(for: context)
            
            let now = Date().toUTCPreservingWallClock()
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            
            debugInfo += "📧 EVENT INVITES:\n"
            debugInfo += "Total in database: \(eventSnapshots.count)\n\n"
            
            for (index, doc) in eventSnapshots.enumerated() {
                let data = doc.data()
                let title = data["title"] as? String ?? "Unknown"
                let startDate = (data["startDateTime"] as? Timestamp)?.dateValue() ?? Date()
                let isPast = startDate < now
                
                debugInfo += "  \(index + 1). \(title)\n"
                debugInfo += "     Start: \(dateFormatter.string(from: startDate))\n"
                debugInfo += "     Status: \(isPast ? "❌ PAST (not counted)" : "✅ UPCOMING (counted)")\n\n"
            }
            
            let upcomingCount = eventSnapshots.filter { doc in
                let data = doc.data()
                guard let startDateTime = (data["startDateTime"] as? Timestamp)?.dateValue() else {
                    return false
                }
                return startDateTime >= now
            }.count
            
            debugInfo += "➡️ Upcoming event invites: \(upcomingCount)\n\n"
        } catch {
            debugInfo += "❌ Error fetching events: \(error.localizedDescription)\n\n"
        }
        
        // Check friend requests
        do {
            let friendReqSnapshot = try await db.collection("friendRequests")
                .document(context.uid)
                .getDocument()
            
            let requests = friendReqSnapshot.data()?["requests"] as? [String] ?? []
            
            debugInfo += "👥 FRIEND REQUESTS:\n"
            debugInfo += "Total pending: \(requests.count)\n"
            for (index, requester) in requests.enumerated() {
                debugInfo += "  \(index + 1). From: \(requester)\n"
            }
            debugInfo += "\n"
        } catch {
            debugInfo += "❌ Error fetching friend requests: \(error.localizedDescription)\n\n"
        }
        
        // Total badge count
        let totalBadge = await calculateBadgeCount(for: context)
        debugInfo += "================================\n"
        debugInfo += "🎯 TOTAL BADGE COUNT: \(totalBadge)\n"
        
        return debugInfo
    }
}

// MARK: - Database Observer

extension BadgeManager {
    /// Sets up real-time listeners for badge updates (optional, for when app is active)
    func startObservingBadgeUpdates(for identifier: String) {
        Task {
            guard let context = await resolveUserContext(for: identifier) else { return }
            attachBadgeObservers(for: context)
        }
    }
    
    private func attachBadgeObservers(for context: BadgeUserContext) {
        let db = Firestore.firestore()
        
        // Listen to events where user is invited
        db.collection("events")
            .whereField("attendeesInvited", arrayContains: context.uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, error == nil else { return }
                Task {
                    await self.updateBadge(for: context.uid)
                }
            }
        
        if !context.canonicalPhone.isEmpty {
            db.collection("events")
                .whereField("invitedPhoneNumbers", arrayContains: context.canonicalPhone)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self, error == nil else { return }
                    Task {
                        await self.updateBadge(for: context.uid)
                    }
                }
        }
        
        // Listen to friend requests
        db.collection("friendRequests")
            .document(context.uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, error == nil else { return }
                Task {
                    await self.updateBadge(for: context.uid)
                }
            }
    }
}
