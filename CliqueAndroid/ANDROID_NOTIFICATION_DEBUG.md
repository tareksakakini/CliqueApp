# Android Notification Debugging Guide

## Overview
This guide helps debug why Android users aren't receiving notifications when actions are performed in the app.

## Enhanced Logging Features

The app now includes comprehensive logging to help identify notification issues. All logs are prefixed with emojis for easy identification:
- 🔧 = Initialization
- 🔐 = Login/Authentication
- 📤 = Sending notification
- ✅ = Success
- ❌ = Error
- ⚠️ = Warning
- 📡 = API Response
- 🔔 = Notification received/clicked

## Common Issues and Solutions

### Issue 1: "No recipients found" Warning

**Symptom:** Log shows:
```
⚠️ Notification sent but no recipients found. Receiver may not be logged into OneSignal with external ID: {receiverUid}
```

**Cause:** The receiver hasn't logged into OneSignal with their user ID.

**Solution:**
1. The receiver must:
   - Have the app installed
   - Be signed in to the app
   - Have notification permissions granted
2. When the receiver signs in, check Logcat for:
   ```
   ✅ Successfully logged in user to OneSignal: {userId}
   ```
3. If you don't see this log, the login may have failed. Check for error messages.

### Issue 2: OneSignal Not Initialized

**Symptom:** Log shows:
```
❌ OneSignal not initialized: App ID is blank or placeholder
```

**Cause:** OneSignal credentials are not configured.

**Solution:**
1. Check `CliqueAndroid/local.properties`:
   ```properties
   ONESIGNAL_APP_ID=your-app-id-here
   ONESIGNAL_REST_KEY=your-rest-key-here
   ```
2. Rebuild the app after adding credentials
3. Check Logcat on app startup for initialization logs

### Issue 3: HTTP 401 Error

**Symptom:** Log shows:
```
❌ Failed to send notification (HTTP 401)
   This usually means: Invalid REST API key
```

**Cause:** The REST API key is incorrect or expired.

**Solution:**
1. Go to OneSignal Dashboard → Settings → Keys & IDs
2. Copy the REST API Key
3. Update `local.properties` with the correct key
4. Rebuild the app

### Issue 4: HTTP 404 Error

**Symptom:** Log shows:
```
❌ Failed to send notification (HTTP 404)
   This usually means: App ID not found or receiver not registered with OneSignal
```

**Cause:** Either the App ID is wrong, or the receiver is not registered.

**Solution:**
1. Verify the App ID in `local.properties` matches OneSignal Dashboard
2. Ensure the receiver has:
   - Opened the app at least once
   - Signed in (which calls `OneSignal.login()`)
   - Granted notification permissions

### Issue 5: Notification Permission Denied

**Symptom:** Log shows:
```
   Notification permission: DENIED
```

**Cause:** User denied notification permissions.

**Solution:**
1. Ask user to go to: Settings → Apps → Yalla → Notifications
2. Enable notifications
3. Or uninstall and reinstall the app to get permission prompt again

## Step-by-Step Debugging Process

### Step 1: Check Sender Logs

When a user performs an action that should send a notification:

1. Open Logcat and filter by `OneSignalManager` or `CliqueAppViewModel`
2. Look for the notification send attempt:
   ```
   📤 Sending notification:
      Receiver UID: {receiverUid}
      Message: {message}
   ```
3. Check the response:
   - ✅ `Notification sent successfully (HTTP 200)` = API call succeeded
   - Check for `recipients` count in response
   - If `recipients: 0`, the receiver is not logged into OneSignal

### Step 2: Check Receiver Status

For the user who should receive the notification:

1. **Check if they're logged into OneSignal:**
   - When they sign in, look for:
     ```
     ✅ Successfully logged in user to OneSignal: {userId}
     ```
   - If this log is missing, login failed

2. **Check OneSignal status:**
   - The app logs OneSignal status on login:
     ```
     OneSignal status after login: {status}
     ```
   - Verify `currentExternalId` matches their user ID

3. **Check notification permissions:**
   - Look for: `Notification permission: GRANTED`
   - If denied, user needs to enable in settings

### Step 3: Verify in OneSignal Dashboard

1. Go to [OneSignal Dashboard](https://onesignal.com/)
2. Navigate to your app
3. Go to **Users** → Search for the receiver's user ID
4. Check if they appear in the list with status "Subscribed"
5. Go to **Messages** → **History** to see notification delivery status

### Step 4: Test Manually

Test if OneSignal is working:

1. Go to OneSignal Dashboard → **Messages** → **New Push**
2. Select "Send to Specific Users"
3. Enter the receiver's user ID (external user ID)
4. Send a test notification
5. If this works → Issue is in app code
6. If this doesn't work → Issue is with receiver's OneSignal setup

## Key Logs to Look For

### On App Startup:
```
🔧 Initializing OneSignal...
   App ID: {appId}
✅ OneSignal initialized successfully
   Notification permission: {GRANTED/DENIED}
```

### On User Sign In:
```
🔐 Logging user into OneSignal: {userId}
   OneSignal status before login: {...}
✅ Successfully logged in user to OneSignal: {userId}
   OneSignal status after login: {...}
✅ User successfully logged into OneSignal
```

### When Sending Notification:
```
📤 Sending notification:
   Receiver UID: {receiverUid}
   Message: {message}
✅ Notification sent successfully (HTTP 200)
✅ Notification delivered to 1 recipient(s)
```

### If Receiver Not Found:
```
⚠️ Notification sent but no recipients found. Receiver may not be logged into OneSignal with external ID: {receiverUid}
   The receiver needs to: 1) Have the app installed, 2) Be signed in, 3) Have OneSignal.login() called with their user ID
```

## Quick Checklist

Before reporting a notification issue, verify:

- [ ] Sender's OneSignal is initialized (check startup logs)
- [ ] Sender's REST API key is configured (not "REPLACE" or blank)
- [ ] Receiver has app installed and opened at least once
- [ ] Receiver is signed in (check for login logs)
- [ ] Receiver has notification permissions granted
- [ ] Receiver appears in OneSignal Dashboard under "Users"
- [ ] Notification shows in OneSignal Dashboard → Messages → History
- [ ] HTTP response code is 200-299
- [ ] Response shows `recipients > 0` (not 0)

## Testing Between Two Devices

1. **Device A (Sender):**
   - Sign in as User A
   - Check Logcat for successful OneSignal login
   - Perform action that should notify User B
   - Check Logcat for notification send logs

2. **Device B (Receiver):**
   - Sign in as User B
   - Check Logcat for successful OneSignal login
   - Verify notification permission is granted
   - Wait for notification

3. **Verify in OneSignal Dashboard:**
   - Both users should appear under "Users"
   - Notification should appear in "Messages" → "History"
   - Check delivery status

## Common Fixes

### Fix 1: Receiver Not Logged In
- Receiver must open app and sign in
- This automatically calls `OneSignal.login(userId)`
- Check Logcat to verify login succeeded

### Fix 2: Credentials Not Configured
- Add `ONESIGNAL_APP_ID` and `ONESIGNAL_REST_KEY` to `local.properties`
- Rebuild the app
- Check startup logs to verify initialization

### Fix 3: Notification Permission Denied
- User must enable notifications in device settings
- Or reinstall app to get permission prompt

### Fix 4: OneSignal Login Failing Silently
- Check Logcat for error messages during login
- Verify OneSignal SDK is properly initialized
- Check for network connectivity issues

## Getting Help

If notifications still don't work after following this guide:

1. Collect Logcat logs from both sender and receiver
2. Filter by: `OneSignalManager`, `CliqueAppViewModel`
3. Note the exact error messages
4. Check OneSignal Dashboard for delivery status
5. Share logs and dashboard screenshots for debugging

