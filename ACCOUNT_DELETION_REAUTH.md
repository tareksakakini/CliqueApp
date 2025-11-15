# Account Deletion Re-authentication

## Overview

Firebase requires recent authentication for sensitive operations like account deletion. If a user hasn't signed in recently (typically within the last 5 minutes), they must re-authenticate before deleting their account.

## Problem

**Before:**
- User tries to delete account after being logged in for a while
- Error occurs: "This operation is sensitive and requires recent authentication"
- User sees generic "Failed to delete account" message
- No way to proceed, user is stuck

**After:**
- User tries to delete account
- System detects re-authentication is required
- Clear alert explains what's happening
- User can re-authenticate with one tap
- Deletion automatically proceeds after successful verification

## Implementation

### Files Modified

1. **MySettingsView.swift**
   - Added state variables for re-authentication flow
   - Detects Firebase error code 17014 (requires recent authentication)
   - Shows clear alert with explanation
   - Presents re-authentication sheet
   - Automatically retries deletion after success

2. **ReAuthenticationView.swift** (New)
   - Dedicated view for re-authentication
   - Automatically sends verification code
   - User enters code to verify identity
   - Uses same phone number as account
   - Clean, focused UI

### User Flow

#### Happy Path (Recent Authentication)
```
1. User taps "Delete Account"
2. Confirms deletion
3. Account deleted immediately ✅
```

#### Re-authentication Path (Stale Session)
```
1. User taps "Delete Account"
2. Confirms deletion
3. System detects stale authentication
4. Alert appears: "Re-authentication Required"
   - Message: "For security reasons, you need to verify 
              your identity before deleting your account. 
              This only takes a moment."
   - Buttons: [Re-authenticate] [Cancel]
5. User taps "Re-authenticate"
6. Sheet appears with verification code entry
7. Code sent to user's phone automatically
8. User enters 6-digit code
9. Taps "Verify & Continue"
10. Sheet dismisses
11. Account deletion proceeds automatically ✅
```

## Technical Details

### Error Detection

**Firebase Error Code:**
- Domain: `FIRAuthErrorDomain`
- Code: `17014` (requiresRecentLogin)
- Message: "This operation is sensitive and requires recent authentication"

**Detection Logic:**
```swift
catch let error as NSError {
    if error.domain == "FIRAuthErrorDomain" && error.code == 17014 {
        // Show re-authentication alert
        showReauthAlert = true
    } else {
        // Handle other errors normally
    }
}
```

### Re-authentication Process

**ReAuthenticationView:**
1. Receives user's phone number
2. Automatically sends verification code on appear
3. User enters verification code
4. Creates Firebase phone credential
5. Calls `currentUser.reauthenticate(with: credential)`
6. On success, calls success callback
7. MySettingsView automatically retries deletion

**State Management:**
- `showReauthAlert`: Shows initial alert
- `showReauthFlow`: Presents re-authentication sheet
- `pendingDeletion`: Tracks if deletion should retry after re-auth
- `verificationID`: Stores verification session
- `verificationCode`: User's input

### Security Benefits

1. **Prevents Unauthorized Deletion**
   - Ensures person deleting account has access to phone
   - Even if someone left device unlocked

2. **Recent Authentication Window**
   - Firebase enforces ~5 minute freshness
   - Balance between security and UX

3. **Phone Verification**
   - Uses same secure method as login
   - SMS code required

## User Experience Improvements

### Clear Communication
- Alert title: "Re-authentication Required"
- Explains why this is happening
- Sets expectation: "This only takes a moment"

### One-Tap Solution
- "Re-authenticate" button in alert
- Takes user directly to verification
- No confusion about what to do

### Automatic Flow
- Code sent automatically
- Deletion retries automatically after verification
- User doesn't need to navigate back

### Visual Feedback
- Loading states during code sending
- Loading states during verification
- Clear error messages if something fails
- Timer for resend code (60 seconds)

## Error Handling

### Re-authentication Errors

**Invalid Code:**
- Shows error message below code input
- User can try again or resend code

**Network Error:**
- Clear message about connection
- User can retry when back online

**Too Many Attempts:**
- Firebase rate limiting message
- Suggests using test numbers for development

**User Cancels:**
- "Cancel" button in alert clears pending deletion
- "Cancel" button in nav bar dismisses sheet
- No deletion occurs if cancelled

### Original Deletion Errors

All other errors still handled normally:
- Network errors
- Firestore errors
- Database errors
- Shows error message with auto-dismiss

## Testing

### Test Re-authentication Flow

**Setup:**
1. Build and run app
2. Login with account
3. Wait a few minutes (or force need for re-auth)
4. Go to Settings

**Test Steps:**
1. Tap "Delete Account"
2. Confirm in dialog
3. Alert should appear: "Re-authentication Required"
4. Tap "Re-authenticate"
5. Enter verification code from SMS
6. Tap "Verify & Continue"
7. Account should delete successfully

**With Test Numbers:**
```
Phone: 650-555-1234
Code: 123456
```

### Edge Cases to Test

1. **Cancel at Alert**
   - Tap "Cancel" in re-auth alert
   - Should abort deletion
   - Can try again later

2. **Cancel in Sheet**
   - Tap "Cancel" in navigation bar
   - Should dismiss sheet
   - Should abort deletion

3. **Wrong Code**
   - Enter incorrect code
   - Should show error
   - Can try again

4. **Network Loss**
   - Disable network during code send
   - Should show network error
   - Can retry when back online

5. **Resend Code**
   - Wait 60 seconds
   - Tap "Resend Code"
   - New code should arrive

## Future Enhancements

Possible improvements:
- Remember re-authentication for X minutes
- Support biometric re-authentication
- Add "Use different phone" option
- Show deletion progress after re-auth
- Add confirmation after successful deletion

## Notes

- Re-authentication is required by Firebase, not optional
- This protects users from accidental/malicious deletions
- Same flow could be used for other sensitive operations:
  - Changing phone number
  - Unlinking accounts
  - Modifying security settings

