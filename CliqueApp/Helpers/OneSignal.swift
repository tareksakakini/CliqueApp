//
//  OneSignalManager.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 3/5/25.
//

import Foundation
import OneSignalFramework

// MARK: - OneSignal Configuration

/// Loads OneSignal configuration from OneSignal-Info.plist
private func loadOneSignalConfig() -> (apiKey: String, appId: String)? {
    guard let path = Bundle.main.path(forResource: "OneSignal-Info", ofType: "plist"),
          let config = NSDictionary(contentsOfFile: path),
          let apiKey = config["API_KEY"] as? String,
          let appId = config["APP_ID"] as? String else {
        print("❌ ERROR: Could not load OneSignal-Info.plist. Make sure the file exists in CliqueApp/Services/")
        return nil
    }
    return (apiKey, appId)
}

func sendPushNotification(notificationText: String,
                          receiverUID: String,
                          receiverEmail: String? = nil,
                          badgeCount: Int? = nil,
                          route: [String: Any]? = nil,
                          title: String? = nil) {
    guard let config = loadOneSignalConfig() else {
        print("❌ Cannot send notification: OneSignal configuration not loaded")
        return
    }
    
    let url = URL(string: "https://onesignal.com/api/v1/notifications")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(config.apiKey, forHTTPHeaderField: "Authorization")

    var payload: [String: Any] = [
        "app_id": config.appId,
        "contents": ["en": "\(notificationText)"],
        "include_external_user_ids": ["\(receiverUID)"],  // Changed from include_player_ids to include_external_user_ids
        "mutable_content": true  // REQUIRED - allows notification service extension to modify badge
    ]
    
    // Add custom title if provided
    if let title = title {
        payload["headings"] = ["en": title]
    }
    
    // DO NOT set badge here - let the Notification Service Extension handle it
    // This prevents double-counting issues
    print("📤 Sending notification WITHOUT badge (will be set by extension)")
    
    // Add custom data for badge calculation in extension
    var customData: [String: Any] = [:]
    if let receiverEmail = receiverEmail {
        customData["receiverEmail"] = receiverEmail
        print("📤 Added receiverEmail to notification: \(receiverEmail)")
    }
    if let route = route {
        customData[NotificationRouter.Key.route] = route
        print("📤 Added route to notification: \(route)")
    }
    if !customData.isEmpty {
        payload["data"] = customData
    }

    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted])
        if let jsonString = String(data: request.httpBody!, encoding: .utf8) {
            print("📦 Notification payload:")
            print(jsonString)
        }
    } catch {
        print("Error serializing JSON: \(error)")
        return
    }

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("❌ Error sending push notification: \(error)")
            return
        }
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 OneSignal response status: \(httpResponse.statusCode)")
        }
        if let data = data, let responseString = String(data: data, encoding: .utf8) {
            print("📡 OneSignal response: \(responseString)")
        }
    }

    task.resume()
}

// MARK: - Enhanced Push Notification with Automatic Badge Calculation

/// Sends a push notification with automatic badge count calculation
func sendPushNotificationWithBadge(notificationText: String,
                                   receiverUID: String,
                                   receiverEmail: String,
                                   route: [String: Any]? = nil,
                                   title: String? = nil) async {
    let badgeCount = await BadgeManager.shared.calculateBadgeCount(for: receiverEmail)
    sendPushNotification(notificationText: notificationText,
                         receiverUID: receiverUID,
                         receiverEmail: receiverEmail,
                         badgeCount: badgeCount,
                         route: route,
                         title: title)
    print("📤 Sent notification to \(receiverEmail)")
    print("   Title: \(title ?? "Yalla")")
    print("   Text: \(notificationText)")
    print("   Badge will be set to: \(badgeCount)")
    print("   User UID: \(receiverUID)")
}

/// Sends a silent notification to update badge count only
func sendSilentBadgeUpdate(receiverUID: String, receiverEmail: String) async {
    guard let config = loadOneSignalConfig() else {
        print("❌ Cannot send silent badge update: OneSignal configuration not loaded")
        return
    }
    
    let badgeCount = await BadgeManager.shared.calculateBadgeCount(for: receiverEmail)
    
    let url = URL(string: "https://onesignal.com/api/v1/notifications")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(config.apiKey, forHTTPHeaderField: "Authorization")
    
    let payload: [String: Any] = [
        "app_id": config.appId,
        "include_external_user_ids": [receiverUID],  // Changed from include_player_ids to include_external_user_ids
        "content_available": true, // Silent notification
        "ios_badgeType": "SetTo",
        "ios_badgeCount": badgeCount,
        "data": ["receiverEmail": receiverEmail, "badgeUpdate": true]
    ]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        
        let (data, _) = try await URLSession.shared.data(for: request)
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔕 Silent badge update sent: \(responseString)")
        }
    } catch {
        print("❌ Error sending silent badge update: \(error)")
    }
}

func getOneSignalSubscriptionId() async -> String? {
    return OneSignal.User.pushSubscription.id
}

// MARK: - OneSignal User Management

/// Sets up OneSignal for a signed-in user with enhanced verification
func setupOneSignalForUser(userID: String) async {
    print("[OneSignal] ===== SETTING UP USER =====")
    print("[OneSignal] Target User ID: \(userID)")
    
    // Log initial state
    await logOneSignalState()
    
    // Set the external user ID to associate this device with the user
    print("[OneSignal] Calling OneSignal.login(\(userID))")
    OneSignal.login(userID)
    
    // Wait longer and verify the change took effect
    print("[OneSignal] Waiting for login to complete...")
    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
    
    // Verify the login worked
    let currentExternalId = getCurrentOneSignalExternalUserId()
    if currentExternalId == userID {
        print("[OneSignal] ✅ SUCCESS: External user ID correctly set to: \(userID)")
    } else {
        print("[OneSignal] ❌ FAILED: Expected \(userID), but got: \(currentExternalId ?? "None")")
        
        // Try again if it failed
        print("[OneSignal] Retrying login...")
        OneSignal.login(userID)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 more second
        
        let retryExternalId = getCurrentOneSignalExternalUserId()
        if retryExternalId == userID {
            print("[OneSignal] ✅ RETRY SUCCESS: External user ID set to: \(userID)")
        } else {
            print("[OneSignal] ❌ RETRY FAILED: Still got: \(retryExternalId ?? "None")")
        }
    }
    
    await logOneSignalState()
    print("[OneSignal] ===== SETUP COMPLETE =====")
}

/// Clears OneSignal association when user signs out with enhanced verification
func clearOneSignalForUser() async {
    print("[OneSignal] ===== CLEARING USER ASSOCIATION =====")
    
    // Log initial state
    await logOneSignalState()
    
    // Log out from OneSignal to disassociate this device from the user
    print("[OneSignal] Calling OneSignal.logout()")
    OneSignal.logout()
    
    // Wait longer and verify the change took effect
    print("[OneSignal] Waiting for logout to complete...")
    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
    
    // Verify the logout worked
    let currentExternalId = getCurrentOneSignalExternalUserId()
    if currentExternalId == nil {
        print("[OneSignal] ✅ SUCCESS: External user ID cleared")
    } else {
        print("[OneSignal] ❌ FAILED: External user ID still set to: \(currentExternalId!)")
        
        // Try again if it failed
        print("[OneSignal] Retrying logout...")
        OneSignal.logout()
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 more second
        
        let retryExternalId = getCurrentOneSignalExternalUserId()
        if retryExternalId == nil {
            print("[OneSignal] ✅ RETRY SUCCESS: External user ID cleared")
        } else {
            print("[OneSignal] ❌ RETRY FAILED: Still set to: \(retryExternalId!)")
        }
    }
    
    await logOneSignalState()
    print("[OneSignal] ===== CLEAR COMPLETE =====")
}

/// Gets the current OneSignal external user ID
func getCurrentOneSignalExternalUserId() -> String? {
    return OneSignal.User.externalId
}

/// Checks if OneSignal is properly configured for the current user
func isOneSignalConfiguredForUser(expectedUserID: String) -> Bool {
    guard let currentExternalId = getCurrentOneSignalExternalUserId() else {
        print("[OneSignal] ❌ No external user ID found, expected: \(expectedUserID)")
        return false
    }
    
    let isConfigured = currentExternalId == expectedUserID
    if isConfigured {
        print("[OneSignal] ✅ Correctly configured for user: \(expectedUserID)")
    } else {
        print("[OneSignal] ❌ MISMATCH - Expected: \(expectedUserID), Current: \(currentExternalId)")
    }
    return isConfigured
}

/// Logs current OneSignal state for debugging
func logOneSignalState() async {
    let externalId = getCurrentOneSignalExternalUserId() ?? "None"
    let subscriptionId = await getOneSignalSubscriptionId() ?? "None"
    
    print("[OneSignal] ===== CURRENT STATE =====")
    print("[OneSignal] External User ID: \(externalId)")
    print("[OneSignal] Subscription ID: \(subscriptionId)")
    print("[OneSignal] ==========================")
}

/// Force verification that OneSignal is in the expected state
func verifyOneSignalState(expectedUserID: String?) async -> Bool {
    await logOneSignalState()
    
    let currentExternalId = getCurrentOneSignalExternalUserId()
    let isCorrect = currentExternalId == expectedUserID
    
    if isCorrect {
        print("[OneSignal] ✅ STATE VERIFICATION PASSED")
    } else {
        print("[OneSignal] ❌ STATE VERIFICATION FAILED")
        print("[OneSignal] Expected: \(expectedUserID ?? "None")")
        print("[OneSignal] Actual: \(currentExternalId ?? "None")")
    }
    
    return isCorrect
}
