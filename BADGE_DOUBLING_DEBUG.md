# Badge Doubling Issue - Debug Guide

## Problem
When the app is closed and a new event invite arrives, the badge increases by **2** instead of **1**. When the app is opened, it corrects to the proper value.

## What I've Added

### 1. Enhanced Logging

All badge operations now log detailed information:

#### In `OneSignal.swift`:
```
🔢 Setting badge via notification to: 3 for user@example.com
📦 Notification payload:
{
  "app_id": "...",
  "contents": {...},
  "ios_badgeType": "SetTo",
  "ios_badgeCount": 3,
  ...
}
📡 OneSignal response status: 200
```

#### In `BadgeManager.swift`:
```
📅 Upcoming event invites for user@example.com: 3 (filtered from 5 total)
📊 Badge count breakdown for user@example.com:
  - Event invites: 3
  - Friend requests: 2
  - Total: 5
```

#### In `AppDelegate`:
```
📬 Received remote notification
📬 Notification data - Email: user@example.com, Expected badge: 3
📬 Badge updated. Current: 4, Expected: 3
⚠️ BADGE MISMATCH DETECTED!
   Current: 4
   Expected: 3
   Difference: 1
```

### 2. Debug Tools

#### Test Badge Calculation
Add this button somewhere in your UI to test:

```swift
Button("Test Badge") {
    Task {
        await BadgeTest.testBadgeNotification(
            userEmail: vm.signedInUser?.email ?? "",
            currentBadge: await UIApplication.shared.applicationIconBadgeNumber
        )
    }
}
```

#### Debug Badge Count
```swift
Button("Debug Badge") {
    Task {
        let info = await BadgeManager.shared.debugBadgeCount(for: "tektech")
        print(info)
    }
}
```

## How to Test

### Test 1: Check Current Badge State

1. With app open, run:
```swift
Task {
    await BadgeTest.testBadgeNotification(
        userEmail: "tektech",
        currentBadge: await UIApplication.shared.applicationIconBadgeNumber
    )
}
```

2. Check Console for output - it will show if badge matches database

### Test 2: Reproduce the Doubling Issue

1. Note current badge count (e.g., 2)
2. Close the app completely
3. Have someone send you an event invite
4. **Before opening the app**, check badge on home screen
5. Expected: 3, Likely seeing: 4
6. Open the app
7. Check Console logs for the mismatch detection

### Test 3: Check Logs When Notification Sent

When creating an event with invites, check the Xcode console for:

```
📤 Sent notification to user@example.com
   Text: John invited you to an event!
   Badge will be set to: 3
   PlayerID: abc123...
📦 Notification payload:
{
  ...
  "ios_badgeType": "SetTo",
  "ios_badgeCount": 3,
  ...
}
```

## Possible Causes

### Cause 1: iOS Auto-Increment + OneSignal SetTo

**Theory:** iOS auto-increments badge when notification arrives (+1), then OneSignal sets it to calculated value (3), resulting in 4.

**Evidence to look for:**
- Logs show badge set to correct value (3)
- But device shows higher value (4)
- Difference is always +1

### Cause 2: Firestore Replication Delay

**Theory:** We calculate badge before Firestore has replicated the new event, so calculation doesn't include the new invite.

**Evidence to look for:**
- Logs show badge calculated as 2 (old value)
- But should be 3 (with new invite)

**Fix applied:** Added 0.5 second delay before calculating badge.

### Cause 3: Notification Sent Twice

**Theory:** Somehow the notification is being sent twice.

**Evidence to look for:**
- Two "Sent notification" log entries for same user
- User receives multiple notifications

### Cause 4: OneSignal Badge Type Not Applied When App Closed

**Theory:** When app is fully closed, iOS might ignore `ios_badgeType: "SetTo"` and use default increment behavior.

**Evidence to look for:**
- Badge correct when app is open/background
- Badge wrong only when app is fully closed

## Debugging Steps

### Step 1: Verify Badge Calculation is Correct

```swift
// Add to a button in your UI
Task {
    let calculated = await BadgeManager.shared.calculateBadgeCount(for: "tektech")
    let device = await UIApplication.shared.applicationIconBadgeNumber
    print("Calculated: \(calculated), Device: \(device)")
    
    if calculated != device {
        print("MISMATCH! Diff: \(device - calculated)")
    }
}
```

### Step 2: Check Notification Payload

After sending an invite, check console for the full payload. Verify:
- ✅ `ios_badgeType` is "SetTo"
- ✅ `ios_badgeCount` is correct number
- ✅ OneSignal response is 200 OK

### Step 3: Monitor App Delegate

When notification arrives with app closed:
1. Open app
2. Check console for `didReceiveRemoteNotification`
3. Look for badge mismatch detection

### Step 4: Test Without Badge in Notification

Try sending notification WITHOUT badge modification to see if double-counting stops:

```swift
// Temporarily modify sendPushNotificationWithBadge to:
func sendPushNotificationWithBadge(notificationText: String, receiverID: String, receiverEmail: String) async {
    // Send without badge
    sendPushNotification(
        notificationText: notificationText, 
        receiverID: receiverID,
        receiverEmail: nil,  // No email
        badgeCount: nil      // No badge!
    )
}
```

Then rely on app delegate to update badge. If this fixes the doubling, we know the issue is with OneSignal's badge handling.

## Potential Solutions

### Solution 1: Use Silent Notification for Badge

Instead of including badge in visible notification, send a separate silent notification to update badge:

```swift
// Send visible notification WITHOUT badge
sendPushNotification(text, id, nil, nil)

// Send silent notification to update badge
await sendSilentBadgeUpdate(receiverID: id, receiverEmail: email)
```

### Solution 2: Let App Delegate Handle All Badge Updates

Remove badge from OneSignal payload entirely:
- Notifications never modify badge
- App delegate always recalculates from database
- Works when app opens or when notification arrives

### Solution 3: Use Notification Service Extension

Update the `NotificationService.swift` to:
1. Intercept notification before display
2. Calculate correct badge
3. Set badge in notification content

```swift
override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
    // ... existing OneSignal code ...
    
    // Calculate and set badge
    if let email = request.content.userInfo["receiverEmail"] as? String {
        Task {
            let badge = await BadgeManager.shared.calculateBadgeCount(for: email)
            bestAttemptContent?.badge = NSNumber(value: badge)
            contentHandler(bestAttemptContent!)
        }
    }
}
```

## Expected Console Output

When everything works correctly, you should see:

```
[Event Creation]
📤 Sent notification to tektech
   Text: John invited you to an event!
   Badge will be set to: 3
   PlayerID: abc123...
📦 Notification payload:
{
  "ios_badgeType": "SetTo",
  "ios_badgeCount": 3,
}
📡 OneSignal response status: 200

[When notification arrives with app closed, then opened]
📬 Received remote notification
📬 Notification data - Email: tektech, Expected badge: 3
📅 Upcoming event invites for tektech: 3 (filtered from 5 total)
📊 Badge count breakdown:
  - Event invites: 3
  - Friend requests: 0
  - Total: 3
📬 Badge updated. Current: 3, Expected: 3
✅ Badge is correct!
```

## Next Steps

1. **Test and gather logs** from both test accounts
2. **Identify pattern** - Is it always +1? Always double?
3. **Check OneSignal Dashboard** - Any delivery issues?
4. **Try Solution 2** - Remove badge from notifications entirely
5. **If still broken** - Implement Solution 3 with Notification Service Extension

Let me know what the logs show and we can narrow down the exact cause!

