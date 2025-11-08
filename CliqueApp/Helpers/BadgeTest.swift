//
//  BadgeTest.swift
//  CliqueApp
//
//  Test utilities for debugging badge notification issues
//

import Foundation
import UIKit

class BadgeTest {
    
    /// Test: Send notification and compare expected vs actual badge
    static func testBadgeNotification(userEmail: String, currentBadge: Int) async {
        print("🧪 BADGE TEST STARTING")
        print("================================")
        print("User: \(userEmail)")
        print("Current badge on device: \(await UIApplication.shared.applicationIconBadgeNumber)")
        print("Current badge expected: \(currentBadge)")
        
        // Calculate what badge SHOULD be
        let calculatedBadge = await BadgeManager.shared.calculateBadgeCount(for: userEmail)
        print("Calculated badge from DB: \(calculatedBadge)")
        
        // Check if they match
        let deviceBadge = await UIApplication.shared.applicationIconBadgeNumber
        if deviceBadge != calculatedBadge {
            print("⚠️ MISMATCH DETECTED!")
            print("   Device shows: \(deviceBadge)")
            print("   Database says: \(calculatedBadge)")
            print("   Difference: \(deviceBadge - calculatedBadge)")
            
            if deviceBadge == calculatedBadge + 1 {
                print("   🔍 Badge is OFF BY ONE - likely auto-increment issue")
            }
        } else {
            print("✅ Badge is correct!")
        }
        
        // Log detailed breakdown
        let debugInfo = await BadgeManager.shared.debugBadgeCount(for: userEmail)
        print("\n" + debugInfo)
        
        print("================================")
        print("🧪 BADGE TEST COMPLETE\n")
    }
    
    /// Simulate what happens when a notification arrives
    static func simulateNotificationArrival(
        currentBadge: Int,
        newInviteCount: Int,
        userEmail: String
    ) async {
        print("🔬 SIMULATING NOTIFICATION ARRIVAL")
        print("================================")
        print("Current badge: \(currentBadge)")
        print("New invites being sent: \(newInviteCount)")
        
        // What we expect after notification
        let expectedBadge = await BadgeManager.shared.calculateBadgeCount(for: userEmail)
        print("Expected badge after notification: \(expectedBadge)")
        
        // What might actually happen with auto-increment
        let possibleBuggyBadge = expectedBadge + newInviteCount
        print("Buggy badge (if auto-increment happens): \(possibleBuggyBadge)")
        
        print("================================\n")
    }
}

