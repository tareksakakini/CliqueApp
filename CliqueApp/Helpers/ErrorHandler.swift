import Foundation
import SwiftUI

/// Centralized error handling and user messaging
class ErrorHandler {
    static let shared = ErrorHandler()
    
    private init() {}
    
    /// Standard error type for the app
    enum AppError: LocalizedError {
        case networkOffline
        case operationFailed(String)
        case authenticationFailed(String)
        case permissionDenied
        case invalidData
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .networkOffline:
                return "Your device is offline. Please check your internet connection."
            case .operationFailed(let operation):
                return "\(operation) failed. Please try again."
            case .authenticationFailed(let message):
                return message
            case .permissionDenied:
                return "Permission denied. Please check your app permissions."
            case .invalidData:
                return "Invalid data received. Please try again."
            case .unknown:
                return "Request failed. Please try again."
            }
        }
    }
    
    /// Determines the appropriate error message based on network status and error type
    func handleError(_ error: Error, operation: String = "Request") -> String {
        // Check if offline
        if !NetworkMonitor.shared.isConnected {
            return AppError.networkOffline.errorDescription ?? "Connection error"
        }
        
        // Check for specific error types
        let errorString = error.localizedDescription.lowercased()
        
        // Network-related errors
        if errorString.contains("network") || 
           errorString.contains("internet") || 
           errorString.contains("connection") ||
           errorString.contains("offline") ||
           errorString.contains("timed out") ||
           errorString.contains("unreachable") {
            return AppError.networkOffline.errorDescription ?? "Connection error"
        }
        
        // Firebase/Firestore specific errors
        if errorString.contains("permission") || errorString.contains("unauthorized") {
            return AppError.permissionDenied.errorDescription ?? "Permission error"
        }
        
        // Return generic error with operation context
        return AppError.operationFailed(operation).errorDescription ?? "Request failed"
    }
    
    /// Validates network connection before performing operation
    func validateNetworkConnection() throws {
        if !NetworkMonitor.shared.isConnected {
            throw AppError.networkOffline
        }
    }
    
    /// Creates a standardized alert configuration
    func createAlert(title: String = "Error", message: String) -> (title: String, message: String) {
        return (title, message)
    }
}

/// Alert state management for views
struct AlertConfig: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    
    init(title: String = "Error", message: String) {
        self.title = title
        self.message = message
    }
}

