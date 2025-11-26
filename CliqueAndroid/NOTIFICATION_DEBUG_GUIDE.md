# Notification Debugging Guide

## Issue: Friend Request Notifications Not Received

### Common Causes

1. **Receiver Not Logged Into OneSignal**
   - The receiver must have the app installed and logged in
   - OneSignal must be initialized with their user ID via `OneSignal.login(userId)`
   - Check: The receiver should see their user ID in OneSignal dashboard under "Users" → "External User IDs"

2. **OneSignal Not Configured**
   - Check `BuildConfig.ONESIGNAL_APP_ID` and `BuildConfig.ONESIGNAL_REST_KEY`
   - Verify they're not blank or "REPLACE"
   - Check `local.properties` has `ONESIGNAL_REST_KEY` set

3. **Notification Permissions Not Granted**
   - Receiver must grant notification permissions on their device
   - Check device settings → Apps → Yalla → Notifications

4. **Network/API Issues**
   - Check Logcat for OneSignal error messages
   - Verify HTTP response codes (should be 200-299)
   - Check OneSignal dashboard for delivery status

### Debugging Steps

#### Step 1: Check Logcat Output

When sending a friend request, you should see logs like:

```
D/CliqueAppViewModel: 📤 Sending friend request from {senderUid} to {receiverUid}
D/CliqueAppViewModel: ✅ Friend request saved to database
D/CliqueAppViewModel: 📤 Sending notification with route: {...}
D/OneSignalManager: 📤 Sending notification:
D/OneSignalManager:    Receiver UID: {receiverUid}
D/OneSignalManager:    Message: {senderName} just sent you a friend request!
D/OneSignalManager:    Title: Yalla
D/OneSignalManager:    Route: {...}
D/OneSignalManager:    Route JSON: {...}
D/OneSignalManager: 📦 Notification payload: {...}
D/OneSignalManager: ✅ Notification sent successfully (HTTP 200)
D/OneSignalManager: 📡 OneSignal response: {...}
```

**If you see errors:**
- `❌ Cannot send notification: OneSignal not configured` → Check BuildConfig values
- `❌ Failed to send notification (HTTP 400/401)` → Check API key and app ID
- `❌ Failed to send notification (HTTP 404)` → Receiver not found in OneSignal

#### Step 2: Verify Receiver's OneSignal Setup

The receiver must:
1. Have the app installed
2. Be signed in to the app
3. Have granted notification permissions
4. Have OneSignal initialized with their user ID

**To verify:**
- Ask receiver to check Logcat when they sign in
- Should see: `OneSignal.login({userId})` being called
- Check OneSignal dashboard: Settings → Users → Search for receiver's user ID

#### Step 3: Check OneSignal Dashboard

1. Go to [OneSignal Dashboard](https://onesignal.com/)
2. Navigate to your app
3. Go to **Messages** → **History**
4. Look for the notification you sent
5. Check delivery status:
   - ✅ **Delivered**: Notification was sent successfully
   - ❌ **Failed**: Check error message
   - ⏳ **Pending**: Still processing

#### Step 4: Test Notification Manually

You can test if OneSignal is working by:
1. Going to OneSignal Dashboard
2. **Messages** → **New Push**
3. Select "Send to Specific Users"
4. Enter the receiver's user ID (external user ID)
5. Send a test notification
6. If this works, the issue is in the app code
7. If this doesn't work, the issue is with receiver's OneSignal setup

### Code Verification Checklist

- [ ] `OneSignalManager.sendPushNotification()` is being called
- [ ] Receiver UID is correct (not empty, matches user's actual UID)
- [ ] Route is properly formatted
- [ ] BuildConfig has valid OneSignal credentials
- [ ] No exceptions are being caught silently
- [ ] HTTP response code is 200-299

### Quick Fixes

1. **If receiver hasn't logged in:**
   - Receiver must open the app and sign in
   - This will call `oneSignalManager.login(userId)`

2. **If OneSignal credentials are wrong:**
   - Check `local.properties` for `ONESIGNAL_REST_KEY`
   - Check `strings.xml` for `onesignal_app_id`
   - Rebuild the app after changes

3. **If notification is sent but not received:**
   - Check device notification settings
   - Check if app is in battery optimization (may block notifications)
   - Try uninstalling and reinstalling the app

### Testing Locally

To test notifications between two devices:

1. **Device A (Sender):**
   - Sign in as User A
   - Send friend request to User B

2. **Device B (Receiver):**
   - Sign in as User B
   - Should receive notification
   - Check Logcat for OneSignal activity

3. **Verify in OneSignal Dashboard:**
   - Both users should appear under "Users"
   - Notification should appear in "Messages" → "History"



