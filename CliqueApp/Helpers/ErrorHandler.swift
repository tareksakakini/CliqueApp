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
        
        // Firebase Phone Auth specific errors
        if errorString.contains("too-many-requests") || errorString.contains("quota") || errorString.contains("unusual activity") {
            return "Too many verification attempts. Please wait 15-60 minutes, or use a test phone number for development (see FIREBASE_TEST_NUMBERS.md)."
        }
        
        if errorString.contains("invalid-phone-number") {
            return "Invalid phone number format. Please check and try again."
        }
        
        if errorString.contains("missing-phone-number") {
            return "Please enter a phone number."
        }
        
        if errorString.contains("captcha") || errorString.contains("recaptcha") {
            return "Verification failed. Please make sure you have a stable internet connection and try again."
        }
        
        if errorString.contains("invalid-verification") || errorString.contains("session-expired") {
            return "Verification code expired or invalid. Please request a new code."
        }
        
        if errorString.contains("missing-client-identifier") || errorString.contains("app-not-authorized") {
            return "App configuration error. Please contact support."
        }
        
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
        
        // Return generic error with operation context, but include the actual error for debugging
        return "\(AppError.operationFailed(operation).errorDescription ?? "Request failed") (\(error.localizedDescription))"
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

