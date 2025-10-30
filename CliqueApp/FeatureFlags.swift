//
//  FeatureFlags.swift
//  CliqueApp
//
//  Feature flags to enable/disable features across the app
//

import Foundation

struct FeatureFlags {
    /// Enable or disable the "Create with AI" button
    /// Set to false to prevent users from using OpenAI API
    static let enableAIEventCreation: Bool = false
    
    /// Force the app to always use light mode
    /// Set to true to disable dark mode
    static let forceLightMode: Bool = true
    
    // Add more feature flags here as needed
}

