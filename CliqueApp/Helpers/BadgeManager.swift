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
    
    // MARK: - Public Methods
    
    /// Updates the app badge with the total count of unanswered invites and friend requests
    func updateBadge(for userEmail: String) async {
        let count = await calculateBadgeCount(for: userEmail)
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
    func calculateBadgeCount(for userEmail: String) async -> Int {
        let eventInvitesCount = await getUnansweredEventInvitesCount(for: userEmail)
        let friendRequestsCount = await getFriendRequestsCount(for: userEmail)
        let total = eventInvitesCount + friendRequestsCount
        
        print("📊 Badge count breakdown for \(userEmail):")
        print("  - Event invites: \(eventInvitesCount)")
        print("  - Friend requests: \(friendRequestsCount)")
        print("  - Total: \(total)")
        
        return total
    }
    
    /// Gets the count of unanswered event invitations for a user
    /// Only counts upcoming events (not past events)
    private func getUnansweredEventInvitesCount(for userEmail: String) async -> Int {
        let db = Firestore.firestore()
        
        do {
            // Query events where the user is in the attendeesInvited array
            let snapshot = try await db.collection("events")
                .whereField("attendeesInvited", arrayContains: userEmail)
                .getDocuments()
            
            // Filter to only count upcoming events (not past)
            let now = Date()
            let upcomingInvites = snapshot.documents.filter { document in
                guard let data = document.data() as? [String: Any],
                      let startDateTime = (data["startDateTime"] as? Timestamp)?.dateValue() else {
                    return false
                }
                return startDateTime >= now
            }
            
            let count = upcomingInvites.count
            print("📅 Upcoming event invites for \(userEmail): \(count) (filtered from \(snapshot.documents.count) total)")
            
            return count
        } catch {
            print("❌ Error fetching event invites count: \(error.localizedDescription)")
            return 0
        }
    }
    
    /// Gets the count of pending friend requests for a user
    private func getFriendRequestsCount(for userEmail: String) async -> Int {
        let db = Firestore.firestore()
        
        do {
            let snapshot = try await db.collection("friendRequests")
                .document(userEmail)
                .getDocument()
            
            let requests = snapshot.data()?["requests"] as? [String] ?? []
            return requests.count
        } catch {
            print("❌ Error fetching friend requests count: \(error.localizedDescription)")
            return 0
        }
    }
    
    // MARK: - Helper Methods for Push Notifications
    
    /// Gets badge data to include in push notifications
    /// Returns a dictionary with badge count and breakdown
    func getBadgeDataForNotification(receiverEmail: String) async -> [String: Any] {
        let badgeCount = await calculateBadgeCount(for: receiverEmail)
        
        return [
            "badge": badgeCount,
            "receiverEmail": receiverEmail
        ]
    }
    
    // MARK: - Debugging Methods
    
    /// Detailed debugging information about badge count
    func debugBadgeCount(for userEmail: String) async -> String {
        let db = Firestore.firestore()
        var debugInfo = "🔍 Badge Debug for: \(userEmail)\n"
        debugInfo += "================================\n\n"
        
        // Check event invites
        do {
            let eventSnapshot = try await db.collection("events")
                .whereField("attendeesInvited", arrayContains: userEmail)
                .getDocuments()
            
            let now = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            
            debugInfo += "📧 EVENT INVITES:\n"
            debugInfo += "Total in database: \(eventSnapshot.documents.count)\n\n"
            
            for (index, doc) in eventSnapshot.documents.enumerated() {
                let data = doc.data()
                let title = data["title"] as? String ?? "Unknown"
                let startDate = (data["startDateTime"] as? Timestamp)?.dateValue() ?? Date()
                let isPast = startDate < now
                
                debugInfo += "  \(index + 1). \(title)\n"
                debugInfo += "     Start: \(dateFormatter.string(from: startDate))\n"
                debugInfo += "     Status: \(isPast ? "❌ PAST (not counted)" : "✅ UPCOMING (counted)")\n\n"
            }
            
            let upcomingCount = eventSnapshot.documents.filter { doc in
                guard let data = doc.data() as? [String: Any],
                      let startDateTime = (data["startDateTime"] as? Timestamp)?.dateValue() else {
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
                .document(userEmail)
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
        let totalBadge = await calculateBadgeCount(for: userEmail)
        debugInfo += "================================\n"
        debugInfo += "🎯 TOTAL BADGE COUNT: \(totalBadge)\n"
        
        return debugInfo
    }
}

// MARK: - Database Observer

extension BadgeManager {
    /// Sets up real-time listeners for badge updates (optional, for when app is active)
    func startObservingBadgeUpdates(for userEmail: String) {
        let db = Firestore.firestore()
        
        // Listen to events where user is invited
        db.collection("events")
            .whereField("attendeesInvited", arrayContains: userEmail)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, error == nil else { return }
                Task {
                    await self.updateBadge(for: userEmail)
                }
            }
        
        // Listen to friend requests
        db.collection("friendRequests")
            .document(userEmail)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, error == nil else { return }
                Task {
                    await self.updateBadge(for: userEmail)
                }
            }
    }
}

