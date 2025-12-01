# OneSignal Firebase V1 API Setup

## Current Situation

Your Firebase project is using **Firebase Cloud Messaging API (V1)** (the recommended, modern API), but the **Legacy API is disabled**. OneSignal needs to be configured to work with V1 API.

## Solution: Use Service Account with OneSignal

Since you're using V1 API, OneSignal needs a **Service Account** instead of the old Server Key.

### Step 1: Create/Get Service Account in Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Make sure you're in the correct project: **cliqueapp-3834b**
3. Navigate to **IAM & Admin** → **Service Accounts**
4. Look for an existing service account, or create a new one:
   - Click **"Create Service Account"**
   - Name: `onesignal-fcm` (or any name you prefer)
   - Click **"Create and Continue"**
   - Grant role: **"Firebase Cloud Messaging API Admin"** or **"Firebase Admin"**
   - Click **"Continue"** → **"Done"**

### Step 2: Create and Download Service Account Key

1. In the **Service Accounts** list, find the service account you just created (or use an existing one)
2. Click on the service account name
3. Go to the **"Keys"** tab
4. Click **"Add Key"** → **"Create new key"**
5. Select **JSON** format
6. Click **"Create"** - this will download a JSON file (e.g., `cliqueapp-3834b-xxxxx.json`)

### Step 3: Configure OneSignal with Service Account

**Option A: Using OneSignal Dashboard (Recommended)**

1. Go to [OneSignal Dashboard](https://onesignal.com/)
2. Select your app: **CliqueApp**
3. Navigate to **Settings** → **Platforms** → **Google Android (FCM)**
4. You should see options for:
   - **FCM Sender ID**: `798737564089` (already correct ✅)
   - **Firebase Server Key** (Legacy) - leave empty since Legacy is disabled
   - **Service Account** section - this is what you need!

5. In the Service Account section:
   - Upload the JSON file you downloaded, OR
   - Enter the Service Account Email and Private Key manually

**Option B: Manual Entry (if upload doesn't work)**

1. Open the downloaded JSON file in a text editor
2. Find these values:
   - `"client_email"`: This is the Service Account email
   - `"private_key"`: This is the private key (starts with `-----BEGIN PRIVATE KEY-----`)
3. In OneSignal dashboard, enter:
   - **Service Account Email**: (from `client_email`)
   - **Private Key**: (from `private_key` - include the entire key with BEGIN/END markers)

### Step 4: Verify Configuration

1. Save the configuration in OneSignal
2. Wait 2-3 minutes for OneSignal to validate
3. Check your device subscription in OneSignal dashboard
4. The "Invalid Google Project Number" error should disappear

### Step 5: Reinstall the App

1. **Uninstall** the app from your device completely
2. **Rebuild** the app
3. **Reinstall** and launch
4. Grant notification permissions
5. Device should register correctly with OneSignal

## Important Notes

- ✅ **V1 API is the recommended approach** - you're using the modern API
- ✅ **Sender ID** (`798737564089`) is already configured correctly
- ✅ **Service Account** is more secure than Legacy Server Key
- ⚠️ **Keep the Service Account JSON file secure** - don't commit it to Git
- ⚠️ **OneSignal may need a few minutes** to validate the Service Account

## Troubleshooting

### OneSignal doesn't have Service Account option?
- Make sure you're using a recent version of OneSignal SDK (you have 5.1.15 ✅)
- Some OneSignal accounts may need to enable V1 API support
- Contact OneSignal support if the option isn't available

### Still seeing errors?
1. Verify the Service Account has the correct permissions in Google Cloud
2. Check that the JSON file is valid (not corrupted)
3. Make sure you're using the correct project's Service Account
4. Try regenerating the Service Account key

### Alternative: Enable Legacy API (Not Recommended)

If OneSignal doesn't support V1 Service Account yet, you can temporarily:
1. Go back to Firebase Console → Cloud Messaging
2. Enable "Cloud Messaging API (Legacy)"
3. Generate a Server Key
4. Use that in OneSignal (but this is deprecated and will stop working in 2024)





