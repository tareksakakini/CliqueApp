# Badge Notifications Implementation Guide

## Overview

This guide explains the implementation of app icon badge notifications for CliqueApp. The badge count displays the total number of **unanswered event invitations** and **pending friend requests** for the current user.

## How It Works

### 🎯 Key Features

1. **Real-time Updates**: Badge count updates automatically when:
   - A user receives an event invitation
   - A user receives a friend request
   - A user accepts/declines an event invitation
   - A user accepts/rejects a friend request
   - The app becomes active (foreground)

2. **Works When App is Closed**: Badge updates via push notifications, so users see accurate counts even when the app isn't running

3. **Accurate Calculation**: Badge count = Event Invites + Friend Requests

## Implementation Components

### 1. BadgeManager (`Helpers/BadgeManager.swift`)

Central manager for all badge-related functionality.

**Key Methods:**
- `updateBadge(for userEmail: String)` - Calculates and sets badge count
- `calculateBadgeCount(for userEmail: String)` - Returns total badge count
- `clearBadge()` - Removes badge from app icon

**Badge Calculation:**
```swift
Badge Count = Unanswered Event Invites + Pending Friend Requests
```

### 2. Enhanced Push Notifications (`Helpers/OneSignal.swift`)

Updated to include badge counts in all notifications.

**New Functions:**

#### `sendPushNotificationWithBadge()`
Automatically calculates and includes badge count when sending notifications.

```swift
await sendPushNotificationWithBadge(
    notificationText: "John invited you to an event!", 
    receiverID: user.subscriptionId, 
    receiverEmail: user.email
)
```

#### `sendSilentBadgeUpdate()`
Updates badge without showing notification (for background updates).

```swift
await sendSilentBadgeUpdate(
    receiverID: user.subscriptionId, 
    receiverEmail: user.email
)
```

#### `sendPushNotification()` (Updated)
Original function now supports optional badge count parameter:

```swift
sendPushNotification(
    notificationText: "Hello!", 
    receiverID: user.subscriptionId,
    receiverEmail: user.email,  // Optional
    badgeCount: 5                // Optional
)
```

### 3. App Lifecycle Handling (`CliqueAppApp.swift`)

Automatically updates badge when app becomes active.

**Features:**
- Monitors app state (active/inactive/background)
- Updates badge on app foreground
- Handles background push notifications
- Clears badge on first notification permission grant

### 4. ViewModel Integration (`ViewModel/ViewModel.swift`)

Badge updates integrated into all data-changing operations:

**Event Actions:**
- ✅ Accept event invite → Updates badge
- ❌ Decline event invite → Updates badge
- 🚪 Leave event → Updates badge
- ➕ Create/update event → Sends notifications with badges
- 🗑️ Delete event → Sends notifications with badges

**Friend Actions:**
- ➕ Send friend request → Notification with badge
- ✅ Accept friend request → Updates badge + notification
- ❌ Reject friend request → Updates badge
- 🔄 Data refresh → Updates badge

### 5. View Updates

Updated views to use badge-aware notifications:
- `PersonPillView.swift` - Friend request accept/reject
- `FriendDetailsView.swift` - Friend relationship actions

## Technical Details

### OneSignal Badge Configuration

The implementation uses OneSignal's iOS badge functionality:

```swift
payload["ios_badgeType"] = "SetTo"  // Sets absolute badge count
payload["ios_badgeCount"] = badgeCount  // The count to display
```

**Badge Types:**
- `SetTo`: Sets badge to specific number (used in this implementation)
- `Increase`: Increments current badge count
- `None`: No badge update

### Database Queries

Badge count is calculated from:

1. **Event Invites:**
```swift
db.collection("events")
  .whereField("attendeesInvited", arrayContains: userEmail)
```

2. **Friend Requests:**
```swift
db.collection("friendRequests")
  .document(userEmail)
  .getDocument()
```

## Usage Examples

### In ViewModel Functions

```swift
func acceptButtonPressed(user: UserModel, event: EventModel) async {
    // ... database update ...
    
    // Update badge for the user who accepted
    await BadgeManager.shared.updateBadge(for: user.email)
    
    // Notify host with badge
    if let host = self.getUser(by: event.host) {
        await sendPushNotificationWithBadge(
            notificationText: "\(user.fullname) is coming to your event!",
            receiverID: host.subscriptionId,
            receiverEmail: host.email
        )
    }
}
```

### Manual Badge Update

```swift
// In any view or function
Task {
    await BadgeManager.shared.updateBadge(for: currentUser.email)
}
```

### Clear Badge

```swift
await BadgeManager.shared.clearBadge()
```

## Best Practices

### ✅ Do:
- Use `sendPushNotificationWithBadge()` for all user-facing notifications
- Update badge after any action that changes invite/request counts
- Let the app lifecycle handler update badge on foreground
- Include `receiverEmail` in all badge notifications

### ❌ Don't:
- Manually calculate badge counts in views (use BadgeManager)
- Forget to update badge after database changes
- Use old `sendPushNotification()` without badge parameters
- Call badge updates on every small UI change (let system handle)

## Testing

### Test Scenarios:

1. **Event Invitations:**
   - [ ] Create event and invite users → Badge appears on invitees' devices
   - [ ] Accept invitation → Badge decreases
   - [ ] Decline invitation → Badge decreases
   - [ ] Delete event → Badges update for all invitees

2. **Friend Requests:**
   - [ ] Send friend request → Badge appears on receiver's device
   - [ ] Accept friend request → Badge decreases on both devices
   - [ ] Reject friend request → Badge decreases

3. **App Lifecycle:**
   - [ ] Close app, receive invite → Badge shows correct count
   - [ ] Open app → Badge refreshes
   - [ ] Background → Notification updates badge

4. **Multiple Actions:**
   - [ ] Receive 3 event invites + 2 friend requests → Badge shows 5
   - [ ] Accept 1 event, reject 1 friend request → Badge shows 3

## Troubleshooting

### Badge not updating?

1. **Check notification permissions:**
```swift
// Badge requires notification permission
UNUserNotificationCenter.current().getNotificationSettings { settings in
    print("Badge permission: \(settings.badgeSetting)")
}
```

2. **Verify OneSignal player ID:**
```swift
let playerId = await getOneSignalSubscriptionId()
print("OneSignal ID: \(playerId ?? "None")")
```

3. **Check Firestore data:**
```swift
// Manually check badge count
let count = await BadgeManager.shared.calculateBadgeCount(for: userEmail)
print("Badge count should be: \(count)")
```

### Badge shows wrong number?

- Clear and refresh: 
```swift
await BadgeManager.shared.clearBadge()
await BadgeManager.shared.updateBadge(for: userEmail)
```

### Badge not updating when app is closed?

- Verify push notification payload includes badge:
  - Check OneSignal dashboard for notification delivery
  - Ensure `ios_badgeType` and `ios_badgeCount` are in payload
  - Confirm user has valid `subscriptionId` in Firestore

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     App Icon Badge                           │
│                    Shows: Events + Friends                   │
└────────────────────────┬────────────────────────────────────┘
                         │
        ┌────────────────┴────────────────┐
        │                                  │
   ┌────▼────┐                      ┌─────▼──────┐
   │  Local  │                      │   Remote   │
   │ Updates │                      │  Updates   │
   └────┬────┘                      └─────┬──────┘
        │                                  │
   ┌────▼──────────┐              ┌───────▼────────┐
   │ App Lifecycle │              │ Push           │
   │ • Foreground  │              │ Notifications  │
   │ • Active      │              │ • OneSignal    │
   │ • Background  │              │ • Silent Push  │
   └────┬──────────┘              └───────┬────────┘
        │                                  │
        └──────────┬───────────────────────┘
                   │
           ┌───────▼────────┐
           │  BadgeManager  │
           │  • Calculate   │
           │  • Update      │
           │  • Clear       │
           └───────┬────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
   ┌────▼─────┐         ┌────▼────────┐
   │ Firestore│         │  ViewModel  │
   │ Events   │         │  Friend Req │
   │ Invites  │         │             │
   └──────────┘         └─────────────┘
```

## Performance Considerations

- **Efficient Queries**: Badge calculations use indexed Firestore queries
- **Caching**: ViewModel caches event and friend data to reduce queries
- **Debouncing**: App lifecycle updates only when necessary (foreground)
- **Async Operations**: All badge operations are async to prevent UI blocking

## Future Enhancements

Potential improvements:

1. **Real-time Listeners**: Use Firestore listeners for instant badge updates (already implemented in `BadgeManager.startObservingBadgeUpdates()`)
2. **Category Breakdown**: Show separate badges for events vs friends
3. **Rich Notifications**: Include badge count in notification content
4. **Analytics**: Track badge click-through rates
5. **Smart Batching**: Batch multiple badge updates within short time window

## Summary

The badge notification system provides users with at-a-glance information about pending actions, encouraging engagement with the app. By leveraging OneSignal's push notification infrastructure and iOS's native badge system, the implementation ensures badges stay accurate whether the app is open, in background, or completely closed.

**Key Benefits:**
- ✅ Always up-to-date badge counts
- ✅ Works when app is closed
- ✅ Minimal performance impact
- ✅ Integrates seamlessly with existing notification system
- ✅ Easy to maintain and extend

---

*Implementation Date: November 8, 2025*  
*Last Updated: November 8, 2025*

