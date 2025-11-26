# OneSignal Setup Instructions for Android

## Overview
OneSignal is already integrated into the Android app. You just need to add your credentials to complete the setup.

## Current Status
✅ OneSignal SDK dependency is added (version 5.1.15)  
✅ OneSignalManager is implemented and initialized  
✅ AndroidManifest has required permissions and meta-data  
✅ Notification routing is configured  
❌ **You need to add your OneSignal credentials**

## Setup Steps

### Step 1: Get Your OneSignal Credentials

1. Go to [OneSignal Dashboard](https://onesignal.com/)
2. Navigate to your app: **CliqueApp** (ID: `5374139d-d071-43ca-8960-ab614e9911b0`)
3. Go to **Settings** → **Keys & IDs**
4. Copy the following:
   - **App ID** (under "OneSignal App ID") - looks like: `5374139d-d071-43ca-8960-ab614e9911b0`
   - **REST API Key** (under "REST API Key") - looks like: `os_v2_app_...`

### Step 2: Add OneSignal App ID

1. Open `CliqueAndroid/app/src/main/res/values/strings.xml`
2. Replace `CHANGE_ME_IN_SECRETS` with your actual OneSignal App ID:

```xml
<resources>
    <string name="app_name">Yalla</string>
    <string name="onesignal_app_id">5374139d-d071-43ca-8960-ab614e9911b0</string>
</resources>
```

### Step 3: Add OneSignal REST API Key

1. Open `CliqueAndroid/local.properties` (this file is already gitignored)
2. Add your REST API key at the end of the file:

```properties
## This file must *NOT* be checked into Version Control Systems,
# as it contains information specific to your local configuration.
#
# Location of the SDK. This is only used by Gradle.
# For customization when using a Version Control System, please read the
# header note.
#Tue Nov 18 22:23:39 PST 2025
sdk.dir=/Users/tareksakakini/Library/Android/sdk

# OneSignal REST API Key (DO NOT COMMIT THIS FILE)
ONESIGNAL_REST_KEY=os_v2_app_YOUR_ACTUAL_KEY_HERE
```

**Important:** Replace `os_v2_app_YOUR_ACTUAL_KEY_HERE` with your actual REST API key from Step 1.

### Step 4: Verify Setup

1. **Sync Gradle** in Android Studio (or run `./gradlew build` from terminal)
2. **Build the app** to ensure there are no errors
3. **Run the app** on a device or emulator
4. Check Logcat for OneSignal initialization messages:
   - ✅ Look for: "OneSignal initialized successfully"
   - ❌ If you see: "OneSignal App ID not configured" - check your `strings.xml`
   - ❌ If you see: "OneSignal REST API Key not configured" - check your `local.properties`

### Step 5: Test Notifications

1. The app will automatically request notification permissions on first launch
2. Grant notification permissions when prompted
3. Test sending a notification from the OneSignal dashboard:
   - Go to OneSignal Dashboard → **Messages** → **New Push**
   - Select your app
   - Send a test notification to your device

## Security Notes

⚠️ **NEVER commit the following files to Git:**
- `local.properties` - Contains your REST API key (already in `.gitignore`)
- Any files with actual API keys

⚠️ **The following files are safe to commit:**
- `strings.xml` - Contains App ID (less sensitive, but still be careful)
- `build.gradle.kts` - Only contains placeholder values

⚠️ **If an API key is exposed:**
1. OneSignal will automatically revoke it
2. Generate a new key from the OneSignal dashboard
3. Update your `local.properties` file
4. DO NOT hardcode keys in source code

## Troubleshooting

### "OneSignal App ID not configured" Error
- Check that `strings.xml` has the correct App ID
- Make sure the App ID doesn't contain "CHANGE_ME"
- Rebuild the app after making changes

### "OneSignal REST API Key not configured" Error
- Check that `local.properties` exists in `CliqueAndroid/` directory
- Verify `ONESIGNAL_REST_KEY` is set in `local.properties`
- Make sure the key doesn't contain "REPLACE_WITH"
- Sync Gradle after adding the key

### Notifications Not Working
1. Verify your API key is valid in OneSignal dashboard
2. Check that your App ID matches your OneSignal app
3. Ensure notification permissions are granted on device
4. Check Logcat for OneSignal error messages
5. Verify Firebase Cloud Messaging is properly configured (required for Android)

### Build Errors
- Make sure `local.properties` file exists (even if empty)
- Sync Gradle: **File** → **Sync Project with Gradle Files**
- Clean and rebuild: **Build** → **Clean Project**, then **Build** → **Rebuild Project**

## For Team Members

When cloning this repository:
1. Create `CliqueAndroid/local.properties` if it doesn't exist
2. Add your SDK path: `sdk.dir=/path/to/your/android/sdk`
3. Add `ONESIGNAL_REST_KEY=your_key_here` to `local.properties`
4. Update `strings.xml` with the OneSignal App ID (or get it from team lead)
5. Never commit your `local.properties` file

## Architecture Notes

The OneSignal integration follows this flow:

1. **Initialization**: `CliqueAndroidApp.onCreate()` → `OneSignalManager.initialize()`
2. **User Login**: When user logs in, call `oneSignalManager.login(userId)`
3. **User Logout**: When user logs out, call `oneSignalManager.logout()`
4. **Notification Click**: Handled by `OneSignalManager` → `NotificationRouter.handlePayload()`
5. **Sending Notifications**: Use `oneSignalManager.sendPushNotification()` method

The `OneSignalManager` is available through the `AppContainer` and can be accessed via dependency injection in your ViewModels.



