# Quick Fix Option for Badge Doubling

## The Issue
OneSignal's `ios_badgeType: "SetTo"` + iOS default behavior = double counting

## Quick Fix: Disable Badge in Notifications

### Option A: Remove Badge from Notification (Simplest)

Modify `sendPushNotification` to NEVER set badge via notification:

```swift
// In OneSignal.swift, change this:
if let badgeCount = badgeCount {
    payload["ios_badgeType"] = "SetTo"
    payload["ios_badgeCount"] = badgeCount
}

// To this:
// Don't set badge via notification at all
// Let app handle it locally
```

**Pros:** Simple, eliminates double-counting
**Cons:** Badge only updates when user opens app

### Option B: Use Notification Service Extension (Recommended)

The Notification Service Extension runs BEFORE the notification is displayed, even when app is closed. This is the proper iOS way to modify badges.

1. Update `NotificationService.swift`:

```swift
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
            // Let OneSignal process first
            OneSignalExtension.didReceiveNotificationExtensionRequest(self.receivedRequest, with: bestAttemptContent, withContentHandler: nil)
            
            // Then calculate and set correct badge
            if let receiverEmail = bestAttemptContent.userInfo["receiverEmail"] as? String {
                calculateAndSetBadge(for: receiverEmail, content: bestAttemptContent, handler: contentHandler)
            } else {
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    private func calculateAndSetBadge(for email: String, content: UNMutableNotificationContent, handler: @escaping (UNNotificationContent) -> Void) {
        // Initialize Firebase if needed
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        let db = Firestore.firestore()
        
        // Calculate badge from Firestore
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
                
                // Count friend requests
                let friendReqSnapshot = try await db.collection("friendRequests")
                    .document(email)
                    .getDocument()
                let friendRequests = (friendReqSnapshot.data()?["requests"] as? [String])?.count ?? 0
                
                // Set badge
                let totalBadge = upcomingInvites + friendRequests
                content.badge = NSNumber(value: totalBadge)
                
                print("📛 [Extension] Set badge to \(totalBadge) for \(email)")
                
                handler(content)
            } catch {
                print("❌ [Extension] Error calculating badge: \(error)")
                handler(content)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            OneSignalExtension.serviceExtensionTimeWillExpireRequest(self.receivedRequest, with: self.bestAttemptContent)
            contentHandler(bestAttemptContent)
        }
    }
}
```

2. Update OneSignal notifications to NOT include badge:

```swift
// In OneSignal.swift, modify sendPushNotification:
var payload: [String: Any] = [
    "app_id": "5374139d-d071-43ca-8960-ab614e9911b0",
    "contents": ["en": "\(notificationText)"],
    "include_player_ids": ["\(receiverID)"],
    "mutable_content": true  // REQUIRED for extension to run
]

// DON'T set ios_badgeType or ios_badgeCount
// Let the extension handle it

// Add email to data so extension can calculate badge
payload["data"] = ["receiverEmail": receiverEmail ?? ""]
```

**Pros:** 
- ✅ Works when app is closed
- ✅ Badge accurate immediately
- ✅ No double-counting
- ✅ Proper iOS approach

**Cons:** 
- Requires Firebase in extension
- Slightly more complex

### Option C: Hybrid Approach (Balanced)

Keep current badge-in-notification approach, but fix it in app delegate when notification arrives:

```swift
// In AppDelegate
func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    
    // Extract email from notification
    if let customData = userInfo["custom"] as? [String: Any],
       let additionalData = customData["a"] as? [String: Any],
       let receiverEmail = additionalData["receiverEmail"] as? String {
        
        Task {
            // Force recalculation from database (fixes any double-counting)
            await BadgeManager.shared.updateBadge(for: receiverEmail)
            completionHandler(.newData)
        }
    } else {
        completionHandler(.noData)
    }
}
```

**Pros:** 
- ✅ Simple change
- ✅ Fixes badge when app opens
- ✅ Backup for notification badge

**Cons:** 
- ⚠️ Badge wrong until app opens

## My Recommendation

**Try Option B (Notification Service Extension)** - it's the proper iOS solution and will fix the issue completely.

The extension runs BEFORE the notification displays, so the badge will always be correct, even when app is fully closed.

## Testing After Fix

1. Close app completely
2. Have someone send you an invite
3. Check badge on home screen
4. Should show correct count immediately
5. Open app - badge should stay the same (not change)

Let me know which approach you want to try!

