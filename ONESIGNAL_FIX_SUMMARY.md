# OneSignal Notification Fix - Summary

## Problem

Users were receiving notifications on devices even after signing out. The issue was that the app was sending notifications using **device-specific subscription IDs** (`include_player_ids`) rather than **user-specific external user IDs** (`include_external_user_ids`).

### What was happening:
1. User signs in on Device A → their subscription ID is saved to Firestore
2. User signs out from Device A → `OneSignal.logout()` is called, but subscription ID remains in database
3. App sends notification using the subscription ID from Firestore
4. Device A receives notification even though user is logged out

## Solution

The fix involves switching from device-based to user-based notification targeting, which respects OneSignal's login/logout state.

### Key Changes:

#### 1. **Notification Sending (OneSignal.swift)**
- **Changed**: `include_player_ids` → `include_external_user_ids`
- **Impact**: Notifications are now sent to user IDs instead of device IDs
- **Result**: OneSignal only delivers notifications to devices where the user is currently logged in

```swift
// OLD (device-based)
"include_player_ids": [receiverID]

// NEW (user-based)
"include_external_user_ids": [receiverUID]
```

#### 2. **Removed Subscription ID Tracking**
- Removed `subscriptionId` field from `UserModel`
- Removed `updateUserSubscriptionId()` from Database and ViewModel
- Updated all notification calls to use `receiverUID` instead of `receiverID`
- Removed subscription ID checks throughout the codebase

#### 3. **Improved Sign-In/Sign-Out Flow**

**Sign In (ViewModel.signInUser):**
```swift
1. Clear any existing OneSignal associations
2. Set up OneSignal for the new user (OneSignal.login(userID))
3. Verify the setup succeeded
```

**Sign Out (ViewModel.signoutButtonPressed):**
```swift
1. Clear OneSignal associations (OneSignal.logout())
2. Verify the clearing succeeded
3. Sign out from Firebase
```

**App Launch (StartingView):**
```swift
1. Check if user is signed in
2. If yes:
   - Verify OneSignal is configured for correct user
   - If mismatch: clear and re-setup
3. If no:
   - Ensure OneSignal is cleared
```

#### 4. **Removed App Launch Clean State**
- Removed `initializeOneSignalCleanState()` from app launch
- OneSignal now maintains user state across app launches
- This allows users to receive notifications on multiple devices

## How It Works Now

### Multi-Device Support
Users can now receive notifications on multiple devices:
1. User signs in on Device A → OneSignal.login(userUID) on Device A
2. User signs in on Device B → OneSignal.login(userUID) on Device B
3. Both devices are associated with the same external user ID
4. Notification sent to userUID → both devices receive it
5. User signs out from Device A → Device A stops receiving notifications
6. Device B continues receiving notifications

### The Golden Rule
**A device receives notifications if and only if:**
- The user is currently signed in on that device
- OneSignal.login(userUID) has been called for that user
- OneSignal.logout() has NOT been called since then

## Technical Details

### OneSignal External User IDs
- Each Firebase user UID is used as the OneSignal external user ID
- `OneSignal.login(userUID)` associates the current device with that user
- `OneSignal.logout()` removes the association
- Multiple devices can be associated with the same external user ID

### Notification Delivery Flow
```
1. Event occurs (e.g., friend request)
2. App calls sendPushNotificationWithBadge(receiverUID: user.uid, ...)
3. OneSignal receives notification with include_external_user_ids: [userUID]
4. OneSignal finds all devices logged in as that userUID
5. OneSignal delivers notification to those devices only
```

### Safety Mechanisms
- **StartingView**: Verifies OneSignal state on app launch
- **Sign-In**: Always clears before setting up (prevents stale sessions)
- **Sign-Out**: Verifies clearing succeeded (retries if needed)
- **MainView**: Re-verifies OneSignal configuration if needed

## Files Modified

1. **CliqueApp/Helpers/OneSignal.swift**
   - Changed notification sending to use external_user_ids
   - Removed initializeOneSignalCleanState()

2. **CliqueApp/Models/User.swift**
   - Removed subscriptionId field

3. **CliqueApp/Helpers/Database.swift**
   - Removed updateUserSubscriptionId()

4. **CliqueApp/ViewModel/ViewModel.swift**
   - Removed updateOneSignalSubscriptionId()
   - Updated all notification calls to use receiverUID

5. **CliqueApp/Views/StartingView.swift**
   - Enhanced OneSignal verification logic
   - Added mismatch detection and correction

6. **CliqueApp/CliqueAppApp.swift**
   - Removed initializeOneSignalCleanState() call

7. **CliqueApp/Views/MainView.swift**
   - Removed updateOneSignalSubscriptionId() call

8. **All notification sending locations**
   - Updated to use receiverUID instead of receiverID

## Testing Recommendations

1. **Single Device Test:**
   - Sign in → verify notifications work
   - Sign out → verify notifications stop
   - Sign in again → verify notifications resume

2. **Multi-Device Test:**
   - Sign in on Device A → verify notifications work
   - Sign in on Device B → verify notifications work on both
   - Sign out from Device A → verify Device B still gets notifications
   - Sign out from Device B → verify notifications stop

3. **Account Switching Test:**
   - Sign in as User 1 → verify notifications
   - Sign out
   - Sign in as User 2 → verify only User 2 notifications arrive

4. **App Restart Test:**
   - Sign in → restart app → verify notifications still work
   - Sign out → restart app → verify notifications don't arrive

## Important Notes

- **No database migration needed**: Old subscriptionId fields in Firestore are simply ignored
- **Backward compatible**: Old users will automatically work with new system on next sign-in
- **No API changes**: OneSignal API version remains the same
- **Multiple devices**: Users can be signed in on unlimited devices simultaneously

## Conclusion

The new system properly respects user sessions and device states. Notifications will only be delivered to devices where the user is actively signed in, while still supporting multiple simultaneous sessions across different devices.

