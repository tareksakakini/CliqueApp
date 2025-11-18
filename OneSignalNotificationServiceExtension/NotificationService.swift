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
            
            // Extract receiver data from notification
            var receiverId: String? = nil

            if let custom = bestAttemptContent.userInfo["custom"] as? [String: Any],
               let additionalData = custom["a"] as? [String: Any],
               let userId = additionalData["receiverId"] as? String {
                receiverId = userId
                print("🔔 [Extension] Found receiverId in custom.a: \(userId)")
            } else if let userId = bestAttemptContent.userInfo["receiverId"] as? String {
                receiverId = userId
                print("🔔 [Extension] Found receiverId in root: \(userId)")
            }
            
            if let receiverId {
                calculateAndSetBadge(userId: receiverId, content: bestAttemptContent, handler: contentHandler)
            } else {
                print("⚠️ [Extension] No receiverId found, delivering notification without badge")
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    private func calculateAndSetBadge(userId: String, content: UNMutableNotificationContent, handler: @escaping (UNNotificationContent) -> Void) {
        print("🔔 [Extension] Calculating badge for: id=\(userId)")
        
        // Initialize Firebase if needed
        if FirebaseApp.app() == nil {
            print("🔔 [Extension] Initializing Firebase")
            FirebaseApp.configure()
        }
        
        let db = Firestore.firestore()
        
        // Use a task to handle async operations
        Task {
            do {
                let doc = try await db.collection("users").document(userId).getDocument()
                
                guard let data = doc.data() else {
                    print("❌ [Extension] User document not found for \(userId)")
                    handler(content)
                    return
                }
                
                let phoneValues = phoneQueryValues(from: data["phoneNumber"] as? String ?? "")
                
                // Count upcoming event invites
                var eventDocs: [QueryDocumentSnapshot] = []
                var seen = Set<String>()
                
                let invitedSnapshot = try await db.collection("events")
                    .whereField("attendeesInvited", arrayContains: userId)
                    .getDocuments()
                for doc in invitedSnapshot.documents where seen.insert(doc.documentID).inserted {
                    eventDocs.append(doc)
                }
                
                for phone in phoneValues {
                    let phoneSnapshot = try await db.collection("events")
                        .whereField("invitedPhoneNumbers", arrayContains: phone)
                        .getDocuments()
                    for doc in phoneSnapshot.documents where seen.insert(doc.documentID).inserted {
                        eventDocs.append(doc)
                    }
                }
                
                let now = floatingWallClockNow()
                let upcomingInvites = eventDocs.filter { doc in
                    let data = doc.data()
                    guard let timestamp = data["startDateTime"] as? Timestamp else {
                        return false
                    }
                    return timestamp.dateValue() >= now
                }.count
                
                print("🔔 [Extension] Upcoming event invites: \(upcomingInvites)")
                
                // Count friend requests
                let friendReqSnapshot = try await db.collection("friendRequests")
                    .document(userId)
                    .getDocument()
                let friendRequests = (friendReqSnapshot.data()?["requests"] as? [String])?.count ?? 0
                
                print("🔔 [Extension] Friend requests: \(friendRequests)")
                
                // Calculate total badge
                let totalBadge = upcomingInvites + friendRequests
                content.badge = NSNumber(value: totalBadge)
                
                print("🔔 [Extension] ✅ Set badge to \(totalBadge) for id=\(userId)")
                
                // Deliver the notification
                handler(content)
                
            } catch {
                print("❌ [Extension] Error calculating badge: \(error.localizedDescription)")
                // Deliver notification anyway, just without updated badge
                handler(content)
            }
        }
    }
    
    private func floatingWallClockNow() -> Date {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: TimeZone.current, from: now)
        var utcComponents = DateComponents()
        utcComponents.year = components.year
        utcComponents.month = components.month
        utcComponents.day = components.day
        utcComponents.hour = components.hour
        utcComponents.minute = components.minute
        utcComponents.second = components.second
        utcComponents.timeZone = TimeZone(identifier: "UTC")
        
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        return utcCalendar.date(from: utcComponents) ?? now
    }
    
    private func canonicalPhoneNumber(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        guard !digits.isEmpty else { return "" }
        if digits.count == 11, digits.hasPrefix("1") {
            return String(digits.dropFirst())
        }
        return digits
    }
    
    private func e164PhoneNumber(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        
        if trimmed.hasPrefix("+") {
            let normalizedDigits = trimmed.dropFirst().filter { $0.isNumber }
            return normalizedDigits.isEmpty ? "" : "+\(normalizedDigits)"
        }
        
        if trimmed.hasPrefix("00") {
            let normalizedDigits = trimmed.dropFirst(2).filter { $0.isNumber }
            return normalizedDigits.isEmpty ? "" : "+\(normalizedDigits)"
        }
        
        let digits = trimmed.filter { $0.isNumber }
        guard !digits.isEmpty else { return "" }
        
        if digits.count == 10 {
            return "+1\(digits)"
        }
        
        if digits.count == 11, digits.hasPrefix("1") {
            return "+\(digits)"
        }
        
        return "+\(digits)"
    }
    
    private func phoneQueryValues(from rawPhone: String) -> [String] {
        var values = Set<String>()
        let canonical = canonicalPhoneNumber(rawPhone)
        if !canonical.isEmpty {
            values.insert(canonical)
        }
        let e164 = e164PhoneNumber(rawPhone)
        if !e164.isEmpty {
            values.insert(e164)
        }
        return Array(values)
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
