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

