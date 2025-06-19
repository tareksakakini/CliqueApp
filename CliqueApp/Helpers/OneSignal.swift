//
//  OneSignalManager.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 3/5/25.
//

import Foundation
import OneSignalFramework

func sendPushNotification(notificationText: String, receiverID: String) {
    let url = URL(string: "https://onesignal.com/api/v1/notifications")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("os_v2_app_kn2bhhoqofb4vclavnqu5girwanuad26cpne66v3bw6punh5go7lz726njfiualvmiy2672p5tt7elokzcti2zb2xhqqrwudzmiy2ga", forHTTPHeaderField: "Authorization")

    let payload: [String: Any] = [
        "app_id": "5374139d-d071-43ca-8960-ab614e9911b0",
        "contents": ["en": "\(notificationText)"],
        "include_player_ids": ["\(receiverID)"]
    ]

    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
    } catch {
        print("Error serializing JSON: \(error)")
        return
    }

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error sending push notification: \(error)")
            return
        }
        if let data = data, let responseString = String(data: data, encoding: .utf8) {
            print("Response: \(responseString)")
        }
    }

    task.resume()
}

func getOneSignalSubscriptionId() async -> String? {
    return OneSignal.User.pushSubscription.id
}

// MARK: - OneSignal User Management

/// Force a clean slate for OneSignal - call at app startup
func initializeOneSignalCleanState() async {
    print("[OneSignal] 🧽 INITIALIZING CLEAN STATE")
    
    // Start with a clean slate
    OneSignal.logout()
    
    // Wait for it to clear
    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
    
    await logOneSignalState()
    
    let currentId = getCurrentOneSignalExternalUserId()
    if currentId == nil {
        print("[OneSignal] ✅ Clean state initialized successfully")
    } else {
        print("[OneSignal] ⚠️ WARNING: Still have external ID after clean: \(currentId!)")
    }
}

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

