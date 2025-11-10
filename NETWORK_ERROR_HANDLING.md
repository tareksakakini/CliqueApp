# Network Error Handling Implementation

## Overview
This document describes the comprehensive network error handling system implemented to address silent failures and improve user feedback throughout the app.

## Problem Statement
Previously, when network operations failed:
- Failures occurred silently without user notification
- Loading indicators would stall and eventually stop without explanation
- Users were left waiting without knowing if operations succeeded or failed
- No distinction was made between offline status and other errors

## Solution Architecture

### 1. NetworkMonitor (`CliqueApp/Helpers/NetworkMonitor.swift`)
A singleton class that monitors real-time network connectivity status.

**Features:**
- Monitors WiFi, cellular, and ethernet connections
- Publishes connection status changes
- Available throughout the app via `NetworkMonitor.shared`

**Usage:**
```swift
if NetworkMonitor.shared.isConnected {
    // Perform network operation
}
```

### 2. ErrorHandler (`CliqueApp/Helpers/ErrorHandler.swift`)
A centralized error handling utility that provides user-friendly error messages.

**Key Components:**
- `AppError` enum: Standard error types (networkOffline, operationFailed, etc.)
- `handleError()`: Intelligently determines the appropriate error message
- `validateNetworkConnection()`: Validates connectivity before operations
- `AlertConfig`: Standardized alert configuration struct

**Error Detection Logic:**
1. **Offline Detection**: Checks `NetworkMonitor.shared.isConnected`
2. **Network Error Detection**: Scans error messages for network-related keywords
3. **Context-Aware Messages**: Returns operation-specific error messages

**Error Messages:**
- **Offline**: "Your device is offline. Please check your internet connection."
- **Online but Failed**: "[Operation] failed. Please try again."

### 3. Database Layer Updates (`CliqueApp/Helpers/Database.swift`)
All 25+ database operations now include network validation before execution.

**Pattern Applied:**
```swift
func someOperation() async throws {
    // Check network connection before attempting operation
    try ErrorHandler.shared.validateNetworkConnection()
    
    // Proceed with operation
    // ...
}
```

**Operations Updated:**
- User management (add, get, update, delete)
- Event operations (create, update, delete, retrieve)
- Friend management (add, remove, requests)
- Profile operations (upload images, update settings)

### 4. ViewModel Layer Updates (`CliqueApp/ViewModel/ViewModel.swift`)
All major ViewModel operations now properly throw and propagate errors.

**Changes:**
- Methods converted from `async` to `async throws`
- Errors are caught and re-thrown with context
- `refreshData()` silently handles errors (background refresh)

**Key Operations Updated:**
- `signInUser()` - Authentication
- `signUpUserAndAddToFireStore()` - Registration
- `createEventButtonPressed()` - Event creation
- `acceptButtonPressed()` / `declineButtonPressed()` / `leaveButtonPressed()` - Event responses
- `getAllEvents()` / `getAllUsers()` - Data fetching

### 5. Service Layer Updates
**OpenAI Service (`CliqueApp/Services/OpenAIService.swift`):**
- Network validation before API calls
- Proper error propagation

**Unsplash Service (`CliqueApp/Services/UnsplashService.swift`):**
- Network validation with graceful fallback (returns nil)
- Silent failure for non-critical image fetching

### 6. View Layer Updates
All views with network operations now display error alerts to users.

#### CreateEventView
- Error handling for event creation/update
- Uses `ErrorHandler` for contextual messages
- Shows alerts with "OK" button

#### EventDetailView
- Error handling for accept/decline/leave operations
- Error handling for event deletion
- Integrated alert display with `AlertConfig`

#### EventResponseView
- Error handling for all RSVP actions
- Maintains loading states during operations
- Shows contextual error messages

#### LoginView & SignUpView
- Network validation before authentication
- User-friendly error messages for auth failures
- Distinguishes between offline and auth errors

## Error Flow Example

### Example: Creating an Event (Offline)
1. User clicks "Create Event" button
2. Loading indicator appears
3. `createEventButtonPressed()` is called
4. `ErrorHandler.validateNetworkConnection()` is called
5. `NetworkMonitor` detects device is offline
6. Throws `AppError.networkOffline`
7. Caught by view layer
8. `ErrorHandler.handleError()` generates message
9. Alert shown: "Your device is offline. Please check your internet connection."
10. Loading indicator stops

### Example: Creating an Event (Online, Server Error)
1. User clicks "Create Event" button
2. Loading indicator appears
3. Network validation passes
4. Firebase operation begins
5. Server returns error (e.g., permission denied)
6. Error caught by ViewModel
7. Caught by view layer
8. `ErrorHandler.handleError()` generates message
9. Alert shown: "Create event failed. Please try again."
10. Loading indicator stops

## User Experience Improvements

### Before:
- ❌ Silent failures
- ❌ Indefinite loading states
- ❌ No feedback on what went wrong
- ❌ Users uncertain if operations succeeded

### After:
- ✅ Clear error messages
- ✅ Loading states properly resolved
- ✅ Distinction between offline and other errors
- ✅ Users know exactly what happened and what to do

## Testing Scenarios

### Manual Testing Checklist:
1. **Offline Testing:**
   - Turn off WiFi and cellular
   - Attempt to create an event → Should show offline alert
   - Attempt to accept an invite → Should show offline alert
   - Attempt to sign in → Should show offline alert

2. **Online with Server Errors:**
   - Test with invalid credentials → Should show auth error
   - Test with network timeout (simulate) → Should show retry message

3. **Loading States:**
   - All operations should show loading indicators
   - Loading indicators should always resolve (not hang)
   - Success should navigate/dismiss
   - Failure should show alert and stop loading

## Coverage

### Operations with Error Handling:
- ✅ User Authentication (Sign In, Sign Up)
- ✅ Event Creation & Editing
- ✅ Event Deletion
- ✅ RSVP Actions (Accept, Decline, Leave)
- ✅ Friend Requests (Send, Accept, Remove)
- ✅ Profile Updates (Name, Username, Photo)
- ✅ Phone Number Linking
- ✅ AI Event Generation
- ✅ Data Fetching (Events, Users, Friends)

### Non-Critical Operations (Silent Failure):
- Background data refresh (`refreshData()`)
- Image loading for display
- Unsplash image fetching (optional feature)

## Code Patterns

### Adding Error Handling to New Operations:

```swift
// In Database/Service Layer:
func newOperation() async throws {
    try ErrorHandler.shared.validateNetworkConnection()
    // ... operation logic
}

// In ViewModel:
func performNewOperation() async throws {
    do {
        try await databaseManager.newOperation()
        // ... success handling
    } catch {
        print("Error: \(error.localizedDescription)")
        throw error  // Propagate to view
    }
}

// In View:
@State private var errorAlert: AlertConfig? = nil

Button("Do Something") {
    Task {
        do {
            try await vm.performNewOperation()
            // ... success UI updates
        } catch {
            errorAlert = AlertConfig(
                message: ErrorHandler.shared.handleError(error, operation: "Operation name")
            )
        }
    }
}
.alert(errorAlert?.title ?? "Error", isPresented: Binding(
    get: { errorAlert != nil },
    set: { if !$0 { errorAlert = nil } }
)) {
    Button("OK", role: .cancel) { errorAlert = nil }
} message: {
    if let errorAlert = errorAlert {
        Text(errorAlert.message)
    }
}
```

## Files Modified/Created

### Created:
- `CliqueApp/Helpers/NetworkMonitor.swift` (New)
- `CliqueApp/Helpers/ErrorHandler.swift` (New)

### Modified:
- `CliqueApp/Helpers/Database.swift` (25+ methods updated)
- `CliqueApp/ViewModel/ViewModel.swift` (10+ methods updated)
- `CliqueApp/Services/OpenAIService.swift` (1 method updated)
- `CliqueApp/Services/UnsplashService.swift` (1 method updated)
- `CliqueApp/Views/EventViews/CreateEventView.swift` (Error alerts added)
- `CliqueApp/Views/EventViews/EventDetailView.swift` (Error alerts added)
- `CliqueApp/Views/EventViews/EventResponseView.swift` (Error alerts added)
- `CliqueApp/Views/AccountViews/LoginView.swift` (Error handling added)
- `CliqueApp/Views/AccountViews/SignUpView.swift` (Error handling added)

## Maintenance Notes

- NetworkMonitor runs continuously and is lightweight
- Error messages are user-friendly and avoid technical jargon
- All errors are logged to console for debugging
- Loading states are always properly managed (start and stop)
- Alert configurations use SwiftUI's native alert system

## Future Enhancements

Potential improvements for future iterations:
1. Retry logic for transient failures
2. Offline operation queuing
3. More granular error types (timeout, permission, etc.)
4. Analytics integration for error tracking
5. Localization of error messages
6. Network quality indicators in UI

