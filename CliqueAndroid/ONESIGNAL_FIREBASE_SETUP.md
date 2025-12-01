# OneSignal Firebase Configuration Fix

## Issue: "Invalid Google Project Number" in OneSignal Dashboard

Even though we've configured the Google Project Number in `AndroidManifest.xml`, OneSignal also needs the **Firebase Server Key** configured in the OneSignal dashboard.

## Solution: Configure Firebase Server Key in OneSignal

### Step 1: Get Your Firebase Server Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **cliqueapp-3834b**
3. Click the **gear icon** (⚙️) → **Project settings**
4. Go to the **Cloud Messaging** tab
5. Under **Cloud Messaging API (Legacy)**, you'll see:
   - **Sender ID**: `798737564089` (this is your Google Project Number - already configured ✅)
   - **Server key**: Click **"Generate new key"** or copy the existing key (starts with `AAAA...`)

### Step 2: Add Server Key to OneSignal Dashboard

1. Go to [OneSignal Dashboard](https://onesignal.com/)
2. Select your app: **CliqueApp** (ID: `5374139d-d071-43ca-8960-ab614e9911b0`)
3. Navigate to **Settings** → **Platforms** → **Google Android (FCM)**
4. Enter the following:
   - **FCM Sender ID**: `798737564089` (your Google Project Number)
   - **Firebase Server Key**: Paste the Server Key from Step 1
5. Click **Save**

### Step 3: Verify Configuration

After saving:
1. The "Invalid Google Project Number" error should disappear
2. Wait a few minutes for OneSignal to validate the configuration
3. Check the subscription profile again - it should show "Active" status

### Step 4: Reinstall the App (Important!)

Even though the app code is correct, you need to:
1. **Uninstall** the app from your device completely
2. **Rebuild** the app (to ensure latest manifest is included)
3. **Reinstall** the app on your device
4. **Launch** the app and grant notification permissions
5. The device should now register correctly with OneSignal

## Current Configuration Summary

✅ **AndroidManifest.xml**: Google Project Number = `798737564089`  
✅ **google-services.json**: Present and configured  
✅ **OneSignal App ID**: `5374139d-d071-43ca-8960-ab614e9911b0`  
✅ **OneSignal REST API Key**: Configured in `local.properties`  
❌ **OneSignal Dashboard**: Needs Firebase Server Key (do this now!)

## Troubleshooting

### Still seeing "Invalid Google Project Number"?
1. Make sure you've added the **Firebase Server Key** (not just the Sender ID) in OneSignal dashboard
2. Wait 2-3 minutes after saving for OneSignal to validate
3. Uninstall and reinstall the app after making dashboard changes
4. Check that the Sender ID in OneSignal matches: `798737564089`

### Can't find Firebase Server Key?
- If you don't see a Server Key in Firebase Console:
  1. Go to **Cloud Messaging** tab in Project Settings
  2. If "Cloud Messaging API (Legacy)" is not enabled, you may need to enable it
  3. Or use the newer "Cloud Messaging API (V1)" - OneSignal supports both

### Notifications still not working?
1. Verify notification permissions are granted on device
2. Check Logcat for OneSignal initialization messages
3. Send a test notification from OneSignal dashboard
4. Verify the device appears in OneSignal dashboard under **Audience** → **All Users**

## Important Notes

- The **Google Project Number** (`798737564089`) is the same as the **FCM Sender ID**
- The **Firebase Server Key** is different from the **REST API Key**
- Both need to be configured: one in code (AndroidManifest), one in dashboard (OneSignal)
- The app must be reinstalled after any manifest changes for them to take effect





