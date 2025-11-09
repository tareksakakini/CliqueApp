//
//  CliqueAppApp.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI
import Firebase
import OneSignalFramework
import FirebaseAuth

@main
struct CliqueAppApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var vm = ViewModel()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            StartingView()
                .environmentObject(vm)
                .accentColor(.green)
                .preferredColorScheme(FeatureFlags.forceLightMode ? .light : nil)
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhaseChange(newPhase)
                }
        }
    }
    
    // MARK: - App Lifecycle Handling
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            print("🟢 App became active")
            updateBadgeIfNeeded()
        case .inactive:
            print("🟡 App became inactive")
        case .background:
            print("🔴 App went to background")
        @unknown default:
            break
        }
    }
    
    private func updateBadgeIfNeeded() {
        // Update badge when app becomes active
        Task {
            if let user = await vm.getSignedInUser() {
                await BadgeManager.shared.updateBadge(for: user.email)
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Load OneSignal App ID from config file
        guard let path = Bundle.main.path(forResource: "OneSignal-Info", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let appId = config["APP_ID"] as? String else {
            print("❌ CRITICAL: Could not load OneSignal App ID from OneSignal-Info.plist")
            print("❌ Notifications will NOT work!")
            return true
        }
        
        OneSignal.initialize(appId, withLaunchOptions: launchOptions)
        OneSignal.Notifications.requestPermission({ accepted in
            print("User accepted notifications: \(accepted)")
            if accepted {
                // Clear badge on first launch if user accepts notifications
                Task {
                    await BadgeManager.shared.clearBadge()
                }
            }
        }, fallbackToSettings: true)
        
        // Initialize OneSignal with clean state
        Task {
            await initializeOneSignalCleanState()
        }
        
        return true
    }
    
    // MARK: - Background Notification Handling
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("📬 Received remote notification")
        print("📬 UserInfo: \(userInfo)")
        
        // Handle badge update from notification data
        if let customData = userInfo["custom"] as? [String: Any],
           let additionalData = customData["a"] as? [String: Any] {
            
            let receiverEmail = additionalData["receiverEmail"] as? String
            let expectedBadge = additionalData["expectedBadge"] as? Int
            
            print("📬 Notification data - Email: \(receiverEmail ?? "none"), Expected badge: \(expectedBadge ?? -1)")
            
            if let email = receiverEmail {
                Task {
                    // Recalculate badge from database to ensure accuracy
                    await BadgeManager.shared.updateBadge(for: email)
                    
                    let currentBadge = await UIApplication.shared.applicationIconBadgeNumber
                    print("📬 Badge updated. Current: \(currentBadge), Expected: \(expectedBadge ?? -1)")
                    
                    if let expected = expectedBadge, currentBadge != expected {
                        print("⚠️ BADGE MISMATCH DETECTED!")
                        print("   Current: \(currentBadge)")
                        print("   Expected: \(expected)")
                        print("   Difference: \(currentBadge - expected)")
                    }
                    
                    completionHandler(.newData)
                }
            } else {
                completionHandler(.noData)
            }
        } else {
            completionHandler(.noData)
        }
    }
}
