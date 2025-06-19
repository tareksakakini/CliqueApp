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

/// Sets up OneSignal for a signed-in user
func setupOneSignalForUser(userID: String) async {
    print("[OneSignal] Setting up OneSignal for user: \(userID)")
    
    // Set the external user ID to associate this device with the user
    OneSignal.login(userID)
    
    // Wait a moment for the login to complete
    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    
    print("[OneSignal] External user ID set to: \(userID)")
    await logOneSignalState()
}

/// Clears OneSignal association when user signs out
func clearOneSignalForUser() async {
    print("[OneSignal] Clearing OneSignal user association")
    
    // Log out from OneSignal to disassociate this device from the user
    OneSignal.logout()
    
    print("[OneSignal] User association cleared")
    await logOneSignalState()
}

/// Gets the current OneSignal external user ID
func getCurrentOneSignalExternalUserId() -> String? {
    return OneSignal.User.externalId
}

/// Checks if OneSignal is properly configured for the current user
func isOneSignalConfiguredForUser(expectedUserID: String) -> Bool {
    guard let currentExternalId = getCurrentOneSignalExternalUserId() else {
        print("[OneSignal] No external user ID found")
        return false
    }
    
    let isConfigured = currentExternalId == expectedUserID
    print("[OneSignal] Configured for user \(expectedUserID): \(isConfigured) (current: \(currentExternalId))")
    return isConfigured
}

/// Logs current OneSignal state for debugging
func logOneSignalState() async {
    let externalId = getCurrentOneSignalExternalUserId() ?? "None"
    let subscriptionId = await getOneSignalSubscriptionId() ?? "None"
    
    print("[OneSignal] Current State:")
    print("  - External User ID: \(externalId)")
    print("  - Subscription ID: \(subscriptionId)")
}

