import UserNotifications
import OneSignalExtension
import FirebaseCore
import FirebaseFirestore

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var receivedRequest: UNNotificationRequest!
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.receivedRequest = request
        self.contentHandler = contentHandler
        self.bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            print("🔔 [Extension] Notification received")
            
            // Let OneSignal process the notification first (but don't call handler yet)
            OneSignalExtension.didReceiveNotificationExtensionRequest(self.receivedRequest, with: bestAttemptContent, withContentHandler: nil)
            
            // Extract receiver email from notification data
            var receiverEmail: String? = nil
            
            // Try to get email from OneSignal custom data format
            if let custom = bestAttemptContent.userInfo["custom"] as? [String: Any],
               let additionalData = custom["a"] as? [String: Any],
               let email = additionalData["receiverEmail"] as? String {
                receiverEmail = email
                print("🔔 [Extension] Found email in custom.a: \(email)")
            }
            // Also try direct data field
            else if let email = bestAttemptContent.userInfo["receiverEmail"] as? String {
                receiverEmail = email
                print("🔔 [Extension] Found email in root: \(email)")
            }
            
            if let email = receiverEmail {
                // Calculate and set badge
                calculateAndSetBadge(for: email, content: bestAttemptContent, handler: contentHandler)
            } else {
                print("⚠️ [Extension] No receiverEmail found, delivering notification without badge")
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    private func calculateAndSetBadge(for email: String, content: UNMutableNotificationContent, handler: @escaping (UNNotificationContent) -> Void) {
        print("🔔 [Extension] Calculating badge for: \(email)")
        
        // Initialize Firebase if needed
        if FirebaseApp.app() == nil {
            print("🔔 [Extension] Initializing Firebase")
            FirebaseApp.configure()
        }
        
        let db = Firestore.firestore()
        
        // Use a task to handle async operations
        Task {
            do {
                // Count upcoming event invites
                let eventSnapshot = try await db.collection("events")
                    .whereField("attendeesInvited", arrayContains: email)
                    .getDocuments()
                
                let now = Date()
                let upcomingInvites = eventSnapshot.documents.filter { doc in
                    guard let data = doc.data() as? [String: Any],
                          let timestamp = data["startDateTime"] as? Timestamp else {
                        return false
                    }
                    return timestamp.dateValue() >= now
                }.count
                
                print("🔔 [Extension] Upcoming event invites: \(upcomingInvites)")
                
                // Count friend requests
                let friendReqSnapshot = try await db.collection("friendRequests")
                    .document(email)
                    .getDocument()
                let friendRequests = (friendReqSnapshot.data()?["requests"] as? [String])?.count ?? 0
                
                print("🔔 [Extension] Friend requests: \(friendRequests)")
                
                // Calculate total badge
                let totalBadge = upcomingInvites + friendRequests
                content.badge = NSNumber(value: totalBadge)
                
                print("🔔 [Extension] ✅ Set badge to \(totalBadge) for \(email)")
                
                // Deliver the notification
                handler(content)
                
            } catch {
                print("❌ [Extension] Error calculating badge: \(error.localizedDescription)")
                // Deliver notification anyway, just without updated badge
                handler(content)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        print("⏰ [Extension] Time expiring, delivering notification")
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            OneSignalExtension.serviceExtensionTimeWillExpireRequest(self.receivedRequest, with: self.bestAttemptContent)
            contentHandler(bestAttemptContent)
        }
    }
}
