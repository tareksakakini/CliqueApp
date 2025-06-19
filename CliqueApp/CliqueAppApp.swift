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
    
    var body: some Scene {
        WindowGroup {
            StartingView()
                .environmentObject(vm)
                .accentColor(.green)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        OneSignal.initialize("5374139d-d071-43ca-8960-ab614e9911b0", withLaunchOptions: launchOptions)
        OneSignal.Notifications.requestPermission({ accepted in
            print("User accepted notifications: \(accepted)")
        }, fallbackToSettings: true)
        
        // Initialize OneSignal with clean state
        Task {
            await initializeOneSignalCleanState()
        }
        
        return true
    }
}
