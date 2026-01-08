# Enable Firebase Legacy API to Get Server Key

## Quick Fix: Enable Legacy API

Since OneSignal may still require the Legacy Server Key, here's how to enable it:

### Step 1: Enable Cloud Messaging API (Legacy)

1. In the Firebase Console (where you're currently viewing Cloud Messaging settings)
2. Find the **"Cloud Messaging API (Legacy)"** section (it shows "Disabled")
3. Click the **three dots (⋮)** or **"Manage API in Google Cloud Console"** link
4. This will open Google Cloud Console
5. Click **"Enable"** to activate the Legacy API
6. Return to Firebase Console and **refresh the page**

### Step 2: Get the Server Key

1. After enabling, go back to Firebase Console → **Project Settings** → **Cloud Messaging** tab
2. Under **"Cloud Messaging API (Legacy)"**, you should now see:
   - **Sender ID**: `798737564089`
   - **Server key**: Click **"Generate new key"** or copy the existing one (starts with `AAAA...`)

### Step 3: Add to OneSignal

1. Go to [OneSignal Dashboard](https://onesignal.com/)
2. **Settings** → **Platforms** → **Google Android (FCM)**
3. Enter:
   - **FCM Sender ID**: `798737564089`
   - **Firebase Server Key**: (paste the key from Step 2)
4. Click **Save**

### Step 4: Reinstall App

1. Uninstall app from device
2. Rebuild and reinstall
3. Launch and grant permissions

## Note

⚠️ **Legacy API is deprecated** and will stop working on June 20, 2024. However, OneSignal may still require it for now. You can migrate to V1 API later when OneSignal fully supports it.









